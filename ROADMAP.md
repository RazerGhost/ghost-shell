# Roadmap: Quickshell desktop shell + Hyprland

The phase plan and the decisions behind the shell. API facts and testing tips are in `NOTES.md`.

## The task

Build a full desktop shell in Quickshell on top of a modular Hyprland Lua config, themed from the
wallpaper with matugen. Work in phases; commit and push after each phase, then give the user a short
test checklist and wait for their results before starting the next one. Ask before building anything
ambiguous or with real trade-offs.

**Laptop:** HP Omen 16, CachyOS, fish shell. Ryzen 7 7840HS (AMD 780M iGPU) + RTX 4070 Max-Q
(nvidia-open, `nvidia-prime`). Panel 1920x1080 @ 165 Hz. Hyprland 0.56 (Lua config), Quickshell 0.3.2,
Qt 6.12. Quickshell owns the bar, notifications, launcher, OSD and lock screen; there is no other bar,
notification daemon or launcher.

**API accuracy:** Quickshell and Hyprland's Lua API change between versions. Check every type,
property and function against quickshell.org/docs (v0.3.x) and wiki.hypr.land (0.56) before using it,
not memory or old dotfiles. Facts already checked are in `NOTES.md` ("Verified API notes"). Say in
the phase summary what couldn't be verified.

**After each phase, report:** what was built; commands to run (fish-compatible); a test checklist;
anything unverified. Update `packages.txt` / `aur.txt` for every new package, and `install.sh` for every
new setup step.

## Look and architecture

- **Bar = the island** (user's choice, replacing the floating pills): a small shape attached to the
  top edge, with concave curves into the screen edge, showing workspaces, the time (no date) and tiny
  status icons. Clicking the time or the status icons morphs it (Android-style) into a menu: "today"
  (date, calendar, media; notifications in Phase 3) or quick settings (tiles, sliders, battery, tray;
  Wi-Fi and Bluetooth tiles slide in their own page). Categorized pages, not one crowded panel.
  Aesthetic reference: saneAspect's Hyprland/Quickshell builds (clean, rounded, Material-ish, subtle
  animations).
- **Colors:** matugen from the wallpaper is the single source of truth for Quickshell, Hyprland borders,
  Ghostty, GTK and Yazi. Dark mode by default.
- **Icons:** Material Symbols (`Material Symbols Rounded`), outline at weight 300 (user's choice after comparing styles, 2026-10-28: filled made the few symbols with a solid variant look heavy; light sits closer to the Colloid app icons). **UI font:** Inter. **Mono:** MesloLGS Nerd Font.
- **QML:** `shell.qml` entry, one folder per area (`bar/`, `launcher/`, `notifications/`, `osd/`,
  `controlcenter/`, `services/`, `theme/`, `widgets/` for shared components). Singletons for shared
  state, services and theme. No hardcoded colors or sizes in components: use `Colors` and `Theme`. Comment the non-obvious parts
  briefly; the user is learning Quickshell through this.
- **Panels** are toggled from Hyprland binds through Quickshell IPC (`qs ipc call <target> <fn>`).
- **Layer rules:** every Quickshell surface sets `WlrLayershell.namespace: "qs-<name>"`; add blur and
  animation rules for them in `hypr/.config/hypr/rules.lua`.

## Phases

### Phase 1: Foundation (done, verified on the laptop)
- Hyprland split into `monitors`, `env`, `autostart`, `look`, `input`, `binds`, `rules`, plus the
  matugen-generated `colors.lua` (loaded last, through `pcall`).
- GPU offload: udev rule `system/etc/udev/rules.d/61-gpu-symlinks.rules` creates `/dev/dri/amd-igpu`
  and `/dev/dri/nvidia-dgpu`. `env.lua` sets `AQ_DRM_DEVICES=/dev/dri/amd-igpu:/dev/dri/nvidia-dgpu`;
  heavy apps use `prime-run`.
- matugen config and templates (`matugen/.config/matugen/`) for Quickshell (JSON), Hyprland
  (`colors.lua`), Ghostty, GTK3/4 (`gtk.css`) and Yazi (`theme.toml`).
- Quickshell: `theme/Theme.qml` (tokens), `theme/Colors.qml` (matugen JSON, live reload),
  and a first bar of floating pills, replaced by the island in Phase 2.

**Added alongside Phase 1 at the user's request:**
- `install.sh`: packages, GPU rule check, early KMS, Plymouth off, greetd, GTK dark mode, stow for
  every package, a matugen run. Safe to re-run.
- Nautilus (now Super+E), Yazi in Ghostty (now Super+Shift+E), adw-gtk3 theme.
- greetd + tuigreet as the login screen (a stopgap until Phase 5).
- Ghostty window padding. Zen browser (`zen-browser-bin`) instead of Firefox.

### Phase 2: Island + control center + launcher + OSD (done, verified on the laptop 2026-10-28,
  except the media card: untested until Spotify is installed)
