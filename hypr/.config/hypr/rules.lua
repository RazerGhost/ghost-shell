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
-- tiles over the dimmed workspace below (decoration.dim_special, look.lua). A handler, since
-- Hyprland 0.57 deprecated the on_created_empty workspace rule. Moving a window into a
-- scratchpad that doesn't exist yet also creates it empty, with the window arriving just after,
-- so the handler looks again a moment later and only starts a terminal if it's still empty.
local function scratchpad_empty()
    for _, workspace in ipairs(hl.get_workspaces()) do
        if workspace.name == "special:magic" then
            return workspace.windows == 0
        end
    end
    return false -- gone again (closed before the check)
end

hl.on("workspace.created", function(workspace)
    if workspace.name ~= "special:magic" then
        return
    end
    hl.timer(function()
        if scratchpad_empty() then
            hl.exec_cmd("ghostty")
        end
    end, { timeout = 150, type = "oneshot" })
end)

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

-- How each one opens: an animation, or none (`false`) for the ones that animate themselves.
local panels = {
    { "qs-island",           "slide top" },    -- the bar
    { "qs-wallpaper",        false },          -- Quickshell fades it in; sliding in at login looked off
    { "qs-snap",             "popin 90%" },    -- window menu (Alt+Space, Super+Z), over its window
    { "qs-snap-assist",      "fade" },         -- Snap Assist: the windows offered for an empty spot
    { "qs-switcher",         "popin 90%" },    -- Alt+Tab
    { "qs-dock",             false },          -- slides itself
    { "qs-launcher",         "popin 90%" },    -- from its center
    { "qs-osd",              "slide bottom" }, -- volume / brightness pop-up
    { "qs-polkit",           "fade" },         -- apps' password prompt
    { "qs-overview",         "fade" },         -- Super+Tab
    { "qs-wallpaper-picker", "slide top" },    -- the strip under the island
}

for _, panel in ipairs(panels) do
    local namespace, animation = panel[1], panel[2]
    local rule = { name = namespace, match = { namespace = "^" .. namespace .. "$" } }
    if animation then
        rule.animation = animation
    else
        rule.no_anim = true
    end
    hl.layer_rule(rule)
end
