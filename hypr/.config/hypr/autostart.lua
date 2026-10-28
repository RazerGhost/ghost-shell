-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("hypridle")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("~/.config/hypr/shell.sh") -- Quickshell, restarted if it crashes
    -- Night light: Quickshell switches it (services/NightLight.qml); hyprsunset applies it.
    hl.exec_cmd("hyprsunset")
    -- Bluetooth pairing agent: answers BlueZ's "confirm this pairing" prompts, which Quickshell
    -- can't. bt-agent asks on stdin (its --daemon mode rejects every prompt instead), so `yes`
    -- answers for us. The laptop isn't discoverable, so only pairings started from the island's
    -- Bluetooth page reach it.
    hl.exec_cmd("yes | bt-agent -c NoInputNoOutput")
    -- USB sticks and SD cards: mounted when plugged in, with a notification; unmount and eject
    -- from its tray menu (quick settings' "Running in the background"). --appindicator puts it
    -- in the StatusNotifier tray the shell reads, not the old X11 one.
    hl.exec_cmd("udiskie --automount --notify --tray --appindicator")
    -- Your phone through KDE Connect (the phone module): its tray menu has the phone's
    -- battery, file sending and clipboard.
    hl.exec_cmd("kdeconnect-indicator")
end)
