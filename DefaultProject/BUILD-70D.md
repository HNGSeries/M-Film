# Building M-Film for the Canon EOS 70D (firmware 1.1.2)

This is the patch that makes the M-Film fork build for the **70D.112** platform. It is the same
fix the project already applied to the 6D: give Magic Lantern a larger slice of Canon's
AllocateMemory pool at boot.

**Patch:** `M-Film-70D.patch` (against M-Film **v0.1.2**, commit `508f9ca`)
**SHA-256:** `E0692F0F93EA128C1419EA13182AF1BF426F1B895543596E29D8925008F170E6`

> The 848K reservation is **unverified on a 70D**. Measure free memory with stock Magic Lantern
> first (step 4). Nothing here has been tried on a camera yet.

---

## 1. What the patch changes

| File | Change |
|---|---|
| `ml-dev/fork/apply_fork.py` | `CONFIG_70D` now takes the 6D's `0x520000` reservation (848K) instead of `0x4E0000` (592K). Also upgrades a tree that was patched by the older 6D-only fork. |
| `ml-dev/cameras.txt` | `70D.112` goes from `memory` / `605952` to `testing` / `868096`, so the build script no longer refuses it and CI builds it. |
| `.github/workflows/camera.yml` | Adds `70D.112` to the normal build matrix, and to the `--no-darkroom` test matrix as a fallback. |
| `README.md`, `README.th.md`, `TESTING.md` | 70D moves to "Builds, needs a tester", with the card-file name. TESTING gets a 70D memory warning. |
| `ml-dev/MEMORY.md` | Records the raise and that it is unverified. |

No Film OS source is touched: `fos_dev.c` already has `CONFIG_70D`, and `filmroll.c` already maps
the 70D's controls (joystick and Q → SET, wheel, MENU/INFO/PLAY, trash → Home, half-shutter → leave).

### The numbers

| | Bytes |
|---|---|
| Old 70D limit (592K) | 605,952 |
| New limit (848K, the 6D's) | 868,096 |
| Full build | 690,432 (was 84,480 over) |
| Build without darkroom | 632,832 (was 26,880 over) |

The 70D's pool is the same as the 6D's (`0x44C000`–`0xD3C000`), which is why `0x520000` is the
first thing to try. The build now has 177,664 bytes of headroom.

---

## 2. Before anything: check the camera

- The camera must be on Canon firmware **1.1.2** exactly. ML's 70D port does not support 1.1.3,
  and Canon's 1.1.3 update blocks downgrades (some users have got back to 1.1.2 with the normal
  SD-card update; not all).
- Magic Lantern on the 70D is itself a beta. Expect missing features (FPS override is not in the
  stock build, H.264 bitrate changes and several focus features are disabled).
- Keep a second card with stock ML (or no ML) to go back to. A build that hangs at power-on is
  recovered by removing the battery and the card.

---

## 3. Build it

### Option A — let GitHub Actions build it (no Linux needed)

The patch already adds the 70D to the CI matrix, so this is the least work:

1. Fork `HNGSeries/M-Film` on GitHub, then clone your fork and check out the release tag:
   ```bash
   git clone https://github.com/<you>/M-Film.git
   cd M-Film
   git checkout -b 70d v0.1.2
   git apply /path/to/M-Film-70D.patch
   git add -A && git commit -m "70D: raise the boot reservation to 848K"
   git push -u origin 70d
   ```
2. Open a pull request from `70d` to your fork's `main` (a push to `main` also triggers it).
3. In *Actions → M-Film camera*, wait for the run. Download the artifacts:
   - `M-Film-camera-70D.112` — the normal card files.
   - `test-M-Film-camera-70D.112-nodark` — the smaller fallback (no in-camera darkroom).

   Each artifact is a zip containing the card zip; unzip twice.

### Option B — build locally in WSL2 / Linux

Ubuntu 24.04 matches the project's CI (gcc 13.2, the version the size figures come from).

```bash
wsl --install -d Ubuntu          # Windows: then reopen the shell
sudo apt update
sudo apt install -y build-essential git python3 python3-pip \
    gcc-arm-none-eabi binutils-arm-none-eabi zip unzip
python3 -m pip install numpy scipy pillow segno docutils

mkdir -p ~/ml && cd ~/ml
git clone --filter=blob:none https://github.com/reticulatedpines/magiclantern_simplified.git
git -C magiclantern_simplified checkout ed3e7c0dfacfdeaf3349dee73edf9e3621217462

git clone https://github.com/HNGSeries/M-Film.git
cd M-Film
git checkout v0.1.2
git apply "/mnt/c/Users/Ryan/Documents/Default Project/M-Film-70D.patch"
# on a newer main instead of v0.1.2, try:  git apply -3 ...
# without git:                            patch -p1 < ...
```

