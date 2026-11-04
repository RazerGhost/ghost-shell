import QtQuick
import qs.theme
import qs.widgets

// A desktop widget's card: glass like the shell's panels, small (a square), medium (twice as
// wide) or large (that, twice as tall), every widget the same corners and padding
// (Theme.desktop). The content goes inside the padding.
Surface {
    id: root

    property bool medium: false
    property bool large: false
    default property alias content: inner.data
    // The desktop's keyboard mode (Super+D, WidgetStage.browsing) is on this widget: a widget
    // with rows of its own shows which one the keys are on.
    property bool chosen: false

    // A key while this widget is chosen; true if it used it, else the arrow keys move on to the
    // next widget. A widget that does something on Enter says so here.
    function key(event: var): bool {
        return false;
    }

    // Emitted by key() when what it did takes the keyboard elsewhere (the music app opening, the
    // today menu): the keyboard mode ends there, without going back to your workspace.
    signal handOff()

    implicitWidth: medium || large ? Theme.desktop.medium : Theme.desktop.size
    implicitHeight: large ? Theme.desktop.medium : Theme.desktop.size
    width: implicitWidth
    height: implicitHeight
    radius: Theme.desktop.radius
    color: Colors.widgetTranslucent

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: Theme.desktop.padding
    }
}
