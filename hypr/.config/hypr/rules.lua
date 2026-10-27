--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

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

-- Bar: blur behind the translucent pills. ignore_alpha skips the fully transparent
-- parts of the surface (rounded corners), so only the pills themselves get blurred.
hl.layer_rule({
    name  = "qs-bar",
    match = { namespace = "^qs-bar$" },
    blur         = true,
    ignore_alpha = 0.3,
    animation    = "slide top",
})
