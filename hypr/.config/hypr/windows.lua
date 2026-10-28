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
