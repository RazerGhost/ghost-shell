-- Hyprland for the login screen. greetd runs it as the "greeter" user (config.toml); it shows
-- the Quickshell greeter and exits once you've logged in, so greetd can start your session.
-- monitors.lua, env.lua and input.lua next to this file are copies of yours (modules/core/greeter.sh),
-- so the GPU, screens and keyboard layout match your session.
require("monitors")
require("env")
require("input")
-- Your keyboard layout and touchpad settings from the shell's settings window, kept up to date by
-- greeter/sync.sh (a symlink into /var/lib/qs-greeter/shared, see modules/core/greeter.sh). Optional.
pcall(require, "shell-settings")

-- Your theme's background color (greeter/sync.sh writes it as rrggbb), so the screen starts on
-- the color the login screen and your desktop use instead of Hyprland's default. Data, not
-- code: anything but six hex digits is ignored.
local background = "rgb(000000)"
local file = io.open("/var/lib/qs-greeter/shared/background")
if file then
    local hex = (file:read("l") or ""):match("^%x%x%x%x%x%x$")
    file:close()
    if hex then
        background = "rgb(" .. hex .. ")"
    end
end

hl.config({
    misc = {
        disable_hyprland_logo   = true,
        force_default_wallpaper = 0,
        background_color        = background,
    },
    -- No update-news or donation pop-up on the login screen: hyprland-update-screen crashed
    -- (SIGSEGV) as the greeter user at every boot (coredumpctl, 2026-10-29).
    ecosystem = {
        no_update_news  = true,
        no_donation_nag = true,
    },
})

hl.on("hyprland.start", function()
    -- The greeter quits after starting your session; end this Hyprland with it.
    hl.exec_cmd("qs -p /etc/greetd/quickshell/greeter.qml; hyprctl dispatch 'hl.dsp.exit()'")
end)
