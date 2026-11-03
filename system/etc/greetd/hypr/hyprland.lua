-- Hyprland for the login screen. greetd runs it as the "greeter" user (config.toml); it shows
-- the Quickshell greeter and exits once you've logged in, so greetd can start your session.
-- monitors.lua, env.lua and input.lua next to this file are copies of yours (modules/core/greeter.sh),
-- so the GPU, screens and keyboard layout match your session.
require("monitors")
require("env")
require("input")
-- Your keyboard layout, pointer, touchpad and screens from the shell's settings, as key=value
-- lines greeter/sync.sh keeps in the shared folder (settings/HyprlandConfig.js greeterData). That
-- folder is yours, so it's read as data and every value is checked here: nothing in it runs.
local shared = "/var/lib/qs-greeter/shared/"
local function lines_of(name)
    local file = io.open(shared .. name)
    if not file then
        return function() end
    end
    local text = file:read("a")
    file:close()
    return text:gmatch("[^\n]+")
end

local input, touchpad = {}, {}
for line in lines_of("greeter-settings") do
    local key, value = line:match("^([%w_]+)=(.*)$")
    if key == "kb_layout" and value:match("^[a-z0-9_]+[a-z0-9_,]*$") then
        input.kb_layout = value
    elseif key == "sensitivity" and tonumber(value) and math.abs(tonumber(value)) <= 1 then
        input.sensitivity = tonumber(value)
    elseif (key == "natural_scroll" or key == "tap_to_click") and (value == "true" or value == "false") then
        touchpad[key] = value == "true"
    elseif key == "cursor_theme" and value:match("^[%w ._-]+$") then
        hl.env("XCURSOR_THEME", value)
        hl.env("HYPRCURSOR_THEME", value)
    elseif key == "cursor_size" and value:match("^%d%d?$") then
        hl.env("XCURSOR_SIZE", value)
        hl.env("HYPRCURSOR_SIZE", value)
    elseif key == "monitor" then
        local output, mode, scale, transform, vrr = value:match("^([%w_.-]+) (%d+x%d+@[%d.]+) ([%d.]+) (%d) (%d)$")
        if output and tonumber(scale) and tonumber(scale) >= 0.5 and tonumber(scale) <= 3 then
            hl.monitor({ output = output, mode = mode, position = "auto", scale = tonumber(scale),
                         transform = tonumber(transform), vrr = tonumber(vrr) })
        end
    end
end
input.touchpad = touchpad
hl.config({ input = input })

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
