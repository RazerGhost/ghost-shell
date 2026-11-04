// Your phone through KDE Connect (the phone module): the paired phone that's connected now, its
// battery, and what quick settings' Phone page does with it (ring, send files or the clipboard,
// browse its files). Read by phone.sh (parsed by Phone.js) every 10 s, only while something
// shows it (`active`). Pairing happens in the KDE Connect app on the phone.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "Phone.js" as PhoneJs

Singleton {
    id: root

    // Set while quick settings shows the Phone tile or page.
    property bool active: false

    property var phones: [] // [{ id, name, battery, charging }], connected and paired
    readonly property var phone: phones.length > 0 ? phones[0] : null
    readonly property string label: PhoneJs.label(phone)

    readonly property string script: Quickshell.shellDir + "/services/phone.sh"

    function refresh(): void {
        read.start();
    }

    function ring(): void {
        if (phone)
            Quickshell.execDetached(["kdeconnect-cli", "-d", phone.id, "--ring"]);
    }

    function sendClipboard(): void {
        if (phone)
            Quickshell.execDetached(["kdeconnect-cli", "-d", phone.id, "--send-clipboard"]);
    }

    function sendFiles(): void {
        if (phone)
            Quickshell.execDetached(["sh", script, "send", phone.id]);
    }

    // Files dropped on the island (paths): to the connected phone, or the one picked when several
    // are (phone.sh asks); without one, a notification says so.
    function share(paths: var): void {
        if (paths.length > 0)
            Quickshell.execDetached(["sh", script, "share", ...paths]);
    }

    // Its files in the file manager, once KDE Connect has mounted them.
    function browse(): void {
        if (phone)
            mount.start(["sh", script, "mount", phone.id]);
    }

    // The KDE Connect app, for pairing and everything else.
    function openApp(): void {
        Apps.run(["kdeconnect-app"], "org.kde.kdeconnect.app", "");
    }

    onActiveChanged: {
        if (active)
            refresh();
    }

    Timer {
        interval: 10000
        running: root.active
        repeat: true
        onTriggered: root.refresh()
    }

    LatestProcess {
        id: read
        command: ["sh", root.script, "status"]
        stdout: StdioCollector {
            onStreamFinished: root.phones = PhoneJs.parse(text)
        }
    }

    LatestProcess {
        id: mount
        stdout: StdioCollector {
            onStreamFinished: {
                const place = text.trim();
                if (place.startsWith("/"))
                    Apps.openPath(place);
            }
        }
    }
}
