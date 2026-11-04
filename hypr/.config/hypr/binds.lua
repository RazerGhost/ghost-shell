---------------------
---- KEYBINDINGS ----
---------------------

-- hyprlock with its sample config: the fallback lock screen (Super+Shift+L, and Super+L when the
-- shell isn't running).
local fallbackLock = "hyprlock -c /usr/share/hypr/hyprlock.conf"

-- The terminal, browser and file manager are chosen in Quickshell's Settings, so these
-- binds ask the shell to open them. If the shell isn't running (qs ipc fails), they fall back to
-- these, so there's always a way to get a terminal.
local function app(kind, fallback)
    return hl.dsp.exec_cmd("qs ipc call apps open " .. kind .. " || " .. fallback)
end

-- Every bind except the media keys has a description, "Category: what it does": the settings
-- window lists them by category (hyprctl binds -j), and binds with the same description show as
-- one row ("Super + W / Alt + F4").

local mainMod = "SUPER"

-- Windows-style layout (user's choice). Super tapped on its own opens the launcher: a release
-- bind on the Super key itself.

-- Apps
hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd("qs ipc call launcher toggle"), { release = true, description = "Apps: App launcher" })
hl.bind(mainMod .. " + space",   hl.dsp.exec_cmd("qs ipc call launcher toggle"), { description = "Apps: App launcher" })
hl.bind(mainMod .. " + Return",  app("terminal", "ghostty"), { description = "Apps: Terminal" })
hl.bind(mainMod .. " + E",       app("fileManager", "nautilus"), { description = "Apps: File manager" })
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("qs ipc call apps terminal yazi || ghostty -e yazi"), { description = "Apps: Yazi (files in the terminal)" })
hl.bind(mainMod .. " + B",       app("browser", "zen-browser"), { description = "Apps: Browser" })
hl.bind(mainMod .. " + SHIFT + Z", app("editor", "zeditor"), { description = "Apps: Editor" })
hl.bind(mainMod .. " + I",       hl.dsp.exec_cmd("qs ipc call settings open"), { description = "Apps: Settings" })

-- Island menus
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call island toggle settings"), { description = "Menus: Quick settings" })
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("qs ipc call island toggle today"), { description = "Menus: Calendar and notifications" })
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("qs ipc call island toggle clipboard"), { description = "Menus: Clipboard history" })
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("qs ipc call island toggle emoji"), { description = "Menus: Emoji" })
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd("qs ipc call customize menu"), { description = "Menus: Customize (desktop, dock and island, windows, quick settings)" })

-- Session
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("qs ipc call lock lock || " .. fallbackLock), { description = "Session: Lock" })
-- Fallback lock screen with hyprlock's sample config, in case Quickshell's misbehaves.
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd(fallbackLock), { description = "Session: Lock (fallback lock screen)" })
-- Power menu in the island: lock, suspend, log out, restart, shut down.
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("qs ipc call island toggle power"), { description = "Session: Power menu" })

-- Windows
hl.bind(mainMod .. " + W", hl.dsp.window.close(), { description = "Windows: Close window" })
hl.bind("ALT + F4",        hl.dsp.window.close(), { description = "Windows: Close window" })
hl.bind(mainMod .. " + up",   hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), { description = "Windows: Maximize" })
-- Super+Down minimizes (Hyprland has no minimize, so the window goes to a hidden special
-- workspace; the overview lists them, see quickshell's services/Windows.qml).
hl.bind(mainMod .. " + down", hl.dsp.exec_cmd("qs ipc call snap down"), { description = "Windows: Minimize" })
-- Window menu on the window (like Windows' Alt+Space): minimize, maximize, fullscreen, close,
-- the snap layouts and moving it to another workspace. Super+Z opens the same menu.
hl.bind("ALT + space", hl.dsp.exec_cmd("qs ipc call snap picker"), { description = "Windows: Window menu and snap layouts" })
hl.bind(mainMod .. " + F",    hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "Windows: Fullscreen" })

-- Tiling (layout.lua). Super+Left/Right put the window in a half, every other spot is in the
-- window menu; both go through the shell, which offers windows for a spot left empty (Snap Assist).
hl.bind(mainMod .. " + left",  hl.dsp.exec_cmd("qs ipc call snap active left"), { description = "Windows: Snap left" })
hl.bind(mainMod .. " + right", hl.dsp.exec_cmd("qs ipc call snap active right"), { description = "Windows: Snap right" })
hl.bind(mainMod .. " + Z",     hl.dsp.exec_cmd("qs ipc call snap picker"), { description = "Windows: Window menu and snap layouts" })
-- Move the window's border, or swap it with the window next to it.
for _, direction in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + ALT + " .. direction, hl.dsp.layout("resize " .. direction), { repeating = true, description = "Windows: Resize the tiled window" })
    hl.bind(mainMod .. " + SHIFT + " .. direction, hl.dsp.layout("move " .. direction), { description = "Windows: Swap with the window next to it" })
end
hl.bind(mainMod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }), { description = "Windows: Float or tile" })

