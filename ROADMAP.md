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

Sections named in quotes ("Tiling with our own layout" and so on) are in `docs/history.md`.

### Hardware and boot

- **External monitors:** keep the RTX in `AQ_DRM_DEVICES` (second, after the iGPU), so outputs wired
  to it work, accepting the battery cost. Since 2026-11-04 `env.lua` lists only the devices that exist: the
  RTX sometimes misses a boot (again that day), and a desktop has one card or another kind.
  The display GPU draws (2026-11-05, like Omarchy): the one the firmware's `boot_vga` marks,
  where the screens are wired (the laptop's AMD chip, the desktop's RTX), first in
  `AQ_DRM_DEVICES`, the others after it (`ghost-hw drm-devices`; udev gives each GPU a link by
  its PCI slot). Before, "an AMD card exists" meant "the laptop": the desktop's Ryzen 7000 has a
  small iGPU (Radeon 610M), which then drew every frame and copied it to the RTX its screens are
  on. Where NVIDIA drives the display `env.lua` sets the wiki's NVIDIA variables (VA-API's only
  with libva-nvidia-driver installed), and `shell.sh` gives the shell Mesa's EGL only where it
  doesn't.
- **No global NVIDIA env vars:** the wiki's NVIDIA page sets `LIBVA_DRIVER_NAME=nvidia` and
  `__GLX_VENDOR_LIBRARY_NAME=nvidia`, but those are for setups where NVIDIA renders the desktop. Here
  `prime-run` sets them per app.
- **No Plymouth:** it left tty1 in graphics mode (the text greeter of the first days was
  invisible), and its HP logo theme, tried again on 2026-11-04, wasn't worth it (see "The HP logo
  through the boot"). The system module appends `plymouth.enable=0` and a quiet console to
  `/etc/default/limine`; the session, logged in and locked at once, is the first thing drawn.
  The HP logo goes blank when the graphics driver takes over.
- **Early KMS:** CachyOS's chwd removes the `kms` mkinitcpio hook on NVIDIA laptops, so
  `system/etc/mkinitcpio.conf.d/20-early-amdgpu.conf` adds `amdgpu` to MODULES.

### Windows and keybinds

