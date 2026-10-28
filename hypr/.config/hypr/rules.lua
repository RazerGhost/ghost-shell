--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Every window floats, like on Windows and macOS: Hyprland draws tiled windows below all
-- floating ones, so a tiled window could never come to the front. Snapping (Super+Left/Right,
-- Super+Z) places windows side by side instead. New windows open centered.
hl.window_rule({
    name   = "float-by-default",
    match  = { class = ".*" },
    float  = true,
    center = true,
})

-- Ignore maximize requests from apps
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix XWayland dragging issues
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})


---------------------
---- LAYER RULES ----
---------------------

-- Quickshell panels are layer surfaces; each sets a namespace starting with "qs-"
-- (check with: hyprctl layers).

-- Island (the bar): blur behind it. ignore_alpha skips the fully transparent parts of its
-- surface (the window is as big as the open menu), so only the island itself gets blurred.
hl.layer_rule({
    name  = "qs-island",
    match = { namespace = "^qs-island$" },
    blur         = true,
    ignore_alpha = 0.3,
    animation    = "slide top",
})

-- Wallpaper: no open animation (it would slide in at login); Quickshell fades it itself.
hl.layer_rule({
    name  = "qs-wallpaper",
    match = { namespace = "^qs-wallpaper$" },
    no_anim = true,
})

-- Snap picker: blurred, pops in over the window it snaps.
hl.layer_rule({
    name  = "qs-snap",
    match = { namespace = "^qs-snap$" },
    blur         = true,
    ignore_alpha = 0.3,
    animation    = "popin 90%",
})

-- Snap Assist (the other windows, offered for the space next to a snapped one): blurred, fades in.
hl.layer_rule({
    name  = "qs-snap-assist",
    match = { namespace = "^qs-snap-assist$" },
    blur         = true,
    ignore_alpha = 0.3,
    animation    = "fade",
})

-- Alt+Tab switcher: blurred, pops in.
hl.layer_rule({
    name  = "qs-switcher",
    match = { namespace = "^qs-switcher$" },
    blur         = true,
    ignore_alpha = 0.3,
    animation    = "popin 90%",
})

-- Dock: blurred; no open animation, it slides itself.
hl.layer_rule({
    name  = "qs-dock",
    match = { namespace = "^qs-dock$" },
    blur         = true,
    ignore_alpha = 0.3,
    no_anim      = true,
})

-- Launcher: blurred, pops in from its center.
hl.layer_rule({
    name  = "qs-launcher",
    match = { namespace = "^qs-launcher$" },
    blur         = true,
    ignore_alpha = 0.3,
    animation    = "popin 90%",
})

-- OSD (volume / brightness popup): blurred, slides up from the bottom edge.
hl.layer_rule({
    name  = "qs-osd",
    match = { namespace = "^qs-osd$" },
    blur         = true,
    ignore_alpha = 0.3,
    animation    = "slide bottom",
})
