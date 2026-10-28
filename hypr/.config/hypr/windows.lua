-----------------------------
---- WINDOW BEHAVIOUR ----
-----------------------------
-- Windows / macOS-style window handling on top of Hyprland's defaults.

-- Whatever gets focus comes to the front: Hyprland raises a floating window when it's clicked,
-- but not when focus moves by a key, by closing another window or from the shell. Without a
-- window argument, alter_zorder acts on the active window, which is the one just focused.
hl.on("window.active", function()
    hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)

-- Terminals that run a command as root (CachyOS Hello installs packages through `ghostty -e
-- pkexec ...`) float in the middle at a terminal's size instead of tiling: they're short-lived
-- prompts. Their title only becomes "pkexec" after they open, too late for a window rule.
hl.on("window.title", function(window)
    if window.title ~= "pkexec" or window.floating then
        return
    end
    local target = "address:" .. window.address
    hl.dispatch(hl.dsp.window.float({ window = target, action = "enable" }))
    hl.dispatch(hl.dsp.window.resize({ window = target, x = 1000, y = 600 }))
    hl.dispatch(hl.dsp.window.center({ window = target }))
end)

-- Minimize buttons in apps (GTK title bars, Ghostty) and taskbar-style requests: Hyprland 0.57
-- tells Lua about them. Minimized windows go to the same hidden workspace the shell uses
-- (quickshell's services/Windows.qml), and come back to the workspace you're on.
hl.on("window.minimize", function(window, minimize)
    if not window then
        return
    end
    local target = "address:" .. window.address
    if minimize then
        hl.dispatch(hl.dsp.window.move({ window = target, workspace = "special:minimized", follow = false }))
    else
        local ws = hl.get_active_workspace()
        hl.dispatch(hl.dsp.window.move({ window = target, workspace = tostring(ws and ws.id or 1), follow = false }))
        hl.dispatch(hl.dsp.focus({ window = target }))
    end
end)
