#!/usr/bin/env bash
# Build the film-mode ML fork inside WSL (or any Linux) and collect the card
# files (autoexec.bin + ML/ folder, ready to copy to the card).
#
#   build_fork.sh                 EOS M          -> ml-dev/out/fork/
#   build_fork.sh 650D.104        another camera -> ml-dev/out/fork-650D.104/
#   build_fork.sh 6D.116 --no-darkroom
#                                 without the in-camera darkroom (~60 KB less at boot, for cameras
#                                 that can't spare it) -> ml-dev/out/fork-6D.116-nodark/
#   build_fork.sh 1100D.105 --module
#                                 the film OS as a module (ML/modules/filmos.mo, loaded after boot):
#                                 autoexec.bin keeps only Magic Lantern and three hooks, ~190 KB less
#                                 at boot -> ml-dev/out/fork-1100D.105-module/ (both flags can go together)
#
# The cameras are the folders under platform/ in magiclantern_simplified; the
# ones M-Film knows are listed in CAMERAS (ml-dev/cameras.txt).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="${ML_SRC:-$HOME/ml/magiclantern_simplified}"
PLAT="${1:-EOSM.202}"
NODARK=""
MODULE=""
for a in "${@:2}"; do
    case "$a" in
        --no-darkroom) NODARK="--no-darkroom" ;;
        --module)      MODULE="--module" ;;
        *) echo "unknown option $a"; exit 1 ;;
    esac
done
TAG="${NODARK:+-nodark}${MODULE:+-module}"
if [ "$PLAT" = "EOSM.202" ] && [ -z "$TAG" ]; then OUT="$HERE/out/fork"; else OUT="$HERE/out/fork-$PLAT$TAG"; fi
LOG="${LOG:-$HOME/ml/build_fork_$PLAT$TAG.log}"

cp "$HERE"/fork/src/filmroll.{c,h} "$HERE"/fork/src/filmhook.c "$HERE"/filmos/fos*.{c,h} "$SRC/src/"
sed -i 's/\r$//' "$SRC"/src/filmroll.{c,h} "$SRC"/src/filmhook.c "$SRC"/src/fos*.{c,h}
# M-Film's version, one for the camera and the program (VERSION at the top of the repository)
VERSION=$(tr -d ' \r\n' < "$HERE/../VERSION")
printf '#define MFILM_VERSION "%s"\n' "$VERSION" > "$SRC/src/fos_version.h"
echo "M-Film $VERSION"
python3 "$HERE/fork/apply_fork.py" "$SRC" "$PLAT" $NODARK $MODULE

cd "$SRC/platform/$PLAT"
make clean >/dev/null
make -j"$(nproc)" FATAL_WARNINGS=y > "$LOG" 2>&1 || true
grep -E "error:|warning:" "$LOG" | grep -v "#warning FIXME" || true

