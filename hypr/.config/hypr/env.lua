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

-- The wiki's NVIDIA page sets LIBVA_DRIVER_NAME=nvidia and __GLX_VENDOR_LIBRARY_NAME=nvidia.
-- Those are for setups where NVIDIA renders the desktop; here they would push iGPU apps onto
-- NVIDIA libraries. prime-run sets the right variables for each offloaded app instead.
