import QtQuick
import qs.services
import qs.theme

// Phone page of quick settings (KDE Connect, the phone module): the connected phone with its
// battery, and what to do with it: ring it to find it, send it files or the clipboard, browse its
// files. Without one, how to pair it. Read while the tile or this page shows (Phone.active).
Column {
    id: root

    signal back()

    spacing: Theme.spacing.s

    PageHeader {
        width: parent.width
        title: "Phone"
        hasSwitch: false
        onBack: root.back()
    }

    ListRow {
        visible: Phone.phone !== null
        width: parent.width
        icon: "smartphone"
        title: Phone.phone?.name ?? ""
        subtitle: Phone.label
        highlighted: true
        activeFocusOnTab: false
        cursorShape: Qt.ArrowCursor
    }

    Repeater {
        model: Phone.phone === null ? [] : [
            { icon: "ring_volume", title: "Ring it", subtitle: "Find it, even on silent", act: "ring" },
            { icon: "upload_file", title: "Send files", subtitle: "Pick files to send to it", act: "send" },
            { icon: "content_paste_go", title: "Send the clipboard", subtitle: "What you copied here, to copy there", act: "clipboard" },
            { icon: "folder_open", title: "Browse its files", subtitle: "In the file manager", act: "browse" }
        ]

        ListRow {
            required property var modelData

            width: root.width
            icon: modelData.icon
            title: modelData.title
            subtitle: modelData.subtitle
            onActivated: {
                if (modelData.act === "ring")
                    Phone.ring();
                else if (modelData.act === "send")
                    Phone.sendFiles();
                else if (modelData.act === "clipboard")
                    Phone.sendClipboard();
                else
                    Phone.browse();
            }
        }
    }

    Text {
        visible: Phone.phone === null
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        topPadding: Theme.spacing.m
        bottomPadding: Theme.spacing.s
        text: "No phone connected. Put the KDE Connect app on your phone, join the same Wi-Fi, and pair it from there."
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
    }

    ListRow {
        width: parent.width
        icon: "open_in_new"
        title: "Open KDE Connect"
        subtitle: "Pairing, and everything else it does"
        onActivated: Phone.openApp()
    }
}
