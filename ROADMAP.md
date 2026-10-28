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
  Ghostty, GTK, Yazi, Spotify (Ghost theme) and Discord (Ghost plugin). Dark mode by default.
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
  three parts are evenly spaced
  (user's choice, 2026-10-28: with the clock forced into the exact middle it sat 20 px from the
  dots but 55 px from the status icons, which looked off-center; now 24 px gaps and 26 px ends,
  the dots got smaller). Both sides of the island are as wide as
  the wider group, each group against the island's end with the same padding (user's choice
  2026-10-28: centered on its side, one workspace dot floated in empty space next to the wider
  status icons; spreading the narrower group to match looked odd with two dots), so the island is symmetric and the time or cover sits exactly in the screen's middle, under the webcam (user's
  request). Workspace dots for workspaces 1-5 and
  higher ones in use, the empty ones dimmed (user's choice 2026-10-28; only the used ones left one
  or two dots and the island looked lopsided); hovering them shows
  all workspaces 1-5 (and higher ones in use) as numbers to click (`WorkspaceNumbers.qml`), with
  the minimized windows below; scroll over the dots to step through. Status icons: Wi-Fi as three arcs with the
  unlit ones dimmed to 45 % (`widgets/WifiIcon.qml`, also in the Wi-Fi tile and list), battery as an Android 16-style pill that fills with the charge, no text (user's choice: the
  percentage is in quick settings) (`bar/BatteryPill.qml`). Opens
  `controlcenter/TodayPanel.qml` (calendar, `MediaCard`) or `QuickSettings.qml` (tiles for Wi-Fi,
  Bluetooth, power mode, microphone; volume and brightness `LevelSlider`s; battery; `Tray`, since 2026-10-28 its own row "Running in
  the background" with a chip per app, icon and name, user's choice over icons next to the battery), with
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
  are buttons. Bodies are shown as plain text (no markup). A progress bar shows when the app sends a progress value (the `value`
  hint, `notify-send -h int:value:64`; `NotificationProgress.js`, tested), updating as the app
  updates the notification.
- Quick settings tiles: Do Not Disturb (no pop-ups except critical; history still collects) and
  night light (`services/NightLight.qml`, hyprsunset; warmth and a schedule in Settings, see
  decisions). Both became round buttons under the wide tiles later (see the Quickshell additions).
- Power menu (`controlcenter/PowerPanel.qml`, power button in quick settings or Ctrl+Alt+Delete):
  lock, suspend, log out, restart, shut down; the last three need a second click within 4 s.
  Lock uses Quickshell's lock screen (Phase 5).

### Phase 4: Clipboard + wallpaper (done, verified on the laptop 2026-10-28)
- Clipboard menu in the island (`controlcenter/ClipboardPanel.qml`, Super+V): cliphist history
  with a search field, image thumbnails (decoded once into `$XDG_RUNTIME_DIR/qs-clipboard`),
  arrow keys / Enter, Delete or × to remove, Clear all. Picking an entry copies it and pastes it
  into the previous window with `wtype` (user's choice). Parsing in `ClipboardEntries.js`, tested.
- Wallpaper: Quickshell draws it on the background layer (`wallpaper/WallpaperLayer.qml`, fades
  in). The picker (`wallpaper/WallpaperPicker.qml` + `WallpaperPanel.qml`, wallpaper button in quick
  settings or `qs ipc call wallpaper picker`) is its own strip across the top under the island
  (user's choice: a strip, not a menu; it stretched the island itself until 2026-10-28; the
  bottom edge is the dock's) with one row of
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
  Super+Shift+Z) shows a picker, its own card at the top center of the window, not in the island
  (user's choice); since 2026-10-28 it's the window menu (`snap/WindowMenu.qml`, also Alt+Space)
  with halves, quarters, thirds and two-thirds below the window's actions. Since the move back
  to tiling (see "Tiling with our own layout"), a spot arranges the whole workspace around the
  window. Super+Down minimizes.
- **Snap Assist** (`snap/SnapAssist.qml`): when a snap leaves a spot empty (a lone window in a
  half, two windows in thirds), that spot shows the windows not tiled on the workspace: floating
  ones there, minimized ones and ones on other workspaces (live previews, most recent first;
  user's choice). Clicking one (or arrow keys and Enter) tiles it into the spot; the next empty
  spot asks again. Escape or a click elsewhere skips.
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
- Hidden until the pointer touches the bottom edge (user's choice since windows tile; it used
  to show on an empty desktop and hide while a window overlapped it). While shown, the input mask is a fixed area where the dock ends up, down to the screen edge:
  masking to the sliding bar made the dock hide again right after revealing (the bar was still
  below the screen, so the pointer counted as having left).
- It reserves no space (`ExclusionMode.Ignore`); maximized windows cover it.
- Resting 400 ms on an app with windows shows live previews of them above the dock (click one to
  switch; the pointer can move up onto them). A badge on an icon counts that app's notifications
  in the today menu's history (`DockApps.notificationCount`, tested; exact matches only). Apps'
  own unread counts (the Unity LauncherEntry D-Bus signal) aren't read: Quickshell has no API for
  it, and whether Vesktop sends one on Linux is unverified.

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
  - **Default apps:** terminal, browser, file manager, image viewer (Loupe), video and audio
    player (Celluloid for both, user's choice over Showtime + Decibels) (installed apps of the
    matching .desktop categories). The shell makes the system's defaults (xdg-mime,
    xdg-settings) match the settings at every start, the only place they're set, so re-running
    install.sh doesn't undo a choice. The keybinds open the chosen ones; the browser and file manager also become the
    system defaults (`xdg-settings`, `xdg-mime`).
  - **Keyboard and touchpad** (layout from XKB's list, natural scrolling, tap to click, pointer
    speed) and **Windows** (gaps, border, corners, apps reopening where they were): Hyprland
    options, written to the generated `hypr/shell-settings.lua` (gitignored, loaded last by
    hyprland.lua; `settings/HyprlandSettings.qml` + tested `HyprlandConfig.js`) and applied with
    `hyprctl reload` only when the content changes. The gaps apply to tiled windows. The login screen
    gets the file through the shared folder (keyboard layout).
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

### Quickshell additions (built 2026-10-28; waiting on the user's test results)
From a survey of every Quickshell 0.3.2 type and the quickshell-examples repo (user: "do all").
- Quick settings: a **Sound** tile and page (output device, microphone, per-app volume:
  `controlcenter/SoundPage.qml`) and **Keep awake** (`services/KeepAwake.qml`, an
  `IdleInhibitor` on the island windows). The menu got too long, so (user's choice) Wi-Fi,
  Bluetooth, Sound and Power mode stay wide tiles and microphone, Do Not Disturb, night light
  and keep awake are round buttons (`RoundToggle`, Android 16 style).
- Media menu: shuffle and repeat buttons; clicking the cover focuses the player's window.
- App shortcuts (.desktop actions) in the dock's right-click menu and in the launcher, ranked
  with the apps (`Fuzzy.results`, tested).
- The island reports shell reloads and their errors (replaces Quickshell's pop-up).
- Quick reply for notifications that offer it (`inline-reply`).
- `ScriptModel` for lists that change while shown; `PersistentProperties` keeps the open island
  menu and the settings window across reloads.
- **Quickshell is the polkit agent** (`polkit/PolkitPrompt.qml`): apps' password prompts are a
  card over the dimmed screen. `hyprpolkitagent` had failed at every login (started before
  Wayland was up), so there was no agent at all; it's no longer started (`autostart.lua`), but
  stays installed: if the shell is down, `systemctl --user start hyprpolkitagent` brings it back. Verified
  on the laptop: `pkexec true` with the password works.
- Skipped, with reasons: global shortcuts instead of `qs ipc` binds (a call takes ~27 ms, not
  noticeable, and the binds would lose their fallback when the shell is down); `LazyLoader`
  (nothing measurable to gain); hibernate, i3/X11, sockets (not relevant). Bluetooth device
  batteries were already in the Bluetooth page.

### Review and cleanup (done, verified on the laptop 2026-10-28)
A review of the whole repo (two agents, findings checked), worked through in four batches:
fragile parts (the shell restarts after a crash, lock falls back to hyprlock, default apps set
from Settings at startup, night light retries, battery time), shared implementations
(`Windows.show`/`forApp`, `Session`, `WindowPreview`, `AlbumArt`, `SearchField`, `MorphAnimation`,
`Theme.state`, `Colors.scrim`), the window menu as one card on the window, the wallpaper strip as
its own surface (with arrow keys), new settings (editor, keyboard and touchpad, windows), and
cleanup (package lists with comments, files in the right folders, the roadmap). Third-party code that
runs on the machine is pinned (2026-10-28, `clone_at` in `setup/lib.sh`): Vencord at a release
tag, Material-Theme at a commit; the user's own Ghost repos follow their main branch.

### Emoji picker (done, verified on the laptop 2026-10-28)
- An island menu (`controlcenter/EmojiPanel.qml`, Super+. like Windows): search field, a grid
  with the recently used emoji first (`~/.local/state/quickshell/emoji.json`), arrow keys and
  Enter or click. Terminals get the emoji typed (wtype); other apps get it pasted
  (Discord and other Electron apps ignore emoji typed through a virtual keyboard), and the
  clipboard gets its old content back; both marked sensitive, so cliphist skips them. The list comes from the `unicode-emoji` package's emoji-test.txt (user's choice
  over a copy in the repo), parsed and searched by `services/EmojiData.js` (tested); skin-tone
  variants are left out. The search field is shared with the clipboard menu (`SearchField`).

### Overview (done, verified on the laptop 2026-10-28)
- `overview/Overview.qml`, like Windows' Task View (user's choice): Super+Tab, a three-finger
  swipe up (down closes), or the hot corner: the pointer resting 150 ms in the top-left corner
  (`HotCorner.qml`, a 2x2 px surface; off while a window is fullscreen, e.g. games; Settings ->
  Windows). The current workspace's windows as live previews in a grid that keeps
  their shapes (`services/WindowGrid.js`, tested, shared with Snap Assist): click or arrow keys
  and Enter to switch, × to close. A strip of the
  workspaces in use as miniatures (windows at their positions): click to go, drag a window onto
  one to move it, + for a new workspace; or 1-9 / Shift+Left/Right to move the selected window
  (the overview stays open to sort more). Keyboard on demand (focus race, see the switcher).

### Update indicator (built 2026-10-28; waiting on the user's test results)
- `services/Updates.qml` counts waiting updates: `checkupdates` (repositories, from
  `pacman-contrib`; checks a copy of the database, no root) and `paru -Qua` (AUR), parsed by
  `Updates.js` (tested). Counted a minute after login, every hour, and a few seconds after
  `/var/log/pacman.log` changes (any install or update, whoever ran it; watched without reading
  it). A download icon in the island's status icons while there are some; quick settings shows
  "12 updates · 3 from the AUR" with an Update button that runs `paru` in the default terminal
  (user's choice over `cachy-update`). `qs ipc call updates check|summary`.

### System page (built 2026-10-28; waiting on the user's test results)
- Quick settings' monitor button opens a System page (user's pick from the Glyph rice's ideas):
  processor load and temperature, memory, each graphics card (load, temperature, video memory)
  and the disk, each with a bar that turns the error color above 90 %. `services/SystemStats.qml`
  runs `system-stats.sh` every 2 s only while the page is open, parsed by `SystemStats.js`
  (tested). Sensors are found by hwmon name (numbers change between boots). The RTX is only
  asked (`nvidia-smi`) while it's awake: asking would wake it, so a sleeping one shows "Asleep".

### Weather (built 2026-10-28; waiting on the user's test results)
- A row under the date in the today menu (user's pick from the Glyph rice's ideas): icon,
  temperature, sky, today's high and low, and the town (`controlcenter/WeatherRow.qml`,
  `services/Weather.qml`, parsing in `Weather.js`, tested). open-meteo: free, no account. The town
  is typed once in that row (click it to change; `weatherLocation` in settings.json) and looked
  up with open-meteo's own geocoding, rather than guessing the place from the IP address
  through another service. Refreshed every 30 minutes.

### Screenshot tool (built 2026-10-28; waiting on the user's test results)
- `screenshot/Screenshot.qml`, like Windows' Snipping Tool (user's choice): Super+Shift+S freezes
  the focused monitor (one `ScreencopyView` frame) and dims it, with a Region / Window / Screen
  bar under the island (R / W / S keys too, Escape cancels). Print takes the whole screen at once.
- Every screenshot is copied and saved to `~/Pictures/Screenshots` (user's choice: both), with a
  notification showing it; clicking it opens the picture. The picture is cut from the frozen
  frame, so it's exactly what was frozen (menus, tooltips). Without the shell, the binds fall back
  to grim + slurp.

### Setup: modules, `dots`, local overrides, docs (built 2026-10-28; waiting on the user's test results)
User's request: "change this dotfiles into something with a better setup" (chosen: a `dots`
command, modules with local overrides, docs; not CI checks).
- `modules/<name>/` (packages + `setup.sh`) replaced `packages.txt`, `aur.txt`, `setup/` and
  `update-greeter.sh` (now `modules/core/greeter.sh`). The Stow packages stayed where they are:
  moving them would break the running desktop's links for a moment.
- `dots` (`bin/.local/bin/dots`): install, update, theme, greeter, doctor, modules, keybinds.
  `install.sh` only bootstraps it. Each machine picks modules in `~/.config/dots/modules`.
- Gitignored overrides loaded last: `hypr/local.lua` (a broken one shows in Hyprland's error bar),
  Ghostty's `local` (`config-file = ?local`), fish's `conf.d/local.fish`.
- `README.md` (screenshots from an empty workspace, install, modules, overrides, layout) and
  `docs/keybinds.md` generated by `dots keybinds`.

### Settings reorganized (built 2026-10-28; waiting on the user's test results)
User's choice: a grouped sidebar with search. Personalize: Appearance (wallpaper, glass, window
border and corners), Display (night light; room for monitor settings), Lock screen. System:
Windows (gaps, hot corner, reopen floating apps), Notifications (Do Not Disturb), Power (idle and
sleep), Keyboard and mouse. Apps: Default apps, Keybinds, Weather and clock (the weather town, and
a 24-hour setting now shared by the island and the lock screen: `clock24Hour`, was `lock24Hour`).
The search field (focused when Settings opens) matches page titles and a list of words per page,
so it finds the page for any setting; Enter opens the first match. The sidebar scrolls.

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
- **Tiling with our own layout** (user's choice, 2026-10-28, replacing "everything floats"):
  snapping floating windows meant redoing what a tiling layout does (gaps, neighbours), and apps
  with a minimum size (Discord, 972 px against a 920 px half) only report their real size some
  time after a resize, with no event, so adjusting the neighbours was unreliable. Now every
  workspace tiles in a Lua layout (`hypr/layout.lua`, arrangements in `hypr/tiling.lua`, tested
  with `lua tests/tiling_test.lua`): by the number of windows (one full, two halves, three as one
  big and two stacked, more in a grid) until a spot is picked, then the chosen arrangement (halves,
  thirds, 1/3 + 2/3, quarters) keeps its shape: new windows fill empty spots or stack in the last
  column. The window menu's spots and "Arrange automatically", Super+Left/Right, Super+Alt+arrows
  (move the border), Super+Shift+arrows (swap with the neighbour). A tiled app with a minimum
  size is cut off at its box. Dialogs float by themselves; Super+Shift+Space or the window menu's
  Float/Tile floats any window, and floating windows stay above tiled ones (Hyprland can't
  change that). Super + right-drag on a tiled window moves the borders on the pointer's side
  (user's request): Hyprland doesn't pass drags to Lua layouts, so `drag.lua` follows the
  pointer with `hl.timer` + `hl.get_cursor_pos` while the button is held (`tiling.drag`, tested).
  Super + left-drag on a tiled window swaps it with the tiled window it's dropped on (`tiling.swap`, tested). Dragging the border itself (without Super) does nothing on tiled windows. `input.float_switch_override_focus = 0`, or focusing a tiled window under a
  floating one jumped back to the window under the pointer. Windows already open when this came
  in keep floating until tiled. Helpers float: CachyOS Hello (a window rule), its root terminals
  (`ghostty -e pkexec`, floated from `windows.lua` when the title becomes "pkexec": a rule only
  sees the title at open, "Ghostty"), and picture-in-picture videos (floating and pinned).
- **Click to focus and raise on focus** (Windows/macOS behaviour, user's choice after research):
  `input.follow_mouse = 2` (hover still scrolls, a click focuses) and `hypr/windows.lua` raises
  every newly focused window (`hl.on("window.active", ...)` + `alter_zorder({ mode = "top" })`);
  Hyprland only raises on click by itself.
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
  Super+Down minimize, Alt+Space or Super+Z window menu (with snap layouts), Alt+Tab switcher,
  Super+Tab overview, Super+Left/Right snap, Super+Alt+arrows resize, Super+Shift+arrows swap,
  Super+Shift+Space float or tile, Super+N quick settings, Super+C calendar,
  Super+Shift+S screenshot (Print: whole screen), Super+V clipboard, Super+. emoji, Super+L lock
  (Super+Shift+L hyprlock fallback), Ctrl+Alt+Delete power menu, Super+Ctrl+arrows focus, Super+I
  settings, Super+Shift+Z editor. Full list in `hypr/binds.lua` and the settings window.
- **Window buttons:** Hyprland draws no title bars, so instead of hyprbars: keybinds plus a window
  menu on the window itself (`snap/WindowMenu.qml`, Alt+Space or Super+Z; user's choice
  2026-10-28, it used to be an island menu next to a separate snap picker): minimize, maximize,
  fullscreen, float or tile, close, move to workspace 1-5, and the snap layouts. Minimized windows are restored
  from the workspace dots' hover.
- **Minimize:** Hyprland has none. A minimized window moves to the hidden `special:minimized`
  workspace (Super+Down, the window menu, the dock); the next most recent window on that workspace
  gets the focus, and `Windows.active` ignores minimized windows (Hyprland can still report one as
  active, which made a second dock click minimize again instead of restoring). Restoring moves
  it to the current workspace and focuses it (`services/Windows.qml`). Hovering the workspace dots shows the minimized windows
  under the workspace numbers (`MinimizedList`, also in the window menu); no separate indicator, to keep the island
  consistent (user's choice).
- **Media in the island:** while music plays, a "live activity" (`bar/MediaActivity.qml`: the
  album cover; level bars next to it were dropped, user's choice) replaces the clock, so the island stays centered (no
  alternating: user's choice). Hovering it opens a small player (`MediaCard`, no keyboard focus,
  closes when the pointer leaves the island) and brings the time back in the middle. Clicking the
  activity or the small player opens the media menu (`controlcenter/MediaPanel.qml`: cover, track,
  seek bar, controls); clicking the middle opens whatever it shows. Player choice
  lives in `services/Media.qml`. Spotify (1.3.4) reports a frozen MPRIS position (equal to the
  track length) while playing, so its seek bar reads full; other players are untested.
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
- **Bluetooth pairing agent:** Quickshell can't register a BlueZ agent, and devices like the
  Keychron M6 ask the host to confirm pairing (journal: "No agent available for request type 2").
  `bt-agent` (`bluez-tools`, user-approved) runs from `autostart.lua` as
  `yes | bt-agent -c NoInputNoOutput`: without `--daemon` it reads answers from stdin, and in
  `--daemon` mode it rejects confirmations unless a PIN file matches. The Bluetooth page also sets
  the adapter `pairable` and the device `trusted` before `pair()`, and connects once paired.
- **Apps reopen where they were** (`hypr/positions.lua`): on `window.close` a floating window's
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
- **The shell restarts after a crash** (`hypr/shell.sh`, started by `autostart.lua`): the lock
  screen, idle, notifications and password prompts live in it. A normal exit or `pkill -x qs`
  (exit 143) ends the loop; a crash (exit 255) restarts qs after a second. Locking falls back to
  hyprlock when the shell isn't running (Super+L, hypridle's `lock_cmd`), and the idle lock goes
  straight to the shell instead of through hypridle.
- **App keybinds go through the shell** (Phase 7): Super+Enter/B/E and Super+Shift+E call
  `qs ipc call apps ...`, which opens the default app chosen in settings. If the shell isn't
  running the call fails and the bind falls back to Ghostty / Zen / Nautilus, so there's always a
  terminal.
- **Glass look** (user's request, 2026-10-28, like the Ghost Spotify theme: a strongly blurred
  background, translucent panels, a faint light edge). Every shell panel is a `widgets/Surface.qml`
  (the island draws the same with its shape's outline): `Colors.surfaceTranslucent` at the
  setting's opacity (45 % by default, 35-85; below ~30 % the layer rules' `ignore_alpha` would
  stop the blur) and a 1 px edge in the text color at 8 % (`Colors.glassEdge`). Settings ->
  Windows -> Shell panels turns it off (85 % opaque, no edge). Hyprland's blur is stronger
  (size 8, 3 passes, more vibrancy, a little darker; look.lua). Ghostty (`background-opacity
  0.85`) and Zed (`background.appearance: blurred`, main backgrounds at 85 %) are see-through
  too; those are fixed, not following the setting. GTK/libadwaita apps can't be.
- **Island window height** is 840 px (was 680) so the "today" menu with notifications fits.
- **Island menu widths:** menus are `Theme.island.panelWidth` (380) wide, and the island's window
  is just that wide (plus its curves and offset); the wallpaper picker is its own surface.
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
