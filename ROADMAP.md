# Roadmap: Quickshell desktop shell + Hyprland

How the work is done, the standing decisions and what's open. What was built and why, phase by
phase, is in [docs/history.md](docs/history.md); where each feature lives is in
[docs/index.md](docs/index.md); API facts and testing tips are in `NOTES.md`.

## The task

Build a full desktop shell in Quickshell on top of a modular Hyprland Lua config, themed from the
wallpaper with matugen. Work in phases; commit and push after each phase, then give the user a short
test checklist and wait for their results before starting the next one. Ask before building anything
ambiguous or with real trade-offs.

**Laptop:** HP Omen 16, CachyOS, zsh. Ryzen 7 7840HS (AMD 780M iGPU) + RTX 4070 Max-Q (nvidia-open,
`nvidia-prime`). Panel 1920x1080 @ 165 Hz. **Desktop:** CachyOS, an RTX driving two 24" 1080p
monitors, a small Ryzen iGPU beside it. Hyprland 0.57 (Lua config), Quickshell 0.3.2, Qt 6.12.
Quickshell owns the bar, notifications, launcher, OSD, lock screen and polkit prompts; there is no
other bar, notification daemon, launcher or login screen.

**API accuracy:** Quickshell and Hyprland's Lua API change between versions. Check every type,
property and function against quickshell.org/docs (v0.3.x) and wiki.hypr.land before using it, not
memory or old dotfiles. Facts already checked are in `NOTES.md` ("Verified API notes"). Say in the
phase summary what couldn't be verified.

**After each phase, report:** what was built; commands to run (zsh); a test checklist; anything
unverified. Add every new package to its module's `packages.txt` / `aur.txt`, and every setup step
to its module's `setup.sh`. Add a section for the phase to `docs/history.md`.

## Look and architecture

