-- Hyprland for the login screen. greetd runs it as the "greeter" user (config.toml); it shows
-- the Quickshell greeter and exits once you've logged in, so greetd can start your session.
-- monitors.lua, env.lua and input.lua next to this file are copies of yours (update-greeter.sh),
-- so the GPU, screens and keyboard layout match your session.
require("monitors")
require("env")
require("input")

hl.config({
    misc = {
        disable_hyprland_logo   = true,
        force_default_wallpaper = 0,
    },
})

hl.on("hyprland.start", function()
    -- The greeter quits after starting your session; end this Hyprland with it.
    hl.exec_cmd("qs -p /etc/greetd/quickshell/greeter.qml; hyprctl dispatch 'hl.dsp.exit()'")
end)
