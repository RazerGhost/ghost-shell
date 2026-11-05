-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Quickshell's icon theme: Colloid, the same as GTK apps (the core module's setup). Quickshell doesn't read
-- GTK's setting; without this it found only hicolor icons (no fallback app icon either).
hl.env("QS_ICON_THEME", "Colloid-Dark")

-- GPU: the first entry is the one Hyprland (and everything it launches) renders on.
-- A laptop (the firmware's chassis type) renders on the AMD iGPU, which drives its own screen;
-- the RTX is listed second only so outputs wired to it (HDMI / USB-C) still work. Run heavy apps
-- on the RTX with: prime-run <app>. A desktop renders on the NVIDIA card, where its screens are;
-- a Ryzen's small iGPU (the desktop's Radeon 610M) stays second, for a screen on the board's own
-- outputs. (Until 2026-11-05 the AMD chip came first everywhere, and the desktop drew every
-- frame on its 610M and copied it to the RTX.)
--
-- /dev/dri/amd-igpu and /dev/dri/nvidia-dgpu are stable symlinks created by
-- system/etc/udev/rules.d/61-gpu-symlinks.rules in this repo. cardN numbers can change
-- between boots, and /dev/dri/by-path/ can't be used because this list is colon-separated.
-- Only read when Hyprland starts: log out and back in after changing it.
-- Only the ones that exist: the RTX sometimes misses a boot, and another machine (a desktop
-- with one card) has neither or one; with none listed Hyprland picks the card itself.
-- Opening fails with "No such file" (errno 2) only when it's missing: another error (no access
-- yet at the start of the session) still means it's there.
local function is_laptop()
    local file = io.open("/sys/class/dmi/id/chassis_type", "r")
    if not file then
        return false
    end
    local chassis = tonumber(file:read("*l"))
    file:close()
    -- SMBIOS: portable, laptop, notebook, sub notebook, convertible, detachable.
    return chassis == 8 or chassis == 9 or chassis == 10 or chassis == 14 or chassis == 31 or chassis == 32
end
local order = { "/dev/dri/amd-igpu", "/dev/dri/nvidia-dgpu" }
if not is_laptop() then
    order = { "/dev/dri/nvidia-dgpu", "/dev/dri/amd-igpu" }
end
local gpus = {}
for _, device in ipairs(order) do
    local file, _, code = io.open(device, "r")
    if file then
        file:close()
    end
    if file or code ~= 2 then
        table.insert(gpus, device)
    end
end
if #gpus > 0 then
    hl.env("AQ_DRM_DEVICES", table.concat(gpus, ":"))
end

-- Where NVIDIA draws (the desktop's RTX 3070), apps should use its libraries, as the Hyprland
-- wiki's NVIDIA page sets. Not on the laptop (below), where the AMD chip draws and prime-run
-- picks NVIDIA per app. Video decoding through VA-API only with NVIDIA's VA-API driver installed
-- (libva-nvidia-driver), or video would lose it.
if gpus[1] == "/dev/dri/nvidia-dgpu" then
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    local vaapi = io.open("/usr/lib/dri/nvidia_drv_video.so", "r")
    if vaapi then
        vaapi:close()
        hl.env("LIBVA_DRIVER_NAME", "nvidia")
        hl.env("NVD_BACKEND", "direct")
    end
end

-- On the laptop the wiki's NVIDIA variables (set above only where NVIDIA draws) would push
-- iGPU apps onto NVIDIA libraries; prime-run sets them for each offloaded app instead.
