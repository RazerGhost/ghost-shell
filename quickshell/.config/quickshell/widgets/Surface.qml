import QtQuick
import qs.theme

// A panel of the shell (menus, dock, launcher, OSD, overview...): glass like the Ghost Spotify
// theme, see-through over Hyprland's blur with a thin light edge (Settings: glass), or nearly
// solid with the setting off. The island draws the same with its own shape (bar/PillShape.qml).
Rectangle {
    color: Colors.surfaceTranslucent
    border.width: Theme.glass.edge
    border.color: Colors.glassEdge
}