- **The island** (user's choice): one small shape under the webcam, floating below the top edge or
  attached to it, showing the time (the music's cover while it plays) and alerts. Notifications
  pop out of it; it morphs (Android-style) into its menus: a click opens "today", a right-click
  quick settings, whose pages slide in. Categorized pages, not one crowded panel. Aesthetic
  reference: saneAspect's Hyprland/Quickshell builds (clean, rounded, Material-ish, subtle
  animations). The bottom edge belongs to the dock.
- **Colors:** matugen from the wallpaper is the single source of truth for the shell and the apps
  (list in `matugen/.config/matugen/config.toml`). Dark by default; light or at sunset in Settings.
- **Icons:** Material Symbols Rounded, outline at weight 300 (user's choice: filled looked heavy
  next to the Colloid app icons). **UI font:** Inter. **Mono:** MesloLGS Nerd Font.
- **QML:** `shell.qml` entry, one folder per area, singletons for shared state, services and theme.
  No hardcoded colors or sizes in components: use `Colors` and `Theme`. Comment the non-obvious
  parts briefly; the user is learning Quickshell through this.
- **Visual settings are edited on the screen** (the Customize editors, Super+U); Settings keeps
  only what isn't seen.
- **Panels** are toggled from Hyprland binds through Quickshell IPC (`qs ipc call <target> <fn>`).
- **Layer rules:** every Quickshell surface sets `WlrLayershell.namespace: "qs-<name>"`; its rules
  go in `hypr/.config/hypr/rules.lua`.

## Still to check

Built but not yet tried for real (details in the history's sections of the same name):

- On the desktop: several screens (arranging by drag, a live wallpaper and the desktop editor on
  a second screen), the quick settings Display page's projection, the Wave:3's Voice chain after
  a replug, caps lock by a real key press on either keyboard, the night light's tint on NVIDIA, a
  recording on the RTX's screens.
- The network sign-in hint (needs a network with a login page), the hotspot and airplane mode.
- The lock screen's quiet side and the presets placed around the art.
- The 60 Hz refresh rate switching on battery; the quick settings output chooser unfolding.
- Out of memory closing the whole session (the alert at the next login).

## Not doing (user's call)

Hibernation, fingerprint login and dictation. Letting games take Super (Quickshell's
ShortcutInhibitor only covers the shell's own windows). Not possible on Wayland: a global app menu.

## Decisions made

How things are, and why. The story of each (what was tried first) is in `docs/history.md`.

### Hardware and boot

- **GPUs:** the display GPU (the firmware's `boot_vga`, where the screens are wired: the laptop's
  AMD chip, the desktop's RTX) comes first in `AQ_DRM_DEVICES`, the others after it, only those
  that exist (`ghost-hw drm-devices`; a udev link per PCI slot). The laptop's RTX stays in the list
  so outputs wired to it work, at a battery cost. Where NVIDIA drives the display, `env.lua` sets
  the wiki's NVIDIA variables; elsewhere `prime-run` sets them per app, and `shell.sh` gives the
  shell Mesa's EGL only.
- **No Plymouth, no login screen:** greetd logs in at boot and the shell locks at once, so the lock
  screen is the first thing drawn. The system module sets `plymouth.enable=0` and a quiet console.
- **Early KMS:** CachyOS's chwd removes the `kms` hook on NVIDIA laptops, so
  `system/etc/mkinitcpio.conf.d/20-early-amdgpu.conf` adds `amdgpu` where there is an AMD chip.

### Windows and keybinds

- **Tiling with our own Lua layout** (`hypr/layout.lua`, `tiling.lua`, `drag.lua`; tested by
  `lua tests/tiling_test.lua`): by window count until a spot is picked, then the chosen
  arrangement keeps its shape. Arrangements survive `hyprctl reload` in
  `$XDG_RUNTIME_DIR/hypr-tiling-<instance>`. Hyprland passes no drags to Lua layouts, so drags
  follow the pointer with `hl.timer` + `hl.get_cursor_pos`. Dialogs, CachyOS Hello, its pkexec
  terminals and picture-in-picture float; floating windows stay above tiled ones.
  `input.float_switch_override_focus = 0`, or focus jumps to the window under the pointer.
- **Click to focus, raise on focus** (`input.follow_mouse = 2`; `windows.lua` raises on
  `window.active`).
- **Windows-style keybinds** (user's choice): the list is `hypr/binds.lua`, `docs/keybinds.md` and
  Settings -> Keybinds. App binds go through `qs ipc call apps ...` (the default apps from
  Settings) and fall back to Ghostty / Zen / Nautilus when the shell is down.
- **No title bars:** keybinds and a window menu on the window (`snap/WindowMenu.qml`).
- **Minimize** moves a window to `special:minimized`; restore from the overview, dock or Alt+Tab.
  `Windows.active` ignores minimized windows (Hyprland can still report one active). GTK's
  minimize button stays greyed out: Hyprland only advertises fullscreen and maximize.
- **Floating apps reopen where they were** (`hypr/positions.lua`), unless another window of the
  class is open or the spot is off-screen.
- **Apps can't steal focus** (`misc.focus_on_activate` false): urgent windows show an attention card
  from the island. `services/Windows.qml` tracks Hyprland's `urgent` events itself
  (`HyprlandToplevel.urgent` doesn't follow them).
- **Apps may maximize themselves** (no `suppress_event = "maximize"` rule).

### The island and panels

- **Island window:** fixed at its largest size (`Theme.island.maxHeight`; resizing a layer surface
  every frame stutters), input masked to the shape, `exclusiveZone` only the closed height. Menu
  widths per menu in `Theme.island.menuWidths`.
- **Island keyboard focus: `OnDemand` while a menu is open, `None` while closed.** Always `OnDemand`
  stole the keyboard on hover; `None`/`Exclusive` made Hyprland drop the focus grab.
- **Notifications pop out of the island**, one at a time on the focused screen, waiting while a
  menu is open, the screen is locked or a window is fullscreen. The service records arrival times
  (notifications carry none).
- **Media:** the playing player's cover replaces the clock. Player choice in `services/Media.qml`
  (`MediaPlayers.js`): playing, else last played, else the music app heard last; `playerctld` is
  never followed. Spotify announces no metadata for its first track, so `Media` reads it with
  `playerctl metadata`; its MPRIS position is frozen, so no seek from it.
- **Brightness OSD through IPC:** sysfs backlight sends no inotify events, so the binds call
  `qs ipc call brightness refresh`. `brightnessctl` always gets `-c backlight`.
- **The bottom edge belongs to the dock.** Settings and Wallpapers are pages of the launcher.

### Colors and look

- **QML color names use an `m3` prefix** (`Colors.m3onSurface`): `onSurface` next to `surface`
  reads as a change handler and silently gives `#000000`.
- **matugen's colors.json lives in `~/.local/state/quickshell/`**: files changing in the shell's
  config folder reload the whole shell.
- **Glass:** every panel is a `widgets/Surface.qml` at the glass setting with a faint edge; solid
  when off. Ghostty and Zed are see-through at a fixed 85 %.
- **Icons: Colloid** (user's choice), dark or light by the mode, through `wallpaper.sh` and
  `QS_ICON_THEME` (`hypr/shell.sh`).
- **Apps follow the wallpaper** through matugen templates and hooks (`matugen/.config/matugen/`):
  MangoHud (the whole config is the template: edit it, not GOverlay), Zed (a theme Zed watches),
  Steam (Millennium's Material-Theme, MIT, pinned; live), Zen (`chrome/matugen.css`, after a
  restart), Spotify (Ghost's `[matugen]` scheme, merged by a hook since Ghost's installer replaces
  `color.ini`), Discord (Vesktop theme, live). Each module's `setup.sh` installs its part.
- **Without a wallpaper** the colors come from seed `#6750a4`, matching `Colors.qml`'s fallbacks.
- **Calendar locale:** `Qt.locale(Qt.uiLanguage)`: English UI with Dutch formats gave Dutch day
  names next to English dates.

### System and tooling

- **Bluetooth pairing:** Quickshell can't register a BlueZ agent, so `yes | bt-agent -c
  NoInputNoOutput` runs (stdin answers; `--daemon` rejects confirmations). The adapter is pairable
  only while the Bluetooth page pairs.
- **Night light and idle live in Quickshell:** `NightLight.qml` holds the state (hyprsunset can't
  report on/off); `idle/Idle.qml` has one `IdleMonitor` per step, so times change live. hypridle
  only locks before suspend. D-Bus inhibitors don't hold the idle steps, Wayland ones do.
- **The shell restarts after a crash** (`hypr/shell.sh`); a normal exit or exit 143 ends it.
  Locking falls back to hyprlock when the shell is down.
- **Apps start in their own scopes** (`hypr/run-app.sh`), so systemd-oomd ends the app, not the
  session.
- **JavaScript runtime: bun** (user's choice). Node and pnpm only for Vencord's build.
- **Compositor: Hyprland, not Umbriel** (looked at 2026-11-07, github.com/noctalia-dev/umbriel,
  MIT, 0.1.0, no tagged releases, Arch only as `umbriel-git`). Its scope fixes the layouts at
  scrolling, dwindle, master and floating, with no scripting, so our Lua layout couldn't move;
  everything on `Quickshell.Hyprland` would need rewriting over its JSON socket. Look again once
  it has tagged releases; try it first as a second session from a TTY on the desktop.

## Open issues

- The RTX missing after a shutdown (docs/history.md, "The RTX missing after a shutdown"): a
  restart brings it back; `ghost-hp-8bca-rtx-off.service` is the fix being watched.