ZIP=$(ls -t build/*.zip 2>/dev/null | head -1 || true)
if [ -z "$ZIP" ]; then
    echo "no zip produced, see $LOG; its end:"
    tail -60 "$LOG"
    exit 1
fi

# What autoexec.bin takes at boot: the camera gives ML everything from
# RESTARTSTART to the end of its bss out of Canon's own memory, and with too
# much it hangs at power on (card LED stays lit). The limit is known only
# where someone has found it on the camera (cameras.txt): on the EOS M,
# 727072 bytes is the largest build known to start (2026-10).
LIMIT=$(awk -v p="$PLAT" '$1 == p { print $3 }' "$HERE/cameras.txt")
RESTART=$(sed -n 's/^RESTARTSTART *= *//p' Makefile)
BSS_END=0x$(arm-none-eabi-nm build/magiclantern | awk '$3 == "_bss_end" { print $1 }')
USED=$((BSS_END - RESTART))
if [ -n "$LIMIT" ] && [ "$LIMIT" != "-" ]; then
    echo "ML takes $USED bytes at boot (limit $LIMIT)"
    if [ "$USED" -gt "$LIMIT" ]; then
        echo "TOO BIG: the camera may not start. Move code or data out of autoexec.bin."
        exit 1
    fi
else
    echo "ML takes $USED bytes at boot (no limit known for $PLAT yet: if the camera hangs at power on, it is too big)"
fi
mkdir -p "$HERE/out" && echo "$USED" > "$HERE/out/.size-$PLAT$TAG"

rm -rf "$OUT" && mkdir -p "$OUT"
(cd "$OUT" && unzip -q "$SRC/platform/$PLAT/$ZIP")

if [ -n "$MODULE" ]; then
    # the film OS as ML/modules/filmos.mo, built for this camera only (fork/module/Makefile)
    MOD="$SRC/modules/filmos"
    # every setting filmroll.c keeps must be in the module's list too, or the module forgets it at power off
    UNSAVED=$(comm -23 <(grep -o 'CONFIG_INT("filmroll\.[a-z_]*", *[a-z_]*' "$HERE/fork/src/filmroll.c" | sed 's/.*, *//' | sort) \
                       <(grep -o 'MODULE_CONFIG([a-z_]*)' "$HERE/fork/src/filmos_mod.h" | sed 's/MODULE_CONFIG(\(.*\))/\1/' | sort))
    if [ -n "$UNSAVED" ]; then
        echo "settings in filmroll.c missing from MODULE_CONFIGS in fork/src/filmos_mod.h:"; echo "$UNSAVED"; exit 1
    fi
    rm -rf "$MOD" && mkdir -p "$MOD"
    cp "$HERE"/fork/module/{Makefile,README.rst} "$HERE"/fork/src/filmroll.{c,h} "$HERE"/fork/src/filmos_mod.h \
       "$HERE"/filmos/fos*.{c,h} "$SRC"/src/fos_version.h "$MOD/"
    sed -i 's/\r$//' "$MOD"/*.c "$MOD"/*.h
    OBJS="filmroll.o fos_gfx.o fos_film.o fos_ui.o fos_shelf.o fos_pages.o fos_hud.o fos_print.o"
    if [ -n "$NODARK" ]; then OBJS="$OBJS fos_nodark.o"; else OBJS="$OBJS fos_dark.o fos_dev.o fos_lab.o fos_looks.o fos_jpeg.o"; fi
    make -C "$MOD" FILMOS_PLATFORM="$PLAT" FILMOS_OBJS="$OBJS" FATAL_WARNINGS=y >> "$LOG" 2>&1 || { tail -40 "$LOG"; echo "the film OS module didn't build, see $LOG"; exit 1; }
    # Only the module's entry points stay global: the loader refuses a module that defines a name
    # autoexec.bin already has (libgcc's helpers, pulled in with __powisf2).
    arm-none-eabi-objcopy --wildcard --keep-global-symbol='__module_*' \
        --keep-global-symbol=filmos_key_used --keep-global-symbol=filmos_menu_open \
        --keep-global-symbol=filmos_overlays "$MOD/build/filmos.mo"
    # libgcc's and libm's unwind tables: Magic Lantern's TCC crashes loading them, and the camera
    # hangs in its module loader with no film OS and no Modules tab (#46, #48). Nothing unwinds here.
    arm-none-eabi-objcopy --remove-section=.ARM.exidx --remove-section=.rel.ARM.exidx \
        --remove-section=.ARM.extab "$MOD/build/filmos.mo"
    if arm-none-eabi-readelf -SW "$MOD/build/filmos.mo" | grep -q "\.ARM\.ex"; then
        echo "the film OS module still has unwind tables, which the camera's loader can't load"; exit 1
    fi
    arm-none-eabi-readelf -sW "$MOD/build/filmos.mo" | awk '$5 == "GLOBAL" && $7 == "UND" {print $8}' | sort -u > "$MOD/build/filmos.dep"
    # every symbol the module needs must be in this camera's autoexec.bin, or the loader refuses it
    # the symbol file the camera's module loader reads (5D2_212.sym, t3_105.sym on the 1100D ...)
    SYM="$OUT/ML/modules/$(cd "$SRC/platform/$PLAT/build" && ls *.sym | grep -v '^magiclantern.sym$' | head -1)"
    [ -f "$SYM" ] || { echo "no symbol file for $PLAT in the card files"; exit 1; }
    MISSING=$(comm -23 <(sort -u "$MOD/build/filmos.dep") <(awk '{print $2}' "$SYM" | sort -u))
    if [ -n "$MISSING" ]; then
        echo "the film OS module needs symbols this camera's Magic Lantern doesn't export:"; echo "$MISSING"
        exit 1
    fi
    CLASH=$(comm -12 <(arm-none-eabi-readelf -sW "$MOD/build/filmos.mo" | awk '$5 == "GLOBAL" && $7 != "UND" {print $8}' | sort -u) <(awk '{print $2}' "$SYM" | sort -u))
    if [ -n "$CLASH" ]; then
        echo "the film OS module defines names autoexec.bin already has:"; echo "$CLASH"
        exit 1
    fi
    # link it as the camera's loader will, with ML's own TCC, where qemu-arm can run it (fork/module/linktest.c)
    if command -v qemu-arm > /dev/null; then
        arm-none-eabi-gcc -march=armv5te -O1 -I"$SRC/tcc" -o "$MOD/build/linktest" "$HERE/fork/module/linktest.c" \
            "$SRC/platform/$PLAT/build/tcc/libtccx.o" --specs=rdimon.specs -lc -lrdimon -lm >> "$LOG" 2>&1 \
            || { echo "linktest didn't build, see $LOG"; exit 1; }
        (cd "$MOD/build" && qemu-arm -cpu arm926 ./linktest filmos.mo "$SYM") || { echo "the camera's loader wouldn't take the film OS module"; exit 1; }
    else
        echo "(no qemu-arm: the module isn't link-tested; apt install qemu-user)"
    fi
    # next to ML's own modules, in the zip's spelling (the card doesn't care, a computer unzipping it does)
    mkdir -p "$OUT/ML/modules" "$OUT/ML/SETTINGS"
    cp "$MOD/build/filmos.mo" "$OUT/ML/modules/filmos.mo"
    : > "$OUT/ML/SETTINGS/filmos.en"        # enabled: ML's menu, where modules are switched on, is the film OS's
    echo "film OS module: $(stat -c %s "$OUT/ML/modules/filmos.mo") bytes, loaded after boot"
fi

# the film OS fonts, loaded from the card after boot
gcc -O2 -I"$HERE/filmos" -o "$HOME/ml/fontblob" "$HERE/filmos/tools/fontblob.c"
mkdir -p "$OUT/ML/data"
"$HOME/ml/fontblob" "$OUT/ML/data/FOSFONT.BIN"

# the films beyond the built-in eight (films/films.py, tools/catalog.py)
F="$HERE/filmos"
python3 "$F/tools/genfilms.py" "$OUT/ML/data/FOSFILMS.BIN"

# the donation links in donate.txt as QR codes (needs segno: pip install segno)
python3 -c "import segno" 2>/dev/null || pip install -q segno
python3 "$F/tools/genqr.py" "$HERE/donate.txt" "$OUT/ML/data/FOSQR.BIN"

# every film's colour table, so the darkroom never spends its first
# develop of a film mixing one (the camera checks they match its looks):
# mixed from the look, then baked from the film's LUT where it has one
# (films/getluts.py fetches the Film-Luts ones; your own go in films/luts/)
[ -d "$HERE/films/luts/filmluts" ] || python3 "$HERE/films/getluts.py"
gcc -O2 -std=gnu99 -DFOS_DEV_TEST -I"$F" -o "$HOME/ml/devtest" "$F"/sim/devtest.c "$F"/sim/port_files.c \
    "$F"/sim/films.c "$F"/fos_dev.c "$F"/fos_print.c "$F"/fos_looks.c "$F"/fos_film.c "$F"/fos_gfx.c "$F"/fos_jpeg.c -lm
mkdir -p "$OUT/ML/DARKROOM"
FOS_FILMS="$OUT/ML/data/FOSFILMS.BIN" "$HOME/ml/devtest" -T "$OUT/ML/DARKROOM"
python3 "$F/tools/genfilms.py" "$OUT/ML/data/FOSFILMS.BIN" --tables "$OUT/ML/DARKROOM"

# the shelf's samples (PLAY on the shelf): one photo developed with every
# film, with the tables above, as the camera's darkroom would. The prints
# don't depend on the camera, so every camera gets the same ones.
mkdir -p "$OUT/ML/SAMPLES"
FOS_FILMS="$OUT/ML/data/FOSFILMS.BIN" FOS_LUT_DIR="$OUT/ML/DARKROOM" \
    "$HOME/ml/devtest" -S "$HERE/films/sample/SAMPLE.CR2" "$OUT/ML/SAMPLES"

# with no darkroom, the colour tables were only for the samples: the card is done
if [ -n "$NODARK" ]; then
    rm -rf "$OUT/ML/DARKROOM"
    python3 "$F/tools/genfilms.py" "$OUT/ML/data/FOSFILMS.BIN"
    echo "== card files in $OUT (no darkroom) =="
    (cd "$OUT" && find . -maxdepth 3 | sort | head -60)
    exit 0
fi
echo "== card files in $OUT =="
(cd "$OUT" && find . -maxdepth 3 | sort | head -60)

# keep the fork's source changes next to the project
(cd "$SRC" && git add -A src/filmroll.c src/filmroll.h src/filmhook.c src/fos*.c $(ls src/fos*.h | grep -v fos_version.h) && git diff ed3e7c0df -- src platform > "$HERE/fork/film-mode.patch")
echo "patch: $HERE/fork/film-mode.patch"