- **Tiling with our own layout** (user's choice, 2026-10-28, replacing "everything floats"):
  snapping floating windows meant redoing what a tiling layout does (gaps, neighbours), and apps
  with a minimum size (Discord, 972 px against a 920 px half) only report their real size some
  time after a resize, with no event, so adjusting the neighbours was unreliable. Now every
  workspace tiles in a Lua layout (`hypr/layout.lua`, arrangements in `hypr/tiling.lua`, tested
  with `lua tests/tiling_test.lua`): by the number of windows (one full, two halves, three as one
  big and two stacked, more in a grid) until a spot is picked, then the chosen arrangement (halves,
  thirds, 1/3 + 2/3, quarters) keeps its shape: new windows fill empty spots or stack in the last
  column. The arrangements are kept in `$XDG_RUNTIME_DIR/hypr-tiling-<instance>` (2026-11-03):
  every config reload runs layout.lua again, and the shell reloads Hyprland for any of its
  settings, game mode and the windows editor, so chosen spots kept going back to automatic.
  After a reload Hyprland gives the layout a workspace's windows one at a time, so a saved
  arrangement waits until all its windows are back (or 3 s). The window menu's spots and
  "Arrange automatically", Super+Left/Right, Super+Alt+arrows
  (move the border), Super+Shift+arrows (swap with the neighbour). A tiled app with a minimum
  size is cut off at its box. Dialogs float by themselves; Super+Shift+Space or the window menu's
  Float/Tile floats any window, and floating windows stay above tiled ones (Hyprland can't
  change that). Super + right-drag on a tiled window moves the borders on the pointer's side
  (user's request): Hyprland doesn't pass drags to Lua layouts, so `drag.lua` follows the
  pointer with `hl.timer` + `hl.get_cursor_pos` while the button is held (`tiling.drag`, tested).
  Super + left-drag on a tiled window, or dragging it by an app's own title bar (Ghostty's), puts it in the place of the tiled window it's dropped on: Hyprland's drag floats it while it's carried and tiles it again, and the layout gives a window that comes back under the pointer the place of the window there (`tiling.drop`, tested; 2026-11-04, before that only Super + drag swapped, and only left to right worked). Super + Shift + left-drag (2026-11-04, user's request) takes a tiled window out: it floats at its size under the pointer (the timer again, `drag.start_pop`), and let go over a tiled window, a floating one goes back into the tiling where it was let go (the layout's drop); anywhere else it stays floating. Dragging the border itself (without Super) does nothing on tiled windows. `input.float_switch_override_focus = 0`, or focusing a tiled window under a
  floating one jumped back to the window under the pointer. Windows already open when this came
  in keep floating until tiled. Helpers float: CachyOS Hello (a window rule), its root terminals
  (`ghostty -e pkexec`, floated from `windows.lua` when the title becomes "pkexec": a rule only
  sees the title at open, "Ghostty"), and picture-in-picture videos (floating and pinned).
- **Click to focus and raise on focus** (Windows/macOS behaviour, user's choice after research):
  `input.follow_mouse = 2` (hover still scrolls, a click focuses) and `hypr/windows.lua` raises
  every newly focused window (`hl.on("window.active", ...)` + `alter_zorder({ mode = "top" })`);
  Hyprland only raises on click by itself.
- **Keybinds: Windows-style** (user's choice, 2026-10-28): tap Super or Super+Space launcher,
  Super+Enter terminal, Super+E files, Super+B browser, Super+W / Alt+F4 close, Super+Up maximize,
  Super+Down minimize, Alt+Space or Super+Z window menu (with snap layouts), Alt+Tab switcher,
  Super+Tab overview, Super+Left/Right snap, Super+Alt+arrows resize, Super+Shift+arrows swap,
  Super+Shift+Space float or tile, Super+A quick settings, Super+N notifications and calendar
  (Windows 11's keys since 2026-11-04; they were Super+N and Super+C), Super+X power menu,
  Ctrl+Shift+Esc the System page (task manager), Super+Shift+W wallpapers, Super+Shift+F focus
  mode, Super+Ctrl+Left/Right workspaces, Super+Up/Down on a snapped half its quarters,
  Super+Shift+S screenshot (Print: whole screen), Super+V clipboard, Super+. emoji, Super+U
  customize, Super+L lock
  (Super+Shift+L hyprlock fallback), Ctrl+Alt+Delete power menu, Super+Ctrl+arrows focus, Super+I
  settings, Super+Shift+Z editor. Full list in `hypr/binds.lua` and the settings window.
- **Window buttons:** Hyprland draws no title bars, so instead of hyprbars: keybinds plus a window
  menu on the window itself (`snap/WindowMenu.qml`, Alt+Space or Super+Z; user's choice
  2026-10-28, it used to be an island menu next to a separate snap picker): minimize, maximize,
  fullscreen, float or tile, close, move to workspace 1-5, and the snap layouts. Minimized windows are restored
  from the overview's list, the dock or Alt+Tab.
- **Minimize:** Hyprland has none (since 0.57 it tells Lua when an app or a taskbar-style tool
  asks: `windows.lua` sends those requests to the same hidden workspace. GTK's minimize button
  stays greyed out, tested: Hyprland 0.57 only advertises fullscreen and maximize to windows
  (`XDGShell.cpp` wm_capabilities), so the GTK title bars keep no minimize button). A minimized window moves to the hidden `special:minimized`
  workspace (Super+Down, the window menu, the dock); the next most recent window on that workspace
  gets the focus, and `Windows.active` ignores minimized windows (Hyprland can still report one as
  active, which made a second dock click minimize again instead of restoring). Restoring moves
  it to the current workspace and focuses it (`services/Windows.qml`). The overview lists the minimized windows in its
  bottom-left corner (`overview/MinimizedList.qml`; until 2026-11-03 under the island's workspace numbers on hover); no
  indicator in the island, to keep it consistent (user's choice).
- **Apps reopen where they were** (`hypr/positions.lua`): on `window.close` a floating window's
  position and size are saved per class in `~/.local/state/hypr/window-positions`; on
  `window.open` they're applied, unless another window of that class is open (dialogs, second
  windows) or the spot is off-screen. Fullscreen and minimized windows aren't saved.
- **Attention like a flashing taskbar button:** apps can't steal focus (`misc.focus_on_activate`
  stays false); Hyprland marks them urgent and the island shows an `AttentionCard` (icon, title,
  click to switch) for the notification time, after any notification pop-up. `services/Windows.qml` keeps its own
  list from Hyprland's `urgent` raw events, dropping a window once it's focused or closed:
  `HyprlandToplevel.urgent` didn't follow these events (false for a terminal bell). Opening a
  window also sends `urgent` just before focusing it, which the list ignores.
- **Apps may maximize themselves** (2026-10-28): the `suppress_event = "maximize"` rule from
  Hyprland's example config (Phase 1) is gone. With everything floating it made the maximize
  buttons in title bars (Ghostty, GTK apps, the settings window) do nothing. Apps that ask to
  start maximized now do.
- **App keybinds go through the shell** (Phase 7): Super+Enter/B/E and Super+Shift+E call
  `qs ipc call apps ...`, which opens the default app chosen in settings. If the shell isn't
  running the call fails and the bind falls back to Ghostty / Zen / Nautilus, so there's always a
  terminal.

### The island and panels

- **Brightness OSD through IPC:** sysfs backlight files send no inotify events, so the brightness
  binds run `qs ipc call brightness refresh` after `brightnessctl`. Volume and mic need nothing:
  the OSD watches PipeWire.
- **Island window:** fixed at the open menu's maximum size (resizing a layer surface every frame
  would stutter); `mask: Region { item: pill }` limits input to the shape and `exclusiveZone`
  reserves only the closed height. The shape is one `ShapePath` (no seams between body and curves).
- **Island keyboard focus: `OnDemand` while a menu is open, `None` while closed.** Always
  `OnDemand` stole the keyboard: Hyprland gives the keyboard to a layer surface that accepts it as
  soon as the pointer moves over it (`InputManager.cpp`, `rawSurfaceFocus`), and a click back into
  the window didn't take it back because Hyprland still counted that window as focused, so only
  Alt+Tab refocused. Switching between `None` and `Exclusive` instead made Hyprland clear the
  `HyprlandFocusGrab` right after it started (the menu closed at once); `None`/`OnDemand` keeps
  menus open. (The launcher maps a new surface with `Exclusive`, which works.)
- **Media in the island:** while music plays, a "live activity" (`bar/MediaActivity.qml`: the
  album cover; level bars next to it were dropped, user's choice) replaces the clock, so the island stays centered (no
  alternating: user's choice). Hovering it opens a small player (`MediaCard`, no keyboard focus,
  closes when the pointer leaves the island) and brings the time back in the middle. Clicking the
  activity or the small player opens the media menu (`controlcenter/MediaPanel.qml`: cover, track,
  seek bar, controls); clicking the middle opens whatever it shows. Player choice
  lives in `services/Media.qml` (`MediaPlayers.js`, tested): the one playing, else the one that
  played last, else the music app heard last (`lastMediaApp`), else the first; KDE Connect's phone
  players come first in MPRIS's list, so "the first" took a paused Spotify's place. The media
  keys (`qs ipc call media`) follow it. `playerctld` (a mirror of the active player, started on
  demand) is never followed. Spotify doesn't announce the first track after it starts (it's on the
  bus before the track loads), so that track showed without its title, artist or cover until the
  next (user's find, 2026-11-05; a fresh Quickshell read it fine): while the followed player plays
  without a title, `Media` reads the details itself with `playerctl metadata` (a few tries a second
  apart) and the views take them from `Media.title()`, `artist()`, `album()` and `artUrl`
  (`MediaPlayers.parseMetadata`, `detail`, tested). Spotify (1.3.4) reports a frozen MPRIS position (equal to the
  track length) while playing, so its seek bar reads full; other players are untested.
- **Notifications from the island** (user's choice; for a day, 2026-11-03, cards in the top-right
  corner instead): one at a time on the focused screen, each for Settings' time with a full time
  of its own (paused while the pointer is on the island; critical ones stay until dismissed),
  then a window asking for attention. They wait while a menu is open. A notification leaves the
  queue when it closes (dismissed, clicked, closed by its app): a destroyed one only turned into
  null in the list, which didn't notify, and left an empty card. Notifications carry no timestamp, so the service records arrival times; after a shell
  restart (not a reload) the history is empty.
- **Island window height** is 840 px (was 680) so the "today" menu with notifications fits.
- **Island menu widths** (user's choice, 2026-11-04: each menu its own, over one wider size):
  quick settings, clipboard and emoji 460, today, media and background apps 400, power 340
  (`Theme.island.menuWidth`); the hover player and the notification and attention pop-ups stay `panelWidth` (380).
  The island keeps a menu's width while it closes, so the fading menu doesn't reflow. Quick
  settings' round buttons fit six to a row at 460 when there are more than five. The island's
  window spans the screen's width; the wallpaper picker is its own surface.
- **The bottom edge belongs to the dock:** nothing else goes there.
- **Settings is a page of the launcher** (since 2026-10-31, see "Settings, Wallpapers and
  Customize grow out of the launcher"): its header has Back, the page's name, three sizes and
  close; the window with its own title bar is gone.

### Colors and look

- **Color names in QML use an `m3` prefix** (`Colors.m3onSurface`). QML treats `on` + capital letter
  as a change handler: next to a `surface` property, `onSurface` silently reads as `#000000`.
  Reproduced in Qt 6.12. Follow this for every new color.
- **matugen's Quickshell JSON lives outside the shell directory**
  (`~/.local/state/quickshell/colors.json`). Quickshell reloads the whole shell when files in its config
  directory change; `Colors.qml` watches the file instead.
- **Glass look** (user's request, 2026-10-28, like the Ghost Spotify theme: a strongly blurred
  background, translucent panels, a faint light edge). Every shell panel is a `widgets/Surface.qml`
  (the island draws the same with its shape's outline): `Colors.surfaceTranslucent` at the
  setting's opacity (45 % by default, 20-85; it was 35-85 while the blur came from layer rules
  with `ignore_alpha`, see "Native blur shapes") and a 1 px edge in the text color at 8 % (`Colors.glassEdge`). Settings ->
  Appearance -> Shell panels -> Glass turns it off (solid since 2026-11-04, no edge; it was 85 %
  opaque, and the Solid look still showed the wallpaper through). Hyprland's blur is stronger
  (size 8, 3 passes, more vibrancy, a little darker; look.lua). Ghostty (`background-opacity
  0.85`) and Zed (`background.appearance: blurred`, main backgrounds at 85 %) are see-through
  too; those are fixed, not following the setting. GTK/libadwaita apps can't be.
- **Icons: Colloid** (`Colloid-Dark`, `colloid-icon-theme-git` from the AUR; user's choice over
  WhiteSur and Tela Circle after previews in the dock, 2026-10-28): set for Quickshell with
  `QS_ICON_THEME` in `env.lua` and for GTK apps with gsettings in `install.sh`. It redraws
  nearly every app in one style; Adwaita has few app icons, so apps showed their own.
- **MangoHud follows the wallpaper** (user's request): matugen writes the whole
  `~/.config/MangoHud/MangoHud.conf` from `templates/mangohud.conf` (what it shows: fps, frame
  times, GPU and CPU load and temperature, RAM, VRAM, battery; a rounded card top left; fps and
  load colors change from primary to error). Changes go in the template: GOverlay writes the
  same file and would be overwritten. Games read it at start (Shift_L+F4 reloads). Verified with
  `mangohud vkcube`.
- **Zed, Steam and Zen follow the wallpaper** (user's request, 2026-10-28):
  - Zed: `templates/zed-theme.json` is a whole Zed theme ("Matugen", every key of Zed's One Dark;
    terminal colors as in Ghostty) in `~/.config/zed/themes/`, which Zed watches; Zed's settings
    are now in the repo (`zed/` package) and pick it. A Zed that was running when the themes
    folder was replaced by the link needs one restart.
  - Steam: Millennium's [Material-Theme](https://github.com/kuska1/Material-Theme) (MIT), whose
    Color option "Matugen" re-reads `css/main/colors/matugen.css` every 1.5 s, so Steam
    recolors live. matugen renders `templates/steam-material.css` (the theme's own template)
    to the state folder and `hooks/steam-material.sh` copies it into the theme. install.sh
    clones the theme into `~/.local/share/Steam/millennium/themes/` and, once Millennium has
    written `~/.config/millennium/config.json`, selects it with Color: Matugen.
  - Zen: `templates/zen-colors.css` sets Zen's own variables (its accent and dark base, from
    which Zen derives the rest, plus backgrounds, menus, URL bar, borders); `hooks/zen.sh`
    copies it into the profile from `installs.ini` as `chrome/matugen.css`, imports it from
    `userChrome.css` and turns on `toolkit.legacyUserProfileCustomizations.stylesheets` in
    `user.js`. Zen reads it at startup, so a new wallpaper shows after a Zen restart. Zen's
    workspace gradients no longer apply (the template's values are `!important`).
- **Spotify follows the wallpaper:** matugen renders `templates/spicetify-ghost.ini` (Ghost's
  `color.ini` keys) to `~/.local/state/matugen/spicetify-ghost.ini`, and `hooks/spicetify-ghost.sh`
  merges it into Ghost's `color.ini` as the `[matugen]` scheme, selects it and runs
  `spicetify refresh` (Spotify shows it after a restart). Its own file because Ghost's installer
  replaces `color.ini`; install.sh runs the hook again after installing Ghost. Ghost's accent still
  follows the album art unless its setting Colours -> Accent is "Theme" (then it's `primary`).
  Spotify runs on Wayland (`spotify/.config/spotify-flags.conf`, read by the AUR package's
  launcher). Not yet tested on the laptop.
- **Discord follows the wallpaper:** matugen writes `templates/vesktop-ghost.css` (`--matugen-*`
  variables) into Vesktop's themes folder as `ghost-matugen.css`; Vencord watches that folder, so
  Discord recolours live. The Ghost plugin (discord-ghost) uses it for Accent "From matugen" and
  "Colours from matugen". install.sh sets Vesktop's `nativeTitleBar` (no Discord window buttons;
  Hyprland draws none), enables the theme, and gives the plugin matugen and Hyprland's rounding as
  defaults on first run only. If Vesktop runs under XWayland, `~/.config/vesktop-flags.conf` with
  `--ozone-platform-hint=auto` (vesktop-bin's launcher reads it). Not yet tested on the laptop.
- **No wallpaper yet:** `install.sh` with no argument generates colors from seed `#6750a4`, the same
  scheme as the fallbacks in `Colors.qml`. `./install.sh "#rrggbb"` or `./install.sh <image>` overrides it.
- **Calendar locale:** `Qt.locale(Qt.uiLanguage)` (en_GB): the user has English UI with Dutch
  regional formats, and plain `Qt.locale()` gave Dutch day names next to English dates.

### System and tooling

- **Bluetooth pairing agent:** Quickshell can't register a BlueZ agent, and devices like the
  Keychron M6 ask the host to confirm pairing (journal: "No agent available for request type 2").
  `bt-agent` (`bluez-tools`, user-approved) runs from `autostart.lua` as
  `yes | bt-agent -c NoInputNoOutput`: without `--daemon` it reads answers from stdin, and in
  `--daemon` mode it rejects confirmations unless a PIN file matches. The Bluetooth page also sets
  the adapter `pairable` and the device `trusted` before `pair()`, and connects once paired.
- **Night light is manual by default** (user's choice, after a fixed 20:00-07:00 schedule turned
  it on at every evening login); a schedule is a setting since Phase 7. Quickshell runs it, not
  hyprsunset: `hyprsunset.conf` has one all-day neutral profile, and `services/NightLight.qml`
  keeps the on/off state (hyprsunset only reports the last temperature it was given, not whether
  it's on) and sets hyprsunset to match at startup.
- **Idle timing lives in Quickshell** (Phase 7): `idle/Idle.qml` uses one `IdleMonitor` per step,
  so the times change live and switch between battery and plugged in at once. hypridle couldn't
  do that without regenerating its config and restarting; it now only locks before suspend.
  Wayland idle inhibitors (a playing video in the browser) hold the steps off; D-Bus inhibitors
  (`systemd-inhibit`, which hypridle also honoured) don't.
- **The shell restarts after a crash** (`hypr/shell.sh`, started by `autostart.lua`): the lock
  screen, idle, notifications and password prompts live in it. A normal exit or `pkill -x qs`
  (exit 143) ends the loop; a crash (exit 255) restarts qs after a second. Locking falls back to
  hyprlock when the shell isn't running (Super+L, hypridle's `lock_cmd`), and the idle lock goes
  straight to the shell instead of through hypridle.
- **JavaScript runtime: bun** (user's choice, 2026-10-28): the setup's scripts (`json_edit`,
  `wallpaper.sh`, `ghost keybinds`, the Haunt lookup) and the discord-ghost build (`bun install`
  reads its package-lock.json; tested) run on bun. npm is gone. Node and pnpm stay only for
  Vencord, which pins pnpm (`packageManager`) and builds with `node`; Haunt also wants Node 22.18+.

## Open issues

- The RTX missing after a shutdown (docs/history.md, "The RTX missing after a shutdown"): a
  restart brings it back; `ghost-hp-8bca-rtx-off.service` is the fix being watched.
