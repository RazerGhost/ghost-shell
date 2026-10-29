import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.theme
import qs.widgets
import "Calc.js" as Calc

// The launcher's calculator: a sum or a unit conversion typed into the search ("5 km in miles",
// "20 usd to eur") answered by qalc (Calc.js, tested). Selected while it shows; Enter or a click
// copies the answer (`copied`, and the launcher closes).
MouseArea {
    id: root

    // The search's text now: an answer that comes back for older text is dropped.
    property string current
    property string answer: ""
    property bool selected: false
    property string asked: ""

    signal copied()

    function ask(query: string): void {
        if (!Calc.isExpression(query)) {
            answer = "";
            selected = false;
            return;
        }
        asked = query;
        wait.restart();
    }

    function copy(): void {
        Quickshell.execDetached(["wl-copy", answer]);
        copied();
    }

    height: Theme.launcher.rowHeight
    visible: answer !== ""
    onAnswerChanged: selected = answer !== ""
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: copy()

    Accessible.role: Accessible.Button
    Accessible.name: "Result: " + answer + ", press Enter to copy"
    Accessible.onPressAction: copy()

    // After typing pauses, so qalc doesn't run for every key.
    Timer {
        id: wait
        interval: 150
        onTriggered: qalc.start()
    }

    // A currency question can take a moment (qalc fetches rates); asked again meanwhile, it
    // answers the newest question after.
    LatestProcess {
        id: qalc
        // Dots for decimals whatever the regional format.
        command: ["qalc", "-s", "decimal comma off", "-t", Calc.prepare(root.asked)]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.asked === root.current)
                    root.answer = Calc.answer(text, root.asked);
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.m
        color: Colors.m3surfaceContainerHighest
        visible: root.selected || root.containsMouse
    }

    MaterialIcon {
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing.s + (Theme.icon.launcher - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        icon: "calculate"
        color: Colors.m3primary
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing.s + Theme.icon.launcher + Theme.spacing.m
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: "= " + root.answer
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            font.weight: Font.DemiBold
        }

        Text {
            text: "Enter copies the result"
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
        }
    }
}
