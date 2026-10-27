import QtQuick
import qs.theme

// A Material Symbols glyph. The font maps names to glyphs through ligatures, so `icon` is the
// symbol's name from fonts.google.com/icons, e.g. "volume_up".
Text {
    property string icon
    // Material Symbols is a variable font; FILL 1 draws the solid variant of the symbol.
    property bool filled: true

    text: icon
    color: Colors.m3onSurface
    font.family: Theme.font.icon
    font.pixelSize: Theme.icon.bar
    font.variableAxes: { "FILL": filled ? 1 : 0 }
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    // The glyph is decorative; interactive parents set their own Accessible.name.
    Accessible.ignored: true
}