-- Window tabs (Hyprland groups): windows sharing one spot, with a tab bar on top. Super+G makes
-- the window a tab group (again: back to separate windows), Super+Ctrl+Shift+arrows moves a
-- window into the group next to it, Super+Shift+G takes it out; clicking a tab or Alt+`
-- switches. The window menu has "Tabs" / "Take out" too.
hl.bind(mainMod .. " + G",         hl.dsp.group.toggle(), { description = "Windows: Make a tab group (again: separate the windows)" })
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.window.move({ out_of_group = true }), { description = "Windows: Take the window out of its tab group" })
hl.bind("ALT + grave",         hl.dsp.group.next(), { description = "Windows: Next tab" })
hl.bind("ALT + SHIFT + grave", hl.dsp.group.prev(), { description = "Windows: Previous tab" })
for direction, short in pairs({ left = "l", right = "r", up = "u", down = "d" }) do
    hl.bind(mainMod .. " + CTRL + SHIFT + " .. direction, hl.dsp.window.move({ into_group = short }), { description = "Windows: Move into the tab group next to it" })
end

-- Alt+Tab switcher: Tab steps through the windows, releasing Alt switches (Quickshell sees that).
hl.bind("ALT + Tab",         hl.dsp.exec_cmd("qs ipc call switcher next"), { description = "Windows: Switch windows" })
hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("qs ipc call switcher previous"), { description = "Windows: Switch windows, backwards" })

-- Overview, like Windows' Task View: every window on the workspace, and the workspaces strip.
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("qs ipc call overview toggle"), { description = "Windows: Overview" })

-- Focus with arrow keys
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.focus({ direction = "left" }), { description = "Windows: Move focus" })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.focus({ direction = "right" }), { description = "Windows: Move focus" })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.focus({ direction = "up" }), { description = "Windows: Move focus" })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.focus({ direction = "down" }), { description = "Windows: Move focus" })

-- Screenshots (quickshell's screenshot/Screenshot.qml): saved to ~/Pictures/Screenshots and copied.
-- Super+Shift+S picks a region, window or the screen; Print takes the whole screen. Without the
-- shell, grim + slurp still copy a region.
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd('qs ipc call screenshot region || grim -g "$(slurp)" - | wl-copy'), { description = "Capture: Screenshot (region, window or screen)" })
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("qs ipc call screenshot record"), { description = "Capture: Record the screen (again: stop)" })
hl.bind("Print",                   hl.dsp.exec_cmd("qs ipc call screenshot screen || grim - | wl-copy"), { description = "Capture: Screenshot of the screen" })

-- Workspaces 1-10 (Super+0 = 10)
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }), { description = "Workspaces: Go to workspace 1-10" })
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { description = "Workspaces: Move window to workspace 1-10" })
end

-- Scratchpad
hl.bind(mainMod .. " + grave",         hl.dsp.workspace.toggle_special("magic"), { description = "Workspaces: Show or hide the scratchpad (a terminal when empty)" })
-- Both ways (user's request): a window on the scratchpad comes back to the workspace under it,
-- any other window goes onto the scratchpad.
local function toggle_scratchpad_window()
    local window = hl.get_active_window()
    if not window then
        return
    end
    local target = "address:" .. window.address
    if window.workspace.name == "special:magic" then
        local ws = hl.get_active_workspace() -- the normal workspace, also while the scratchpad shows
        hl.dispatch(hl.dsp.window.move({ window = target, workspace = tostring(ws and ws.id or 1) }))
    else
        hl.dispatch(hl.dsp.window.move({ window = target, workspace = "special:magic" }))
    end
end
hl.bind(mainMod .. " + SHIFT + grave", toggle_scratchpad_window, { description = "Workspaces: Move window to or from the scratchpad" })

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Workspaces: Next or previous workspace" })
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { description = "Workspaces: Next or previous workspace" })

-- Magnifier, like Windows': zoom in around the pointer in steps, out again, and back to normal.
local function zoom(factor)
    return function()
        local now = hl.get_config("cursor.zoom_factor") or 1
        local next = factor and math.max(1, math.min(8, now * factor)) or 1
        hl.config({ cursor = { zoom_factor = next } })
    end
end
hl.bind(mainMod .. " + equal",  zoom(1.5),     { repeating = true, description = "Zoom: Zoom in (magnifier)" })
hl.bind(mainMod .. " + minus",  zoom(1 / 1.5), { repeating = true, description = "Zoom: Zoom out (magnifier)" })
hl.bind(mainMod .. " + Escape", zoom(nil),     { description = "Zoom: Zoom back to normal" })

-- Move/resize windows with mouse. Hyprland's own drag and resize only reach floating windows;
-- for tiled ones drag.lua follows the pointer while the button is held (it does nothing over a
-- floating window): left-drag swaps the window with the tiled one it's dropped on, right-drag
-- moves the borders nearest the pointer.
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "Windows: Move window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Windows: Resize window" })
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

-- Media keys (Fn + F8 / F9 / F10 on the Omen): the shell's player (services/Media.qml: the one
-- playing, else the one that played last), the same the island shows. playerctl alone took the
-- first player, KDE Connect's phone; it's the fallback while the shell is down.
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("qs ipc call media next || playerctl next"),           { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("qs ipc call media playPause || playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("qs ipc call media playPause || playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("qs ipc call media previous || playerctl previous"),   { locked = true })

-- Touchpad gestures: here with the keybinds, so they're held back too until the lock screen
-- is up after an automatic login (hyprland.lua).
-- 3-finger swipe to switch workspaces
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- 3-finger swipe up opens the overview (Quickshell's overview/Overview.qml), down closes it.
hl.gesture({
    fingers   = 3,
    direction = "up",
    action    = function() hl.exec_cmd("qs ipc call overview open") end,
})
hl.gesture({
    fingers   = 3,
    direction = "down",
    action    = function() hl.exec_cmd("qs ipc call overview close") end,
})
