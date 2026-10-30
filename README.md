<div align="center">

<img src="docs/images/mfilm.png" width="112" alt="M-Film">

# M-Film

**Your Canon, shot like film.**

A film camera's interface for Canon cameras that run Magic Lantern.<br>
Load a roll from a shelf of 72 film stocks, shoot without looking at the screen, then develop the roll: in the camera, or on your computer with **Darkrooms**.<br>
The camera side is free and open, for everyone.

[![Download](https://img.shields.io/badge/Download-eca834?style=for-the-badge)](../../releases/latest)
[![Buy the developer a coffee](https://img.shields.io/badge/Buy%20the%20developer%20a%20coffee-ffdd00?style=for-the-badge&logo=buymeacoffee&logoColor=black)](https://buy.stripe.com/7sY14p8d93QE5Ny5M58so02)

[![License GPL-2.0](https://img.shields.io/badge/license-GPL--2.0-3b352f)](LICENSE)
[![Cameras](https://img.shields.io/badge/cameras-1%20works%20%C2%B7%2014%20in%20testing-3b352f)](#cameras)
[![Films](https://img.shields.io/badge/films-72-3b352f)](FILMS.md)

**English** · [ภาษาไทย](README.th.md) · [Films](#72-films) · [Cameras](#cameras) · [Darkrooms](#develop-on-your-computer-darkrooms) · [Take it further](PORTING.md)

<br>

<img src="ml-dev/filmos/preview/shelf.gif" alt="The film shelf in the camera" width="720">

</div>

---

## A film camera, inside your camera

M-Film replaces the camera's menus with a film camera drawn from scratch, with Magic Lantern running
underneath. There is no picture on the screen after each shot and no going back through them: you shoot
the roll, then develop it and see what you got.

<table>
<tr>
<td width="50%"><img src="ml-dev/filmos/preview/shelf.png" alt="The film shelf"></td>
<td width="50%"><img src="ml-dev/filmos/preview/roll.png" alt="The roll"></td>
</tr>
<tr>
<td><b>Load a roll.</b> A shelf of canisters that turn to face you. Pick one and the leader comes out of it.</td>
<td><b>Count your frames.</b> A film camera's frame counter, from S to the last frame of the roll, and a rewind.</td>
</tr>
<tr>
<td><img src="ml-dev/filmos/preview/hud.png" alt="Viewfinder HUD"></td>
<td><img src="ml-dev/filmos/preview/developing.png" alt="Developing in the camera"></td>
</tr>
<tr>
<td><b>Shoot.</b> An SLR viewfinder: aperture scale, light meter needle, red seven-segment frame count.</td>
<td><b>Develop in the camera.</b> The darkroom develops the finished roll frame by frame, into JPEG folders on the card.</td>
</tr>
<tr>
<td><img src="ml-dev/filmos/preview/prints-sheet.png" alt="Contact sheet"></td>
<td><img src="ml-dev/filmos/preview/home.png" alt="Home"></td>
</tr>
<tr>
<td><b>See the prints.</b> A contact sheet of the roll, and each print full screen.</td>
<td><b>Home</b> instead of the camera's menu: the roll you have loaded and everything else.</td>
</tr>
</table>

Every RAW is kept, so nothing is lost: you can develop the same roll again with another film later.

---

## 72 films

Colour negative, slide, black and white, and cinema film, on four shelves. Each film has its own colour,
grain, halation and softness; rolls come in 36, 24 or 12 frames.

<!-- samples: one photo per film in docs/samples/<film>.jpg (3:2) -->
<table>
<tr>
<td width="33%"><img src="docs/samples/portra400.jpg" alt="Kodak Portra 400"><br><b>Kodak Portra 400</b><br><sub>Soft warm skin, gentle highlights</sub></td>
<td width="33%"><img src="docs/samples/gold200.jpg" alt="Kodak Gold 200"><br><b>Kodak Gold 200</b><br><sub>Golden hour, all day long</sub></td>
<td width="33%"><img src="docs/samples/ektar100.jpg" alt="Kodak Ektar 100"><br><b>Kodak Ektar 100</b><br><sub>Punchy colour, ultra fine grain</sub></td>
</tr>
<tr>
<td><img src="docs/samples/superia400.jpg" alt="Fujicolor Superia 400"><br><b>Fujicolor Superia 400</b><br><sub>Green shadows, everyday snaps</sub></td>
<td><img src="docs/samples/velvia50.jpg" alt="Fujichrome Velvia 50"><br><b>Fujichrome Velvia 50</b><br><sub>Vivid slide film, hard contrast</sub></td>
<td><img src="docs/samples/kodachrome64.jpg" alt="Kodak Kodachrome 64"><br><b>Kodak Kodachrome 64</b><br><sub>Magazine colour of the 70s</sub></td>
</tr>
<tr>
<td><img src="docs/samples/cinestill800t.jpg" alt="CineStill 800T"><br><b>CineStill 800T</b><br><sub>Tungsten cine film, night goes blue</sub></td>
<td><img src="docs/samples/kodak2383.jpg" alt="Kodak Vision 2383"><br><b>Kodak Vision 2383</b><br><sub>Cinema print: teal shadows</sub></td>
<td><img src="docs/samples/trix400.jpg" alt="Kodak Tri-X 400"><br><b>Kodak Tri-X 400</b><br><sub>Gritty contrast, street classic</sub></td>
</tr>
</table>

**[All 72 films, on the same photo →](FILMS.md)**

Colour for 63 of them comes from the [Film-Luts](https://github.com/YahiaAngelo/Film-Luts) collection; the rest
from M-Film's own film models ([`ml-dev/films/films.py`](ml-dev/films/films.py)).

---

## Cameras

M-Film was made on the EOS M, where it works. It now builds for every camera on which Magic Lantern
itself is mature (DIGIC 4 and 5), but those builds **haven't been tried on a camera yet**. If you have
one of them, you can help: [TESTING.md](TESTING.md) says how (about 20 minutes, and you can always go back).

<!-- cameras:start -->
| Camera | Canon firmware | Status | Card files |
|---|---|---|---|
| Canon EOS M | 2.0.2 | ✅ **Works** | `M-Film-camera-EOSM.202.zip` |
| Canon EOS 100D / Rebel SL1 / Kiss X7 | 1.0.1 | 🧪 Builds, needs a tester | `M-Film-camera-100D.101.zip` |
| Canon EOS 650D / Rebel T4i / Kiss X6i | 1.0.4 | 🧪 Builds, needs a tester | `M-Film-camera-650D.104.zip` |
| Canon EOS 700D / Rebel T5i / Kiss X7i | 1.1.5 | 🧪 Builds, needs a tester | `M-Film-camera-700D.115.zip` |
| Canon EOS 6D | 1.1.6 | 🧪 Builds, needs a tester | `M-Film-camera-6D.116.zip` |
| Canon EOS 70D | 1.1.2 | 🧪 Builds, needs a tester | `M-Film-camera-70D.112.zip` |
| Canon EOS 5D Mark III (firmware 1.1.3) | 1.1.3 | 🧪 Builds, needs a tester | `M-Film-camera-5D3.113.zip` |
| Canon EOS 5D Mark III (firmware 1.2.3) | 1.2.3 | 🧪 Builds, needs a tester | `M-Film-camera-5D3.123.zip` |
| Canon EOS 550D / Rebel T2i / Kiss X4 | 1.0.9 | 🧪 Builds, needs a tester | `M-Film-camera-550D.109.zip` |
| Canon EOS 600D / Rebel T3i / Kiss X5 | 1.0.2 | 🧪 Builds, needs a tester | `M-Film-camera-600D.102.zip` |
| Canon EOS 60D | 1.1.1 | 🧪 Builds, needs a tester | `M-Film-camera-60D.111.zip` |
| Canon EOS 1100D / Rebel T3 / Kiss X50 | 1.0.5 | 🧪 Builds, needs a tester | `M-Film-camera-1100D.105.zip` |
| Canon EOS 500D / Rebel T1i / Kiss X3 | 1.1.1 | 🧪 Builds, needs a tester | `M-Film-camera-500D.111.zip` |
| Canon EOS 50D | 1.0.9 | 🧪 Builds, needs a tester | `M-Film-camera-50D.109.zip` |
| Canon EOS 5D Mark II | 2.1.2 | 🧪 Builds, needs a tester | `M-Film-camera-5D2.212.zip` |

**Not yet:** 7D (Magic Lantern's current source doesn't build it) · 200D, 750D, 77D, 80D, 7D Mark II, 5D Mark IV, 5DS R, 6D Mark II, 850D, M50, R, RP, R5, R6, SX70 HS, SX740 HS (Magic Lantern itself is still experimental on these).
<!-- cameras:end -->

✅ tried on the camera and works · 🧪 builds; waiting for someone to try it. The card files are in each
[release](../../releases/latest). The list lives in [`ml-dev/cameras.txt`](ml-dev/cameras.txt); porting
notes in [PORTING.md](PORTING.md).

### Putting it on the camera

1. The camera needs exactly the Canon firmware in the table (MENU → last settings tab → *Firmware ver.*).
2. Unzip the card files for your camera onto an SD card, put it in the camera and run *Firmware ver.* →
   update once. From then on M-Film starts with the camera from that card.
3. Full steps, and how to go back: [TESTING.md](TESTING.md). Building it yourself:
   `ml-dev/build_fork.sh <camera>`.

---

## Develop on your computer: Darkrooms

The camera develops its rolls by itself, slowly. **Darkrooms** does it on your computer, fast.
Plug the camera in (or put its card in a reader) and open Darkrooms. It finds the camera, shows every
roll you shot with its film, and develops them at full resolution.

<table>
<tr>
<td width="50%"><img src="docs/images/app-rolls.jpg" alt="Film rolls"></td>
<td width="50%"><img src="docs/images/app-darkroom.jpg" alt="Developing a roll"></td>
</tr>
<tr>
<td><b>Your rolls</b>, each with its canister and a strip of its frames. Develop whole rolls or pick single frames.</td>
<td><b>The lights go red.</b> Prints come out of the developer and hang on the line.</td>
</tr>
<tr>
<td><img src="docs/images/app-lights-on.jpg" alt="Lights on: the roll and its contact sheet"></td>
<td><img src="docs/images/app-develop.jpg" alt="Develop settings"></td>
</tr>
<tr>
<td><b>Lights on.</b> Every roll gets a contact sheet and its own folder.</td>
<td><b>Full detail.</b> Every pixel of the RAW, JPEG with 4:4:4 colour, EXIF kept, optional date stamp.</td>
</tr>
</table>

### Free, or Full

| | Free | Darkrooms Full |
|---|---|---|
| Rolls a day | 1 | as many as you like |
| Every film, full size, EXIF, contact sheets | ✓ | ✓ |
| Many rolls at once on every core | | ✓ |
| Price | free | **$5.99 once**, updates included |

The camera's own darkroom stays free and unlimited. Buy Darkrooms Full in the program
(gear icon → *Get Full*); the licence key arrives by e-mail and works on one computer at a time
(release it in Darkrooms to move it to another).

### Download

| Your computer | Get | Open it |
|---|---|---|
| **Windows 10 / 11** | `Darkrooms-windows-x64.zip` | Unzip, run `Darkrooms.exe`. If Windows warns: *More info* → *Run anyway*. |
| **Mac with Intel** | `Darkrooms-macos-intel.zip` | Unzip, drag to Applications and open it. The first time: *System Settings → Privacy & Security → Open Anyway* (macOS 14 and older: right-click → Open). |
| **Mac with Apple silicon** | `Darkrooms-macos-apple-silicon.zip` | Same. |

From the **[latest release](../../releases/latest)**. About 25–45 MB. The program isn't signed with Apple or
Microsoft yet, hence the warning the first time.

---

## Take it further

- **Have one of the cameras above?** [TESTING.md](TESTING.md): try it and tell us, so it can move to ✅.
- **Another camera?** [PORTING.md](PORTING.md) says what moves easily (the Film OS
  screens), what has to be redone per camera (the Magic Lantern side), and how to go about it.
- **Every screen and button** of the camera side, and how it works inside (in Thai):
  [docs/MANUAL.th.md](docs/MANUAL.th.md).
- **Something broken?** [Open an issue](../../issues/new/choose) and paste what the gear icon →
  *What does the computer see?* shows.
- **The films** (looks, LUT list) are in [`ml-dev/films/`](ml-dev/films/); the camera build bakes them in.
- **Darkrooms**, the desktop program, is closed source and isn't in this repository.

## Support

The camera side of M-Film is free and stays free. If it gave you a roll you like, you can
**[buy the developer a coffee ☕](https://buy.stripe.com/7sY14p8d93QE5Ny5M58so02)**.

## License

This repository: GPL-2.0 ([LICENSE](LICENSE)), as the camera side builds on Magic Lantern.
Darkrooms (the desktop program) is a separate, closed-source program under its own licence. Fonts, film LUTs and other
parts: [THIRD_PARTY.md](THIRD_PARTY.md). Not affiliated with Canon, Kodak, Fujifilm or any film maker.