- Island (`bar/Island.qml` for the state, `IslandWindow.qml` per monitor, `IslandShape.qml`): closed = workspaces, clock, `StatusIcons`; the
  clock sits in the exact middle (both sides get the same width). Workspace dots always show at
  least 5 (`WorkspaceSlots.js`, tested in `tests/tst_workspaces.qml`): click one to go there, even
  if it's empty; scroll over them to step through. Status icons: Wi-Fi as three arcs with the
  unlit ones dimmed to 45 % (`widgets/WifiIcon.qml`, also in the Wi-Fi tile and list), battery as an Android 16-style pill that fills with the charge, no text (user's choice: the
  percentage is in quick settings) (`bar/BatteryPill.qml`). Opens
  `controlcenter/TodayPanel.qml` (calendar, `MediaCard`) or `QuickSettings.qml` (tiles for Wi-Fi,
  Bluetooth, power mode, microphone; volume and brightness `LevelSlider`s; battery; `Tray`), with
  `WifiPage` (scan, connect, password prompt) and `BluetoothPage` (scan, pair, connect). Super+N /
  Super+C or `qs ipc call island toggle settings|today`.
- Services: `Audio`, `Brightness`, `NetworkStatus`, `BluetoothStatus`, `Battery`. Widgets:
  `MaterialIcon`, `IconButton`, `Switch`, `LevelSlider`, `TextButton`.
- Launcher (`launcher/`, tap Super or Super+Space): `Fuzzy.js` scoring, tested in `tests/tst_fuzzy.qml`. Terminal apps
  open in Ghostty.
- OSD (`osd/Osd.qml`) for volume, mute, mic mute and brightness, on the focused monitor.
- Windows open floating and centered (user's request). Since Phase 6 nothing tiles; see decisions.

### Phase 3: Notifications + rest of the control center + session menu (done, verified on the laptop
  2026-10-28)
