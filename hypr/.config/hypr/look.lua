-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 20,

        border_size = 2,

        -- Fallback until matugen has generated colors.lua, which overrides these
        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Drag a floating window's edge or corner to resize it (Super + right-drag works too).
        -- Tiled windows ignore it (Hyprland doesn't pass drags to Lua layouts): Super+Alt+arrows.
        resize_on_border = true,
        -- Games may tear for lower latency (only windows with the `immediate` rule, rules.lua).
        allow_tearing    = true,

        -- Our own tiling layout (layout.lua): halves, thirds and quarters, picked from the
        -- window menu or arranged by the number of windows.
        layout = "lua:shell",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        -- The workspace below the scratchpad (Super+`), dimmed while it's shown.
        dim_special = 0.3,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        -- Strong and a little darker, for the shell's glass panels and see-through Ghostty and Zed
        -- (like the Ghost Spotify theme's blurred background).
        blur = {
            enabled    = true,
            size       = 8,
            passes     = 3,
            vibrancy   = 0.3,
            brightness = 0.85,
        },
    },

    -- Window tabs (Hyprland groups, binds.lua): the tab bar as rounded tabs (the "gradients"),
    -- not thin lines, in the shell's font. Colors come from matugen (colors.lua).
    group = {
        -- Windows join a group only through the keys or the window menu, not by dragging.
        drag_into_group = 0,
        groupbar = {
            font_family          = "Inter",
            font_size            = 11,
            font_weight_active   = "semibold",
            font_weight_inactive = "normal",
            height               = 22,
            gradients            = true,
            indicator_height     = 0,
            rounding             = 8,
            gradient_rounding    = 8,
            round_only_edges          = false,
            gradient_round_only_edges = false,
            gaps_in  = 4,
            gaps_out = 4,
            blur     = true,
        },
    },

    animations = {
        enabled = true,
    },

    misc = {
        -- Variable refresh rate for fullscreen windows (games, video) on the 165 Hz panel: smooth
        -- without a fixed frame rate. Not for everything: VRR on the desktop can flicker.
        vrr = 2,
        force_default_wallpaper = -1,
        disable_hyprland_logo   = false,
        -- If the lock screen (Quickshell) crashes, the session stays locked; this lets a new
        -- lock screen take over (see "Lock screen recovery" in ROADMAP.md).
        allow_session_lock_restore = true,
    },
})

-- Curves
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, damping = 24.21279333 })

-- Animations. `speed` is how long each takes, in tenths of a second, at normal speed.
-- GhostAnimations(factor, styles) sets them all; shell-settings.lua calls it again with
-- Settings' animation speed (2 = twice as fast), so the windows keep pace with the shell, and
-- the chosen styles: `styles.windows` for windows opening and closing, `styles.workspaces` for
-- switching workspaces (settings/HyprlandConfig.js checks them).
local animations = {
    { leaf = "global",        speed = 10,   bezier = "default" },
    { leaf = "border",        speed = 5.39, bezier = "easeOutQuint" },
    { leaf = "windows",       speed = 4.79, spring = "easy" },
    { leaf = "windowsIn",     speed = 4.1,  spring = "easy",         style = "popin 87%" },
    { leaf = "windowsOut",    speed = 1.49, bezier = "linear",       style = "popin 87%" },
    { leaf = "fadeIn",        speed = 1.73, bezier = "almostLinear" },
    { leaf = "fadeOut",       speed = 1.46, bezier = "almostLinear" },
    { leaf = "fade",          speed = 3.03, bezier = "quick" },
    { leaf = "layers",        speed = 3.81, bezier = "easeOutQuint" },
    { leaf = "layersIn",      speed = 4,    bezier = "easeOutQuint", style = "fade" },
    { leaf = "layersOut",     speed = 1.5,  bezier = "linear",       style = "fade" },
    { leaf = "fadeLayersIn",  speed = 1.79, bezier = "almostLinear" },
    { leaf = "fadeLayersOut", speed = 1.39, bezier = "almostLinear" },
    { leaf = "workspaces",    speed = 1.94, bezier = "almostLinear", style = "fade" },
    { leaf = "workspacesIn",  speed = 1.21, bezier = "almostLinear", style = "fade" },
    { leaf = "workspacesOut", speed = 1.94, bezier = "almostLinear", style = "fade" },
    { leaf = "zoomFactor",    speed = 7,    bezier = "quick" },
}

-- Which leaves take which chosen style.
local styled = { windowsIn = "windows", windowsOut = "windows",
                 workspaces = "workspaces", workspacesIn = "workspaces", workspacesOut = "workspaces" }

function GhostAnimations(factor, styles)
    for _, a in ipairs(animations) do
        local style = a.style
        if styles and styled[a.leaf] and styles[styled[a.leaf]] then
            style = styles[styled[a.leaf]]
        end
        hl.animation({ leaf = a.leaf, enabled = true, speed = a.speed / factor,
                       bezier = a.bezier, spring = a.spring, style = style })
    end
end

GhostAnimations(1)