Now build. `build_fork.sh` uses `~/ml/magiclantern_simplified` by default:

```bash
cd ~/ml/M-Film
bash ml-dev/build_fork.sh 70D.112
```

Expected (the line to check):

```
ML takes 690432 bytes at boot (limit 868096)
== card files in ~/ml/M-Film/ml-dev/out/fork-70D.112 ==
```

The card files are in `~/ml/M-Film/ml-dev/out/fork-70D.112/` (autoexec.bin, `ML/`, `ML-SETUP.FIR`).

Fallback build without the in-camera darkroom (60 KB smaller):

```bash
bash ml-dev/build_fork.sh 70D.112 --no-darkroom
# ML takes 632832 bytes at boot (limit 868096)
# -> ml-dev/out/fork-70D.112-nodark/
```

If `apply_fork.py` stops with "anchor not found", the ML checkout is not at `ed3e7c0df`, or its
`src/boot-d45-am.c` was changed by hand. Re-clone it (or `git checkout -- src/boot-d45-am.c`).
A tree patched by the older 6D-only fork is detected and upgraded automatically.

---

## 4. Measure free memory before flashing (important)

The risk is not ML's own size check — it is Canon running out of the pool later and hanging.

1. Put **stock** Magic Lantern for the 70D on a card
   (`builds.magiclantern.fm/70D.html`, build `magiclantern.2025-06-20.70D.112.zip`).
2. Boot it, open *Debug → Free Memory*, and note the **AllocateMemory** line, idle and in LiveView.
3. Stock ML reserves 592K. The patch reserves 848K, so it takes another **256K**:

   `free after raise ≈ stock free − 256K`

   You want at least ~1.5 MB left, as on the 6D. If the stock figure is below ~1.75 MB, use a
   smaller raise instead of 848K.

### If you need a smaller raise

Edit two places in `ml-dev/fork/apply_fork.py` and one in `ml-dev/cameras.txt`:

| Reservation | Instruction (`addr_AllocMem_end[1]`) | Limit | Fits |
|---|---|---|---|
| 0x520000 (848K) | `0xE3A00852` | 868,096 | full + nodark (default) |
| 0x510000 (784K) | `0xE3A00851` | 802,560 | full + nodark |
| 0x500000 (720K) | `0xE3A00850` | 737,024 | full (46 KB spare) |
| 0x4F0000 (656K) | `0xE3A0084F` | 671,488 | **nodark only** (632,832) |

In `apply_fork.py`, change both `addr_AllocMem_end[1] = ...` and `ml_reserved_mem = 0x...... - RESTARTSTART`
in the 6D/70D block (and the matching update block below it). Set the same limit in `cameras.txt`
for `70D.112`, then rebuild. Keep the 100D on `0x4E0000`.

---

## 5. Install and test

1. Format a card in the camera, copy the **contents** of the 70D card folder to the card root.
2. MENU → *Firmware ver.* → update once, then power-cycle.
3. Give the film shelf up to 15 seconds (on a DSLR it appears from the normal shooting screen with
   LiveView off).

**If it does not start** (black screen, card light on): remove the battery, remove the card. A card
light blinking **3 long, 3 short, pause** means boot.h rejected the size — the reservation or the
build size is wrong.

Then check, per `TESTING.md`:

- [ ] Colours (System → Screen colour has a test chart; Portra yellow, Ektar red)
- [ ] Keys: dial/arrows, SET, MENU, INFO, PLAY, trash → Home, half-shutter → leave
- [ ] Load a roll, shoot through the viewfinder and in LiveView; frame count and HUD
- [ ] Rewind and develop in the camera (this exercises the 70D CR2 decoder)
- [ ] `ML/FILMROLL.LOG` on the card

Report to `HNGSeries/M-Film` issues with firmware, what worked, the Free Memory numbers, and
`FILMROLL.LOG`. If it boots, the same patch is a reasonable upstream PR.

---

## 6. Rollback

Format the card in the camera, or run `ML-SETUP.FIR` again from *Firmware ver.* and remove the boot
flag. Deleting `autoexec.bin` and `ML/` also stops it starting.

## 7. What this patch does not do

- It does not verify anything on hardware, and it cannot tell you whether 848K is safe for Canon.
- It does not fix the 70D Magic Lantern beta's own limitations.
- It does not touch **Darkrooms**, the separate closed-source desktop program; 70D full-size
  development there is outside this patch.
- If you distribute builds, GPL-2.0 applies: keep the source (this patch) available.
