# Roadmap: Quickshell desktop shell + Hyprland

Handover document for continuing this work. Phase 1 was built in a Windows session that couldn't
run anything; work now continues on the laptop, where changes can be run and tested directly.

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
not memory or old dotfiles. Facts already checked are listed under "Verified API notes" below. Say in
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
- **Icons:** Material Symbols (`Material Symbols Rounded`). **UI font:** Inter. **Mono:** MesloLGS Nerd Font.
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
  `bar/Bar.qml` + `Pill.qml` + `Workspaces.qml` + `Clock.qml` (center pill only).

**Added alongside Phase 1 at the user's request:**
- `install.sh`: packages, GPU rule check, early KMS, Plymouth off, greetd, GTK dark mode, stow for
  every package, a matugen run. Safe to re-run.
- Nautilus (now Super+E), Yazi in Ghostty (now Super+Shift+E), adw-gtk3 theme.
- greetd + tuigreet as the login screen (a stopgap until Phase 5).
- Ghostty window padding. Zen browser (`zen-browser-bin`) instead of Firefox.

### Phase 2: Island + control center + launcher + OSD (done, verified on the laptop 2026-10-28,
  except the media card: untested until Spotify is installed)
- Island (`bar/Island.qml`, `IslandShape.qml`): closed = workspaces, clock, `StatusIcons`; the
  clock sits in the exact middle (both sides get the same width). Workspace dots always show at
  least 5 (`WorkspaceSlots.js`, tested in `tests/tst_workspaces.qml`): click one to go there, even
  if it's empty; scroll over them to step through. Status icons: Wi-Fi as three arcs with the
  unlit ones dimmed (`widgets/WifiIcon.qml`), battery as an Android 16-style pill with the
  percentage inside (`bar/BatteryPill.qml`). Opens
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
  choice: its own strip, not a menu; the bottom edge is kept free for a dock) with one row of
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
- Idle (`hypr/hypridle.conf`, user's "balanced" choice): dim at 4 min, lock at 5, screen off at
  5.5, suspend at 15 only on battery (`condition_cmd` checks `ACAD/online`). Locks before every
  suspend (`inhibit_sleep = 3` waits for the lock).
- Greeter (`greeter.qml` entry + `greeter/Greeter.qml`, `Quickshell.Services.Greetd`): the lock
  screen's look plus the user's name; Enter logs in and launches `start-hyprland`. greetd runs it
  as the `greeter` user inside a small Hyprland (`system/etc/greetd/hypr/hyprland.lua`, which
  requires copies of `monitors/env/input.lua`), with `HOME=/var/lib/qs-greeter`. The greeter
  can't read the user's home, so `update-greeter.sh` (run by install.sh) copies the shell to
  `/etc/greetd/quickshell/` and snapshots colors, wallpaper and user name into its home. Re-run
  it after changing the wallpaper. When qs quits after launching, the greeter's Hyprland exits
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
  wtype holding a real Alt key. Caveat: a very quick Alt+Tab tap may release Alt before the
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

### Dock (built; waiting on the user's test results)
Added at the user's request (2026-10-28), between Phases 6 and 7.
- `dock/Dock.qml` + `DockBar.qml` + `DockItem.qml`: a macOS-style bar floating above the bottom
  edge (user's choice, after first trying the island shape turned over), whose icons magnify near
  the pointer (a bell curve over the icons' resting positions, so they don't wobble while the bar
  widens). Pinned apps then other running ones (`DockApps.js`, tested), a dot per
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

### Phase 7: Settings app
Added at the user's request (2026-10-28), after night light went manual-only: things that are
fixed in config files should become settings.
- A larger settings window (opened from a gear button in quick settings, and an IPC call),
  categorized like the island menus. Candidates: night light (manual or a schedule, times,
  temperature), idle timings (dim, lock, screen off, suspend; battery vs. plugged in), a Do Not
  Disturb schedule, the wallpaper (the picker), a readable list of keybinds, default apps
  (browser, terminal). The login screen's look and options too (the user wants more
  customization there later), which update-greeter.sh would carry over.
- Choices saved in one settings file outside the shell directory (like
  `~/.local/state/quickshell/*.json`), read by the services. Settings that live in other
  programs' configs (hypridle, hyprsunset) need those files generated from it, or the program
  restarted with new values: decide per setting, and check how each program reloads.
- Ask the user which settings matter most before building, and whether it's an island menu
  (wide, like the wallpaper picker) or a normal window.

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
- **Island keyboard focus is always `OnDemand`.** Switching it between `None` and `Exclusive` while
  the surface was mapped made Hyprland clear the `HyprlandFocusGrab` right after it started, so the
  menu closed immediately. (The launcher maps a new surface with `Exclusive`, which works.)
- **Keybinds: Windows-style** (user's choice, 2026-10-28): tap Super or Super+Space launcher,
  Super+Enter terminal, Super+E files, Super+B browser, Super+W / Alt+F4 close, Super+Up maximize,
  Super+Down minimize, Alt+Space window menu, Alt+Tab switcher, Super+Left/Right snap, Super+Z snap picker, Super+N quick settings, Super+C calendar, Super+Shift+S screenshot, Super+V clipboard, Super+L lock (Super+Shift+L hyprlock fallback),
  Ctrl+Alt+Delete power menu, Super+Ctrl+arrows focus. Super+Left/Right are kept free for snapping
  (Phase 6). Full list in `hypr/binds.lua`.
- **Window buttons:** Hyprland draws no title bars, so instead of hyprbars: keybinds plus a window
  menu in the island (`controlcenter/WindowPanel.qml`, Alt+Space or right-click the island's top
  row): minimize, maximize, float/tile, fullscreen, close, move to workspace 1-5, and the minimized
  windows to restore.
- **Minimize:** Hyprland has none. A minimized window moves to the hidden `special:minimized`
  workspace (Super+Down, or the window menu); restoring moves it to the current workspace and
  focuses it (`services/Windows.qml`). Hovering the workspace dots shows the minimized windows
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
- **Night light is manual** (user's choice, after first having a 20:00-07:00 schedule turned it on
  at every evening login): `hyprsunset.conf` has one all-day neutral profile, and only the tile
  turns it warm. hyprsunset can't report a manual override, so the tile state comes from its
  profile at startup (`on-switch = qs ipc call nightlight refresh`) and from the tile itself. The
  conf file shows how to add a schedule back.
- **Island window height** is 840 px (was 680) so the "today" menu with notifications fits.
- **Island menu widths:** menus are `Theme.island.panelWidth` (380) wide; the wallpaper picker
  spans the screen, so the island's window is as wide as the screen. Regular menus keep their
  width and stay centered while the island is wider.
- **Bottom edge reserved for a dock** (the user plans one): nothing else goes there.
- **Calendar locale:** `Qt.locale(Qt.uiLanguage)` (en_GB): the user has English UI with Dutch
  regional formats, and plain `Qt.locale()` gave Dutch day names next to English dates.
- **No wallpaper yet:** `install.sh` with no argument generates colors from seed `#6750a4`, the same
  scheme as the fallbacks in `Colors.qml`. `./install.sh "#rrggbb"` or `./install.sh <image>` overrides it.

## Open issues

None. Phase 1 verified on the laptop on 2026-10-27: RTX back on the PCI bus (cause unknown; it
returned on its own), tuigreet shows at boot, clock text is light, Nautilus follows the matugen accent,
live recolor works for the bar, borders and Ghostty, the bar's slide animation plays, and
`prime-run glxgears` shows up in `nvidia-smi`.

## Verified API notes

Checked against the docs or source in October 2026. Re-check anything not listed.

**Hyprland 0.56 (Lua)**
- `require("name")` is relative to `hyprland.lua`; a missing file aborts the calling file, so use
  `pcall(require, "name")` for optional files. The docs don't say whether required files are watched
  for changes; use `hyprctl reload`.
- Colors: `"rgba(rrggbbaa)"`, `"#rrggbb"`, `"rgb(...)"`; gradients are
  `{ colors = { ... }, angle = 45 }`.
- `hl.layer_rule({ name, match = { namespace = "<regex>" }, blur, blur_popups, ignore_alpha (0–1),
  dim_around, xray, animation, no_anim, order, above_lock, no_screen_share })`.
- `hl.exec_cmd` runs immediately (use inside `hl.on("hyprland.start", ...)`). `hl.dsp.exec_cmd` returns
  an action for `hl.bind`. Events: `hyprland.start`, `hyprland.shutdown`, `config.reloaded`.
- Window rules: `hl.window_rule({ name, match = { class = ".*" }, float = true, center = true })`;
  `float`/`center` are static effects (applied when the window opens).
- Bind flags (third argument): `locked`, `release`, `repeating`, `mouse`, `long_press`,
  `non_consuming`, `description`, ...
- `hl.env` runs before the compositor starts; `AQ_DRM_DEVICES` is a colon-separated list with the
  primary GPU first. `/dev/dri/by-path` can't be used in it because those paths contain colons.

**Quickshell 0.3.2**
- Imports: `import qs.<folder>` relative to `shell.qml`; no `qmldir` needed. Singletons:
  `pragma Singleton` with a `Singleton {}` root.
- `PanelWindow`: `anchors.*`, `margins.*`, `implicitWidth/Height`, `exclusionMode`
  (`ExclusionMode.Auto/Normal/Ignore`), `exclusiveZone`, `mask: Region`. Set `color: "transparent"`
  from the start. Anchoring only `top` centers the window (wlr-layer-shell spec).
  `WlrLayershell.namespace / .layer (WlrLayer.Background|Bottom|Top|Overlay) / .keyboardFocus
  (WlrKeyboardFocus.None|Exclusive|OnDemand)`.
- `Quickshell.Hyprland`: `Hyprland.workspaces / monitors / toplevels` are ObjectModels (`.values` in
  JS). `focusedWorkspace`, `focusedMonitor`, `monitorFor(screen)`, `refreshWorkspaces()`.
  `HyprlandWorkspace`: `id`, `name`, `active`, `focused`, `urgent`, `monitor`, `toplevels`,
  `activate()`. `Hyprland.dispatch(str)` sends the string as-is; with a Lua config it must be Lua,
  e.g. `hl.dsp.focus({ workspace = "3" })`. Prefer `activate()` where it exists.
- `SystemClock { precision: SystemClock.Minutes }`, then `Qt.formatDateTime(clock.date, ...)`.
- `FileView { path; watchChanges: true; onFileChanged: reload(); adapter: JsonAdapter { ... } }`.
  `Quickshell.env("HOME")`. `Quickshell.statePath()` points at a per-shell folder, not
  `~/.local/state`.
- `IpcHandler { target: "name"; function f(arg: string): void {} }`: arguments and returns must be
  typed (string, int, bool, real, color). Call with `qs ipc call name f`; list with `qs ipc show`.
- `Process { command: [...]; running }` (no shell; use `["sh", "-c", ...]`), `StdioCollector`,
  `Quickshell.execDetached([...])`.
- `Quickshell.Services.Greetd` exists: `createSession`, `respond`, `launch`, `cancelSession`; signals
  `authMessage`, `readyToLaunch`, `launched`, `authFailure`, `error`.
- Services load lazily: `UPower`, `Bluetooth`, `Networking`, `SystemTray`, `DesktopEntries` are empty
  until first accessed, then fill in asynchronously. Bindings are fine; a one-off read is not.
- `Quickshell.Services.Pipewire`: `Pipewire.defaultAudioSink/Source` (`PwNode`), `node.audio.volume`
  (0-1, writable), `.muted` (writable). Needs `PwObjectTracker { objects: [...] }` to fill `audio`.
- `Quickshell.Services.UPower`: `UPower.displayDevice` (`percentage` 0-1, `state`
  `UPowerDeviceState.Charging/...`, `isLaptopBattery`), `PowerProfiles.profile` (writable,
  `PowerProfile.PowerSaver/Balanced/Performance`, `PowerProfile.toString()`),
  `PowerProfiles.hasPerformanceProfile`.
- `Quickshell.Bluetooth`: `Bluetooth.defaultAdapter` (`enabled` writable, `devices`),
  `BluetoothDevice.connected`.
- `Quickshell.Networking`: `Networking.devices` (`NetworkDevice`: `type` `DeviceType.Wifi/Wired`,
  `connected`, `networks`), `WifiNetwork.signalStrength` (0-1), `Networking.wifiEnabled`.
- `Quickshell.Services.SystemTray`: `SystemTray.items` of `SystemTrayItem` (`icon`, `title`, `id`,
  `tooltipTitle`, `onlyMenu`, `hasMenu`, `menu`, `activate()`, `secondaryActivate()`).
  `QsMenuAnchor { menu; anchor.item; anchor.edges: Edges.Bottom; open() }`.
- `DesktopEntries.applications` of `DesktopEntry` (`name`, `genericName`, `comment`, `icon`,
  `keywords`, `noDisplay`, `runInTerminal`, `command` (string list), `execute()`). `execute()`
  ignores `runInTerminal`. `Quickshell.iconPath(name, fallback)`; `IconImage` in
  `Quickshell.Widgets` (`source`, `implicitSize`).
- `HyprlandFocusGrab { windows: [...]; active; onCleared }`. `mask: Region { Region { item } }`;
  an empty `Region {}` makes a surface click-through. A layer surface with no anchors is centered.
- `font.variableAxes: { "FILL": 1 }` fills Material Symbols (Qt 6.12).
- `Quickshell.Services.Mpris`: `Mpris.players` of `MprisPlayer` (`trackTitle`, `trackArtist`,
  `trackArtUrl`, `isPlaying`, `canTogglePlaying`, `canGoNext/Previous`, `togglePlaying()`, `next()`,
  `previous()`).
- Networking: `Networking.wifiEnabled` and `WifiDevice.scannerEnabled` are writable;
  `Network.connect()`, `disconnect()`, signal `connectionFailed(reason)` (`ConnectionFailReason`);
  `WifiNetwork.connectWithPsk(psk)`, `security` (`WifiSecurityType.Open/Owe/...`), `known`, `state`.
- Bluetooth: `BluetoothAdapter.discovering` writable; `BluetoothDevice` `connect()`, `disconnect()`,
  `pair()`, `paired`, `pairing`, `state` (`BluetoothDeviceState`), `battery`, `deviceName`, `icon`.
- Qt: `QtQuick.Shapes` (`Shape.CurveRenderer`, `PathArc.direction`), `MonthGrid` / `DayOfWeekRow`
  from `QtQuick.Controls.Basic` (MonthGrid needs an explicit height).
- `console.log` doesn't reach `qs log`; use `console.warn` when debugging.
- `Quickshell.Services.Notifications`: `NotificationServer { keepOnReload; actionsSupported;
  imageSupported; persistenceSupported; onNotification: n => n.tracked = true }`;
  `trackedNotifications`. `Notification`: `id`, `appName`, `appIcon`, `image`, `summary`, `body`,
  `urgency` (`NotificationUrgency.Low/Normal/Critical`), `actions` (`identifier`, `text`,
  `invoke()`), `transient`, `lastGeneration` (true for ones carried over a reload, which are
  announced again), `dismiss()`, `expire()`. No timestamp. App icons can be names, paths or URLs;
  show them with `IconImage` (a plain `Image` scales up a tiny icon).
- Lock: `WlSessionLock { locked; WlSessionLockSurface { ... } }` (one surface per screen;
  `Quickshell.Wayland`). `PamContext { config: "login"; start(); respond(text) }` with
  `responseRequired`, `completed(PamResult.Success/Failed/Error/MaxTries)`, `error(PamError)`.
  `MultiEffect` (`QtQuick.Effects`) blurs (`blurEnabled`, `blur`, `blurMax`). Use
  `Qt.locale(name).toString(date, format)`; `Qt.formatDate(date, locale, x)` treats `x` as a
  format type, not a string.
- hypridle 0.1.8: `general { lock_cmd; before_sleep_cmd; after_sleep_cmd; inhibit_sleep }`,
  `listener { timeout; on-timeout; on-resume; condition_cmd; condition_retry }`. Screen off is
  `hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'`.
- cliphist: `cliphist list` prints `<id>\t<preview>` newest first; images look like
  `[[ binary data 120 KiB png 1920x1080 ]]`. `cliphist decode <id>`, `cliphist delete` (the
  whole line on stdin), `cliphist wipe`. `wtype -M ctrl v -m ctrl` presses Ctrl+V.
- `Qt.labs.folderlistmodel` `FolderListModel { folder; nameFilters; showDirs }` (roles
  `filePath`, `fileName`) doesn't notice its folder being created later; reset `folder` to
  re-read. `FileView.writeAdapter()` saves a `JsonAdapter`; `printErrors: false` silences a
  missing file.
- hyprsunset 0.4: `hyprctl hyprsunset temperature <K>` / `identity` / `reset` / `profile` (prints
  the active profile's Time/Temperature/Gamma/Identity, not manual overrides). Profiles in
  `~/.config/hypr/hyprsunset.conf` with `time`, `temperature`, `identity`, `on-switch`.
- `HyprlandToplevel.address` has no `0x` (Hyprland's selector needs `address:0x<address>`).
  `Hyprland.activeToplevel` is null after the shell starts until focus changes; match
  `ToplevelManager.activeToplevel` (`Quickshell.Wayland`) against `HyprlandToplevel.wayland`.
  `DesktopEntries.heuristicLookup(appId)` finds a window's .desktop entry (icon).
- Lua dispatchers take a target window: `hl.dsp.window.move({ window = "address:0x...",
  workspace = "special:x", follow = false })`, also `close`, `float`, `fullscreen({ mode =
  "maximized" | "fullscreen", action = "toggle" })`, `move({ x, y, relative })`;
  `hl.dsp.focus({ window = ... })`. A special workspace that's never toggled stays hidden.
- Lua events: `hl.on("window.active", function(window, reason) ... end)`, also `window.urgent`,
  `window.close`, `window.open`, `window.update_state` (see the wiki's events.md). `input.follow_mouse`:
  0 cursor never focuses, 1 hover focuses, 2 click focuses (pointer separate), 3 click doesn't
  focus. `hl.dsp.window.alter_zorder({ window?, mode = "top" | "bottom" })`.
- Lua `HL.Window` (stubs in `/usr/share/hypr/stubs/hl.meta.lua`): `address` (with 0x, so
  `"address:" .. w.address` selects it), `class`, `at.x/.y`, `size.x/.y`, `floating`, `fullscreen`
  (0 = no), `workspace.name`, `focus_history_id`, `pinned`. `hl.get_windows()`, `hl.get_monitors()`
  (`x`, `y`, `width`, `height`, `scale`). Lua's `io` and `os` work in the config. A window is still
  readable in `window.close`.
- `Hyprland.rawEvent(event)` gives every socket2 event (`event.name`, `event.data`, e.g.
  `urgent` with the address without 0x). Don't annotate the parameter's type in QML
  (`HyprlandIpcEvent` isn't a registered name; Qt logs an error per event).
- wtype: Hyprland doesn't run its binds for wtype's virtual keyboard, so binds can't be tested
  with it. `wtype -M alt` only sets the modifier, without Alt key events; `-P Alt_L` / `-p Alt_L`
  send real ones.
- `ScreencopyView { captureSource: toplevel.wayland; live; constraintSize }` (`Quickshell.Wayland`)
  captures windows on other workspaces too.
- `float({ action })` takes `"toggle"` (default), `"enable"`/`"on"`, `"disable"`/`"off"`; an
  unknown value like `"set"` toggles. `fullscreen` uses `"set"`/`"unset"`. `resize({ window, x, y
  })` and `move({ window, x, y })` take logical pixels (a 940x1004 resize gives exactly that).
  Monitor `lastIpcObject.reserved` is `[left, top, right, bottom]` (after `refreshMonitors()`);
  `hyprctl getoption general:gaps_out -j` gives `{ "css": "20 20 20 20" }` (top right bottom left).
  `hyprctl clients -j` has `focusHistoryID` (0 = focused, then most recently used).
- `hl.dsp.cursor.move({ x, y })` moves the pointer: useful for testing hover behaviour.
- A singleton is only created when something uses it, so an `IpcHandler` inside one doesn't exist
  until then ("Target not found"); put handlers in always-loaded components.
- Scrolling: `WheelHandler` received no wheel events on the island's layer surface; a
  `MouseArea { acceptedButtons: Qt.NoButton; onWheel: ... }` under the content works and lets
  clicks through. Wheel events pass through MouseAreas that have no `onWheel`.
- Deprecated: `Quickshell.configDir` / `shellRoot` (use `shellDir`), and setting window
  `width/height` (use `implicit*`).

**matugen 4.2** (in Arch `extra`)
- Templates: `{{colors.<name>.default.hex}}` (also `hex_stripped`, `rgba`, ...), `{{mode}}`, loops
  `<* for name, value in colors *>`, filters like `| set_alpha: 0.5`. Relative `input_path` resolves
  against the config file; `output_path` can be a list.
- Hooks run through `sh -c`. A non-zero exit is only logged; the run continues.
- `matugen image <img> -m dark --source-color-index 0` (the index skips an interactive prompt),
  `matugen color hex "#rrggbb" -m dark`.

**Others**
- Ghostty: `theme = Matugen` loads `~/.config/ghostty/themes/Matugen`; `SIGUSR2` reloads the config.
  Ghostty runs as one process for all windows (`--gtk-single-instance=true`), so new windows only
  get config changes after that reload; `window-decoration = client` showed in new windows after it.
- GTK: libadwaita and adw-gtk3 read `@define-color accent_bg_color, window_bg_color, view_*,
  headerbar_*, sidebar_*, card_*, popover_*` from `~/.config/gtk-{3,4}.0/gtk.css`. Open apps need a
  restart.
- Yazi 26.9: sections `[mgr] [tabs] [mode] [indicator] [status] [input] [pick] [cmp] [tasks] ...`. A
  partial `theme.toml` is merged with the defaults; Yazi reads it at startup.
- tuigreet 0.11 (`greetd-tuigreet`): `--time --remember --asterisks --cmd <command>`.

## Testing on the laptop

- Quickshell reloads on file changes, but a reload after adding a property to a singleton
  (e.g. `Theme`) can leave parts blank; restart it then:
  `hyprctl dispatch 'hl.dsp.exec_cmd("pkill -x qs; sleep 0.5; qs")'`. `qs log` prints the running instance's log; panels can be
  opened with `qs ipc call ...` and checked with `grim -g "x,y wxh" out.png`. Run `pkill qs; qs` in a terminal to watch its log (also saved
  under `/run/user/1000/quickshell/`). `qs ipc show` lists IPC targets.
- `hyprctl reload` after editing a required Lua file; `hyprctl layers` shows layer namespaces;
  `hyprctl binds` shows loaded binds.
- Changes to `env.lua`, the initramfs, the kernel cmdline or greetd only apply after logging in again
  or rebooting. Say so in the checklist, and give a recovery path (Ctrl+Alt+F2, then
  `sudo systemctl disable greetd`) before changes that could stop the user getting to a desktop.
