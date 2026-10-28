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

// The value for `pw-cli set-param ghost-equalizer Props <value>`.
function props(g) {
    const params = bands.map((b, i) => `"${b.name}:Gain" ${gains(g)[i].toFixed(1)}`);
    return `{ params = [ ${params.join(" ")} ] }`;
}
