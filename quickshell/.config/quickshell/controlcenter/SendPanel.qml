import QtQuick
import Quickshell
import qs.services
import qs.theme

// Where files dropped on the island go (bar/Island.qml's offerSend): your phone through KDE
// Connect, or another device nearby through LocalSend (its app opens on its Send page with them,
// where you pick the device). Click outside or Escape to keep them.
Column {
    id: root

    required property var paths

    // Sent (or handed to LocalSend); the island closes the menu.
    signal done()

    readonly property bool kdeConnect: DesktopEntries.applications.values.some(entry => entry.id === "org.kde.kdeconnect.app")

    padding: Theme.spacing.l
    topPadding: Theme.spacing.s
    spacing: Theme.spacing.xs

    Component.onCompleted: Phone.refresh() // the phone's name

    Text {
        width: root.width - root.leftPadding - root.rightPadding
        bottomPadding: Theme.spacing.xs
        text: root.paths.length === 1 ? "Send " + root.paths[0].split("/").pop()
                                      : "Send " + root.paths.length + " files"
        elide: Text.ElideMiddle
        color: Colors.m3onSurface
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
        font.weight: Font.DemiBold
        Accessible.role: Accessible.Heading
        Accessible.name: text
    }

    ListRow {
        visible: root.kdeConnect
        width: root.width - root.leftPadding - root.rightPadding
        icon: "smartphone"
        title: Phone.phone?.name ?? "Your phone"
        subtitle: Phone.phone ? "KDE Connect" : "KDE Connect · not connected now"
        onActivated: {
            Phone.share(root.paths);
            root.done();
        }
    }

    ListRow {
        width: root.width - root.leftPadding - root.rightPadding
        icon: "devices"
        title: "Another device"
        subtitle: "LocalSend · pick one nearby"
        onActivated: {
            Phone.sendWithLocalSend(root.paths);
            root.done();
        }
    }
}
