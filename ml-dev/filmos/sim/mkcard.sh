#!/usr/bin/env bash
# A memory card for the simulator's darkroom: rolls of half-size test CR2s and
# their logs, as the camera writes them (out/card/DCIM/100CANON).
#   ./mkcard.sh
#   PHOTOS=dir ./mkcard.sh     the frames are the photos in dir (*.pfm: linear sRGB, 0.18 = mid grey,
#                              taller than wide = shot on its side), in turn, instead of test scenes
#   CARD=out/cardp ./mkcard.sh --problems
#                              instead, the rolls the darkroom has to find or explain (cardtest.sh):
#                              shot as JPEG, Adobe RGB with a file deleted, across the IMG_9999 wrap
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p out
gcc -O2 -o out/mkcr2 tools/mkcr2.c -lm
CARD=${CARD:-out/card}
rm -rf "$CARD" && mkdir -p "$CARD/DCIM/100CANON" "$CARD/ML"
DIR="$CARD/DCIM/100CANON"
file=100
photos=()
[ -n "${PHOTOS:-}" ] && photos=("$PHOTOS"/*.pfm)

# roll <number> <film> <exposures> <frames> <loaded> [nofiles|jpeg|adobe]
#   nofiles  the log only (the roll in the camera)
#   jpeg     shot with a JPEG image quality: IMG_nnnn.JPG on the card, no CR2
#   adobe    in Adobe RGB: the log says IMG_nnnn.CR2, Canon wrote _MG_nnnn.CR2
roll() {
    local n=$1 film=$2 exp=$3 frames=$4 loaded=$5 mode=${6:-} log
    log="$DIR/ROLL_$(printf %03d "$n").TXT"
    printf '# ML film mode roll log (filmroll module)\nroll = %03d\nfilm = %s\nexposures = %d\nloaded = %s:00\n\n' \
        "$n" "$film" "$exp" "$loaded" > "$log"
    for ((i = 1; i <= frames; i++)); do
        file=$((file + 1))
        local name; name=$(printf IMG_%04d.CR2 "$file")
        local scene=chart extra=""
        (( i % 2 == 0 )) && scene=street
        (( i % 5 == 3 )) && extra="--portrait"
        local ev; ev=$(python3 -c "print(round(-0.7 + 0.35 * ($i % 5), 2))")
        if [ ${#photos[@]} -gt 0 ]; then
            local p=${photos[$(( (file - 101) % ${#photos[@]} ))]}
            extra=""; ev=0
            [ "$(head -c 64 "$p" | sed -n 2p | awk '{ print ($2 > $1) }')" = 1 ] && extra="--portrait"
            scene="chart --image $p"
        fi
        case "$mode" in
            nofiles) ;;
            jpeg)    printf 'not a CR2\n' > "$DIR/${name%.CR2}.JPG" ;;
            adobe)   out/mkcr2 "$DIR/_${name:1}" --half --scene $scene $extra --ev "$ev" --seed $((n * 100 + i)) 2>/dev/null ;;
            *)       out/mkcr2 "$DIR/$name" --half --scene $scene $extra --ev "$ev" --seed $((n * 100 + i)) 2>/dev/null ;;
        esac
        local t; t=$(printf '%02d:%02d:%02d' $((9 + i / 4)) $(((i * 7) % 60)) $(((i * 13) % 60)))
        printf '%d  %s  %s %s  f/%s\n' "$i" "$name" "${loaded%% *}" "$t" "$( ((i % 3)) && echo 2.8 || echo 5.6)" >> "$log"
    done
    [ "$frames" -lt "$exp" ] && printf '\n# rewound %s after %d of %d frames\n' "$loaded" "$frames" "$exp" >> "$log"
    return 0
}

# a roll that ran past IMG_9999: Canon went on in 101CANON from IMG_0001, and
# the camera started a log there too; IMG_9998 and IMG_9999 stay in 100CANON (#17)
wrap_roll() {
    local n=$1 film=$2 loaded=$3 i=0 name dir log note=""
    for f in 100CANON:9998 100CANON:9999 101CANON:1 101CANON:2; do
        i=$((i + 1)); dir="$CARD/DCIM/${f%%:*}"; name=$(printf IMG_%04d.CR2 "${f##*:}")
        log="$dir/ROLL_$(printf %03d "$n").TXT"
        mkdir -p "$dir"
        [ "${f%%:*}" = 100CANON ] || note=" - continued from the previous DCIM folder"
        [ -f "$log" ] || printf '# ML film mode roll log (filmroll module)%s\nroll = %03d\nfilm = %s\nexposures = 12\nloaded = %s:00\n\n' \
            "$note" "$n" "$film" "$loaded" > "$log"
        out/mkcr2 "$dir/$name" --half --scene chart --seed $((n * 100 + i)) 2>/dev/null
        printf '%d  %s  %s 10:%02d:00  f/2.8\n' "$i" "$name" "${loaded%% *}" "$i" >> "$log"
    done
    printf '\n# rewound %s after 4 of 12 frames\n' "$loaded" >> "$log"
}

if [ "${1:-}" = "--problems" ]; then
    file=500
    roll 6 portra400 12 4 "2026-10-01 09:00" jpeg
    roll 7 ektar100  12 4 "2026-10-02 09:00" adobe
    rm "$DIR/_MG_0506.CR2"                                  # frame 2: deleted on the camera
    wrap_roll 8 gold200 "2026-10-03 09:00"
else
    roll 9  ektar100       12 12 "2026-10-12 08:30"
    roll 10 portra400      12 12 "2026-10-18 10:05"
    roll 11 gold200        12  8 "2026-10-20 19:40"
    roll 12 cinestill800t  36 14 "2026-10-21 18:02" nofiles   # the one in the camera
fi
echo "card: $(find "$CARD" -name '*.CR2' | wc -l) CR2 files, $(du -sh "$CARD" | cut -f1)"
