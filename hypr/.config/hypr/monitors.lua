------------------
---- MONITORS ----
------------------

-- Check name + available modes with: hyprctl monitors
-- If "preferred" runs at 60 Hz, set the mode explicitly, e.g. mode = "2560x1600@240"
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
