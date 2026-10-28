---------------------
---- KEYBINDINGS ----
---------------------

-- hyprlock with its sample config: the fallback lock screen (Super+Shift+L, and Super+L when the
-- shell isn't running).
local fallbackLock = "hyprlock -c /usr/share/hypr/hyprlock.conf"

-- The terminal, browser and file manager are chosen in Quickshell's settings window, so these
-- binds ask the shell to open them. If the shell isn't running (qs ipc fails), they fall back to
-- these, so there's always a way to get a terminal.
local function app(kind, fallback)
    return hl.dsp.exec_cmd("qs ipc call apps open " .. kind .. " || " .. fallback)
end

-- Every bind except the media keys has a description: the settings window lists them
-- (hyprctl binds -j), and binds with the same description show as one row ("Super + W / Alt + F4").

local mainMod = "SUPER"

-- Windows-style layout (user's choice). Super tapped on its own opens the launcher: a release
-- bind on the Super key itself.

-- Apps
hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd("qs ipc call launcher toggle"), { release = true, description = "App launcher" })
hl.bind(mainMod .. " + space",   hl.dsp.exec_cmd("qs ipc call launcher toggle"), { description = "App launcher" })
hl.bind(mainMod .. " + Return",  app("terminal", "ghostty"), { description = "Terminal" })
hl.bind(mainMod .. " + E",       app("fileManager", "nautilus"), { description = "File manager" })
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("qs ipc call apps terminal yazi || ghostty -e yazi"), { description = "Yazi (files in the terminal)" })
hl.bind(mainMod .. " + B",       app("browser", "zen-browser"), { description = "Browser" })
hl.bind(mainMod .. " + SHIFT + Z", app("editor", "zeditor"), { description = "Editor" })
hl.bind(mainMod .. " + I",       hl.dsp.exec_cmd("qs ipc call settings open"), { description = "Settings" })

-- Island menus
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call island toggle settings"), { description = "Quick settings" })
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("qs ipc call island toggle today"), { description = "Calendar and notifications" })
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("qs ipc call island toggle clipboard"), { description = "Clipboard history" })
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("qs ipc call island toggle emoji"), { description = "Emoji" })

-- Session
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("qs ipc call lock lock || " .. fallbackLock), { description = "Lock" })
-- Fallback lock screen with hyprlock's sample config, in case Quickshell's misbehaves.
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd(fallbackLock), { description = "Lock (fallback lock screen)" })
-- Power menu in the island: lock, suspend, log out, restart, shut down.
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("qs ipc call island toggle power"), { description = "Power menu" })

-- Windows
hl.bind(mainMod .. " + W", hl.dsp.window.close(), { description = "Close window" })
hl.bind("ALT + F4",        hl.dsp.window.close(), { description = "Close window" })
hl.bind(mainMod .. " + up",   hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), { description = "Maximize" })
-- Super+Down minimizes (Hyprland has no minimize, so the window goes to a hidden special
-- workspace that the island lists; see quickshell's services/Windows.qml).
hl.bind(mainMod .. " + down", hl.dsp.exec_cmd("qs ipc call snap down"), { description = "Minimize" })
-- Window menu on the window (like Windows' Alt+Space): minimize, maximize, fullscreen, close,
-- the snap layouts and moving it to another workspace. Super+Z opens the same menu.
hl.bind("ALT + space", hl.dsp.exec_cmd("qs ipc call snap picker"), { description = "Window menu and snap layouts" })
hl.bind(mainMod .. " + F",    hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "Fullscreen" })

-- Tiling (layout.lua). Super+Left/Right put the window in a half, every other spot is in the
-- window menu; both go through the shell, which offers windows for a spot left empty (Snap Assist).
hl.bind(mainMod .. " + left",  hl.dsp.exec_cmd("qs ipc call snap active left"), { description = "Snap left" })
hl.bind(mainMod .. " + right", hl.dsp.exec_cmd("qs ipc call snap active right"), { description = "Snap right" })
hl.bind(mainMod .. " + Z",     hl.dsp.exec_cmd("qs ipc call snap picker"), { description = "Window menu and snap layouts" })
-- Move the window's border, or swap it with the window next to it.
for _, direction in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + ALT + " .. direction, hl.dsp.layout("resize " .. direction), { repeating = true, description = "Resize the tiled window" })
    hl.bind(mainMod .. " + SHIFT + " .. direction, hl.dsp.layout("move " .. direction), { description = "Swap with the window next to it" })
end
hl.bind(mainMod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }), { description = "Float or tile" })