- Quickshell is the notification server (`services/Notifications.qml`). New notifications pop up
  from the island (`NotificationCard`) on the focused monitor, one at a time, 5 s each (paused on
  hover; critical ones stay until dismissed), and stay in the history in the "today" menu until
  dismissed or "Clear all". The menu opens with the month calendar folded (user's choice); click
  the date to show it. Click a card for the app's default action; its other actions
  are buttons. Bodies are shown as plain text (no markup).
- Quick settings tiles: Do Not Disturb (no pop-ups except critical; history still collects) and
  night light (`services/NightLight.qml`, hyprsunset at 4000 K; manual only, see decisions).
- Power menu (`controlcenter/PowerPanel.qml`, power button in quick settings or Ctrl+Alt+Delete):
  lock, suspend, log out, restart, shut down; the last three need a second click within 4 s.
  Lock uses Quickshell's lock screen (Phase 5).

### Phase 4: Clipboard + wallpaper (done, verified on the laptop 2026-10-28)
- Clipboard menu in the island (`controlcenter/ClipboardPanel.qml`, Super+V): cliphist history
  with a search field, image thumbnails (decoded once into `$XDG_RUNTIME_DIR/qs-clipboard`),
  arrow keys / Enter, Delete or × to remove, Clear all. Picking an entry copies it and pastes it
  into the previous window with `wtype` (user's choice). Parsing in `ClipboardEntries.js`, tested.
- Wallpaper: Quickshell draws it on the background layer (`wallpaper/WallpaperLayer.qml`, fades
  in). The picker (`controlcenter/WallpaperPanel.qml`, wallpaper button in quick settings or
  `qs ipc call island toggle wallpaper`) stretches the island across the whole top edge (user's
  choice: its own strip, not a menu; the bottom edge is the dock's) with one row of
  pictures: `~/Pictures/Wallpapers` first (local folder only: the user prefers real photos or
  anime art and picks them themselves), then the built-in ones: Hyprland's `/usr/share/hypr/wall*.png` and
  the `cachyos-wallpapers` package (in packages.txt). Those stay in their packages, not in this
  repo: their licensing is unclear (no artist credits) and they're ~200 MB. The row scrolls
  sideways (user's choice: one horizontal row, own and built-in together).
  Thumbnails load the first time the picker opens. Choosing one runs matugen on it. The choice is saved in
  `~/.local/state/quickshell/wallpaper.json`; `qs ipc call wallpaper set <path>` and
  `./install.sh <image>` set it too. With none chosen, Hyprland's default wallpaper shows.

### Phase 5: Lock screen + idle + greeter (done, verified on the laptop 2026-10-28)
- Lock screen (`lock/Lock.qml`, `LockContent.qml`): Quickshell `WlSessionLock` on every monitor,
  blurred wallpaper, big clock and date, password field checked through PAM's `login` config.
  `qs ipc call lock lock` (Super+L, power menu, hypridle); `qs ipc call lock preview` shows it
  without locking, to check the look. Fallback: Super+Shift+L runs hyprlock with its sample config
  (`/usr/share/hypr/hyprlock.conf`).
- Idle (user's "balanced" choice, adjustable since Phase 7): dim at 4 min, lock at 5, screen off
  at 6, suspend at 15 only on battery. Locks before every suspend (`hypr/hypridle.conf`,
  `inhibit_sleep = 3` waits for the lock).
- Greeter (`greeter.qml` entry + `greeter/Greeter.qml`, `Quickshell.Services.Greetd`): the lock
  screen's look plus the user's name; Enter logs in and launches `start-hyprland`. greetd runs it
  as the `greeter` user inside a small Hyprland (`system/etc/greetd/hypr/hyprland.lua`, which
  requires copies of `monitors/env/input.lua`), with `HOME=/var/lib/qs-greeter`. The greeter
  can't read the user's home, so `update-greeter.sh` (run by install.sh) copies the shell to
  `/etc/greetd/quickshell/` and the user name into its home; settings, colors and the picture
  reach it through a shared folder (see "Lock and login screen settings"). When qs quits after launching, the greeter's Hyprland exits
  (`qs ...; hyprctl dispatch 'hl.dsp.exit()'`), so greetd starts the session. Verified at a real
  boot: login works.

**Lock screen recovery.** If the lock screen crashes, Hyprland keeps the session locked (red
screen). `misc.allow_session_lock_restore` (look.lua) lets another lock screen take over:
Ctrl+Alt+F2, log in, run
`hyprctl --instance 0 dispatch 'hl.dsp.exec_cmd("hyprlock -c /usr/share/hypr/hyprlock.conf")'`,
go back with Ctrl+Alt+F1 and unlock with your password.

**Login screen recovery.** If the Quickshell greeter doesn't come up (black screen, or it keeps
restarting): Ctrl+Alt+F2, log in, then switch greetd back to tuigreet and restart it:
`sudo sed -i 's/^command = "env/# command = "env/; s/^# command = "tuigreet/command = "tuigreet/' /etc/greetd/config.toml && sudo systemctl restart greetd`.

### Phase 6: Window switching + snap layouts (done, verified on the laptop 2026-10-28)
Added at the user's request after researching Windows/macOS features (2026-10-28). The phase number
isn't a priority: it can move ahead of Phases 3-5 if the user wants it sooner.
- **Alt+Tab switcher** (built, `switcher/Switcher.qml`): every window on every workspace (user's
  choice) with a live preview (`ScreencopyView`, only while open), most recently used first by
  Hyprland's `focusHistoryID`. Alt+Tab / Alt+Shift+Tab are Hyprland binds calling
  `qs ipc call switcher next|previous`; the switcher takes the keyboard and switches when it sees
  Alt released; Escape or a click elsewhere cancels; minimized windows are restored. Tested with
  wtype holding a real Alt key. The switcher takes the keyboard `OnDemand`, not `Exclusive`:
  while an exclusive surface exists Hyprland refuses to focus windows (`FocusState.cpp`), and
  closing the switcher raced the focus call, so only ~2 in 10 switches moved the focus (the
  window was raised but not focused); with `OnDemand` 30/30 did. Caveat: a very quick Alt+Tab tap may release Alt before the
  switcher has the keyboard; then it stays open until Alt is tapped again (or Escape).
- **Snapping** (built): Super+Left/Right snap the focused window to halves; Super+Z (Zed moved to
  Super+Shift+Z) shows a picker (`snap/SnapPicker.qml`, its own card at the top center of the
  window, not in the island: user's choice) with halves, quarters, thirds and two-thirds. The
  window floats and gets an exact rectangle (`services/SnapLayout.js`, tested): the monitor minus
  its reserved area (the island) and Hyprland's gaps, read with `hyprctl getoption`. The first
  snap saves the window's position and size (from `hyprctl clients -j`); Super+Down puts a
  snapped window back there, and minimizes any other window (Windows behaviour).
- **Snap Assist** (`snap/SnapAssist.qml`): after snapping to a half or a third, the space next to
  it shows the other windows on that workspace (live previews, most recent first); clicking one
  snaps it into that space (`SnapLayout.complement`, tested). Escape or a click elsewhere skips.
  Not for quarters or the center third.
- Later candidates from the same research, not planned yet: a macOS-style dock, an Exposé overview
  (3-finger swipe up / hot corner, reusing the switcher's thumbnails), an emoji picker, a snipping
  overlay. Not possible on Wayland: a global app menu. Hard: real minimize, Stage Manager.

### Dock (done, verified on the laptop 2026-10-28)
Added at the user's request (2026-10-28), between Phases 6 and 7.
- `dock/Dock.qml` + `DockBar.qml` + `DockItem.qml`: a macOS-style bar floating above the bottom
  edge (user's choice, after first trying the island shape turned over); no magnification (tried,
  the user found it excessive), icons lift a little on hover. Pinned apps then other running ones (`DockApps.js`, tested), a dot per
  open window (accent for the focused app) and the name on hover. Click opens the app or switches
  to it, again to cycle its windows, on the focused app's only window it minimizes (Windows
  taskbar). Right-click: new window, pin/unpin, close. Pins are desktop entry ids in
  `~/.local/state/quickshell/dock.json` (defaults: Zen, Ghostty, Nautilus, Zed, Spotify, Vesktop,
  Steam). App launching is shared with the launcher (`services/Apps.qml`).
- Shown on an empty desktop; slides down while a window on that monitor's workspace overlaps it
  or one is fullscreen (user's choice); touching the bottom edge brings it back. Hyprland sends
  no move/resize events, so window positions are re-read every second and on window events.
  While shown, the input mask is a fixed area where the dock ends up, down to the screen edge:
  masking to the sliding bar made the dock hide again right after revealing (the bar was still
  below the screen, so the pointer counted as having left).
- It reserves no space (`ExclusionMode.Ignore`); maximized windows cover it.

### Phase 7: Settings app (done, verified on the laptop 2026-10-28)
Added at the user's request, after night light went manual-only: things that were fixed in
config files became settings.
- A normal window (user's choice over a wide island menu; `settings/SettingsWindow.qml`, a
  Quickshell `FloatingWindow`) with categories in a sidebar. Opened with Super+I, the gear in
  quick settings or `qs ipc call settings open`.
- Saved in `~/.local/state/quickshell/settings.json` (`services/Settings.qml`; every change is
  written right away and applies live, nothing restarts). Pages (user's choice of settings):
  - **Night light:** on/off, warmth (2500-6000 K), and a daily schedule.
  - **Do Not Disturb:** on/off and a daily schedule. Both schedules (`services/Schedule.js`,
    tested) switch at the start and end times; switching by hand lasts until the next of those.
  - **Idle and power:** minutes before dim, lock, screen off and suspend, on battery and plugged
    in separately (`idle/Idle.qml`, see decisions).
  - **Default apps:** terminal, browser and file manager (installed apps of that .desktop
    category). The keybinds open the chosen ones; the browser and file manager also become the
    system defaults (`xdg-settings`, `xdg-mime`).
  - **Keybinds:** read from Hyprland (`hyprctl binds -j`, every bind in `binds.lua` has a
    description), grouped per description (`settings/Keybinds.js`, tested).

### Lock and login screen settings (done, verified on the laptop 2026-10-28)
The follow-up to Phase 7 (user's choice of options; the lock screen shares the look, user's
choice).
- A "Lock and login screen" page: the picture (same as the desktop, or one of the wallpaper
  pictures), blur, darkening, the time (and 12/24-hour), the date; for the login screen, the user
  name and power buttons (suspend, restart, shut down; `systemctl` as the greeter user, which
  logind allows for the active session). "Preview" shows the lock screen. All in `LockContent`.
- **How the login screen gets them without sudo:** `update-greeter.sh` creates
  `/var/lib/qs-greeter/shared/`, owned by the user and only read by the greeter, and symlinks
  `settings.json`, `colors.json` and `wallpaper.json` in the greeter's state folder to it, so the
  greeter's services read them like the desktop's. `greeter/sync.sh` copies the user's settings,
  colors and the lock screen's picture there; `lock/LoginScreenSync.qml` runs it at startup and
  whenever one of those files changes. The greeter's code stays root-owned in `/etc`, so the
  shared folder only holds data. `update-greeter.sh` is now only needed after code changes.
- The wallpaper list moved from the island's picker into `services/Wallpaper.qml`
  (`pictures`, `rescan()`), shared by the picker and this page.

## Decisions made

- **External monitors:** keep the RTX in `AQ_DRM_DEVICES` (second, after the iGPU), so outputs wired
  to it work, accepting the battery cost.
- **No global NVIDIA env vars:** the wiki's NVIDIA page sets `LIBVA_DRIVER_NAME=nvidia` and
  `__GLX_VENDOR_LIBRARY_NAME=nvidia`, but those are for setups where NVIDIA renders the desktop. Here
  `prime-run` sets them per app.
- **No Plymouth:** it leaves tty1 in graphics mode, so tuigreet was invisible (black screen at boot).
  `install.sh` appends `plymouth.enable=0` to `/etc/default/limine`. The Phase 5 greeter is the first
  themed screen instead.
- **Early KMS:** CachyOS's chwd removes the `kms` mkinitcpio hook on NVIDIA laptops, so
  `system/etc/mkinitcpio.conf.d/20-early-amdgpu.conf` adds `amdgpu` to MODULES.
- **Color names in QML use an `m3` prefix** (`Colors.m3onSurface`). QML treats `on` + capital letter
  as a change handler: next to a `surface` property, `onSurface` silently reads as `#000000`.
  Reproduced in Qt 6.12. Follow this for every new color.
- **matugen's Quickshell JSON lives outside the shell directory**
  (`~/.local/state/quickshell/colors.json`). Quickshell reloads the whole shell when files in its config
  directory change; `Colors.qml` watches the file instead.
- **Everything floats, Windows/macOS style** (user's choice, 2026-10-28): a `float = true, center
  = true` rule for every window in `rules.lua`, and no tiling keys (Super+T, P, J are gone).
  Hyprland always draws tiled windows below floating ones, so a focused tiled window could stay
  hidden. Snapping replaces tiling; the window menu's "Float/tile" became "Snap".
- **Click to focus and raise on focus** (Windows/macOS behaviour, user's choice after research):
  `input.follow_mouse = 2` (hover still scrolls, a click focuses) and `hypr/windows.lua` raises
  every newly focused window (`hl.on("window.active", ...)` + `alter_zorder({ mode = "top" })`);
  Hyprland only raises on click by itself. `windows.lua` holds the window behaviours.
- **Brightness OSD through IPC:** sysfs backlight files send no inotify events, so the brightness
  binds run `qs ipc call brightness refresh` after `brightnessctl`. Volume and mic need nothing:
  the OSD watches PipeWire.
- **Island window:** fixed at the open menu's maximum size (resizing a layer surface every frame
  would stutter); `mask: Region { item: island }` limits input to the shape and `exclusiveZone`
  reserves only the closed height. The shape is one `ShapePath` (no seams between body and curves).
- **Island keyboard focus: `OnDemand` while a menu is open, `None` while closed.** Always
  `OnDemand` stole the keyboard: Hyprland gives the keyboard to a layer surface that accepts it as
  soon as the pointer moves over it (`InputManager.cpp`, `rawSurfaceFocus`), and a click back into
  the window didn't take it back because Hyprland still counted that window as focused, so only
  Alt+Tab refocused. Switching between `None` and `Exclusive` instead made Hyprland clear the
  `HyprlandFocusGrab` right after it started (the menu closed at once); `None`/`OnDemand` keeps
  menus open. (The launcher maps a new surface with `Exclusive`, which works.)
- **Keybinds: Windows-style** (user's choice, 2026-10-28): tap Super or Super+Space launcher,
  Super+Enter terminal, Super+E files, Super+B browser, Super+W / Alt+F4 close, Super+Up maximize,
  Super+Down minimize, Alt+Space window menu, Alt+Tab switcher, Super+Left/Right snap, Super+Z snap picker, Super+N quick settings, Super+C calendar, Super+Shift+S screenshot, Super+V clipboard, Super+L lock (Super+Shift+L hyprlock fallback),
  Ctrl+Alt+Delete power menu, Super+Ctrl+arrows focus, Super+I settings. Full list in
  `hypr/binds.lua` and the settings window.
- **Window buttons:** Hyprland draws no title bars, so instead of hyprbars: keybinds plus a window
  menu in the island (`controlcenter/WindowPanel.qml`, Alt+Space or right-click the island's top
  row): minimize, maximize, snap, fullscreen, close, move to workspace 1-5, and the minimized
  windows to restore.
- **Minimize:** Hyprland has none. A minimized window moves to the hidden `special:minimized`
  workspace (Super+Down, the window menu, the dock); the next most recent window on that workspace
  gets the focus, and `Windows.active` ignores minimized windows (Hyprland can still report one as
  active, which made a second dock click minimize again instead of restoring). Restoring moves
  it to the current workspace and focuses it (`services/Windows.qml`). Hovering the workspace dots shows the minimized windows
  (`MinimizedList`, also in the window menu); no separate indicator, to keep the island
  consistent (user's choice).
- **Media in the island:** while music plays, a "live activity" (`bar/MediaActivity.qml`: cover +
  bouncing bars, an effect, not real levels) replaces the clock, so the island stays centered (no
  alternating: user's choice). Hovering it opens a small player (`MediaCard`, no keyboard focus,
  closes when the pointer leaves the island) and brings the time back in the middle. Clicking the
  activity or the small player opens the media menu (`controlcenter/MediaPanel.qml`: cover, track,
  seek bar, controls); clicking the middle opens whatever it shows. Player choice
  lives in `services/Media.qml`. Spotify (1.3.4) reports a frozen MPRIS position (equal to the
  track length) while playing, so its seek bar reads full; other players are untested.
- **Bluetooth pairing agent:** Quickshell can't register a BlueZ agent, and devices like the
  Keychron M6 ask the host to confirm pairing (journal: "No agent available for request type 2").
  `bt-agent` (`bluez-tools`, user-approved) runs from `autostart.lua` as
  `yes | bt-agent -c NoInputNoOutput`: without `--daemon` it reads answers from stdin, and in
  `--daemon` mode it rejects confirmations unless a PIN file matches. The Bluetooth page also sets
  the adapter `pairable` and the device `trusted` before `pair()`, and connects once paired.
- **Apps reopen where they were** (`hypr/windows.lua`): on `window.close` a floating window's
  position and size are saved per class in `~/.local/state/hypr/window-positions`; on
  `window.open` they're applied, unless another window of that class is open (dialogs, second
  windows) or the spot is off-screen. Fullscreen and minimized windows aren't saved.
- **Attention like a flashing taskbar button:** apps can't steal focus (`misc.focus_on_activate`
  stays false); Hyprland marks them urgent and the island shows an `AttentionCard` (icon, title,
  click to switch) for 5 s, after any notification pop-up. `services/Windows.qml` keeps its own
  list from Hyprland's `urgent` raw events, dropping a window once it's focused or closed:
  `HyprlandToplevel.urgent` didn't follow these events (false for a terminal bell). Opening a
  window also sends `urgent` just before focusing it, which the list ignores.
- **Notifications from the island** (user's choice over corner cards). Pop-ups wait while a menu
  is open. Notifications carry no timestamp, so the service records arrival times; after a shell
  restart (not a reload) the history is empty.
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
- **Apps may maximize themselves** (2026-10-28): the `suppress_event = "maximize"` rule from
  Hyprland's example config (Phase 1) is gone. With everything floating it made the maximize
  buttons in title bars (Ghostty, GTK apps, the settings window) do nothing. Apps that ask to
  start maximized now do.
- **Settings window title bar** (user's request: like the other apps): drawn by the window
  itself, GTK style: "Settings" over the sidebar, the page name, maximize and close (round
  buttons); drag to move, double-click to maximize. Maximizing goes through Hyprland, not
  `FloatingWindow.maximized` (see NOTES.md).
- **App keybinds go through the shell** (Phase 7): Super+Enter/B/E and Super+Shift+E call
  `qs ipc call apps ...`, which opens the default app chosen in settings. If the shell isn't
  running the call fails and the bind falls back to Ghostty / Zen / Nautilus, so there's always a
  terminal.
- **Island window height** is 840 px (was 680) so the "today" menu with notifications fits.
- **Island menu widths:** menus are `Theme.island.panelWidth` (380) wide; the wallpaper picker
  spans the screen, so the island's window is as wide as the screen. Regular menus keep their
  width and stay centered while the island is wider.
- **The bottom edge belongs to the dock:** nothing else goes there.
- **Icons: Colloid** (`Colloid-Dark`, `colloid-icon-theme-git` from the AUR; user's choice over
  WhiteSur and Tela Circle after previews in the dock, 2026-10-28): set for Quickshell with
  `QS_ICON_THEME` in `env.lua` and for GTK apps with gsettings in `install.sh`. It redraws
  nearly every app in one style; Adwaita has few app icons, so apps showed their own.
- **Calendar locale:** `Qt.locale(Qt.uiLanguage)` (en_GB): the user has English UI with Dutch
  regional formats, and plain `Qt.locale()` gave Dutch day names next to English dates.
- **No wallpaper yet:** `install.sh` with no argument generates colors from seed `#6750a4`, the same
  scheme as the fallbacks in `Colors.qml`. `./install.sh "#rrggbb"` or `./install.sh <image>` overrides it.

## Open issues

None.
