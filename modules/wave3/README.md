# wave3: the Elgato Wave:3 with openxlr

For the desktop the microphone is plugged into (the original Wave:3, USB id `0fd9:0070`; not the
MK.2). It replaces Elgato Wave Link with [openxlr](https://github.com/emaspa/openxlr) (AUR
`openxlr`, GPL-3.0): the Wave:3's hardware controls (gain, mute, ClipGuard, headphone volume, the
mic/PC balance), a Wave Link–style PipeWire mixer with virtual microphones, and LV2 plugin inserts.

## Setting it up

On that machine, list the module (with the others it uses) in `~/.config/ghost/modules`:

```sh
echo wave3 >> ~/.config/ghost/modules
ghost install wave3
```

It installs `openxlr`, `lsp-plugins-lv2` and `usbutils`, checks the connected microphone is a
Wave:3 (it stops otherwise), enables `openxlr-daemon` for your user, copies the **Voice** profile
into `~/.config/openxlr/profiles/0fd9-0070/` and makes openxlr recall it whenever the microphone
connects. Replug the Wave:3 once after the first install: openxlr's package ships a udev rule for
USB access, which applies on the next plug-in.

## The voice chain

In order, on the Wave:3's strip (Mic 1, id `xlr1`):

| | What | Starting values |
|---|---|---|
| 1 | Noise removal (openxlr's own, DeepFilterNet 3) | strength 100 |
| 2 | Expander (openxlr's own, software; its place in the chain is openxlr's, not checked) | below −55 dB, 4:1, at most 30 dB down, hold 100 ms, release 200 ms |
| 3 | LSP Parametric Equalizer x8 Mono | high-pass 70 Hz (24 dB/oct); +4 dB low shelf at 150 Hz; −1 dB at 275 Hz, wide (Q 0.7); +1 dB at 4 kHz (Q 0.8) |
| 4 | LSP Compressor Mono | 3:1, attack 10 ms, release 100 ms, threshold −34 dB, makeup +12 dB |
| 5 | De-esser: a second LSP Compressor Mono | listens above 5 kHz only (sidechain high-pass, 24 dB/oct), 6:1, attack 1 ms, release 50 ms, threshold −42 dB |
| 6 | LSP Limiter Mono | threshold −1 dBFS |

Why it differs from the Windows chain:

- Noise removal is built into openxlr (RNNoise or DeepFilterNet 3), always first in a
  microphone's chain, so `noise-suppression-for-voice` and a separate DeepFilterNet aren't needed.
  DeepFilterNet it is: RNNoise left the desktop's fan noise audible once the compressor's makeup
  lifted it (about 50 ms of delay instead of 30).
- Calf's Deesser is stereo only, and openxlr only offers mono plugins for a microphone. The
  de-esser is LSP's mono compressor with its detection filtered to the sibilance range, which is
  how a wideband de-esser works.
- The Wave:3's own ClipGuard is controllable on Linux through openxlr; the limiter is the safety
  net after the chain.

## Tuning

Measured on the desktop (2026-11-05): with the Wave:3's gain at 24 dB (it was at its 40 dB
maximum and clipped), speech peaks at −13 to −18 dBFS before the chain. At −34 dB the compressor
takes 3–6 dB off normal speech, and the makeup brings Chat to −20.7 LUFS with peaks around −8 dB.
Then by ear: more bass (the low shelf, the high-pass lower, less of the 275 Hz cut and the 4 kHz
lift), a firmer de-esser (the "s" sounds went from 14 to 22 dB under the loudest speech), and
DeepFilterNet with the expander: the room's noise, −24 to −29 dB peaks at the raw mic, ends
around −57 dB after DeepFilterNet and is turned down further in the pauses. The gain is the
microphone's own and stays in it (and in a profile saved from openxlr); the repo's copy holds
only the chain.

openxlr's daemon can be driven over its socket, which is how this was tuned (the instance id is
in `waveInterfaces` in `/api/v1/state`):

