M-Film for the camera (Film OS + Magic Lantern)
================================================

What is in here: autoexec.bin, the ML/ folder and ML-SETUP.FIR, for ONE camera model and
ONE Canon firmware version (the zip's name says which, e.g. 650D.104 = EOS 650D, firmware 1.0.4).

Only the EOS M build has been tried on a camera. The others build, but nobody has tried them yet:
read TESTING.md at https://github.com/HNGSeries/M-Film before you use one.

Install
  1. Check the camera's Canon firmware (MENU > the last settings tab > Firmware ver.).
     It must be the version in this zip's name. If not, update Canon's firmware first.
  2. Copy everything in this zip to the root of a freshly formatted card.
  3. Put the card in the camera, MENU > Firmware ver. > update, and follow the screen.
     This sets the camera to start Magic Lantern from the card.
  4. Switch the camera on. The film shelf appears once the camera has started.

Update to a new version
  Don't copy a new version over the old one: files left from before can make the camera misbehave.
  1. Finish the roll and develop it (in the camera or with Darkrooms).
  2. Copy your photos off the card (the DCIM folder).
  3. Format the card in the camera, and choose to remove Magic Lantern.
  4. Install the new version as above, Firmware ver. > update included.
  Your settings go back to their defaults.

If the camera doesn't start (black screen, card light stays on): take the battery out, take the
card out, and the camera starts normally without it. Tell us (see TESTING.md).

Remove: format the card in the camera, or delete autoexec.bin and ML/.
Logs for a bug report: ML/FILMROLL.LOG on the card.

Free software (GPL-2.0, LICENSE.txt; the source is at https://github.com/HNGSeries/M-Film).
Other parts and their licences, among them the Film-Luts colours: THIRD_PARTY.txt.
Buy the developer a coffee: https://buy.stripe.com/7sY14p8d93QE5Ny5M58so02
