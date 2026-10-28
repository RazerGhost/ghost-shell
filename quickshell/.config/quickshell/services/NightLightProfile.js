// Reads `hyprctl hyprsunset profile` for services/NightLight.qml. Plain JavaScript, so it can be
// tested on its own (tests/tst_nightlight.qml).
.pragma library

// Whether the profile warms the screen. The output looks like:
//   Time: 20:00
//   Temperature: 4000
//   Gamma: 1
//   Identity: false
// "Identity: true" means no color change; so does a neutral temperature (6000 K or more).
function warm(output) {
    const identity = /Identity:\s*(\w+)/.exec(output);
    const temperature = /Temperature:\s*(\d+)/.exec(output);
    if (!identity || !temperature)
        throw new Error("unexpected hyprsunset profile output: " + output);
    return identity[1] !== "true" && Number(temperature[1]) < 6000;
}
