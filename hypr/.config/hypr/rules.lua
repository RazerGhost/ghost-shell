--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Windows tile (layout.lua); Hyprland floats dialogs by itself, and the window menu or
-- Super+Shift+Space floats any other window. Floating windows stay above tiled ones.

-- Small helper apps float in the middle instead of tiling: CachyOS Hello (its install terminals
-- float from windows.lua, where their title is known).
hl.window_rule({
    name   = "float-helpers",
    match  = { class = "^org\\.cachyos\\.hello$" },
    float  = true,
    center = true,
})

-- The browser's picture-in-picture video floats and stays on every workspace (pinned).
hl.window_rule({
    name  = "float-picture-in-picture",
    match = { title = "^Picture-in-Picture$" },
    float = true,
    pin   = true,
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

-- Window menu (Alt+Space, Super+Z): blurred, pops in over its window.
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

-- Password prompt for apps (polkit): the card is blurred, not the dimmed screen around it
-- (the dimming is 40% opaque, under ignore_alpha), and it fades in.
hl.layer_rule({
    name  = "qs-polkit",
    match = { namespace = "^qs-polkit$" },
    blur         = true,
    ignore_alpha = 0.5,
    animation    = "fade",
})

-- Overview (Super+Tab): the dimmed desktop behind it is blurred too, and it fades in.
hl.layer_rule({
    name  = "qs-overview",
    match = { namespace = "^qs-overview$" },
    blur         = true,
    ignore_alpha = 0.3,
    animation    = "fade",
})

-- Wallpaper picker strip (quick settings' wallpaper button): blurred, slides down from the top.
hl.layer_rule({
    name  = "qs-wallpaper-picker",
    match = { namespace = "^qs-wallpaper-picker$" },
    blur         = true,
    ignore_alpha = 0.3,
    animation    = "slide top",
})
