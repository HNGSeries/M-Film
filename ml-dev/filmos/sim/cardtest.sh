#!/usr/bin/env bash
# The darkroom on a card of problem rolls (mkcard.sh --problems): it develops
# what it can, and says why it can't the rest. Fails if a line is missing.
#   make && ./cardtest.sh
set -euo pipefail
cd "$(dirname "$0")"
CARD=out/cardp ./mkcard.sh --problems >/dev/null
rm -rf out/frames/problems && mkdir -p out/frames/problems
log=out/cardtest.log
FOS_CARD=out/cardp/ ./out/sim scenes/darkroom_problems.txt out/frames/problems > "$log" 2>&1

fail=0
expect() {
    if grep -qF -- "$2" "$log"; then echo "ok    $1"
    else echo "FAIL  $1: no \"$2\""; fail=1; fi
}
reject() {        # an extended regex
    if grep -qE -- "$2" "$log"; then echo "FAIL  $1: \"$2\""; fail=1
    else echo "ok    $1"; fi
}

# a roll shot as JPEG: each frame says so, and names the JPEG
expect "JPEG roll: frame 1 is a JPEG"       "roll 006 frame 1: shot as JPEG, no RAW: out/cardp/DCIM/100CANON/IMG_0501.JPG"
expect "JPEG roll: frame 4 is a JPEG"       "roll 006 frame 4: shot as JPEG, no RAW: out/cardp/DCIM/100CANON/IMG_0504.JPG"
# Adobe RGB (_MG_): found by Canon's name; the deleted one is named that way too
expect "Adobe RGB: frame 1 found"           "roll 007 frame 1 developed"
expect "Adobe RGB: deleted, by Canon's name" "roll 007 frame 2: no RAW file out/cardp/DCIM/100CANON/_MG_0506.CR2"
expect "Adobe RGB: frame 4 found"           "roll 007 frame 4 developed"
# across IMG_9999 -> IMG_0001: each frame in its own folder's log
expect "9999 wrap: all four RAWs"           "roll 008 (gold200): 4 frames, 4 RAW files"
reject "9999 wrap: nothing missing"         "roll 008 frame [0-9]+: (no RAW|shot as JPEG)"
for f in 1 2 3 4; do expect "9999 wrap: frame $f developed" "roll 008 frame $f developed"; done

[ $fail = 0 ] && echo "cardtest: all passed" || { echo "cardtest: failed (log: sim/$log)"; exit 1; }
