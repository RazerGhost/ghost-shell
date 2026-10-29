import QtQuick
import qs.theme

// A small heading over a group of things (Settings' groups and sidebar sections, the Sound
// page's Output / Input / Apps), in the accent color. Screen readers announce it as a heading.
Text {
    color: Colors.m3primary
    font.family: Theme.font.sans
    font.pixelSize: Theme.font.small
    font.weight: Font.DemiBold
    Accessible.role: Accessible.Heading
    Accessible.name: text
}