-- Alt+Tab switcher: Tab steps through the windows, releasing Alt switches (Quickshell sees that).
hl.bind("ALT + Tab",         hl.dsp.exec_cmd("qs ipc call switcher next"), { description = "Switch windows" })
hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("qs ipc call switcher previous"), { description = "Switch windows, backwards" })

-- Overview, like Windows' Task View: every window on the workspace, and the workspaces strip.
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("qs ipc call overview toggle"), { description = "Overview" })

-- Focus with arrow keys
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.focus({ direction = "left" }), { description = "Move focus" })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.focus({ direction = "right" }), { description = "Move focus" })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.focus({ direction = "up" }), { description = "Move focus" })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.focus({ direction = "down" }), { description = "Move focus" })

-- Screenshots (quickshell's screenshot/Screenshot.qml): saved to ~/Pictures/Screenshots and copied.
-- Super+Shift+S picks a region, window or the screen; Print takes the whole screen. Without the
-- shell, grim + slurp still copy a region.
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd('qs ipc call screenshot region || grim -g "$(slurp)" - | wl-copy'), { description = "Screenshot (region, window or screen)" })
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("qs ipc call screenshot record"), { description = "Record the screen (again: stop)" })
hl.bind("Print",                   hl.dsp.exec_cmd("qs ipc call screenshot screen || grim - | wl-copy"), { description = "Screenshot of the screen" })

-- Workspaces 1-10 (Super+0 = 10)
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }), { description = "Go to workspace 1-10" })
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { description = "Move window to workspace 1-10" })
end

-- Scratchpad
hl.bind(mainMod .. " + grave",         hl.dsp.workspace.toggle_special("magic"), { description = "Show or hide the scratchpad (a terminal when empty)" })
hl.bind(mainMod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:magic" }), { description = "Move window to the scratchpad" })

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Next or previous workspace" })
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { description = "Next or previous workspace" })

-- Magnifier, like Windows': zoom in around the pointer in steps, out again, and back to normal.
local function zoom(factor)
    return function()
        local now = hl.get_config("cursor.zoom_factor") or 1
        local next = factor and math.max(1, math.min(8, now * factor)) or 1
        hl.config({ cursor = { zoom_factor = next } })
    end
end
hl.bind(mainMod .. " + equal",  zoom(1.5),     { repeating = true, description = "Zoom in (magnifier)" })
hl.bind(mainMod .. " + minus",  zoom(1 / 1.5), { repeating = true, description = "Zoom out (magnifier)" })
hl.bind(mainMod .. " + Escape", zoom(nil),     { description = "Zoom back to normal" })

-- Move/resize windows with mouse. Hyprland's own drag and resize only reach floating windows;
-- for tiled ones drag.lua follows the pointer while the button is held (it does nothing over a
-- floating window): left-drag swaps the window with the tiled one it's dropped on, right-drag
-- moves the borders nearest the pointer.
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "Move window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })
local drag = require("drag")
hl.bind(mainMod .. " + mouse:272", drag.start_move, { non_consuming = true })
hl.bind(mainMod .. " + mouse:272", drag.stop_move, { release = true, non_consuming = true })
hl.bind(mainMod .. " + mouse:273", drag.start, { non_consuming = true })
hl.bind(mainMod .. " + mouse:273", drag.stop, { release = true, non_consuming = true })

-- Volume & brightness
-- Quickshell's OSD sees volume changes through PipeWire by itself. It can't watch the backlight,
-- so the brightness binds tell it to re-read the level (which also shows the OSD).
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+ && qs ipc call brightness refresh"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%- && qs ipc call brightness refresh"), { locked = true, repeating = true })

-- Media (requires playerctl)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
