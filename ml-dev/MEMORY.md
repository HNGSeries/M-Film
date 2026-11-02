# Memory at boot, camera by camera

Magic Lantern's `autoexec.bin` takes its memory out of Canon's at power on. Too much and the camera
doesn't start. How much a camera can give depends on which of Magic Lantern's boot methods it uses.
This is the survey behind the `memory` status in [`cameras.txt`](cameras.txt) (2026-10, Magic Lantern
`ed3e7c0df`, gcc 13.2).

**Boot size** below is what `build_fork.sh` prints: `_bss_end - RESTARTSTART`, the same figure Magic
Lantern checks (`ml_used_mem`, `src/boot.h`).

## Two kinds of camera

**Sized to fit** (`boot-d45.c`): Magic Lantern moves the start of Canon's malloc pool to just after
its own code and data, however big that is. Nothing stops the boot. If the build is too big, Canon
itself runs short later and the camera hangs at power on with the card light on. The only limit is
how much Canon can spare, and only trying on the camera finds it. On the EOS M it is 727,072 bytes.

**Fixed reservation** (`boot-d45-am.c`, `boot-d45-ch.c`): Magic Lantern takes a fixed slice of
Canon's AllocateMemory pool, the same size whatever the build. If the build is bigger, `src/boot.h`
stops at power on and blinks the card light **3 long, 3 short, a pause**, forever. That is what the
6D did (#3) until the fork raised its slice to 848K (#8).

## The cameras

| Camera | Boot method | Limit (bytes) | Full build | No darkroom | Verdict |
|---|---|---|---|---|---|
| EOS M | sized to fit | 727,072 (found on the camera) | 715,552 | | ✅ works |
| 650D | sized to fit | at least 689,664 (no darkroom starts) | 743,680 (black screen) | 689,664 | ✅ starts without the darkroom: released that way |
| 700D | sized to fit | unknown | 743,936 (black screen, #19) | | 🧪 released without the darkroom, as the 650D |
| 5D Mark III 1.1.3 | sized to fit | unknown | 737,536 | | try it |
| 5D Mark III 1.2.3 | sized to fit | unknown | 733,440 | | try it |
| 60D | sized to fit | unknown | 740,096 | | ✅ a tester's 60D starts (#3) |
| 500D | sized to fit | unknown | 734,208 | | try it |
| 50D | sized to fit | unknown | 716,032 | | try it |
| 5D Mark II | sized to fit | unknown: 705,792 starts (#18), 749,824 hangs | 756,992 (hangs); lean 706,048 | | 🧪 released lean (features left out, darkroom kept) |
| 6D | fixed, raised by the fork | 868,096 (848K) | 740,864 | | ✅ starts (#3, #8) |
| 100D | fixed | 605,952 (592K) | 741,888 | 684,288 | 🔧 too big, even without the darkroom |
| 70D | fixed | 605,952 (592K) | 690,432 | 632,832 | 🔧 too big, even without the darkroom |
| 550D | fixed | 589,568 (576K) | 751,616 | 694,016 | 🔧 too big, even without the darkroom |
| 600D | fixed | 589,824 (576K, see below) | 716,800 | 659,200 | 🔧 too big, even without the darkroom |
| 1100D | fixed | 524,032 (512K) | 672,000 | 614,400 | 🔧 too big, even without the darkroom |

Where the fixed limits come from (`src/boot-d45-am.c`, `src/boot-d45-ch.c`):
- **100D, 70D:** the pool's start moves from `0x44C000` to `0x4E0000`, so the limit is `0x4E0000 - RESTARTSTART (0x44C100)`.
  The pool runs to `0xC3C000` (100D) or `0xD3C000` (70D, as on the 6D).
- **550D:** the pool's end moves from `0xD00000` to `0xC70000`, so the limit is `0xD00000 - RESTARTSTART (0xC70100)`.
- **1100D:** the same with `0xC80000`, so the limit is `0xD00000 - 0xC80100`.
- **600D:** the end moves to `0xC70000` (from `RESTARTSTART`). The original end is read from the ROM at boot,
  so the figure assumes `0xD00000`, as on the 550D.

The sized-to-fit rows have no limit because nothing fixes one. The EOS M is built on the 650D and 700D, so a
650D or 700D above its 727K may hang the same way. Their testers should be told to watch for a card light
that stays on.

That is what happened: the full 650D and 700D builds give a black screen at power on (a 650D tester by message,
the 700D in #19). The 650D tester built it `--no-darkroom` (689,664 bytes at boot) and it starts with the film
interface. So both are `nodark` in cameras.txt: CI builds and releases them without the darkroom, under the
usual zip name. Their rolls are developed with Darkrooms.

The 5D Mark II hangs at power on, or when the shutter is pressed, with the full build (#18, #20, #27, #32).
Enzo-Reveillon left 19 Magic Lantern features M-Film doesn't use out of it (zebras, focus peaking, waveform,
FPS override and the like; `LEAN_FEATURES` in fork/apply_fork.py) and his 5D Mark II starts at 705,792 bytes
with the in-camera darkroom. The fork does the same for it (`LEAN`): 706,048 bytes at boot with today's code.

The same cut doesn't build on the 650D (ML there needs FPS_OVERRIDE, FPS_RAMPING and FOCUS_PEAK). Without those
three, a lean 650D with the darkroom takes 718,336 bytes: under the EOS M's 727,072, but above the 689,664 known
to start on a 650D. Worth a tester's try before it replaces the no-darkroom release.

## The film OS as a module (`build_fork.sh --module`)

The film OS is about 180 KB of code and data. Built in, all of it is part of `autoexec.bin` and comes out
of the memory the camera gives Magic Lantern at power on. As a module it isn't: autoexec.bin keeps Magic
Lantern and three hooks (`fork/src/filmhook.c`), and the film OS is `ML/modules/filmos.mo`, which Magic
Lantern's module loader puts into Canon's memory after boot (about 216 KB there: 185 KB of code, 35 KB
of data). The film OS itself doesn't change: the same sources, built for one camera
(`fork/module/Makefile`), with the same libm and libgcc as autoexec.bin, so it develops the same prints.

Boot size with `--module`, full film OS with the darkroom (2026-11, gcc 13.2):

| Camera | Built in (the survey above) | As a module | Limit | |
|---|---|---|---|---|
| EOS M | 720,416 | 536,864 | 727,072 | |
| 650D | 743,680 | 564,992 | 689,664 (no darkroom starts) | the darkroom back, under what starts |
| 700D | 743,936 | 565,248 | unknown | as the 650D |
| 6D | 740,864 | 562,176 | 868,096 | |
| 5D Mark III 1.1.3 / 1.2.3 | 737,536 / 733,440 | 558,592 / 554,496 | unknown | |
| 60D | 740,096 | 561,152 | unknown | |
| 500D | 734,208 | 555,264 | unknown | |
| 50D | 716,032 | 537,344 | unknown | |
| 5D Mark II (lean) | 706,048 | 520,192 | 705,792 starts | under what starts |
| 100D | 741,888 | 562,944 | 605,952 | ✅ fits |
| 70D | 690,432 | 511,744 | 605,952 | ✅ fits |
| 550D | 751,616 | 572,672 | 589,568 | ✅ fits (16 KB to spare) |
| 600D | 716,800 | 537,856 | 589,824 | ✅ fits |
| 1100D | 672,000 | 493,056 | 524,032 | ✅ fits |

The five fixed-reservation cameras are built this way (`testing:module` in `cameras.txt`), with nothing
of Magic Lantern left out. The others keep the built-in film OS for their releases; CI also builds the
module for the EOS M, 6D, 650D, 700D and 5D Mark II as `test-…-module` artifacts, so a tester can try it
where the built-in one is known to start.

What only a camera can tell:
- **Canon's memory after boot.** The module and the loader's work while linking it (it reads the file and
  links it with TCC) come out of Canon's own memory, which Canon also uses. The one figure known so far: the
  6D had 2,192 KB free with stock Magic Lantern (below). Where there isn't enough, the module fails to load.
- **If the module doesn't load**, the camera starts with Magic Lantern alone: the hooks answer as if there
  were no film OS, so MENU opens Magic Lantern's own menu (Modules tab: why it didn't load). After a crash
  while loading modules, Magic Lantern skips them at the next start and says so.
- **Settings.** The module keeps them in `ML/SETTINGS/filmos.cfg`. The first time it starts it takes the
  `filmroll.*` ones from `magiclantern.cfg`, so a camera moving from the built-in film OS keeps its roll.

How the module is checked when it's built (`build_fork.sh`): every name it needs must be exported by that
camera's autoexec.bin (`*.sym`), it must not define a name autoexec.bin has (only its entry points stay
global), and nothing in it calls into autoexec.bin with a short branch (libm's `__errno` goes to the
module's own `fos_errno`), so it works wherever the loader puts it.

## What would fix the fixed ones (built in)

The same as the 6D: give Magic Lantern a bigger slice of the pool at boot, and check that Canon keeps enough.
- **70D:** its pool starts and ends where the 6D's does (`0x44C000`–`0xD3C000`), so the 6D's `0x520000` (848K)
  is the obvious first try.
- **100D:** its pool is 1 MB smaller (it ends at `0xC3C000`). A smaller raise than the 6D's is safer.
- **550D, 600D, 1100D:** Magic Lantern takes the slice from the pool's end. Lowering that end more (for example to
  `0xC50000`, 704K on the 550D) needs the pool's start and use, which the source doesn't give.

Each needs a number from the camera first: what Canon has free. **Stock** Magic Lantern shows it at
*Debug → Free Memory* (the *AllocateMemory* line). The 6D's came from its crash logs: 2,192K free when idle,
1,503K at the lowest. A raise that leaves about 1.5 MB free is what `src/mem.c` prefers.

A different way out for every camera is to load the film OS as a module from the card after boot, so
`autoexec.bin` stays near stock size. That is a bigger change, and it is only worth making if the raises don't work.
