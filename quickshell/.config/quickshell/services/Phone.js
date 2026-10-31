// Parsing for services/Phone.qml: phone.sh status's lines into phones. Plain JavaScript, so it
// can be tested on its own (tests/tst_phone.qml).
.pragma library

// "<id>\t<name>\t<battery>\t<charging>" lines -> [{ id, name, battery, charging }]. battery is
// 0-100 or null (the phone hasn't said, or its battery plugin is off); a line without an id
// (letters, digits, _ and -, as KDE Connect makes them) is left out.
function parse(text) {
    const phones = [];
    for (const line of String(text).split("\n")) {
        const [id, name, battery, charging] = line.split("\t");
        if (!/^[A-Za-z0-9_-]+$/.test(id ?? ""))
            continue;
        const charge = Number.parseInt(battery, 10);
        phones.push({
            id: id,
            name: name || "Phone",
            battery: Number.isInteger(charge) && charge >= 0 && charge <= 100 ? charge : null,
            charging: charging === "true"
        });
    }
    return phones;
}

// The tile's and page's line under the phone's name.
function label(phone) {
    if (!phone)
        return "Not connected";
    if (phone.battery === null)
        return "Connected";
    return phone.battery + "% battery" + (phone.charging ? ", charging" : "");
}
