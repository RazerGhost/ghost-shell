// The equalizer's bands and presets, and the pw-cli argument that sets its gains
// (services/Equalizer.qml; the filter itself is pipewire/.config/pipewire/filter-chain.conf.d/
// ghost-equalizer.conf, whose node names these are). Plain JavaScript, so it can be tested on its
// own (tests/tst_equalizer.qml).
.pragma library

const bands = [
    { name: "bass",     label: "Bass",      frequency: "80 Hz" },
    { name: "low_mids", label: "Low mids",  frequency: "250 Hz" },
    { name: "mids",     label: "Mids",      frequency: "1 kHz" },
    { name: "presence", label: "Presence",  frequency: "4 kHz" },
    { name: "treble",   label: "Treble",    frequency: "10 kHz" }
];

// Gains in dB, one per band. Starting points to adjust by ear.
const presets = [
    { name: "Off",             gains: [0, 0, 0, 0, 0] },
    // Small speakers can't play deep bass and only distort on it; a little presence helps voices.
    { name: "Laptop speakers", gains: [-6, -1, 0, 2, 1] },
    { name: "Voice",           gains: [-4, -2, 1, 3, 0] },
    { name: "More bass",       gains: [6, 3, 0, 0, 0] },
    { name: "More treble",     gains: [0, 0, 0, 2, 5] }
];

const limit = 12; // dB either way

const flat = presets[0].gains;

// A saved setting as five gains, or flat when it isn't one (nothing saved for this output, or a
// hand-edited settings file). A list read from settings.json isn't a JavaScript Array (it fails
// Array.isArray), so anything with a length is copied into one.
function gains(saved) {
    const list = typeof saved?.length === "number" ? Array.from(saved) : [];
    return list.length === bands.length
        && list.every(g => typeof g === "number" && Math.abs(g) <= limit) ? list : flat;
}

// The preset these gains are, or "Custom".
function presetName(g) {
    return presets.find(p => p.gains.every((v, i) => v === g[i]))?.name ?? "Custom";
}

// An output's own correction, after your five bands (the `sp_*` nodes): what every output
// gets, and the outputs with a profile of their own, by PipeWire node name.
const neutralProfile = { preamp: 1.0, rumble: 10, punch: 0, body: 0, honk: 0, clarity: 0, air: 0 };
const outputProfiles = {
    // The HP Omen 16-xf0's speakers, bass speakers included (the system module's patch): measured
    // with a sweep and the built-in microphone (a hump around 1 kHz, little below 150 Hz), settled
    // by ear (user's pick, 2026-11-04: "B" for voices and instruments, then "B+" for the bass).
    // The preamp keeps the boosts from clipping.
    "alsa_output.pci-0000_05_00.6.HiFi__Speaker__sink":
        { preamp: 0.6, rumble: 90, punch: 4, body: 3, honk: -5, clarity: 2, air: 3 }
};

function profileFor(output) {
    return outputProfiles[output] ?? neutralProfile;
}

// The value for `pw-cli set-param ghost-equalizer Props <value>`: your bands, then the output's
// profile.
function props(g, output) {
    const p = profileFor(output);
    const params = bands.map((b, i) => `"${b.name}:Gain" ${gains(g)[i].toFixed(1)}`).concat([
        `"sp_preamp:Mult" ${p.preamp.toFixed(2)}`, `"sp_rumble:Freq" ${p.rumble.toFixed(1)}`,
        `"sp_punch:Gain" ${p.punch.toFixed(1)}`, `"sp_body:Gain" ${p.body.toFixed(1)}`,
        `"sp_honk:Gain" ${p.honk.toFixed(1)}`, `"sp_clarity:Gain" ${p.clarity.toFixed(1)}`,
        `"sp_air:Gain" ${p.air.toFixed(1)}`]);
    return `{ params = [ ${params.join(" ")} ] }`;
}
