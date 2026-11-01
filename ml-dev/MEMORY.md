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
| 650D | sized to fit | unknown | 743,680 | | ⚠️ above the EOS M's limit: try it |
| 700D | sized to fit | unknown | 743,936 | | ⚠️ above the EOS M's limit: try it |
| 5D Mark III 1.1.3 | sized to fit | unknown | 737,536 | | try it |
| 5D Mark III 1.2.3 | sized to fit | unknown | 733,440 | | try it |
| 60D | sized to fit | unknown | 740,096 | | ✅ a tester's 60D starts (#3) |
| 500D | sized to fit | unknown | 734,208 | | try it |
| 50D | sized to fit | unknown | 716,032 | | try it |
| 5D Mark II | sized to fit | unknown | 749,824 | | try it |
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

## What would fix the fixed ones

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
