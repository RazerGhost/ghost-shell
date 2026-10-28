---------------------
---- KEYBINDINGS ----
---------------------

local terminal    = "ghostty"
local editor      = "zeditor"
local fileManager = "nautilus"
local browser     = "zen-browser"

local mainMod = "SUPER"

-- Windows-style layout (user's choice). Super tapped on its own opens the launcher: a release
-- bind on the Super key itself.

-- Apps
hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd("qs ipc call launcher toggle"), { release = true })
hl.bind(mainMod .. " + space",   hl.dsp.exec_cmd("qs ipc call launcher toggle"))
hl.bind(mainMod .. " + Return",  hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E",       hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(terminal .. " -e yazi"))
hl.bind(mainMod .. " + B",       hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + Z",       hl.dsp.exec_cmd(editor))

-- Island menus
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call island toggle settings")) -- quick settings
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("qs ipc call island toggle today"))    -- calendar
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("qs ipc call island toggle clipboard")) -- clipboard history

-- Session
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("qs ipc call lock lock"))
-- Fallback lock screen with hyprlock's sample config, in case Quickshell's misbehaves.
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("hyprlock -c /usr/share/hypr/hyprlock.conf"))
-- Power menu in the island: lock, suspend, log out, restart, shut down.
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("qs ipc call island toggle power"))

-- Windows
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind("ALT + F4",        hl.dsp.window.close())
hl.bind(mainMod .. " + up",   hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
-- Minimize: Hyprland has none, so the window goes to a hidden special workspace. The island's
-- window menu lists it there to restore (same name as in quickshell's services/Windows.qml).
hl.bind(mainMod .. " + down", hl.dsp.window.move({ workspace = "special:minimized", follow = false }))
hl.bind(mainMod .. " + T",    hl.dsp.window.float({ action = "toggle" })) -- float <-> tile
-- Window menu in the island (like Windows' Alt+Space): minimize, maximize, move, restore.
hl.bind("ALT + space", hl.dsp.exec_cmd("qs ipc call island toggle window"))
hl.bind(mainMod .. " + F",    hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only

-- Focus with arrow keys (Super+Left/Right stay free for Phase 6's snapping)
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.focus({ direction = "down" }))

-- Screenshots (copied to clipboard)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy')) -- region
hl.bind("Print",                   hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy')) -- region
hl.bind("SHIFT + Print",           hl.dsp.exec_cmd("grim - | wl-copy"))              -- full screen

-- Workspaces 1-10 (Super+0 = 10)
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad
hl.bind(mainMod .. " + grave",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

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
