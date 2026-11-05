-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Quickshell's icon theme: Colloid, the same as GTK apps (the core module's setup). Quickshell doesn't read
-- GTK's setting; without this it found only hicolor icons (no fallback app icon either).
hl.env("QS_ICON_THEME", "Colloid-Dark")

-- GPU: the first entry is the one Hyprland (and everything it launches) renders on: the display
-- GPU, the one the screens are wired to (the laptop's AMD chip with its own screen, the desktop's
-- RTX). The others follow, so screens wired to them (the laptop's HDMI and USB-C on the RTX, a
-- screen on the desktop board's own outputs) still work. ghost-hw decides (the firmware's
-- boot_vga, see bin/.local/bin/ghost-hw) and gives each GPU's stable link from
-- system/etc/udev/rules.d/61-gpu-symlinks.rules, only the ones there: a card missing from a boot
-- (the laptop's RTX, sometimes) is left out. With none (ghost-hw or the rule not installed yet)
-- Hyprland picks the card itself. Only read when Hyprland starts: log out and back in after a
-- change. On a hybrid laptop, run heavy apps on the RTX with: prime-run <app>
local ghost_hw = (os.getenv("HOME") or "") .. "/.local/bin/ghost-hw"

-- The command's output and whether it said yes (exit 0). The exit code comes back on the last
-- line: in Hyprland's Lua a pipe's close() can't report it (Hyprland reaps its children itself,
-- so close() gives nil, "No child processes"; NOTES).
local function ask(question)
    local pipe = io.popen("'" .. ghost_hw .. "' " .. question .. " 2>/dev/null; echo \"exit=$?\"")
    if not pipe then
        return "", false
    end
    local out = pipe:read("*a")
    pipe:close()
    local body, code = out:match("^(.-)%s*exit=(%d+)%s*$")
    return body or "", code == "0"
end

local devices = ask("drm-devices")
if devices ~= "" then
    hl.env("AQ_DRM_DEVICES", devices)
end

-- Where NVIDIA drives the display (the desktop's RTX 3070), apps should use its libraries, as the
-- Hyprland wiki's NVIDIA page sets. Not on a hybrid laptop (below), where the AMD chip draws and
-- prime-run picks NVIDIA per app. Video decoding through VA-API only with NVIDIA's VA-API driver
-- installed (libva-nvidia-driver, which the system module's hardware/nvidia.sh adds there), or
-- video would lose it.
local _, nvidia_display = ask("nvidia-display")
if nvidia_display then
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    local vaapi = io.open("/usr/lib/dri/nvidia_drv_video.so", "r")
    if vaapi then
        vaapi:close()
        hl.env("LIBVA_DRIVER_NAME", "nvidia")
        hl.env("NVD_BACKEND", "direct")
    end
end

-- On a hybrid laptop the wiki's NVIDIA variables (set above only where NVIDIA drives the display) would push
-- iGPU apps onto NVIDIA libraries; prime-run sets them for each offloaded app instead.
