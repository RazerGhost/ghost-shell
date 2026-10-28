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

-- Animations
hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })
