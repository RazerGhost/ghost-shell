// VPN, hotspot and airplane mode (services/NetworkExtras.qml): parsing nmcli's and rfkill's
// output. Plain JavaScript, so it can be tested on its own (tests/tst_networkextras.qml).
.pragma library

// `nmcli -t` separates fields with ":" and escapes ":" and "\" inside them with "\".
function fields(line) {
    const out = [""];
    for (let i = 0; i < line.length; i++) {
        if (line[i] === "\\" && i + 1 < line.length)
            out[out.length - 1] += line[++i];
        else if (line[i] === ":")
            out.push("");
        else
            out[out.length - 1] += line[i];
    }
    return out;
}

// Lines of `nmcli -t -f NAME,UUID,TYPE,ACTIVE connection show` -> the saved connections,
// { name, uuid, type, active }.
function connections(text) {
    return text.split("\n").filter(l => l !== "").map(fields).filter(f => f.length === 4)
        .map(f => ({ name: f[0], uuid: f[1], type: f[2], active: f[3] === "yes" }));
}

// VPNs: NetworkManager's VPN plugins (OpenVPN and the like) and WireGuard, which is how Proton
// VPN's app connects.
function vpns(list) {
    return list.filter(c => c.type === "vpn" || c.type === "wireguard");
}

// The hotspot `nmcli device wifi hotspot` makes is a connection named "Hotspot".
const hotspotName = "Hotspot";

function hotspotActive(list) {
    return list.some(c => c.name === hotspotName && c.active);
}

// Lines of `rfkill -n -o SOFT` ("blocked" / "unblocked", one per radio): airplane mode is every
// radio switched off; a machine without radios isn't in airplane mode.
function airplane(text) {
    const states = text.split("\n").map(l => l.trim()).filter(l => l !== "");
    return states.length > 0 && states.every(s => s === "blocked");
}
