// The text in a "join this Wi-Fi" QR code (WifiPage.qml), in the format phones read:
// WIFI:T:<WPA|nopass>;S:<name>;P:<password>;; with \ ; , : and " escaped by a backslash. Plain
// JavaScript, so it can be tested on its own (tests/tst_wifiqr.qml).
.pragma library

function escape(value) {
    return value.replace(/([\\;,:"])/g, "\\$1");
}

// `password` "" for an open network.
function text(name, password) {
    return password === ""
        ? `WIFI:T:nopass;S:${escape(name)};;`
        : `WIFI:T:WPA;S:${escape(name)};P:${escape(password)};;`;
}
