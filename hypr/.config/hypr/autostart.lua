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
    -- What the modules on this machine start (KDE Connect's tray for the phone module): each
    -- module's setup links its modules/<name>/autostart.lua here (module_autostart in
    -- modules/lib.sh), so this file never names a program only one module installs.
    local folder = (os.getenv("HOME") or "") .. "/.config/hypr/autostart.d"
    local list = io.popen("ls -1 '" .. folder .. "'/*.lua 2>/dev/null")
    if list then
        for file in list:lines() do
            local ok, err = pcall(dofile, file)
            if not ok then
                print("autostart.lua: " .. file .. " failed (" .. tostring(err) .. ")")
            end
        end
        list:close()
    end
end)
