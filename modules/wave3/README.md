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
| 1 | Noise removal (openxlr's own, RNNoise) | strength 100 |
| 2 | LSP Parametric Equalizer x8 Mono | high-pass 90 Hz (24 dB/oct); −2 dB at 275 Hz, wide (Q 0.7); +2.5 dB at 4 kHz (Q 0.8) |
| 3 | LSP Compressor Mono | 3:1, attack 10 ms, release 100 ms, threshold −34 dB, makeup +12 dB |
| 4 | De-esser: a second LSP Compressor Mono | listens above 6 kHz only (sidechain high-pass, 24 dB/oct), 4:1, attack 1 ms, release 50 ms, threshold −32 dB |
| 5 | LSP Limiter Mono | threshold −1 dBFS |

Why it differs from the Windows chain:

- Noise removal is built into openxlr (RNNoise or DeepFilterNet 3), always first in a
  microphone's chain, so `noise-suppression-for-voice` and a separate DeepFilterNet aren't needed.
  Switch to DeepFilterNet in the strip's noise removal if RNNoise sounds too aggressive.
- Calf's Deesser is stereo only, and openxlr only offers mono plugins for a microphone. The
  de-esser is LSP's mono compressor with its detection filtered to the sibilance range, which is
  how a wideband de-esser works.
- The Wave:3's own ClipGuard is controllable on Linux through openxlr; the limiter is the safety
  net after the chain.

## Tuning

Measured on the desktop (2026-11-05): with the Wave:3's gain at 24 dB (it was at its 40 dB
maximum and clipped), speech peaks at −13 to −18 dBFS before the chain. At −34 dB the compressor
takes 3–6 dB off normal speech, and the makeup brings Chat to −20.7 LUFS with peaks around −8 dB.
The de-esser is on, gently: compression lifted the "s" sounds by up to 10 dB. The gain is the
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

## Left to do by hand

- Pick openxlr's virtual microphone as the input in Discord (Vesktop), OBS and other apps.
- Set the Wave:3's gain in openxlr (or on the dial) so loud speech peaks around −12 dBFS before
  the chain.