```sh
x() { curl -s --unix-socket "$XDG_RUNTIME_DIR/openxlr/control.sock" -H 'Content-Type: application/json' "$@"; }
x -d '{"cmd":"setWaveControl","device":"0fd9:0070@<id>","control":"gain","value":24}' http://x/api/v1/commands
x -d '{"cmd":"setInsertParam","channel":"xlr1","insertId":"compressor","symbol":"al","value":0.02}' http://x/api/v1/commands
x -d '{"cmd":"saveProfile","name":"Voice"}' http://x/api/v1/commands
```

Open openxlr (the app menu, or `openxlr`), then the Mic 1 strip's inserts: every plugin has its
editor or generated sliders, and **Mic setup** loops a recorded take through the chain while you
tune. Set the compressor's threshold so normal speech gets 3–6 dB of gain reduction, then the
makeup to match. Turn the de-esser on (un-bypass) if "s" sounds are sharp, and lower its
threshold until they soften.

Save it as a profile named **Voice** in openxlr (Header, Profiles) so it survives. The repo's
copy only fills a fresh install; to keep your tuning in the dotfiles:

```sh
cp ~/.config/openxlr/profiles/0fd9-0070/Voice.json ~/Projects/ghost-shell/modules/wave3/Voice.json
```

Check the diff before committing: a profile saved from the UI also holds the hardware settings
(gain, headphone volume) and the whole mixer scene.

## On Windows (Wave Link)

The same desktop boots Windows with Wave Link 3.4 and Elgato's own effects (Noise Removal, De-Esser,
EQ, Compressor, from `C:\Program Files\Common Files\VST3\Elgato`). Their settings, read from
Wave Link's `Settings.json` on 2026-11-05 (the plugins' states are JUCE data inside it), next to
the chain here:

| | Windows (as found) | Linux (above) |
|---|---|---|
| Noise | VoiceFocus, then Elgato Noise Removal (an RNNoise gate: VAD threshold 0.8, release 110 ms) | DeepFilterNet, the expander |
| EQ | low cut 61 Hz; +2.8 dB low shelf at 125 Hz; −2.2 dB at 240 Hz; −1.8 dB at 763 Hz; −1.4 dB at 3 kHz; +2.2 dB high shelf at 7.2 kHz; high cut 18 kHz | high-pass 70 Hz; +4 dB low shelf at 150 Hz; −1 dB at 275 Hz; +1 dB at 4 kHz |
| Compressor | 2:1 from −37 dB, attack 20 ms, release 150 ms, automatic makeup | 3:1 from −34 dB, attack 10 ms, release 100 ms, +12 dB makeup |
| De-esser | two bands, 2.5 and 8 kHz, 4:1 at −60 dB; before the EQ | above 5 kHz, 6:1; after the compressor |

To match the Linux chain, by hand in Wave Link (the plugins show dB and Hz; writing
`Settings.json` from Linux would mean re-encoding the plugins' states on a read-write NTFS mount,
and Wave Link may overwrite or refuse it). The values are a mapping between different plugins,
so compare the two by ear afterwards:

1. Order: the De-Esser below the Compressor.
2. Elgato EQ: band 1 (low cut) 70 Hz; band 3 (low shelf) 150 Hz, +4 dB; band 4 275 Hz, −1 dB,
   Q 0.7; band 6 4 kHz, +1 dB, Q 0.8; band 2 (763 Hz) and band 5 (the high shelf, which lifted
   the "s" sounds) to 0 dB; the high cut stays.
3. Elgato Compressor: threshold −34 dB, ratio 3, attack 10 ms, release 100 ms; automatic makeup
   stays on (it stands in for the fixed +12 dB).
4. Elgato De-Esser: band two at 6 kHz, ratio 6; band one's ratio down to 2 (at 2.5 kHz it dulls
   the voice more than it catches "s").
5. Noise: VoiceFocus and Noise Removal stay; raise Noise Removal's VAD threshold a little if the
   pauses still carry noise.
6. Gain: Wave Link keeps its own (gain lock on; 0.475 on its 0-1 scale, whose dB mapping isn't
   known), so set it by the meter: loud speech about two-thirds up, never in the red. The
   thresholds above assume the input level here (peaks around −13 to −18 dBFS).

## Left to do by hand

- Pick openxlr's virtual microphone as the input in Discord (Vesktop), OBS and other apps.
- Set the Wave:3's gain in openxlr (or on the dial) so loud speech peaks around −12 dBFS before
  the chain.
