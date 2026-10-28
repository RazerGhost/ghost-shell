---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        -- Click to focus, like Windows and macOS: the window under the pointer still gets
        -- scrolling and hover, but only a click moves the keyboard focus.
        follow_mouse = 2,
        -- Focus goes where it's sent: by default, switching focus between a tiled and a floating
        -- window moves it to whichever window is under the pointer instead (the shell's
        -- switcher and snapping focused the wrong window).
        float_switch_override_focus = 0,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- 3-finger swipe to switch workspaces
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- 3-finger swipe up opens the overview (Quickshell's overview/Overview.qml), down closes it.
hl.gesture({
    fingers   = 3,
    direction = "up",
    action    = function() hl.exec_cmd("qs ipc call overview open") end,
})
hl.gesture({
    fingers   = 3,
    direction = "down",
    action    = function() hl.exec_cmd("qs ipc call overview close") end,
})
