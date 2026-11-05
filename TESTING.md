# Testing M-Film on your camera

M-Film runs on the **Canon EOS M** and the **6D**. The same code now **builds** for 13 more cameras
(100D, 650D, 700D, 70D, 5D Mark III on two firmwares, 550D, 600D, 60D, 1100D, 500D, 50D, 5D Mark II),
but few have been tried yet. If you have one, you can be the first: it takes about 20 minutes, and you
can always go back.

> **Is it safe?** Magic Lantern runs from the card and changes nothing permanent in the camera.
> The worst that usually happens is that the camera doesn't start with the card in: take the
> battery and the card out, and it starts normally again. Still, this is untested software on your
> camera, at your own risk. Keep a fully charged battery and don't try it in the middle of a shoot.

## 1. Get the files

From the [latest release](../../releases/latest) (or the newest run under *Actions*), download
`M-Film-camera-<your camera>.zip`:

<!-- cameras:start -->
| Camera | Canon firmware it needs | File |
|---|---|---|
| Canon EOS M | 2.0.2 | `M-Film-camera-EOSM.202.zip` · `M-Film-camera-EOSM.202-module.zip` |
| Canon EOS 100D / Rebel SL1 / Kiss X7 | 1.0.1 | `M-Film-camera-100D.101.zip` |
| Canon EOS 650D / Rebel T4i / Kiss X6i | 1.0.4 | `M-Film-camera-650D.104.zip` · `M-Film-camera-650D.104-module.zip` |
| Canon EOS 700D / Rebel T5i / Kiss X7i | 1.1.5 | `M-Film-camera-700D.115.zip` · `M-Film-camera-700D.115-module.zip` |
| Canon EOS 6D | 1.1.6 | `M-Film-camera-6D.116.zip` · `M-Film-camera-6D.116-module.zip` |
| Canon EOS 70D | 1.1.2 | `M-Film-camera-70D.112.zip` |
| Canon EOS 5D Mark III (firmware 1.1.3) | 1.1.3 | `M-Film-camera-5D3.113.zip` · `M-Film-camera-5D3.113-module.zip` |
| Canon EOS 5D Mark III (firmware 1.2.3) | 1.2.3 | `M-Film-camera-5D3.123.zip` · `M-Film-camera-5D3.123-module.zip` |
| Canon EOS 550D / Rebel T2i / Kiss X4 | 1.0.9 | `M-Film-camera-550D.109.zip` |
| Canon EOS 600D / Rebel T3i / Kiss X5 | 1.0.2 | `M-Film-camera-600D.102.zip` |
| Canon EOS 60D | 1.1.1 | `M-Film-camera-60D.111.zip` · `M-Film-camera-60D.111-module.zip` |
| Canon EOS 1100D / Rebel T3 / Kiss X50 | 1.0.5 | `M-Film-camera-1100D.105.zip` |
| Canon EOS 500D / Rebel T1i / Kiss X3 | 1.1.1 | `M-Film-camera-500D.111.zip` · `M-Film-camera-500D.111-module.zip` |
| Canon EOS 50D | 1.0.9 | `M-Film-camera-50D.109.zip` · `M-Film-camera-50D.109-module.zip` |
| Canon EOS 5D Mark II | 2.1.2 | `M-Film-camera-5D2.212.zip` · `M-Film-camera-5D2.212-module.zip` |
<!-- cameras:end -->

The firmware must match exactly (MENU → last settings tab → *Firmware ver.*).

**Two files for most cameras (since 0.1.4).** `M-Film-camera-<camera>.zip` has the film OS built into
Magic Lantern, as before. `M-Film-camera-<camera>-module.zip` has it as a module that loads after the
camera has started, which takes about 180 KB less of the memory a camera can spare at power on
([MEMORY.md](ml-dev/MEMORY.md)). It's new and untried: please test it too, especially if the first one
hangs at power on (5D Mark II, 650D, 700D). The 100D, 70D, 550D, 600D and 1100D only fit this way, so
their one zip is the module one. If the film shelf doesn't appear and you see Magic Lantern's own menu
instead, the module didn't load: its line in the *Modules* tab says why. Tell us what it says.

## 2. Install

1. Format a card **in the camera**, then copy everything from the zip to the card's root.
2. Camera off, card in, camera on. MENU → *Firmware ver.* → update (first time only: this lets the
   camera start Magic Lantern from the card).
3. Switch the camera off and on.
4. In Canon's menu set **Image quality** to **RAW** (RAW+JPEG works too) and **Image review** to
   **Off**. The in-camera darkroom develops the RAWs: frames shot as JPEG can't be developed.

## 3. What to try, and what to tell us

Go through these and note what happens (a photo of the screen helps a lot):

- [ ] The camera starts, and the **film shelf** appears (on a DSLR, from the normal shooting screen
      with LiveView off; give it up to 15 seconds).
- [ ] **Colours** look right (shelf canisters: Portra yellow, Ektar red; System → Screen colour has a chart).
- [ ] **Buttons**: the dial and arrows move along the shelf, SET loads a film, MENU goes back,
      half-shutter returns to the camera. Which buttons do nothing?
- [ ] **Trash** opens Home; **PLAY** opens the prints instead of Canon's playback.
- [ ] Load a roll and shoot a few frames **through the viewfinder**, and a few in **LiveView**.
      Does the frame count go up? Is the HUD drawn in LiveView?
- [ ] Rewind the roll and **develop it in the camera** (Darkroom). Do prints come out? How long per frame?
- [ ] Open the card in the **M-Film program** on a computer: are the rolls and films there?

Then [open an issue](../../issues/new/choose) with: your camera and firmware, what worked, what didn't,
and the file **`ML/FILMROLL.LOG`** from the card attached.

### If *Firmware ver.* says "Memory card containing firmware is required to update"

The camera found no update file it accepts on the card:
- The Canon firmware isn't exactly the one in the table: `ML-SETUP.FIR` only works on that version.
- `ML-SETUP.FIR` isn't at the top of the card. Unzipping on a Mac often makes a folder
  (`M-Film-camera-EOSM.202/`). The card's top level should show `autoexec.bin`, `ML-SETUP.FIR` and `ML`.
- On a Mac, hidden `._` files next to them can trip the camera. With the card in the reader, run
  `dot_clean -m /Volumes/EOS_DIGITAL` in *Terminal* (your card's name in place of `EOS_DIGITAL`),
  then eject the card before taking it out.

### If you turned on Magic Lantern's console

The MENU button opens M-Film, so Magic Lantern's menu (where the console is switched off) can't be
reached while M-Film runs. On a computer, open `ML/SETTINGS/magic.cfg` on the card and change
`module.console = 1` to `module.console = 0`.

### If it doesn't start

Battery out, card out. Then please tell us, because it most likely means the program is too big for
that camera's memory (on the EOS M the limit is about 727 KB at boot; the other builds are 670–750 KB, and
nobody knows their limits yet). Say
which camera and firmware, and whether the card light stayed on.

## 4. Remove it

Format the card in the camera. To stop the camera looking for Magic Lantern at all, run
`ML-SETUP.FIR` again from *Firmware ver.* and choose to remove the boot flag.

Thank you! Every camera someone tries moves it from *testing* to *working* in the
[list on the front page](README.md#cameras).
