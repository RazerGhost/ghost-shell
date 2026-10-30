pragma Singleton

import Quickshell

// Hyprland Lua that only lasts while the shell needs it: the windows editor's rule that keeps
// its example windows inside its card. settings/HyprlandSettings.qml appends it to the
// shell-settings.lua it writes, so a reload (any setting changed) keeps it, where a rule made
// with `hyprctl eval` was dropped; "" leaves it out again. The login screen's copy never has it
// (greeter/sync.sh).
Singleton {
    property string lua: ""
}
