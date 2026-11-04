-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Quickshell's icon theme: Colloid, the same as GTK apps (the core module's setup). Quickshell doesn't read
-- GTK's setting; without this it found only hicolor icons (no fallback app icon either).
hl.env("QS_ICON_THEME", "Colloid-Dark")

-- GPU: Hyprland (and everything it launches) renders on the AMD iGPU; the first entry is primary.
-- The RTX is listed second only so outputs wired to it (HDMI / USB-C) still work.
-- Run heavy apps on the RTX with: prime-run <app>
--
-- /dev/dri/amd-igpu and /dev/dri/nvidia-dgpu are stable symlinks created by
-- system/etc/udev/rules.d/61-gpu-symlinks.rules in this repo. cardN numbers can change
-- between boots, and /dev/dri/by-path/ can't be used because this list is colon-separated.
-- Only read when Hyprland starts: log out and back in after changing it.
-- Only the ones that exist: the RTX sometimes misses a boot, and another machine (a desktop
-- with one card) has neither or one; with none listed Hyprland picks the card itself.
local gpus = {}
for _, device in ipairs({ "/dev/dri/amd-igpu", "/dev/dri/nvidia-dgpu" }) do
    local file = io.open(device, "r")
    if file then
        file:close()
        table.insert(gpus, device)
    end
end
if #gpus > 0 then
    hl.env("AQ_DRM_DEVICES", table.concat(gpus, ":"))
end

-- An NVIDIA-only machine (the desktop's RTX 3070): NVIDIA draws everything, so apps should use
-- its libraries, as the Hyprland wiki's NVIDIA page sets. Not on the laptop (below), where the
-- AMD chip draws and prime-run picks NVIDIA per app. Video decoding through VA-API only with
-- NVIDIA's VA-API driver installed (libva-nvidia-driver), or video would lose it.
if #gpus == 1 and gpus[1] == "/dev/dri/nvidia-dgpu" then
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    local vaapi = io.open("/usr/lib/dri/nvidia_drv_video.so", "r")
    if vaapi then
        vaapi:close()
        hl.env("LIBVA_DRIVER_NAME", "nvidia")
        hl.env("NVD_BACKEND", "direct")
    end
end

-- On the laptop the wiki's NVIDIA variables (set above only on an NVIDIA-only machine) would push
-- iGPU apps onto NVIDIA libraries; prime-run sets them for each offloaded app instead.
