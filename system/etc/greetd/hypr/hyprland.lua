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

hl.config({
    misc = {
        disable_hyprland_logo   = true,
        force_default_wallpaper = 0,
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
