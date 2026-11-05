-- Started with Hyprland on machines with the phone module (its setup links this file into
-- ~/.config/hypr/autostart.d/, which hypr/autostart.lua runs at Hyprland's start).
-- Your phone through KDE Connect: its tray menu (quick settings' background apps) has the phone's
-- battery, file sending and clipboard.
hl.exec_cmd("kdeconnect-indicator")
