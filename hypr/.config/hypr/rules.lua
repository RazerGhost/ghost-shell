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

-- The scratchpad (Super+`) doubles as a drop-down terminal: opened empty, it starts one. It
-- tiles over the dimmed workspace below (decoration.dim_special, look.lua).
hl.workspace_rule({
    workspace        = "special:magic",
    on_created_empty = "ghostty",
})

-- Games: Proton games (Steam names their windows steam_app_<id>) and gamescope may tear for
-- lower latency (general.allow_tearing in look.lua).
hl.window_rule({
    name      = "games-tear",
    match     = { class = "^(steam_app_.*|gamescope)$" },
    immediate = true,
})

-- Nothing fullscreen gets dimmed, locked or put to sleep for idling (games, videos): the shell's
-- idle steps respect this inhibitor.
hl.window_rule({
    name         = "fullscreen-stays-awake",
    match        = { class = ".*" },
    idle_inhibit = "fullscreen",
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
-- (check with: hyprctl layers). Their blur isn't set here: each panel asks Hyprland for blur
-- behind exactly its cards (BackgroundEffect.blurRegion, ext-background-effect; NOTES.md).

-- Island (the bar): slides in. It asks for blur behind its exact shape itself
-- (BackgroundEffect in bar/IslandWindow.qml), so no blur rule.
hl.layer_rule({
    name  = "qs-island",
    match = { namespace = "^qs-island$" },
    animation    = "slide top",
})

-- Wallpaper: no open animation (it would slide in at login); Quickshell fades it itself.
hl.layer_rule({
    name  = "qs-wallpaper",
    match = { namespace = "^qs-wallpaper$" },
    no_anim = true,
})

-- Window menu (Alt+Space, Super+Z): pops in over its window.
hl.layer_rule({
    name  = "qs-snap",
    match = { namespace = "^qs-snap$" },
    animation    = "popin 90%",
})

-- Snap Assist (the other windows, offered for the space next to a snapped one): fades in.
hl.layer_rule({
    name  = "qs-snap-assist",
    match = { namespace = "^qs-snap-assist$" },
    animation    = "fade",
})

-- Alt+Tab switcher: pops in.
hl.layer_rule({
    name  = "qs-switcher",
    match = { namespace = "^qs-switcher$" },
    animation    = "popin 90%",
})

-- Dock: no open animation, it slides itself. It asks for blur behind the bar and its cards
-- itself (BackgroundEffect in dock/DockBar.qml), so no blur rule.
hl.layer_rule({
    name  = "qs-dock",
    match = { namespace = "^qs-dock$" },
    no_anim      = true,
})

-- Launcher: pops in from its center.
hl.layer_rule({
    name  = "qs-launcher",
    match = { namespace = "^qs-launcher$" },
    animation    = "popin 90%",
})

-- OSD (volume / brightness popup): slides up from the bottom edge.
hl.layer_rule({
    name  = "qs-osd",
    match = { namespace = "^qs-osd$" },
    animation    = "slide bottom",
})

-- Password prompt for apps (polkit): fades in.
hl.layer_rule({
    name  = "qs-polkit",
    match = { namespace = "^qs-polkit$" },
    animation    = "fade",
})

-- Overview (Super+Tab): fades in.
hl.layer_rule({
    name  = "qs-overview",
    match = { namespace = "^qs-overview$" },
    animation    = "fade",
})

-- Wallpaper picker strip (quick settings' wallpaper button): slides down from the top.
hl.layer_rule({
    name  = "qs-wallpaper-picker",
    match = { namespace = "^qs-wallpaper-picker$" },
    animation    = "slide top",
})
