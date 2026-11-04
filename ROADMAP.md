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

- **Bar = the island** (user's choice, replacing the floating pills): a small shape under the
  webcam, floating below the top edge or attached to it with concave curves, showing only the time
  (no date; the music's cover while it plays) and alerts (since 2026-11-03, see "One island,
  notifications in the corner"; it first held workspaces and status icons too). Notifications pop
  out of it. A click morphs it
  (Android-style) into "today" (date, calendar, notifications), a right-click into quick settings
  (status icons, tiles, sliders, battery, background apps; Wi-Fi and Bluetooth tiles slide in
  their own page). Categorized pages, not one crowded panel.
  Aesthetic reference: saneAspect's Hyprland/Quickshell builds (clean, rounded, Material-ish, subtle
  animations).
- **Colors:** matugen from the wallpaper is the single source of truth for Quickshell, Hyprland borders,
  Ghostty, GTK, Yazi, Spotify (Ghost theme) and Discord (Ghost plugin). Dark mode by default; light or at sunset in Settings.
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
The island as first built; since 2026-11-03 it shows only the time and alerts, see "One island,
notifications in the corner".
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
  Bluetooth, power mode, microphone; volume and brightness `LevelSlider`s; battery; `Tray`: since 2026-10-29 its own island menu, "Background apps", opened by an arrow at the
  island's outer right (user's choice) while there are some (verified 2026-10-29), a row per app (user's choice: the chips per app in
  quick settings, 2026-10-28, looked cluttered)), with
  `WifiPage` (scan, connect, password prompt; the connected network can be shared as a QR code a
  phone scans to join, `WifiQr.js` tested, and saved ones forgotten) and `BluetoothPage` (scan, pair, connect). Super+N /
  Super+C or `qs ipc call island toggle settings|today`.
- Services: `Audio`, `Brightness`, `NetworkStatus`, `BluetoothStatus`, `Battery`. Widgets:
  `MaterialIcon`, `IconButton`, `Switch`, `LevelSlider`, `TextButton`.
- Launcher (`launcher/`, tap Super or Super+Space): `Fuzzy.js` scoring, tested in `tests/tst_fuzzy.qml`. A
  calculator: sums and unit or currency conversions ("5 km in miles") answered by `qalc`
  (libqalculate) above the apps; Enter copies (`Calc.js`, tested). Terminal apps
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
  are buttons. Bodies are shown as plain text (no markup). In the today menu they're grouped by app (`NotificationGroups.js`, tested): a
  group shows its newest card, "+N more" the rest, and × clears the app's notifications. A progress bar shows when the app sends a progress value (the `value`
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
  pictures: `~/Pictures/Wallpapers` first (local folder only: the user prefers anime art and
  illustrations, not photos, and picks them themselves; corrected 2026-10-29; since 2026-10-30
  `ghost wallpapers get` can fetch art into it, see "More wallpapers"), then the built-in ones: Hyprland's `/usr/share/hypr/wall*.png` and
  the `cachyos-wallpapers` package (in packages.txt). Those stay in their packages, not in this
  repo: their licensing is unclear (no artist credits) and they're ~200 MB. The row scrolls
  sideways (user's choice: one horizontal row, own and built-in together).
  Thumbnails load the first time the picker opens. Choosing one runs matugen on it. The choice is saved in
  `~/.local/state/quickshell/wallpaper.json`; `qs ipc call wallpaper set <path>` and
  `./install.sh <image>` set it too. With none chosen, Hyprland's default wallpaper shows.

### Phase 5: Lock screen + idle + greeter (done, verified on the laptop 2026-10-28)
As first built; since 2026-11-04 there's no login screen and the lock screen is the desktop,
locked, see "The lock screen is your desktop, locked".
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

**Session recovery.** There's no login screen since 2026-11-04: greetd starts your session at
boot and after every logout. If it can't start (it would start again and again): Ctrl+Alt+F2, log
in, `sudo systemctl stop greetd`, fix it, then `sudo systemctl start greetd`.

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
    description, "Category: what it does"), by category (Apps, Menus, Session, Windows,
    Workspaces, Capture, Zoom; user's request 2026-10-28: the flat list was too spread out), each
    key a key cap, with a search (`settings/Keybinds.js`, tested; `ghost keybinds` loads the same
    file for docs/keybinds.md).

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

### Quickshell additions (done, verified on the laptop 2026-10-29)
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

### Update indicator (done, verified on the laptop 2026-10-29)
- `services/Updates.qml` counts waiting updates: `checkupdates` (repositories, from
  `pacman-contrib`; checks a copy of the database, no root) and `paru -Qua` (AUR), parsed by
  `Updates.js` (tested). Counted a minute after login, every hour, and a few seconds after
  `/var/log/pacman.log` changes (any install or update, whoever ran it; watched without reading
  it). A download icon in the status icons while there are some (quick settings' top row since
  2026-11-03); quick settings shows
  "12 updates · 3 from the AUR" with an Update button that runs `paru` in the default terminal
  (user's choice over `cachy-update`). `qs ipc call updates check|summary`.

### System page (done, verified on the laptop 2026-10-29)
- Quick settings' monitor button opens a System page (user's pick from the Glyph rice's ideas):
  processor load and temperature, memory, each graphics card (load, temperature, video memory)
  and the disk, each with a bar that turns the error color above 90 %. `services/SystemStats.qml`
  runs `system-stats.sh` every 2 s only while the page is open, parsed by `SystemStats.js`
  (tested). Sensors are found by hwmon name (numbers change between boots). The RTX is only
  asked (`nvidia-smi`) while it's awake: asking would wake it, so a sleeping one shows "Asleep".

### Weather (done, verified on the laptop 2026-10-29)
- A row under the date in the today menu (user's pick from the Glyph rice's ideas): icon,
  temperature, sky, today's high and low, and the town (`controlcenter/WeatherRow.qml`,
  `services/Weather.qml`, parsing in `Weather.js`, tested). open-meteo: free, no account. The town
  is typed once in that row (click it to change; `weatherLocation` in settings.json) and looked
  up with open-meteo's own geocoding, rather than guessing the place from the IP address
  through another service. Refreshed every 30 minutes.

### Screenshot tool (done, verified on the laptop 2026-10-29)
- `screenshot/Screenshot.qml`, like Windows' Snipping Tool (user's choice): Super+Shift+S freezes
  the focused monitor (one `ScreencopyView` frame) and dims it, with a Region / Window / Screen
  bar under the island (R / W / S keys too, Escape cancels). Print takes the whole screen at once.
- Capture tools (the capture module, user's picks from the research): the bar also picks what
  to do: Screenshot, Text (tesseract OCR, copied), QR code (zbarimg, copied; a link can be opened
  from the notification) or Record (`services/Recorder.qml`, gpu-screen-recorder with the desktop's
  sound into `~/Videos/Recordings`; a red dot and the time in the island, Stop in quick settings or
  Super+Shift+R again), and has the color picker (hyprpicker, copies #rrggbb). Keys P/T/Q/V and C.
  Mouse selection couldn't be simulated in tests; each tool was tested on its own.
- Every screenshot is copied and saved to `~/Pictures/Screenshots` (user's choice: both), with a
  notification showing it; clicking it opens the picture. The picture is cut from the frozen
  frame, so it's exactly what was frozen (menus, tooltips). Without the shell, the binds fall back
  to grim + slurp.

### Setup: modules, `ghost`, local overrides, docs (done, verified on the laptop 2026-10-29)
User's request: "change this dotfiles into something with a better setup" (chosen: a `ghost`
command, modules with local overrides, docs; not CI checks).
- `modules/<name>/` (packages + `setup.sh`) replaced `packages.txt`, `aur.txt`, `setup/` and
  `update-greeter.sh` (now `modules/core/greeter.sh`). The Stow packages stayed where they are:
  moving them would break the running desktop's links for a moment.
- `ghost` (`bin/.local/bin/ghost`): install, update, theme, greeter, doctor, modules, keybinds.
  `install.sh` only bootstraps it. Each machine picks modules in `~/.config/ghost/modules`.
- Gitignored overrides loaded last: `hypr/local.lua` (a broken one shows in Hyprland's error bar),
  Ghostty's `local` (`config-file = ?local`), fish's `conf.d/local.fish`.
- `README.md` (screenshots from an empty workspace, install, modules, overrides, layout) and
  `docs/keybinds.md` generated by `ghost keybinds`.

### Settings reorganized (done, verified on the laptop 2026-10-29)
User's choice: a grouped sidebar with search. Personalize: Appearance (wallpaper, glass, window
border and corners), Display (screens, night light), Lock screen. System:
Windows (gaps, hot corner, reopen floating apps), Notifications (Do Not Disturb), Power (idle and
sleep), Keyboard and mouse. Apps: Default apps, Keybinds, Weather and clock (the weather town, and
a 24-hour setting now shared by the island and the lock screen: `clock24Hour`, was `lock24Hour`).
The search field (focused when Settings opens) matches page titles and a list of words per page,
so it finds the page for any setting; Enter opens the first match. The sidebar scrolls.

### Battery alerts (done, verified on the laptop 2026-10-29)
- `services/BatteryAlerts.qml`: a notification at 20 % and a critical one (stays until dismissed)
  at 10 %, each once per discharge (`BatteryAlerts.js`, tested). The 20 % one also switches to
  power saver, back to the previous mode when plugged in (Settings -> Power -> Low battery, on by
  default).

### Microphone indicator (done, verified on the laptop 2026-10-29)
- While an app records from the microphone, a mic icon in the island and "Microphone in use by
  ..." in quick settings (`Audio.recordingApps`: the app streams linked to the default source,
  `PwNodeLinkTracker`; verified with `pw-record`).

### Drives and phone (done, verified on the laptop 2026-10-29)
- `udiskie` (core module) mounts USB sticks and SD cards with a notification; its tray menu in
  quick settings' background row unmounts and ejects. `kdeconnect-indicator` (phone module) the
  same for the phone (battery, sending files, clipboard). Both start in `autostart.lua`.
- The phone module opens KDE Connect's ports (1714-1764) in ufw, which CachyOS turns on and
  which refused them, so the phone couldn't find the laptop (`modules/phone/setup.sh`, 2026-10-31).
- Phone in quick settings (done, verified on the laptop with a Nothing Phone 2, 2026-10-31): a
  Phone tile to add
  in edit mode (the connected phone's name and battery) and its page: ring it, send files (picked
  with zenity), send the clipboard, browse its files (KDE Connect's mount, in the file manager),
  and Open KDE Connect for pairing. `services/Phone.qml` asks `phone.sh` every 10 s while the tile
  or page shows (`kdeconnect-cli -a`, the battery from the daemon's D-Bus battery plugin; parsing
  in `Phone.js`, tested). Nautilus: right-click files -> Scripts -> Send to phone (the `nautilus`
  Stow package; with several phones connected it asks which).
- Tray icons that name an icon no theme has (KDE Connect's Plasma-only
  `kdeconnectindicatordark`) fall back to the app's icon from its desktop file, by fuzzy lookup
  or exact name, else a generic one.

### Magnifier and drop-down terminal (done, verified on the laptop 2026-10-29)
- Super+Plus / Super+Minus zoom around the pointer in steps of 1.5x (up to 8x), Super+Escape back
  to normal (`cursor.zoom_factor`, set from Lua binds).
- The scratchpad (Super+`) starts a terminal when it's empty (a `workspace.created` handler since
  Hyprland 0.57 deprecated `on_created_empty`), over the
  dimmed workspace below (`decoration.dim_special`). Super+Shift+` moves a window onto it, or
  back off it to the workspace underneath when it's already there (user's request; verified
  2026-10-29).

### Network sign-in hint (built 2026-10-28; untested: needs a network with a login page)
- When NetworkManager's connectivity check is redirected (`Networking.connectivity` is Portal: a
  hotel's or café's login page), quick settings shows "This network needs you to sign in" with a
  button that opens http://neverssl.com (plain http, so the network can redirect it); the shell
  re-checks every 10 s until it's gone.

### Cover colors in the media menu (done, verified on the laptop 2026-10-29)
- The seek bar and play button take the album cover's most colorful main color, lightened for
  the dark menu (`ColorQuantizer` + `MediaAccent.js`, tested); grey or black and white covers keep
  the theme's accent. The cover is downloaded per track for it (`Media.artFile`).

### Snapshots (done 2026-10-28; the Settings page verified on the laptop 2026-10-29)
- The `snapshots` module (user's request after first skipping it): CachyOS had set up snapper
  for `/` with snap-pac (before and after every pacman transaction) and limine-snapper-sync
  (bootable from the boot menu); the module makes that reproducible, lets the user list them
  (`ALLOW_USERS`, `SYNC_ACL`) and adds a `home` config: hourly, keeping 10 hourly, 7 daily,
  4 weekly. `~/.cache` and `~/.local/share/Steam/steamapps` became subvolumes (reflink copy and
  swap), so home snapshots leave them out. Run by the user (needs sudo); verified afterwards.
- Settings -> Snapshots: the latest system snapshots per update ("System update", "Installed:
  ..."; `SnapshotList.js`, tested against the real list), the home ones with "Open" (their files
  in the file manager), "Take one now", and Btrfs Assistant for restoring.

### Hyprland 0.57 additions (done, verified on the laptop 2026-10-29)
- Minimize requests from apps and tools (see the Minimize decision; GTK's button stays greyed
  out, a Hyprland limit). Settings -> Appearance -> Blur style
  (Hyprland's non-animated blur variants: Classic, Frost, Acrylic, Prism, Aurora, Haze) and
  Settings -> Windows -> Wobbly windows (off by default), through `shell-settings.lua`
  (`HyprlandConfig.js`, tested). The spring curve key renamed to `damping`.

### Touchpad off with a mouse (built 2026-10-28; untested: needs a mouse and a finger)
- Settings -> Keyboard and mouse: "Touchpad off while a mouse is connected" (off by default;
  `services/Touchpad.qml`). Hyprland sends no device events, so udev's input events are watched
  while it's on and `hyprctl devices -j` is read a second after one (it polled every 3 s until
  2026-10-29's review); a mouse is any pointer device other than the touchpad's own two
  (`TouchpadDevices.js`, tested); the touchpads switch with `hl.device` through `hyprctl eval`.
  Not a plain "off": a laptop without its touchpad and no mouse can't easily get it back.
- No keyboard backlight control: the Omen's RGB keyboard isn't exposed to Linux (no
  `kbd_backlight` LED) without HP's own tools.

### Display settings (done, verified on the laptop 2026-10-28)
- Settings -> Display, per screen: resolution and refresh rate (from `hyprctl monitors -j`), scale,
  rotation and variable refresh rate (off, fullscreen only, always; `DisplayModes.js`, tested). A
  change is tried live (`hyprctl eval` of an `hl.monitor` call) with "Keep these display
  settings?": it goes back after 15 s unless kept, so a mode the screen can't show undoes itself.
  Kept setups are saved in `monitors` in settings.json and written to `shell-settings.lua`, which
  overrides monitors.lua's "preferred". Positions stay "auto": arranging several screens isn't
  built (only the laptop's screen to test with).

### Web apps (done, verified on the laptop 2026-10-29)
- `ghost webapp add <name> <url> [icon]` (`modules/apps/webapp.sh`; `remove`, `list`): a desktop
  entry `webapp-<name>.desktop` that opens the site with `chromium --app` (ungoogled-chromium-bin,
  user's choice: Zen has no window-without-tabs mode; Chromium runs only while a web app is
  open). Its `StartupWMClass` is the class Chromium gives the window
  (`chrome-<host>_<path with / as _>-Default`, checked on the laptop), so the dock and switcher
  show the web app's own icon. The icon is the given file or URL, else the site's
  `apple-touch-icon.png`, else its favicon from DuckDuckGo's icon service. All web apps share
  one Chromium profile (one login per site).

### Equalizer (done, verified on the laptop 2026-10-29)
- Five bands (bass 80 Hz, low mids 250 Hz, mids 1 kHz, presence 4 kHz, treble 10 kHz; ±12 dB)
  between the apps and the output, with presets (Off, Laptop speakers, Voice, More bass, More
  treble; `services/Equalizer.js`, tested). PipeWire's own filter-chain (user's choice over
  EasyEffects: no new package), run by `filter-chain.service` (enabled by the core module) from
  the `pipewire` Stow package's `ghost-equalizer.conf`, as a WirePlumber smart filter in front of
  whichever output is the default. Each output keeps its own gains (`equalizer` in
  settings.json); `services/Equalizer.qml` sets them with `pw-cli` when the output changes or
  the filter restarts. The preset in quick settings' Sound page, the bands in Settings ->
  Sound. The equalizer's nodes are left out of the Sound page's outputs and apps.

### Screen time (done, verified on the laptop 2026-10-29)
- Settings -> Screen time (user's choice: a Settings page, only showing the time; no limits or
  reminders): a day's total, the last 7 days as bars (hover for the time, click for that day)
  and the day's apps with their time. `services/ScreenTime.qml` gives the focused window's app
  10 s every 10 s, unless there's been no input for 2 minutes (`IdleMonitor`, so a video or a
  game holding an idle inhibitor still counts); suspend and a locked screen count nothing.
  Apps by desktop entry id (web apps by their own entry). `screentime.json` keeps 30 days
  (`ScreenTime.js`, tested), saved every minute; across a shell reload the counts stay in
  `PersistentProperties` as JSON text (a write during a reload is cancelled).

### Welcome tour (done, verified on the laptop 2026-10-29)
- `welcome/Welcome.qml` (user's choice: cards): seven cards over the dimmed screen (welcome, the
  launcher with files and commands, the island, tiling and switching, the dock and tools, the
  drop-down terminal, Settings; updated 2026-10-29 for that day's features), each with its keys
  as key caps, progress dots, Skip / Back / Next. Right or Enter, Left, Escape. Shown on the
  first start (`welcomeSeen` in settings.json) and again from Settings -> Keybinds ("Show the
  welcome tour") or `qs ipc call welcome show`.

### Sound events (done, verified on the laptop 2026-10-29)
- `services/Sounds.qml`: short sounds from the freedesktop sound theme (`sound-theme-freedesktop`,
  already installed), played with `pw-play` at 60 % through the default output, on by default
  (user's choice). Notifications (a chime, the warning for critical ones; apps' `sound-name` and
  `suppress-sound` hints are honoured; none during Do Not Disturb), the charger
  (`UPower.onBattery`: a full battery stops charging while still plugged in) and USB devices
  (`udevadm monitor`, no Quickshell API), the volume keys (any volume change, at most one tick
  per 150 ms) and screenshots, and the low battery alerts (their own warning; the notification
  stays quiet). `SoundEvents.js` tested. Settings -> Sound (was Equalizer): a switch for all and
  one per kind.

### Window tabs (done, verified on the laptop 2026-10-29)
- Hyprland groups (user's choice: keys and the window menu, no dragging into groups): Super+G
  makes the window a tab group (again: separate windows), Super+Ctrl+Shift+arrows moves a window
  into the group next to it, Super+Shift+G takes it out, Alt+` / Alt+Shift+` or a click on a
  tab switches. The window menu's "Tabs" / "Take out" (`Windows.toggleTabs`). A group takes
  one spot in our layout (checked live). The tab bar is rounded tabs in Inter (look.lua), in
  the wallpaper's colors (matugen's `hyprland-colors.lua`: the active tab in the primary
  container color, the others like the shell's surfaces, blurred).

### Native blur shapes (done, verified on the laptop 2026-10-29)
- Every shell panel asks Hyprland for blur behind exactly its cards (`BackgroundEffect.blurRegion`,
  ext-background-effect-v1) instead of a layer rule blurring every pixel above 30 % opacity
  (the island and dock first, verified by the user; then the rest at their request): the
  island's body rounded at the bottom plus the screen-edge strip minus the fillets' circles; the
  dock's bar, right-click menu and previews (plus one pixel, see NOTES); the launcher, OSD,
  switcher, window menu, Snap Assist, wallpaper strip, polkit prompt and welcome tour their card;
  the overview its whole dimmed screen. No `blur` layer rules are left. Not the screenshot bar
  (over the frozen, opaque picture) or the lock preview (its own blurred wallpaper). The glass
  opacity now goes down to 20 % (was 35, for the rules' `ignore_alpha`; user's choice).

### Elgato Wave:3 (built 2026-10-29; reviewed by the user, untested: the microphone is on the desktop)
- The opt-in `wave3` module (`modules/wave3/`, its README has the details): openxlr (AUR)
  instead of Elgato Wave Link, `lsp-plugins-lv2`, and a "Voice" profile recalled whenever the
  microphone connects: RNNoise noise removal, a high-pass and gentle EQ, a compressor, an
  optional de-esser (LSP compressor with a side-chain high-pass; Calf's de-esser is stereo only)
  and a limiter. Opt-in modules (`opt_in` in `ghost`) only install where
  `~/.config/ghost/modules` lists them, never as part of "all".

### Proton apps (built 2026-10-29)
- The `proton` module (user's request): Proton VPN (`proton-vpn-gtk-app`, extra), Proton Mail
  and Proton Pass (`proton-mail-bin`, `proton-pass-bin`, AUR; Proton's own builds). Proton
  Drive has no Linux app yet (October 2026: in development, no date; an official CLI since
  June 2026, and rclone's `protondrive` backend can mount it). Proton VPN's connections are NetworkManager connections.

### Low disk space warning (built 2026-10-29)
- `services/DiskAlerts.qml`: a notification under 10 % free on `/` (the same Btrfs as /home) and
  a critical one under 5 %, each once until there's room again above 15 % (`DiskAlerts.js`,
  tested); it points at old snapshots. `df` a minute after login and every 10 minutes.

### Media and notifications on the lock screen (done, verified on the laptop 2026-10-29)
- `lock/LockStatus.qml` under the date on the lock screen (not the login screen: `LockContent`
  only has a slot for it, so the greeter never starts the notification server): the island's
  `MediaCard` (play, pause, skip without unlocking) and the number of notifications, never
  their content. Settings -> Lock screen: "Media controls" and "Notification count", both on
  (since 2026-10-30 in the lock screen editor's Widgets tab, see "Lock screen widgets").

### Game mode (done, verified on the laptop 2026-10-29)
- A round button in quick settings (`services/GameMode.qml`; not saved, like Keep awake): while
  on, Hyprland's animations, blur and shadows are off (appended to `shell-settings.lua` after
  the settings, `HyprlandConfig.js`, tested), pop-ups wait in the history like Do Not Disturb
  (critical ones still show) and the power mode is Performance, back to the previous one after.

### Caps lock, keyboard layout and power mode pop-ups (done; caps lock verified on the laptop 2026-10-29)
- The OSD shows "Caps lock on/off", a new keyboard layout's name (Hyprland's `activelayout`
  event for the main keyboard, seeded from `hyprctl devices -j` at start; `services/Keyboard.qml`,
  parsing in `KeyboardDevices.js`, tested) and the power mode when it changes. Caps lock sends no event, and a release bind on
  the key that leaves it alone never fired (user's test), so the shell reads the keyboard's
  caps lock LED (`/sys/class/leds/*::capslock/brightness`) 4 times a second, in-process.
- The OSD got smaller (240 x 40, close to the closed island; user's choice), label pop-ups are
  centered, and it sits 24 px above the edge while the dock is hidden on that screen, 64 px
  above it while shown (`services/DockState.qml`).

### VPN, hotspot and airplane mode (built 2026-10-29; the hotspot and airplane mode untested)
- Under the networks in quick settings' Wi-Fi page (`services/NetworkExtras.qml`, parsing in
  `NetworkExtras.js`, tested): the saved VPNs (NetworkManager's VPN plugins and WireGuard, which
  Proton VPN's app uses; click to connect or disconnect), the hotspot (`nmcli device wifi
  hotspot`; only with a cable connection, since it takes the Wi-Fi card off its network; its QR
  code shares it like a network) and airplane mode (`rfkill block all`; the user may write
  `/dev/rfkill` through logind's ACL, no root). The lists are re-read on `nmcli monitor` and
  `rfkill event` output. The island shows a plane and a key while they're on.

### End task on the System page (done, verified on the laptop 2026-10-29)
- Under the stats: the six busiest apps (CPU over the last 2 s, then memory), like a task
  manager: a window's app with every process under it (Electron and browser helpers), the rest
  by process name (`/proc/<pid>/stat` read by `system-stats.sh`; grouping in `SystemStats.js`,
  tested). "End task" sends SIGTERM to all of them after a second click; processes the session
  needs (Hyprland, the shell, PipeWire, D-Bus, portals) have no button. The shell and everything
  it started (its nmcli, rfkill and udevadm watchers) are one "Ghost Shell" row without one, also
  when its Settings window is open (review 2026-10-29: that window made qs endable).

### Per-app notification settings (done, verified on the laptop 2026-10-29)
- Settings -> Notifications -> Apps: every app that has sent a notification (remembered by name
  in `notificationApps`), each Silent (only into the list, no sound), Pop up (the default) or
  Always pop up (also during Do Not Disturb and game mode). Critical ones always pop up
  (`services/NotificationRules.js`, tested).

### Drawing on screenshots (done, verified on the laptop 2026-10-29)
- The screenshot notification's "Draw on it" opens the picture in satty (`extra`, MPL-2.0,
  GTK 4, so it follows the wallpaper's colors): arrows, boxes, text, blur. Enter saves the drawing
  over the screenshot and copies it. Without satty the button isn't offered.

### Camera and screen sharing indicators (built 2026-10-29; untested with a real call)
- Like the microphone: a camera and a screen icon in the island, and "Camera in use by ..." /
  "Your screen is being shared" in quick settings (`services/Privacy.qml`, `StatusRow`). The
  camera's USB power state is read in-process every 3 s (its folder found once by
  `services/camera.sh devices`; before 2026-10-29's review it started a script every 3 s, ~6,000
  an hour); `camera.sh apps` (`fuser`) names the apps only while it's on (`Privacy.js`, tested). Screen sharing is the portal's PipeWire stream
  (`xdph-streaming-<n>`): Hyprland's `screencast` event also fires for grim and the shell's own
  previews.

### Light mode (done, verified on the laptop 2026-10-29)
- Settings -> Appearance -> Light or dark: Dark (default), Light or At sunset (dark from sunset
  to sunrise at the weather town, open-meteo's `sunrise`/`sunset`; 19:00-07:00 without a town;
  `ColorScheme.js`, tested). `services/ColorScheme.qml` writes the result to
  `~/.local/state/quickshell/scheme` and runs `wallpaper.sh`, which runs matugen with `-m light`
  or `-m dark` and sets GTK's color-scheme, adw-gtk3 or adw-gtk3-dark and Colloid-Light or
  Colloid-Dark (moved there from the core module). Every template takes the scheme's colors;
  Zed's theme says `{{mode}}` (matugen 4.2 has it). `wallpaper.sh` with no wallpaper reuses the
  last seed color (`~/.local/state/quickshell/seed`). The cover accent in the media menu is
  darkened on a light menu. Not switched: the shell's own icon theme (`QS_ICON_THEME`, read at
  start). The shell remembers the mode it applied rather than re-reading the file after a run:
  that read came back stale and made every switch run twice (~2 s; now one run after 300 ms).

### To-do, note and timer in the today menu (done, verified on the laptop 2026-10-29)
Since 2026-11-04 the to-do list is a desktop widget (see "Desktop widgets polish").
- Three buttons under the weather, each opening its part (one at a time, folded when the menu
  opens): a to-do list (Enter adds, click ticks off, × removes, "Clear done"), one note saved
  while typing (both in `~/.local/state/quickshell/today.json`, `services/Planner.qml`), and a
  timer (1, 5, 15 or 25 minutes, pause, cancel; `services/Countdown.qml`, kept across reloads)
  whose time left shows in the island and which ends with a critical notification and the alarm
  sound. List and time logic in `Planner.js`, tested.

### Launcher: windows, files and commands (done, verified on the laptop 2026-10-29)
- Open windows are listed with the apps when the query appears in their title or app name
  (Enter switches, restoring a minimized one). "/ name" searches the home folder with `fd`
  (hidden and git-ignored files left out, the shortest paths first; Enter opens with xdg-open),
  "> command" runs it in the default terminal, which stays open in your shell afterwards.
  `Fuzzy.mode`, `scoredWindows`, `files` and `fileIcon`, tested. fd over plocate: no database
  to keep up to date, and it's fast enough for the home folder (~10 ms). The last results stay
  up while a new search runs (emptying them on every key made the list flicker).

### Calendar events (built 2026-10-29; waiting on the user's share link to test)
- User's choice: no Google; Proton Calendar through its read-only share link ("Share with
  anyone"; Proton has no CalDAV). The `calendar` module (vdirsyncer and khal, `extra`) and
  `ghost calendar add [name]`, which asks for the link without echoing it and keeps it only in
  `~/.config/ghost/calendars` and vdirsyncer's config (both mode 600, outside the repo), then
  writes vdirsyncer's config (http -> filesystem, `a wins`) and khal's (fixed ISO formats).
  `services/Agenda.qml` runs `vdirsyncer sync` at start and every 15 minutes once khal's config
  exists, and asks khal for the shown month and the coming week. The today menu lists the next
  four events under the weather and dots the days with events in the month calendar
  (`CalendarEvents.js`, tested). Read-only: events are made in Proton's app or site. khal gives
  an all-day event's last day as its end date (its `AllDayEvent.end` is DTEND minus a day).

### Optimization review (done, verified on the laptop 2026-10-29)
Four read-only reviews (code against ENGINEERING_PRINCIPLES.md, packages and system, the running
shell's cost, features and customization), checked before acting. Done so far:
- Bugs: settings never saved over an unreadable settings.json (Quickshell loads defaults without
  an error, see NOTES); screen time keeps a bad file as `.bad`; the calendar's range no longer
  changes every minute (khal would have run each minute); `LatestProcess` runs a request made
  while the same job runs after it instead of dropping it (calculator, file search, covers,
  wallpaper, calendar, network state, login screen sync, clipboard); `Notifications.send` sends
  each of the shell's own alerts on its own; a failed wallpaper change notifies.
- The camera indicator reads the camera's power state in-process (it started a script every 3 s).
- Package lists: core gained what the repo used without listing (pipewire-audio, -pulse, -alsa,
  dnsmasq, fd, breeze-icons, gnome-keyring, fish). The login screen's Hyprland turns off its
  update-news pop-up (`ecosystem`), whose helper crashed at every boot. Also listed now:
  base-devel (paru's AUR builds) and libappindicator (udiskie runs with `--appindicator`). The
  haunt module lists nothing: haunt-bin brings its own; building from source is a note there
  (install as dependencies, then `pacman -Rns $(pacman -Qdtq)`).
- System (user's picks, `ghost install system`): Plymouth's initramfs hook and packages removed,
  systemd-resolved's mDNS and LLMNR off (Avahi does mDNS). Tried and dropped: forcing the RTX's
  runtime power management (`NVreg_DynamicPowerManagement=0x02`): the driver then reports
  "Runtime D3 status: Not supported" (MUX mode 0, hybrid), so the card can't power down on this
  laptop; it idles at about 1.6 W (P8).
  Removed by hand: unused icon themes (Papirus, WhiteSur, Tela), AUR build leftovers (cmake, go,
  zip), iwd, xf86-video-amdgpu, profile-sync-daemon, nss-mdns and Haunt's build tools. Removing
  iwd renamed the Wi-Fi card (wlan0 -> wlo1, see NOTES), so the saved network had to be joined
  again; the name stays wlo1 (nothing in the repo uses it).
- Cleanup: quick settings' status lines (sign-in, recording, microphone, camera, screen,
  updates) are one `StatusRow` (icon, text, optional button); QuickSettings 429 -> 351 lines.
  `widgets/TextField.qml` (rounded field with a placeholder) for the Wi-Fi password, the new
  task and a notification's quick reply; the polkit prompt keeps its own (focus border, show
  password, read-only while waiting). `widgets/SectionHeading.qml` for the small accent headings
  (Settings' groups and sidebar, the Sound page), all announced as headings now.
  The keyboard's layout and caps lock moved from the OSD into `services/Keyboard.qml` (signals
  on real changes only); the OSD only shows them (262 -> 202 lines).
  The screenshot tool's shell (save and "Draw on it", text, QR code, color picker) moved from
  template strings in Screenshot.qml into `screenshot/capture.sh`.
  `stow_packages` in `modules/lib.sh` (ghost doctor and the core module each listed them). The
  11 layer rules in `rules.lua` are a table and a loop (same rules, checked).
  `widgets/StateLayer.qml`, the hover/active highlight, in eight controls (it was written out in
  each; three didn't fade); the overview opens through one `show()`.
- Memory (a fresh shell: 464 MB resident, 332 MB proportional; most of it graphics, a GL context
  per surface, fonts and libraries): the island's menus (quick settings, today, media,
  clipboard, emoji, background apps, power) are built only while shown and freed after (on
  every screen), the lock preview is a `LazyLoader`, and Settings builds only the chosen page
  (it kept all 13 up to date while hidden). `MALLOC_ARENA_MAX=2` was tried: no difference.
  The island's and the small player's cover come from the one downloaded copy (`Media.cover`;
  each track's cover was fetched twice). Kept: the wallpaper picker's thumbnails stay decoded
  after the first open (~18 MB for 44 pictures; freeing them would decode up to 5K pictures again
  on every open).
  The shell loads Mesa's EGL only (`__EGL_VENDOR_LIBRARY_FILENAMES` in `hypr/shell.sh`): it
  draws on the iGPU, and NVIDIA's EGL libraries cost it ~57 MB. Fresh shell after all of this:
  393 MB resident, 289 MB proportional (was 464 / 332).
  Tried and dropped: `QSG_RENDER_LOOP=basic` (another ~32 MB, but the Settings window stuttered
  while Hyprland resized it into its tile).
- Splits: the Wi-Fi page's QR sharing is `WifiShare.qml` (387 -> 289 lines); the launcher's
  calculator, file search and result row are `CalcRow`, `FileSearch` and `LauncherRow`
  (433 -> 232). The touchpad rule watches udev's input events instead of polling every 3 s.
  The island's view order (menu, reload notice, notification, attention, hover view) is
  `IslandViews.shown` (tested) and the reload note `ReloadNotice.qml` (IslandWindow 551 -> 528).
  The top row stays in IslandWindow: it reads the island's state in a dozen places (dots,
  media, peeks, the tray arrow, the symmetric widths), so a separate file would only pass all
  of that through properties.

### More settings and live wallpapers (done, verified on the laptop 2026-10-29; user's picks from the research)
- Settings -> Notifications -> Pop-ups: how long a notification stays (3-30 s, 5 by default;
  the attention card too) and the volume and brightness pop-up's place (bottom, or top under the
  island) and time (1-5 s).
- Settings -> Appearance -> Status icons: Wi-Fi, Bluetooth, VPN, airplane mode, timer, updates,
  muted and battery can each be hidden (`hiddenStatusIcons`; since 2026-11-03 in quick settings,
  and the battery always shows there with its percentage). The privacy icons (recording,
  microphone, camera, screen sharing) always show.
- Settings -> Windows -> Dock: at the edge (as before), always (it reserves its space, so windows
  tile above it), or off. Pins move left or right from the dock's right-click menu
  (`DockApps.movePin`, tested).
- Settings -> Appearance: Color style (matugen's scheme types: Tonal by default, Vibrant,
  Expressive, Content, Faithful, Fruit salad, Rainbow, Neutral, Monochrome), Contrast (lower to
  highest, matugen's `--contrast`) and Accent color (the wallpaper's, or one of seven; the
  colors are then made from it, the picture still shows). `~/.local/state/quickshell/scheme` is
  now `key=value` lines (mode, type, contrast, accent; `ColorScheme.file`, tested), and
  wallpaper.sh checks each value again before passing it to matugen.
- Settings -> Appearance -> Fonts (text and monospaced, the installed ones of a short list; Theme
  reads them live) and Icons: the icon theme (Colloid in its folder colors, Breeze, Adwaita;
  `iconTheme`). wallpaper.sh picks its dark or light version for the mode (`-Dark`, `-Light`,
  `-dark`), sets it for GTK and writes it to `icon-theme`, which `hypr/shell.sh` exports as
  `QS_ICON_THEME` at every start, so "Restart the shell" applies it to the shell's own icons
  too (env.lua's Colloid-Dark stays the fallback). Moved out of wallpaper.sh's fixed Colloid.
- Settings -> Weather and clock -> Temperature: °C or °F (open-meteo's `temperature_unit`).
- Settings -> Screenshots and recordings (new page): both folders (typed; empty for the default,
  `~/` works; `CaptureFolders.js`, tested), the recording's frame rate (30/60), quality
  (gpu-screen-recorder's medium to ultra) and the microphone mixed in. The notifications name
  the folder.
- Settings -> Weather and clock -> Clock: the day in the island ("Thu 29  14:32", English day
  names), seconds (the clock then ticks every second), and whether playing music takes the
  clock's place (on by default, as before).
- Settings -> Lock screen: weather and battery under the date (on), and the next calendar event
  (off by default: its title would show to anyone at the locked screen); `LockLine.qml`, and
  the "Today 14:00" wording moved into `Agenda.when` (shared with the today menu). Since
  2026-10-30 these lines are the lock screen widgets, picked in the lock screen editor.
- Wallpapers: the picker's pictures come from `services/wallpapers.sh` (your folder, Hyprland's,
  everything under /usr/share/wallpapers and /usr/share/backgrounds; JPEG XL/AVIF/HEIC only with
  kimageformats) grouped by `Wallpapers.js` (tested): a KDE Plasma picture is one entry at the
  screen's size, dark versions (`images_dark/`, `-dark`, `_dark`, `-d`) paired with their light
  ones (still useful for sets with dark versions). Core gained nwg-shell's digital art; KDE
  Plasma's and Ubuntu's sets were tried and dropped: mostly photos, and the user wants art (anime
  and illustrations), not photos.
  Settings -> Appearance -> Wallpaper: your folder, a slideshow (15 min to 4 h, from yours or
  all; each change recolors), and following light and dark for pictures with a dark version.
- Live wallpapers (user's request, "anime cinematics"): video files (mp4, webm, mkv, mov) in your
  folder are wallpapers too, played by Qt Multimedia (already installed with its FFmpeg backend;
  no new package) over a still frame, muted, only while seen: no window on that screen's
  workspace, not in game mode, on battery or locked (`Session.locked`). The scan makes a
  thumbnail per video once (`~/.cache/quickshell/wallpaper-thumbs`), wallpaper.sh makes the
  colors from a frame (`video-frame.jpg`, which the lock and login screens show). Wallpaper
  Engine scenes (linux-wallpaperengine) aren't built: it isn't installed here.

### Quiet while fullscreen, and more from the research (done 2026-10-29)
- Pop-ups wait while a window is fullscreen on the focused screen (a game, a film; Settings ->
  Notifications, on by default), like Do Not Disturb and game mode. When the quiet ends, one
  notification says how many came in meanwhile (apps set to Silent don't count). Verified:
  nothing popped up during fullscreen, the summary came right after.
- Talking while muted: when an app records from the microphone while it's muted (a call starting
  muted), the OSD says "Microphone is muted" and the island's mic icon turns into a red crossed
  out one for as long as it lasts (`Audio.mutedWhileRecording`). Not voice detection: that would
  mean reading the microphone's level all the time. Verified with pw-record.
- Pinned clipboard texts: the pin button on a text entry (hover) keeps its whole text (from
  `cliphist decode`) in `~/.local/state/quickshell/clipboard-pins.json`, shown first in the
  menu with a pin mark, searched like the rest, kept through "Clear all"; × or Delete unpins
  (`ClipboardEntries.withPins/pin/unpin`, tested). Images can't be pinned.
- Launcher extras: a color typed as #rgb, #rrggbb or rgb() shows a swatch (Enter copies the
  hex); "? words" searches the keybinds (`hyprctl binds -j`, grouped like Settings' page); one
  typo in an app's name still finds it when nothing else does (`Fuzzy.oneTypo`); the last row
  searches the web for the text (DuckDuckGo in the browser; user's choice: no Google). `Fuzzy.color`,
  `keybinds`, typos tested. Verified live.
- The OSD shows a new sound output ("Headphones", a Bluetooth headset's name; plugged in or
  picked) instead of its volume, and a VPN connecting or disconnecting from anywhere (the Wi-Fi
  page, Proton VPN's app, nmcli; `NetworkExtras.vpnSwitched`). Neither for what's already
  there when the shell starts. Verified with a null sink and a WireGuard test connection.
- Out of memory (`services/OomAlerts.qml`): "Memory ran out: <app> was closed" when the kernel's
  OOM killer or systemd-oomd ends an app or service, and at the next login when oomd closed the
  whole session (see NOTES).
- Apps in their own scopes (user's choice): the shell starts every app (launcher, dock, default
  apps, `xdg-open`, the terminal) with `systemd-run --user --scope` in `app.slice` (`Apps.run`),
  as does the scratchpad's terminal, so oomd closes the app that ran out of memory instead of
  the session it used to share with Hyprland. Apps also no longer inherit the shell's Mesa-only
  EGL. The screenshot tool's satty and picture viewer and the recording's Play too, all
  through `hypr/run-app.sh`. Not scoped: what Hyprland's fallback binds start while the shell
  is down. Read from this boot's
  journal and followed (`OomAlerts.js`, tested); the last one reported is in
  `~/.local/state/quickshell/oom-seen`, so a restart doesn't repeat it. Verified with a
  memory-limited test process; the session case is untested.

### Keyboard in the island's menus (done, verified on the laptop 2026-10-29)
- User's request: arrow keys like a native app. In an open menu, the arrow keys move to the
  nearest control that way (`widgets/ArrowNavigation.qml`, the direction logic in
  `ArrowNavigation.js`, tested: controls in line first, others within 45 degrees); with nothing
  chosen yet, the first arrow or Tab picks the first control. Enter or Space use it. Tiles,
  round buttons, icon and text buttons, list rows, switches, sliders (Left and Right set them,
  Up and Down move on), steppers, the to-do rows and text fields take the keyboard; a ring
  inside the control's edge in the accent color (`widgets/FocusRing.qml`) shows which, and a
  click never shows it. Only the menu's own controls: the top row's clock and status icons
  are left out (Enter on one closed the menu and gave the keyboard back to the window, so the
  next keys went there). Quick settings' pages are hidden once they've slid out, so the keys
  skip them. Escape on one of its pages goes back to the main page first.
- The same in the Settings window (the sidebar's pages take the keyboard; Down from the search
  field goes into the list) and in the today and media menus (the date that folds the calendar
  out, the weather town, notification cards, the small player, the cover). Not the media
  menu's seek bar: Spotify reports a frozen position, so stepping from it would jump wrong.

### Review of the day's additions (2026-10-29)
Two read-only reviews of everything since the optimization review, findings checked, then fixed:
- The lock and login screens' password field keeps Tab (Tab reached the power buttons: Tab
  then Enter at the login screen would suspend), and the island's top row is out of the Tab
  order again (Tab wrapped to the clock, and Enter there closed the menu).
- Out-of-memory alerts: without `oom-seen` they count from the boot, so a session closed
  before any other kill is still reported at the next login; apps' scopes
  (`app-ghost-<id>-<random>`, Chromium's `app-<id>-<pid>`) are named by their app; other
  users' units are left out (tested).
- One `hypr/run-app.sh` starts apps in their own scope for the shell, Recorder's Play (it
  wasn't scoped), the screenshot tool and the scratchpad (the systemd-run flags were written
  out three times and had drifted).
- Wallpapers: pictures with the same name (art.png and art.jpg) or two light versions are each
  listed (only the first showed; tested); a video's still frame is made before the shell reads
  the choice and reloads for each video; a new video plays; following light and dark waits
  for the colors made in the new mode (`ColorScheme.appliedMode`), instead of racing them.
- Smaller: a failed `nmcli` read no longer shows a VPN disconnecting and reconnecting; pins
  made in a row are all kept, and the pins file loads before one is written; contrast snaps to
  wallpaper.sh's steps (tested); "Tomorrow" is a calendar day, right on the nights the clocks
  change; comments moved back to their settings.
- Not done: with the dock set to "always" on several screens the OSD's height follows one of
  them (only matters with an external monitor, none to test with).

### UI research round (done, verified on the laptop 2026-10-30)
User's picks from two read-only researches (other Quickshell shells and Hyprland 0.56/0.57; an
audit of our own UI): all sixteen, built in batches.
- Audit fixes: hover on the cards that had none (notifications, attention, the small player,
  the date, the weather town, the window menu's workspaces); critical notifications in
  Material's error colors (`m3errorContainer`, its text in `m3onErrorContainer`); the weather
  line ends in "…" before the town; the OSD pops in from its center (it slid up from the bottom
  even when shown at the top) and moves smoothly between a level and a label; text fields show
  where the typing goes; the switch's thumb grows while held and has hover; outline widths,
  the switch's thumb and a subtitle's dimming are Theme tokens; size animations ease.
- Tooltips (`widgets/Tooltip.qml`): an icon-only button's label after the pointer rests 0.5 s,
  under it or above when there's no room, moved to the top of its window so no clip cuts it
  off; the round buttons' names use it too.
- Animation speed (Settings -> Appearance): off, 0.5x to 2x, for the shell (Theme's durations)
  and Hyprland together: look.lua's animations are one table set by `GhostAnimations(factor)`,
  which shell-settings.lua calls again at the chosen speed (`HyprlandConfig.animationLua`,
  tested).
- Size (Settings -> Appearance): the shell's size (85-125 %), its text on top of that (90-130 %)
  and its corners (square to rounder). Theme's sizes go through `px`, font sizes through
  `text` and radii through `round` (`theme/ThemeScale.js`, tested); timings, counts, outline
  widths and the webcam offset don't change. Checked at 125 % with square corners.
- Dock icon size (Settings -> Windows -> Dock; the bar follows), the launcher's width and rows
  (Appearance -> Size) and the workspace dots (Appearance -> Workspaces: 3-10 always, or only
  the ones in use, which scrolling then steps between: `WorkspaceSlots.stepIn`, tested). The
  window menu keeps five "move to" buttons. Checked live.
- Settings -> Notifications -> Pop-ups for: each OSD pop-up on or off (volume, brightness,
  microphone, muted while recording, a new output, VPN, power mode, keyboard layout, caps lock;
  `hiddenOsdKinds`).
- Launcher favorites, hidden apps and your own commands: resting on an app shows a star (first
  in the list while the search is empty) and a hide button; Settings -> Default apps lists the
  hidden ones (Show) and your commands (a name to find it by and a shell command, run in its
  own scope; add and remove there). `Fuzzy.results` options, tested.
- Lock screen clock (Settings -> Lock screen -> Clock; the login screen too): style (big, stacked
  hours over minutes, thin, analog), size (75-150 %), its own font, and where it sits (top as
  before, in the middle with the field, or the bottom-left corner). `lock/LockClock.qml`, the
  choices, digits and hands in `LockClock.js` (tested). Checked in the preview.
- Lock screen feedback and extras: a wrong password shakes the field and clears it; caps lock
  and (with more than one layout, `Keyboard.layoutCount`) the active layout show under the
  field; the lock and login screens fade in; a message line at the bottom (Settings -> Lock
  screen -> Message, both screens); a grace period after the idle lock (off by default, 5-60 s)
  in which a key or a pointer move of 24 px unlocks without the password (only the idle lock:
  Super+L, the power menu and the lock before a suspend end it); your picture (~/.face, chosen
  in Settings -> Lock screen) above your name on the login screen (`greeter/sync.sh` copies it);
  "Lock and turn off the screen" in the power menu (off once you've stopped touching the laptop
  for a second, back on with any input; `idle/Idle.qml`). `qs ipc call settings page <id>`
  opens a Settings page. Checked: the message, the clock's size and font, the fade, the login
  screen run from the repo; the shake, hints, grace period, picture and screen off are for
  the user's checklist (they need a real lock, a picture or the caps lock key).
- Smooth recoloring: the shell's colors fade to a new wallpaper's over 0.8 s (a `Behavior` on
  each of `Colors`' properties, `Theme.anim.recolor`, so it follows the animation speed; not on
  the first load, which would fade from the fallback colors). Hyprland's borders and the apps
  still switch at once. Checked live by swapping colors.json.
- Hyprland extras (Settings -> Appearance -> Windows): how windows open and close (pop in,
  slide, grow: Hyprland's popin, slide, gnomed) and how workspaces switch (fade, slide, slide
  up, slide and fade), through look.lua's `GhostAnimations(factor, styles)`; a turning border
  (`borderangle` with the `loop` style: Hyprland redraws every frame, so off by default and the
  row says it costs battery); a glow inside the focused window's edge (0.57's
  `decoration.glow`, in the accent at 40 % from matugen's colors.lua); floating windows' border
  in the tertiary color and pinned ones' in the secondary (`border_color` window rules using
  `GhostColors`, which colors.lua defines and shell-settings.lua, loaded after it, reads).
  Settings -> Keyboard and mouse -> Pointer: the cursor theme (the installed ones; only Adwaita
  here) and size, as environment variables for apps started later and `hyprctl setcursor` at
  once. `HyprlandConfig.js` tested. Checked live: every option applied (`hyprctl animations`,
  `getoption`), no config errors.
- Desktop widgets (Settings -> Appearance -> Desktop widgets, all off by default): a clock, the
  weather and the media player (while something plays) as glass cards on the wallpaper
  (`desktop/DesktopWidgets.qml`, a `Bottom`-layer surface on the first screen, so windows
  cover them; input and blur only on the cards). Resting on one shows a handle in its corner;
  dragging that moves it, saved as fractions of the screen in `desktopWidgets` and kept on
  screen (`DesktopWidgets.js`, tested). Checked live on an empty workspace; dragging verified
  by the user on all four edges. The user wants a refinement and polish pass over these later.

### On-screen editors (done 2026-10-30; lock screen, desktop, dock and island verified on the laptop)
User's request: settings like the lock screen's clock should be picked by sight, and edited
on the screen itself, not inside Settings (first planned as previews and cards in Settings;
changed the same day). The direction: Android's customization with iOS's and macOS's polish.
User's choices: four editors (lock screen, desktop, dock and island, windows look), opened
from a Customize button on the matching Settings page and from the launcher (not a long-press
or a key); their visual options leave Settings, which keeps only what isn't seen.
- Lock screen editor (`customize/LockEditor.qml`, `qs ipc call customize lock`): the real
  lock screen, live, with Cancel and Done (Escape, Enter; Cancel writes the earlier values
  back), the clock outlined (click for its tab) and a sheet with Looks (presets as picture
  cards: your picture with each look's clock, `customize/Presets.js`, tested), Clock (style
  and font cards, place and size as segments, time and date) and Picture (the desktop's or
  one of yours, blur, darkening). The editor's surfaces are nearly solid: the lock screen is
  inside its own window, so Hyprland's blur can't reach under them. Shared pieces:
  `widgets/ChoiceCards.qml` (picture cards, wrapping or one scrolling row),
  `widgets/Segmented.qml`, `lock/MiniClock.qml`. Settings -> Lock screen keeps the message,
  what shows under the clock, the grace period and the login screen's options.
- Desktop editor (`customize/DesktopEditor.qml`, `qs ipc call customize desktop`), like
  Android's "Wallpaper & style": opening it goes to an empty workspace (windows would cover the
  desktop; Done or Cancel go back), the island and dock stay to show colors and sizes. Tabs:
  Wallpaper (pictures and videos as cards), Colors (light, dark or at sunset; the accent as
  swatches, the wallpaper's own in its picture; color style; contrast), Widgets (on or off;
  their handles show while it's open, drag them), Style (glass, see-through, blur, corners),
  Size and text (shell size, text size, font cards, icon theme). Its window takes input only
  on its sheet and buttons, so the widgets underneath can be dragged. Cancel writes the earlier
  settings back and sets the earlier wallpaper again. Settings -> Appearance keeps the wallpaper
  folder and slideshow, the launcher's size, animation speed, workspace dots, status icons and
  the windows' border and corners (the last ones move with their editors). The editors share
  `customize/EditorChrome.qml` (Cancel, Done, the tabbed sheet); `customize/Customize.qml`
  holds them and the IPC (`lock`, `desktop`, `close`).
- Every change shows while it's made (user's review): the desktop editor's sheet and buttons
  are glass with Hyprland's blur behind them (`BackgroundEffect`), so see-through, glass and
  blur style show on the sheet itself (the lock screen editor's was frosted, blurring the lock
  screen in its own window, until the lock screen became a card above the sheet);
  "Making the colors…" shows while wallpaper.sh remakes them (`Wallpaper.busy`,
  `ColorScheme.busy`); a new icon theme offers restarting the shell (its own icons are read at
  start); the widgets' places can go back to the start; and the Looks gallery shows "Yours"
  first when your lock screen matches no preset.
- Dock and island editor (`customize/DockIslandEditor.qml`, `qs ipc call customize dock`): the
  real island and dock (kept shown while it's open, `Editing.dock`) change as you pick; its
  sheet sits in the middle of the screen (`EditorChrome.centered`), clear of both. Island:
  workspace dots as segments, the day, seconds and music-for-clock switches, and the status
  icons as chips (filled while shown). Dock: when it shows and its icon size; pinning and
  moving apps stays the dock's own right-click menu (the editor's window takes no input over
  the dock). Moved out of Settings: Appearance's workspace dots and status icons, Windows' dock
  rows (now a Customize button) and Weather and clock's island rows; the 24-hour clock stays
  there (a time format, shared with the lock screen and the desktop clock).
  It goes to an empty workspace too (user's choice: the glass sheet read poorly over windows);
  the trip there and back is `Editing.toEmptyWorkspace()` / `back()`, shared with the desktop
  editor.
- Windows editor (`customize/WindowsEditor.qml`, `qs ipc call customize windows`): on an empty
  workspace with two example windows of its own, tiled side by side (`ExampleWindow.qml`, a
  title and placeholder lines in your colors; user's choice over relying on windows already
  open), the first focused before the editor takes the keyboard so the active border and glow
  show; Done or Cancel close them and go back. A rule lets them take the focus when they open
  (otherwise they'd ask for attention: the island's card). Borders (width, corners, turning border, glow, floating and pinned
  windows standing out), Space (gaps between windows and at the edges), Motion (speed, opening
  and closing, switching workspaces, wobbly windows). Each animation has Play: a floating
  "Animation sample" window opens and closes (a rule in rules.lua floats it; positions.lua
  leaves all the examples out: they share Quickshell's class with the Settings window, whose
  saved place the first sample took), or the workspace switches away and back (its own trip,
  not `Editing`'s, which is the way home). A step list includes your current value
  when it isn't one of its steps. Moved out of Settings: Appearance's animation speed and window
  border and corners, Windows' gaps and wobbly windows (now a Customize button). With this,
  Settings keeps only what isn't seen; every visual option is in an editor.
- The screen as a card (user's request, like GNOME's workspaces and Android's widget editing):
  each editor shows what it edits shrunk into a rounded card on the background color, the
  sheet below it. A live shrunken copy of the whole screen isn't possible on Hyprland 0.57
  (tested 2026-10-30: a full-screen layer ends up in its own screencopy, a mirror in a
  mirror; the `no_screen_share` layer rule draws it black instead of leaving it out), so each
  editor draws its own: the lock screen editor scales LockContent (laid out at the screen's
  size) into the card, which follows the sheet's height as tabs change; the clock's outline
  is inside the card. User's review: more room for both. Cancel and Done moved into the sheet's
  top row (beside the tabs), the sheet is up to 1240 px wide and every tall tab is two columns
  side by side in all four editors, so the sheet is shorter and the card larger. The Clock tab:
  style and font cards side by side (the same card size), place, size and show in one row.
- The desktop editor publishes its card (`Editing.card`, `cardScreen`): the wallpaper layer
  clips its picture to it with the background color around (animating in and out), and the
  widgets' layer scales them into it; dragging divides the pointer's move by the scale, and
  their input and blur regions are computed with it (`desktop/WidgetRegion.qml`).
- The windows editor shows the same card, and its example windows tile inside it: their
  workspace gets a `gaps_out` workspace rule (a table `{ top, right, bottom, left }`; a string
  is refused) of the space around the card minus what bars reserve plus your own gaps, so
  borders, corners and gaps stay Hyprland's own. The rule is appended to shell-settings.lua
  while the editor is open (`services/HyprlandRuntime.qml`; the login screen's copy leaves it
  out) and left out when it closes: made with `hyprctl eval` at first, it was dropped by the
  reload every changed setting does, and the examples jumped out of the card (user's find in
  the Motion tab). Chosen over `hl.monitor`'s `reserved_area`, which would set the screen's
  mode again on every resize. The card's geometry moved into `EditorChrome` (three editors).
- The island and dock in the other editors (user's question): the lock screen editor covers
  both; the desktop and windows editors keep the island (like Android's status bar: colors,
  sizes and glass show on it) and hide the dock (`Editing.hideDock`: its sheet is where the
  dock would be, and the bottom edge doesn't reveal it); the dock and island editor shows both
  at their edges, no card.
- Full-width sheets (user's review): the sheet spans the screen (less its margins); each tab
  lined its settings up side by side at their own widths (a SheetGrid of SheetItems: the name on
  top, the control under it; both replaced by tiles, below), picture cards keeping their size,
  a scrolling row the whole row. (First tried: equal cells stretched to the sheet's width;
  labels ended up far from their controls with gaps between, user: "horrible".) Lock screen
  editor (user's review): the clock's style and font cards are taller (`ChoiceCards.cardHeight`)
  with place, size and show stacked beside them. Picture: a titled row of larger pictures that
  fades out at its end (`ChoiceCards.fadeColor`), a divider, and blur and darkening as sliders
  (their values in the titles), the row and sliders the same height. Desktop editor (same
  review): a titled row of larger wallpapers fading at the end; color styles as segments, all
  colors in one row; the widgets as on/off cards with a small look at each, like the iOS widget
  gallery (`ChoiceCards.chosenValues` for several at once); glass's solidity as a slider and
  the blur styles as segments; shell and text size stacked, then fonts, then icons. Then (user's
  review of all tabs): every setting's header keeps a line for its subtitle (one line, cut
  short), so the controls in a row start at the same height; a row that fits is centered in
  the sheet; glass's switch and solidity are one setting; the widget cards are larger.
- Tiles (user: "really look into how the UI should be designed"): the desktop editor's Widgets,
  Style, and Size and text tabs are rows of equal-height tiles filling the sheet
  (`customize/SheetTiles.qml`, `SheetTile.qml`; widths by weight), like Android's
  "Wallpaper & style" and macOS's Control Center modules: each tile has its title, a short
  note and an optional switch at the top, and a live preview with its control below. Widgets:
  a small copy of each widget (dimmed while off, click toggles) and a Places tile; Style: a
  panel at the glass setting over your wallpaper with its slider, the blur styles as chips
  (`OptionChip.qml`; the sheet itself shows the blur), a corner sample; Size and text: sample
  text with the two sizes, the fonts as "Aa" chips, the icon theme. Equal heights also keep
  the card above from jumping between these tabs. Then every other tab too
  (user's request): a tile can take its content's width (`natural`, the clock's cards) with
  the rest sharing what's left, a row can be taller (`tileHeight`), and `TileRow` holds a label
  and its control inside a tile with several settings. Lock screen: Looks, Style, Font, Place
  and size, Picture, Blur and darken. Desktop: Wallpaper, Light or dark, Accent, Color style
  (the nine as chips), Contrast. Dock and island: workspace dots drawn at your count, the
  island's clock as it will read with its switches, status icons; when the dock shows, icon
  size with sample icons at it, pinned apps. Windows: a sample window at your border width and
  corners, the effects, two windows at your gap between and a window in the screen at your
  edge gap, and the motion settings.
- Desktop widgets polish: one family like iOS's and Android's (`Theme.desktop`): a small square
  and a medium one twice as wide, the same height, corners and padding (`WidgetSurface.qml`).
  Clock (medium): the weekday in the accent, the time, the date. Weather (small): the
  temperature and sky icon at the top, the sky, high and low and the town below. Media
  (medium): the cover, track and artist, and previous, play and next (play in a filled circle;
  no progress bar: Spotify reports a frozen position). They fade and grow in when turned on
  and lift a little under the pointer; a drop near the screen's edges or another widget lines
  up with them (`DesktopWidgets.snapped`, tested). The desktop editor's Widgets tab shows the
  real widgets, scaled. `Editing` moved to `services/` (the editors now import `qs.desktop`,
  which imported `qs.customize` for it). A bug found on the way: on a hidden tab
  `SheetTiles` made its tiles millions of px wide and froze the shell (NOTES).
- Lock screen fix (user's find): a wrong password's message, in the field's column (anchored
  at its bottom), pushed the field up into the lines under the clock. The hints and messages
  now hang below the field in their own column, and in the top layout the field keeps a gap
  below the clock's column, moving down when a large clock with media and status lines reaches
  that far.

### Review of the editors and widgets (2026-10-30)
Two read-only reviews of everything since the editors began (user's pick), findings checked,
then fixed. No way past the lock screen's password was found (the grace period starts only
from the idle lock; every other lock ends it).
- Editors: one at a time (opening one closes another, keeping its changes; they share
  `Editing`); a shell reload with one open goes back to your workspace; the windows editor's
  Play timers stop on close, Play runs once at a time, and close works while it's still
  opening; each editor stays on the screen it opened on; the lock screen editor's Escape and
  Enter work (`LockContent.takesKeyboard`); "Desktop's" picture shows a video wallpaper's
  frame; the Clock tab's fonts scroll at larger shell sizes and tile widths can't go
  negative; keypad Enter picks an accent swatch or status chip instead of finishing the
  editor; value pickers are radio buttons to screen readers, only the editors' tab bars are
  tabs (`Segmented.tabs`); the island clock's sample follows 12/24-hour; the monospaced font
  has a tile again (it had no control left); `Colors.tint` for the tiles' shade; the unused
  frosted sheet and stale comments, tokens and search words removed.
- Widgets and wallpaper: the wallpaper is a plain item and only masked while it's a card
  (a `ClippingRectangle` always drew it through a screen-sized texture, a live wallpaper every
  frame); the card shows even without a wallpaper chosen; the default places no longer
  overlap (tested); widgets grow with the text size and the time shrinks to fit; their blur
  and input follow their own hover and fade scale; the drag handle is a grip to screen
  readers; no division by a window width of 0.
- Lock and login screens: in the bottom-left layout the field moves right to clear a large
  clock; when the top layout pushes it down it keeps room for the hints, messages and the
  message line. The login screen gets only the settings it uses (filtered by `greeter/sync.sh`
  with bun), and its shared folder is readable by the greeter alone (`ghost greeter` applies
  it; it was readable by every user).
- Cancel in the desktop editor goes back to Hyprland's default wallpaper when none was chosen
  before (fixed later the same day: `wallpaper.sh --none`, `Wallpaper.clear()`; the colors
  come from the last seed color, as before the editor).

### Quick settings editor (done, verified on the laptop 2026-10-30)
User's pick after the review: Android's edit mode, on the panel itself.
- Quick settings' wide tiles and round buttons come from two lists in your settings
  (`quickTiles`, `quickToggles`; until edited, what it showed before), made safe and edited by
  `controlcenter/QuickItems.js` (tested: unknown ids and repeats dropped, an empty list kept
  empty). Each tile and button is a component by id in `QuickSettings.qml`.
- The pencil in the bottom row turns on edit mode: the items wiggle a little, a badge in each
  corner removes it, dragging one onto another moves it there (`controlcenter/QuickSlot.qml`;
  with the keyboard Shift + Left / Right moves it, Delete removes it), and "Available" lists
  what isn't shown as chips to add. Reset brings the defaults back, Done or Escape ends it; the
  sliders and the bottom row step aside meanwhile.
- New round buttons to add: airplane mode, dark mode (light or dark by hand), record the screen
  (stops a recording, or opens the screenshot tool on Record), screenshot, wallpaper.
- The battery line in the bottom row ends in "…" before the buttons (the pencil made it run
  under them).
- An odd number of wide tiles: the last one takes the whole row instead of leaving half of it
  empty (user's find, 2026-10-31; the tiles are a `Flow`, since a `Grid` widens a column for it).
- Large and small wide tiles, like Android's (user's pick, 2026-10-31): in edit mode a badge in
  a tile's bottom corner (or Enter / Space) makes it large, the whole row, or small again
  (`quickLarge`; Reset makes them all small). A small one with no small one to pair with takes
  the row too (`QuickItems.fullRow`, tested).

### More desktop widgets (done, verified on the laptop 2026-10-30)
User's pick after the quick settings editor: more of the same family.
- Calendar (medium, like iOS's): the month in the accent, the day large and the weekday on the
  left, the next three events on the right (`Agenda.upcoming`, "Today 14:00" from
  `Agenda.when`); without a calendar, how to add one. Clicking it opens the today menu.
- Battery (small, like iOS's batteries widget): a ring filling with the charge around the
  battery icon, the percentage and the time left or until full; the error color when low. Only
  on a machine with a battery.
- To-do (medium, like Reminders): the today menu's tasks not done yet, three at most and
  "+N more"; clicking one ticks it off, the heading opens the today menu (where tasks are added).
- Their default places are a second column beside the first three (tested: none of the six
  overlap on a 1920 x 1080 screen). The desktop editor's Widgets tab is now a gallery of the
  real widgets, scaled, in one row that scrolls (click one to put it on the desktop or take it
  off; a check under the ones that are on), beside the Places tile: six tiles with switches
  would have been too narrow.

### Lock screen widgets (done, verified on the laptop 2026-10-30)
User's pick: an iOS-like row of small widgets under the clock, picked in the lock screen editor.
- `lock/LockWidget.qml`: round widgets on a translucent circle with the glass edge: weather (sky
  icon and temperature), battery (a ring with the percentage, a bolt while charging, the error
  color when low), notifications (how many, never what they say), to-do (how many are open),
  and a wide one for the next event (when, then its title). They replace the lines under the
  date (LockLine, removed); the media player stays above them. In the bottom-left layout the
  row starts at the left like the clock.
- `lockWidgets` in settings: your order, up to four (`lock/LockWidgets.js`, tested). Until
  you pick, the old switches (weather, battery, event, notification count) decide, so nothing
  changes on its own.
- The lock screen editor's new Widgets tab: the widgets themselves, click to add or take off,
  a number on each shows its place in the row; the media controls' switch beside them. Both
  left Settings -> Lock screen, which keeps the message, the grace period and the login screen.
- The ring is shared with the desktop's battery widget (`widgets/ProgressRing.qml`).
- Follow-ups (user's request): in the tab the ones that are on come first, in the row's
  order, and dragging one onto another moves it there (Shift + Left / Right with the keyboard;
  tested); on the lock screen in the card, the player and widgets are outlined like the
  clock, and clicking them opens the Widgets tab (`customize/EditOutline.qml` for both). Verified on the laptop, with the desktop editor's Cancel fix.

### Themes (done, verified on the laptop 2026-10-30)
User's pick: saved looks for the whole desktop, like Android's themes.
- The desktop editor's first tab, Themes: your saved looks as picture cards (the wallpaper with
  a chip showing the accent color and "Aa" in the theme's font); clicking one sets its settings,
  then its wallpaper (which remakes the colors with them). Beside it, "Save as a theme" (named
  Theme 1, 2, ...; off while the look already is a saved theme) and "Delete" for the current one.
- A theme is the wallpaper (or none) and the colors (light or dark, style, contrast, accent),
  the glass, blur style, corners, fonts, icon theme and the desktop widgets with their places;
  not the shell's and text's sizes (`customize/Themes.js`, tested: saved lists made safe, names,
  which theme the desktop matches now). Saved in `themes` in settings.json; the editor's Cancel
  doesn't undo saving or deleting one, only the look.

### Dock: drag to reorder (done, verified on the laptop 2026-10-30)
User's pick. Like macOS: drag an icon along the dock and let go where it should be among the
pinned apps (its middle decides; `DockApps.placePin`, tested); a running app that isn't pinned
dropped among them is pinned there; dragged up more than the dock's height, a pinned app fades
and says "Remove <app>", and letting go unpins it. A drag never counts as a click, the
previews stay away meanwhile, and the dock stays shown while the pointer is above it. The
right-click menu's Move left / right stay; the dock and island editor's note now says to drag.

### Timer everywhere (done, verified on the laptop 2026-10-30)
User's pick: the today menu's timer (`services/Countdown.qml`, which now keeps the length it
started with for a ring, and the last length used) in more places:
- Quick settings: a "Timer" round button to add in edit mode; it starts the last length (5
  minutes at first), and while the timer runs pauses and resumes it; its name says the time left.
  Cancelling stays in the today menu.
- Desktop: a small timer widget: 1, 5, 15 and 25 minutes to start; running, a ring emptying
  around the time left, with pause or resume and cancel. In the editor's gallery and themes.
- Lock screen: a round timer widget (its icon, or a ring around the time left), picked in the
  lock screen editor's Widgets tab like the others.

### Review of the day's later work (done, verified on the laptop 2026-10-30)
Two read-only reviews of everything since the editors' review (quick settings editor, more
desktop widgets, lock screen widgets, themes, dock dragging, the timer), findings checked, then
fixed:
- Bugs: the lock screen showed a battery at 0 % on a machine without one (the old switch was
  on by default); applying a theme, or Cancel, ran wallpaper.sh twice side by side (the
  wallpaper's run read the old color settings), now the wallpaper waits for the color run
  (`Wallpaper.run`), and Cancel and themes compare with the wallpaper asked for while it's on
  its way (`Wallpaper.target`; a video's frame takes a moment); a dock drag cut short (a window
  of the app opening) left the dock shown for good; quick settings without a Bluetooth adapter
  kept an empty place; a theme's values are applied only where they fit the setting
  (`Themes.applicable`, tested) and a theme with none of its own is dropped; video themes'
  cards use their thumbnail.
- Structure: one list of desktop widgets (`DesktopWidgets.js` `kinds`) that the editor's
  Cancel, themes and the widgets' layer take their keys from; moving items in an ordered list
  is `widgets/OrderedList.js` (quick settings, lock screen widgets, dock pins; tested); the
  dock's drop rule is `DockApps.dropIndex` (tested); quick settings' items are one table (name,
  icon, control); the timer's lengths are `Countdown.lengths`; sizes that were numbers in the
  widgets are Theme tokens and the lock screen widget is a `Surface`.
- Accessibility: round buttons' keyboard ring is round in edit mode, the widget gallery
  scrolls to the one Tab reaches, the calendar and to-do widgets' links are buttons to screen
  readers, "1 notification" and "1 to-do" read right.
- Fixed after (user's request): a theme's card color is the accent as made, not mid-fade
  (`Colors.primaryTarget`); a theme whose picture is gone shows dimmed with "picture gone" and
  isn't applied; Cancel puts saved, renamed and deleted themes back too. Themes can be renamed
  (the name field beside the gallery while one is current; `Themes.renamed`, tested: an empty
  or taken name is ignored).

### Lock screen: drag the clock and widgets (done, verified on the laptop 2026-10-30)
User's pick. In the lock screen editor the clock's and the widgets' outlines can be dragged (or
moved with the arrow keys while one has the keyboard), each on its own (user's choice after
trying them as one group): the clock with its date (`lockClockOffset`) and the player with
the widgets (`lockWidgetsOffset`) move from their place, as fractions of the screen, so the
login screen follows and a resolution change keeps them. Each stays on the screen and never
covers the
password field with its hints: where they would, they stop just above it, and beside it they
may go lower (`LockClock.offset`, `clamped`, tested). Picking a Place or a look starts again
from that place; Cancel puts the old one back.

### Presets in every editor (done, verified on the laptop 2026-10-30)
User's request. Each on-screen editor opens on a Looks tab: its presets as picture cards drawn
on your wallpaper (`customize/LooksTile.qml`, shared with the lock screen's looks; "Yours"
first, see the fix below). Picking one sets its settings at once; each can still
be changed after, and Cancel puts the old ones back (`customize/Presets.js`, tested: each sets
only its editor's settings, with values its controls offer, none twice).
- Desktop (style over your wallpaper, accent and widgets: glass, blur, corners, color style
  and contrast): Ghost (the defaults), Frosted, Vivid, Calm, Solid, Sharp. The card: a panel in
  the look's glass and corners.
- Dock and island: Ghost, Minimal (dots only in use, fewer status icons, small dock), Desk (the
  dock always shown and larger, the day in the island), Everything (eight dots, day and
  seconds). The card: the island as it would read, and the dock (faint while it waits at the
  edge).
- Windows: Ghost, Tight, Spacious (wide gaps, a glow), Playful (turning border, glow, wobble,
  their own borders for floating windows), Still (no motion). The card: two windows at the
  look's gaps, corners and border.
- `Presets.current` compares lists by their contents (the hidden status icons), and `apply`
  copies them, so editing your settings after never changes a preset.
- Widget combinations and places too (user's request: presets are also which widgets and
  where). The desktop editor's Looks tab has Style beside Widget layouts: Clean (none), Glance
  (time and weather, top left), Focus (time, timer and to-do along the top), Music (player
  bottom left, time above, weather beside), Workday (a column on the right: time, events,
  tasks, battery), Everything (all seven, two columns). Places are laid out in px on a
  1920 x 1080 screen and kept as fractions (`Presets.widgetLayout`; tested: on the screen,
  clear of the island and the dock, none over another). Their cards draw the widgets at their
  places. `DesktopWidgets.kinds` now says which widgets are medium.
- The lock screen's looks bring their widgets: Classic (weather, battery, notifications),
  Minimal (none), Analog (weather, notifications), Bold (four), Editorial (weather), and a new
  Split (the clock in the bottom-left corner, weather, battery, notifications and the timer
  apart to the right, through `lockWidgetsOffset`). Never the next event: its title would
  show to anyone at the screen (tested). The cards show each look's widgets as dots under its
  clock.
- Fix (user's find: picking a preset fell back to "Yours", and the galleries didn't show all
  their cards): settings.json is written with object keys sorted, so a layout's widget places
  came back in another order and no longer matched (`Presets.same` compares by content, also
  for saved themes; tested), and the "Yours" card coming and going rebuilt the row under the
  pointer. "Yours" now always comes first and means your settings from when the editor opened:
  picking it goes back to them (only what that gallery sets).
- Fix (user's find: a preset still fell back to "Yours" and wasn't quite the one picked):
  Settings saved after every change in the background and re-read its file after each save,
  so of a preset's dozen values, some came back old (reproduced: three of six kept). It now
  saves once per burst, synchronously, and doesn't re-read while a save waits (all kept). Also
  a list read back from the file isn't a JavaScript Array, which `Presets.same` now handles
  (the lock and dock presets hold lists).

### Customize menu and keyboard in the editors (done, verified on the laptop 2026-10-30)
User's request: a key for choosing what to customize instead of the launcher or Settings, and
the keyboard built into the editors' design.
- Super+U (`qs ipc call customize menu`): a card over the dimmed screen with a tile per editor
  (lock screen, desktop, dock and island, windows) and quick settings (opened in its edit mode:
  `qs ipc call island editQuickSettings`). The first tile has the keyboard: arrow keys move,
  1-5 jump straight to one, Enter or Space opens, Escape or a click outside closes; the keys
  are shown under the tiles as key caps (`customize/CustomizeMenu.qml`).
- Every editor (`EditorChrome`): the arrow keys move to the nearest control that way, on the
  sheet and on what the card shows (the lock screen's outlines), like the island's menus;
  Enter or Space use it; Ctrl+Tab / Ctrl+Shift+Tab (or Ctrl+Page Down / Up) switch tabs;
  Ctrl+Enter is Done and Escape Cancel from anywhere (shortcuts, so a focused control can't
  take them); a row of key caps at the sheet's foot says so. A card Tab or an arrow reaches in
  a sideways row scrolls into view (`ArrowNavigation.reveal` now scrolls sideways too).
- The key caps are one widget (`widgets/KeyCap.qml`) for Settings -> Keybinds, the welcome
  tour, the editors and the menu. The welcome tour's "Make it yours" card names Super+U.

### Smooth changes (done, verified on the laptop 2026-10-30)
User's pick. Picking a preset, a theme or a layout glides instead of jumping:
- the panels' glass (how see-through, the edge) eases to its new value (`Colors.panelAlpha`,
  `edgeAlpha`, under the recolor fade the colors already had);
- desktop widgets glide to new places (a widget layout, "Put them back", lining up after a
  drop), while a drag still follows the pointer;
- the lock screen's clock and widgets glide when a look or the arrow keys move them
  (`EditOutline.stepped`; the clamping is `LockContent.clockShiftFor`/`widgetsShiftFor`).
Corner radii and sizes still change at once: easing them would lay the whole shell out again
every frame.

### Your own looks (done, verified on the laptop 2026-10-30)
User's pick. The Looks galleries of the lock screen, dock and island, and windows editors, and
the desktop's widget layouts, keep looks of your own after their presets
(`customize/SavedLooks.js`, tested; `lockLooks`, `dockLooks`, `windowLooks`, `widgetLooks`):
the last card, "Save this look", keeps the settings now as "My look N" ("My layout N");
picking one sets it like a preset; while one is chosen the gallery's header has its name to
change (Enter; a taken or empty name is ignored, a preset's too) and a delete button. A lock
look keeps everything about the lock screen (clock, picture, blur and darkening, widgets and
their places, media controls), a dock look all of the dock and island editor's settings, a
window look all of the windows editor's. Cancel puts the saved looks back too. The desktop's
own style keeps using themes (with the wallpaper).
- Changed (user's review): "Yours" is gone; the galleries with looks of your own start with
  an empty "New look" card, the chosen one while your settings match no look, which saves them
  as a new look (any number; before, Save only showed while nothing matched, so after one look
  it seemed limited to one). A look of yours is edited in place, like an iOS lock screen:
  while it's chosen, a change is saved into it a moment later, so it stays chosen; presets
  stay fixed. Yours are listed (and matched) before the presets. Each editor closes before
  Cancel puts its settings back, and the gallery only saves while its editor is open
  (`LooksTile.live`), so Cancel can't save the old settings into a look.

### Review of the presets, menu and keyboard work (done, verified on the laptop 2026-10-30)
Two read-only reviews of everything since the last review, findings checked, then fixed:
- Keys: Enter in the editors' name fields (themes, your looks) also pressed Done, and Escape
  cancelled the whole editor; `TextField` now keeps Enter, and with `keepsEscape` Escape only
  puts the name back. A rejected name (empty, taken) shows the old one again. The lock screen's
  outlines, outside the editor's frame, swallowed Escape and Enter and kept the arrow keys:
  now the plain arrows move on (`EditorChrome.navigate`), Shift + arrows move the part (in the
  hints), Enter opens its tab, Escape cancels; their instructions are an accessible description.
- Looks: "Save this look" made a copy that could never be chosen when the look already matched
  one; it's only offered while none matches. "Yours" put back only what the presets set, not
  all a saved lock look sets (the picture, media controls). The Save card is a button to screen
  readers.
- Moves: letting go of a drag counted it twice for a moment and glided back from there, on the
  lock screen and the desktop (a `settling` flag keeps the glide off while it's saved); a click
  with a wobble on an outline is no longer saved as a move (which broke a look's match). The
  lock editor's four move functions are one (`movePart`).
- Quick settings from the customize menu: it closes an open editor first; the edit flag is
  set after the screen (on two screens the other one's quick settings took it) and watched,
  so it also works while quick settings is open and never lingers for the next Super+N.
  Super+U closes the menu again.
- Structure: the cards' picture is drawn once by `LooksTile` (`picture`), not by each editor's
  art; the key hint rows are `widgets/KeyHints.qml` (`EditorChrome.extraHints` for an editor's
  own keys); themes rename and delete through `SavedLooks`; `Presets.plain` turns a list read
  back from settings.json into an Array for both; `Colors.sketch` for the cards' small widgets;
  the glass look's card shows its own edge and solidity (`Theme.surfaceOpacity`); the dock and
  island look's clock follows 12/24 hours.
- Also: launcher entries "Customize" and "Edit quick settings", search words, and the login
  screen's copy of the settings leaves out your saved lock looks.
- A clock or widgets dragged to the very bottom of the login screen could sit over its power
  buttons and message line: fixed after (user's pick): they're kept clear like the field
  (`LockClock.clamped` takes several rects, `LockContent.keepClear`; tested), only where the
  part would cover one, so the bottom-left clock beside a centred message stays put.

### A grid for the desktop widgets (done, verified on the laptop 2026-10-30)
User's request: a grid to place widgets symmetrically. The desktop editor's Widgets tab, Places:
a Grid switch and its size (16-64 px at 100 %; `desktopGrid`, `desktopGridSize`, put back by
Cancel). While it's on, faint lines show over the desktop while the editor is open or a widget
is dragged, running out from the screen's middle (the middle lines stronger), and a dropped
widget lines up its start, middle or end, whichever is nearest, with a line on each axis
(instead of the edges and neighbours it lines up with otherwise). Lines out from the middle
mean a widget and its mirror image land mirrored, and a medium widget can sit centred on the
screen (`DesktopWidgets.gridLines`, `gridSnapped`, tested). The lines are one screen pixel at
any scale (in the editor's shrunk card a 1 px line fell below a pixel and some faded out,
user's find).

### Desktop widgets by keyboard (built 2026-10-30)
User's pick (a gap the review found: the lock screen's parts took the keyboard, the desktop's
widgets didn't). The desktop widgets' layer never takes the keyboard, so it goes through the
editor: in the Widgets tab, a widget's card in the gallery that has the keyboard outlines that
widget on the desktop (`Editing.widget`), and Shift + arrows move it, a grid step at a time
while the grid is on (a step from a line lands on the next one), else 48 px, kept on the
screen (`DesktopWidgets.nudged`, tested). The hint row says so on that tab
(`EditorChrome.extraHints`).

### Themes and looks across machines (built 2026-10-30)
User's pick. `ghost looks export` writes this machine's themes and every editor's own looks
(`themes`, `lockLooks`, `dockLooks`, `windowLooks`, `widgetLooks`) into the repo as
`looks.json`, the home folder written as "~" (a theme's wallpaper, a lock look's picture), to
commit and pull elsewhere; `ghost looks import` merges it in there: the same name replaces,
new ones are added, the others stay (`customize/LooksFile.js`, tested; bun loads the same file
in `modules/core/looks.sh`). While the shell runs, the import goes through it
(`qs ipc call customize importLooks <file>`), since it owns settings.json then; otherwise into
the file. The desktop editor's Themes tab has Export and Import buttons for the same, with a
notification saying what happened. A look whose picture isn't on the other machine shows as
"picture gone" until it is.

### Performance check after the editors (done 2026-10-30)
User's pick, measured on the laptop:
- Idle CPU: about 0.3 % of one core (6 ticks in 20 s), with four desktop widgets on.
- The running shell after 15 minutes with editors opened and closed: 559 MB resident, 432 MB
  proportional (a fresh one was 393 / 289 after the optimization round; restarting it to
  compare like for like wasn't possible from here).
- No leak in the editors: a scratch lock screen editor opened and closed 50 times went up and
  down between 222 and 290 MB proportional (the JavaScript heap and the allocator), not up
  and up.
- The desktop widgets' layer is the one always-on addition: a second surface costs ~11 MB
  whatever its size; your four widgets (clock, calendar, battery, to-do) ~35 MB more with the
  services already loaded, ~12 MB for the first one alone (the cards' and big text's first
  drawing), so mostly shared. The layer only exists while a widget is on.
- Nothing trimmed: no part costs more than what it shows.

### Lock screen: every part on its own, the field too, a battery gauge (built 2026-10-30)
User's requests:
- Every part has its own place (user's picks: each widget, the player, the date apart from the
  clock): the clock, the date, the player, each widget and the password field are dragged (or
  moved with Shift + arrows) by their own outline in the lock screen editor, each kept on the
  screen and clear of the field with its hints, the power buttons and the message line (the
  field only of the bottom row). One setting, `lockPlaces` ({ part: { x, y } }, fractions);
  until it's set the old two moves count (the clock's for the clock and date, the widgets' for
  the player and widgets) and the first drag keeps them (`LockClock.placeOf`, `withPlace`,
  tested). Picking a Place starts every part from it again.
- How: a part moves itself (`lock/PartShift.qml`, a Translate that glides to a new place and
  follows a drag) and draws its own outline as a child (`lock/PartOutline.qml` around
  `widgets/EditOutline.qml`, moved there from customize/ since the lock module can't import
  the editors'), only while `LockContent.editor` is set; the lock screen then takes no other
  input. `LockStatus` gets the LockContent it's in (`lock`). The two outlines the editor drew
  over the card, and its move functions, are gone.
- The battery widget on the lock screen is a gauge like iOS's (user's choice): a thin ring
  open at the bottom (`ProgressRing.span`), the percentage in the middle, the battery or a
  bolt in the gap.
- Looks: two new ones that use the parts' places, Corner (a thin clock and the date top left,
  the widgets top right with the player under them) and Flanked (a bold clock with the weather
  and battery on either side), and Split moves its player and each widget. Each look was
  checked on the real lock screen (a scratch copy whose settings aren't written).

### More wallpapers (built 2026-10-30)
User's pick, for the art they like (anime and illustrations, not photos): `ghost wallpapers get
[search words] [--count N] [--general]` (`modules/core/wallpapers.sh`) fetches from wallhaven.cc's
public search API (no account): the month's best anime, or the best matching the words, at
least 1920x1080 in 16:9, never anything but its safe-for-work purity (the filter is fixed, and
each result is checked again: SFW, a JPEG or PNG, wallhaven's own file host), N new ones (12 by
default, 1-48; ones already there are skipped, files named wallhaven-<id>) into your wallpaper
folder (Settings' wallpaperFolder), never the repo. --general adds illustrations and scenery.
The desktop editor's Wallpaper tab has a "More art" tile: search words (optional) and Get 12,
then the gallery has them and a notification says how many came. Tried into a scratch folder:
downloads, skips what's there, searches.

### Wide lock screen widgets (built 2026-10-30)
User's pick, like iOS's rectangular ones: "Weather, wide" (the sky's icon, the temperature large,
the sky and today's high and low) and "Battery, wide" (a bar filling with the charge, the
percentage and the time left or until full), in the lock screen editor's Widgets tab. Twice as
wide as the round ones, like the next event, but one of the four (`LockWidgets.known`). Machines
without a battery get neither battery widget.

### Review of the lock screen restructuring and the rest (2026-10-30)
Two read-only reviews of everything since the presets review, findings checked, then fixed:
- Bugs: the More art tile sat inside the Wallpaper tile (one brace short); in the editor the
  player's outline couldn't be dragged or focused (the disabled card disabled it: the card is
  now in a holder with the outline beside it); old lock offsets on a machine that still had
  them came back with a look or a Place pick (looks, the Place picker and the first drag now
  clear them, and Cancel and saved looks keep them); looks imported while an editor was open
  were undone by its Cancel or saved over by the look being edited (they now join the editor's
  "before", and a gallery whose list changes from elsewhere stops editing); a wrong password's
  shake was cancelled by the clamp at an edge and made parts beside the field jump (the field's
  place leaves the shake out); a part with no room above a field dragged near the top now goes
  under it (tested); the field's hints glide with it.
- `wallpapers.sh`: a picture's id must be letters and digits and its extension comes from its
  type (a JPEG or PNG), `--` ends the options (the search field's words can start with --),
  `--count 08` works, failed downloads are counted. Imports: a file that can't be read says so,
  names are taken once, the count is of what's merged, a second import waits for the first.
- Structure: `GlideTranslate` (the glide shared by PartShift, the field and its hints);
  `LockWidgets.names` and `available` (screen readers hear "Battery, wide", not an id);
  `js_with` in modules/lib.sh runs a QML JavaScript library from bun for `ghost keybinds` and
  `ghost looks`, paths through the environment; `SavedLooks.followed` and
  `DesktopWidgets.keyStep` hold the rules the gallery and the keyboard move used (tested); the
  wide weather measures its temperature instead of guessing its width; "under the clock" is
  gone from names and comments now that parts go anywhere.
- Not done: the lock looks' preview cards draw wide widgets as dots and don't show a moved date
  or player.

### Lock screen: the quiet side of the picture (built 2026-10-30; untested on the laptop)
User's pick, after looking at how Ryoku handles wallpapers (its wallpaper tone map measures where
a picture is calm for the widgets floating on it). The lock screen editor's Clock tab, Place and
size: "Quiet side" (`lockQuietSide`, off by default; looks and Cancel keep it). While it's on,
the lock and login screens measure their picture once: ffmpeg makes a 48 px wide grey copy
cropped to the screen's shape, `od` prints it, and `LockClock.quietSide` compares how busy the
outer thirds are (the mean difference between neighbouring pixels; one side must be at least
1.5 times as calm). When the clock (or the date without it) sits on the busier side, every part
is mirrored across the middle (`LockClock.mirroredMove`, then the usual clamp), so the art's
subject stays clear; a centred clock or an evenly busy picture moves nothing. The editor shows
and drags the places as saved, never mirrored. Tested: `quietSide`, `sideOf`, `mirroredMove`
(qmltestrunner on the laptop: 316 pass), and the ffmpeg + od pipeline on a picture busy on the
left (quiet: right) and on the laptop's wallpaper (quiet: right, 0.13 s for a 4K picture).

### Wallpaper styles (built 2026-10-30)
User's picks of the kinds of anime art they like: `ghost wallpapers get --style S` fetches the
all-time favourites of one (words typed after narrow it): sky (scenery, big clouds, cities at
dusk, trains: "clouds"), lofi (cozy rooms, rain on windows: "indoors +window"), painterly
(painted illustration, anime or not: "digital painting" with general art too) and minimal (one
figure or shape and empty space, which suits the lock screen's quiet side: "+minimalism -text").
Each search was tried against wallhaven's API first, reading the tags of its top favourites
(plain words that turned out too small or off: "lofi" had 16 results, "scenery" 98; exclusions of
two-word tags like "-anime girls" return nothing). The desktop editor's More art tile has the
styles as chips (Top, the month's best, as before; Sky, Lofi, Painterly, Minimal) beside the
search field. Konachan was looked at and dropped (user: not the kind of anime they want).

### The Wallpapers window (done, verified on the laptop 2026-10-30)
User's choice: finding art belongs in its own window like Settings, not in the desktop editor.
`wallpaper/WallpaperBrowser.qml` (a `FloatingWindow`, "Wallpapers"): a search field and the
styles as chips (Top, Sky, Lofi, Painterly, Minimal), wallhaven's results as pictures in a grid,
more pages as you scroll to the end (and while the pictures don't fill the window, so a
maximized one isn't stuck at one page; user's find), or "Load more" at the end; a check on the
ones in your folder already. Click one (or
arrow keys and Enter) for a larger look: the thumbnail at once, the full picture over it; Left and
Right step through, Escape goes back; Download, or Set as wallpaper (downloads first). Nothing is
downloaded until you pick it. Downloads run one at a time through `ghost wallpapers fetch <id>`,
which asks wallhaven for that picture and checks it again. The searches, the styles and the
checks on each result are one library, `services/Wallhaven.js` (tested), loaded by the window and
by `modules/core/wallpapers.sh` (js_with). Opened from the desktop editor's Wallpaper tab ("Find
wallpapers", which finishes the editor first: windows show under it), the picker strip's "Find
more", Settings -> Appearance, the launcher ("Wallpapers") and `qs ipc call wallpapers browse`.
The editor's More art tile with its styles and Get 12 is gone. The title bar is shared with
Settings now (`widgets/WindowTitleBar.qml`; `WindowButton` and `OptionChip` moved to widgets/).
- More like this and colors (user's pick): the large view lists the picture's tags (from its
  page in the API, asked for once it's shown 0.4 s, so stepping through quickly doesn't spend
  wallhaven's 45 requests a minute); clicking one shows the best pictures with that tag ("Like:
  clouds ×" in the search field; typing, a style or × leave it). wallhaven's own similar search
  (`like:<id>`) answers 403 without an account (checked), so it's a tag. A row of wallhaven's 29
  colors under the search narrows any search to pictures with a lot of one (its palette only; a
  color alone sorts by all-time favourites, since a month's best in one color is a handful).
  `Wallhaven.searchUrl` takes `{ words, style, page, general, tag, color }`; `colors`, `tags`
  tested.
- Yours (user's request): a Find / Yours switch at the top; Yours shows your folder's pictures
  in the same grid (the wallpaper you have now marked), with how many and Open folder. In the
  large view, Set as wallpaper, or Delete: to the trash (`gio trash`, so it can be got back; a
  picture's dark version with it) after a second click within 4 s (or Delete twice); not the
  wallpaper you have now. Checked in a scratch copy: the grid and the large view.
- The system's wallpaper collections are no longer offered (user's request: they included
  pictures the user didn't want, like headsets): the picker, the editors and the slideshow show only your
  folder (the slideshow's "From all pictures" is gone). `cachyos-wallpapers` and
  `nwg-shell-wallpapers` left the core module's packages; Hyprland's default still shows while no
  wallpaper is chosen.

### Presets placed around the art (built 2026-10-30; untested on the laptop)
User's request: better places and combinations for the presets. The README's screenshots show
none, so each lock look and widget layout was drawn as boxes at 1920 x 1080 over wallhaven art
in the user's styles (a centred figure at dusk, a rain window, a sky scene, a painted landscape;
the widget boxes exact, the lock ones estimated from Theme's sizes). Most lock looks stacked
the clock, player and widgets in the middle, over the picture's subject; Corner scattered its
parts (the widgets clamped to the top edge, apart from the player); Flanked's widgets floated
far from the clock. Changed (`customize/Presets.js`; tests pass, qmltestrunner on the laptop: 325):
- Lock: Corner is now Side (a thin clock, the date, the player and four widgets in one column on
  the left third; with the quiet side on it moves to the calmer side); Editorial in the
  bottom-left corner (a serif clock like a magazine cover); Minimal at the top instead of the
  middle; Flanked's widgets closer to the clock (13.5 % of the width instead of 17). Classic,
  Analog, Bold and Split as before. The lock positions are estimates: check each on the laptop.
- Desktop widget layouts: the corner ones 80 px from both edges (the tests keep widgets 80 px
  down, below the island's band); Workday centred top to bottom with the sky and battery side by
  side at its foot, so its edges are even; Everything as three rows across the top left, in the
  upper half (pictures often have their ground and subject lower down); a new Side (clock, sky
  and battery, player in a left column, centred top to bottom), the lock screen's Side on the
  desktop. Clean and Music as before (Music moved 16 px in to the same margin).

### Seamless login, logout and shutdown; dock icons at start (built 2026-10-30)
User's finds:
- Pinned apps in the dock showed the generic icon until they ran: the app list fills in a moment
  after the shell starts, and a binding on `DesktopEntries.byId(id)` alone never looked again;
  the dock's lookups now read the list too (verified with a throwaway `qs -p`, NOTES).
- Between the login screen and the desktop, and at logout and shutdown, tty1 showed Hyprland's
  log text and a cursor. Both Hyprlands' output now goes to the journal (`systemd-cat`:
  `journalctl -t hyprland`, `-t greeter-hyprland`; the greeter's launch and greetd's
  config.toml), and the kernel line gets `loglevel=3 rd.udev.log_level=3
  systemd.show_status=auto vt.global_cursor_default=0` (the system module, like
  `plymouth.enable=0`; a recovery login on Ctrl+Alt+F2 then has no blinking cursor either).
- At login Hyprland flashed its own default picture before the shell's wallpaper: with a
  wallpaper chosen, shell-settings.lua turns it off (`HyprlandConfig.lua`'s third argument,
  tested; written only once the wallpaper's file is read, so a start doesn't flip it), and
  matugen's colors.lua sets `misc.background_color` to the theme's surface color.
- Found on the way: shell-settings.lua was written in the background and `hyprctl reload` could
  read the old file, so a change sometimes applied only at the next one (`blockWrites`).
Needs `ghost install system` (greetd's config and the kernel line; sudo) and `ghost greeter`.

### The media widget stays (built 2026-10-31)
User's find: the desktop's media widget vanished whenever no music app was running. It stays
now: "Nothing playing", and play (or a click on it) opens the music app last heard
(`Media.lastApp`, Settings' `lastMediaApp`, remembered when a player whose desktop entry is in
the Music category starts playing; before that the first installed music app, Spotify here).
Checked in a scratch window with no player. Also: tooltips no longer warn while their window
doesn't exist yet (a null parent instead of undefined).

### Desktop widgets keep together at any size (built 2026-10-31)
User's find (shell size 85 %, text 90 %): the widgets shrank with the sizes but their places,
kept as fractions of the screen, didn't, so the gaps stayed full size and groups (a widget
layout, widgets lined up by hand) spread apart. Places are now kept as they'd be at 100 % and
zoom toward or away from the screen's middle by the widgets' own factor
(`Theme.desktop.zoom`, `DesktopWidgets.shown` / `dropped`, tested: neighbours stay neighbours,
the middle stays put, a drop gives back its place), for dragging, the keyboard's nudges and the
editor's layout cards too. Checked on screen at 85 % / 90 %.
Then (user's find at 125 % / 130 %): zoomed out from the middle, a group near an edge ran past
it and each widget was pushed back on its own, so they piled up. Widgets within two gaps of each
other at 100 % are a group (`DesktopWidgets.arrange`, tested), zoomed together and shifted back
onto the screen as one. Also there: the Size tile's size choices ran into the next tile;
`Segmented.maxWidth` shrinks its segments and their labels to fit (measured with FontMetrics;
reading its own width made a binding loop).

### Settings, Wallpapers and Customize grow out of the launcher (built 2026-10-31)
User's request: not separate windows and a separate menu, but integrated with the search bar,
at different sizes, still able to go full screen (user's picks: grow out of the launcher, three
sizes, the customize tiles under the empty search, the old windows replaced).
- The launcher (`launcher/Launcher.qml`) is one see-through surface over the whole screen that
  takes input only on its card (`mask`), so the card can grow smoothly between the search bar
  and a page. Its state is `services/LauncherState.qml` (open, page, Settings' page, the
  customize focus; kept across reloads), which the rest of the shell uses to open it.
- Pages: Settings (`settings/SettingsView.qml`, was SettingsWindow; the page list and its search
  in `SettingsPages.js`, tested) and Wallpapers (`wallpaper/WallpaperBrowser.qml`, now a plain
  item the launcher keeps for as long as the shell runs, so results and downloads survive
  closing it). The header has Back, the page's name, smaller / larger and close. Sizes
  (`launcherPanelSize`, remembered): compact (the search bar's width: Settings shows its list,
  then a page on its own; Back returns to the list), large (1040 x 680 at 100 %, a sidebar beside
  the page) and full (the screen below the island). Ctrl+Up / Ctrl+Down too; Escape goes back,
  then closes.
- The search finds Settings' pages (up to three, after the apps, from two letters) and has
  "Settings" and "Wallpapers" entries. Super+I, quick settings' gear, `qs ipc call settings
  open|page <id>` and `wallpapers browse` open the launcher on them.
- Customize: with nothing typed, five tiles above the apps (lock screen, desktop, dock and
  island, windows, quick settings); Up from the top of the list or Super+U (`customize menu`)
  gives them the keyboard, Left / Right move, Enter opens, typing goes to the search; Super+U
  again closes. `customize quick` closes an open editor before quick settings' edit mode. The
  menu (`CustomizeMenu.qml`), `WindowTitleBar` and `WindowButton` are gone.
- It steps aside when a window takes the focus (an app or folder opened from it) and when an
  editor opens. Checked on screen: the tiles, Settings large and compact, Wallpapers large and
  full.

### Review of the whole shell (2026-11-03)
Eight read-only reviews (the island and menus; windows and Hyprland; launcher, Settings, editors
and wallpaper; lock, login, setup and capture; the seams between features; a full scan of the
Quickshell 0.3.2, Hyprland 0.57 and Wayland docs; the boot to the desktop; the screen's layout and
the island), findings checked, then the confirmed bugs fixed (user's request):
- Setup: the gaming, Spotify and Zen modules' "Skipped" messages ran `ghost install` again
  (unescaped backticks), recursing forever on a new machine.
- Bluetooth: the adapter stays pairable only while the Bluetooth page pairs (bt-agent accepts
  every pairing; it was left pairable for good).
- Editors: switching straight from one to another kept the empty workspace as "home".
- Touchpad off with a mouse: turned off again after every Hyprland reload.
- Colors: a color scheme run waits for a wallpaper run in progress (the old colors could win).
- Screenshots: a changed folder is made, a failed save says so. Screen time doesn't count
  while locked. Weather retries after a failed first lookup. A late cover download can't
  replace the playing track's. Emoji picked quickly are all pasted. The island's status icons
  reach screen readers. Super+drag over a floating window no longer acts on the tiled window
  under it. Pictures named with # ? or % show (`services/FileUrl.js`, tested). Trashing the lock
  screen's picture puts it back to the desktop's; the slideshow waits in the editors and the
  Wallpapers page; clipboard thumbnails go with their entries; notification times, Do Not
  Disturb, Keep awake and the low battery alert's state survive a shell reload; a recording
  holds off the idle lock; the lock screen clears the typed password after every try; a
  wallhaven search that never answers fails after 20 s.
- Fixed after (user's pick): the login screen's Hyprland no longer runs a Lua file your user
  writes (a copy of shell-settings.lua, as the greeter user): the shell writes what it needs as
  key=value data (`~/.config/hypr/greeter-settings`, `HyprlandConfig.greeterData`, tested) and
  the root-owned greetd config checks every line.
- Fixed after (user's pick): chosen tiling arrangements survive a `hyprctl reload` (see "Tiling
  with our own layout").
- Game mode and the low battery's power saver (user's pick of the rule): a low battery wins and
  each puts back only what it set (`services/PowerModes.js`, tested). Game mode leaves power saver
  on while the battery is low, the saver remembers your mode from before game mode, plugging in
  goes back to it (or to Performance while game mode is still on), and turning game mode off
  puts your mode back only while it's still in Performance. Before, each restored its own saved
  mode and one undid the other.
- The dock (user's pick): running apps that aren't pinned keep the order they opened, like a
  taskbar (they moved left whenever one was focused); each app's windows stay most recently used
  first for its clicks (`DockApps.items`' `opened`, tested).
- Apps' bell (user's pick: Hyprland's own sound): Hyprland 0.57 plays the system bell itself;
  `misc.bell_sound` is "default" only while the shell's sounds would play (Settings -> Sound,
  notifications on) and "none" during Do Not Disturb and game mode (`HyprlandConfig.bellLua`).

### Boot straight to the lock screen (built 2026-11-03; needs `ghost install system`, `ghost greeter` and a reboot to test)
User's pick after the review measured the boot (HP logo gone at Limine, ~4 s of a black or
frozen screen, three screen mode sets, a black flash between the login screen and the desktop):
- greetd's `initial_session` logs you in at boot straight into your Hyprland (one compositor, no
  login screen's Hyprland in between) with `GHOST_AUTOLOGIN=1`, and it locks at once: the shell's
  lock screen comes up first (`lock/Lock.qml`), and hyprland.lua loads no keybinds until it's up
  (the shell marks `$XDG_RUNTIME_DIR/ghost-autologin-locked` once Hyprland confirms the lock, then
  reloads). If the shell hasn't locked within 15 s, hyprlock does. The disk isn't encrypted, so the
  login screen protected nothing more than the lock screen. After a logout the login screen runs
  as before. The user name is filled in by the system module.
- Limine (system module, at the top of limine.conf): `firmware_logo: yes` (the HP logo stays when
  Limine hands over), `quiet: yes` (the menu only on a key during the timeout), `timeout: 1`.
  `splash` left the kernel line (Plymouth's; unknown to the kernel).
- The login screen's Hyprland starts on the theme's background color (`greeter/sync.sh` writes it
  as rrggbb into the shared folder; the root-owned config checks it), and the login screen fades
  to it before your session starts on the same color.
- To check after a reboot: the logo stays until the lock screen, `cat
  /sys/firmware/acpi/bgrt/status` is 1, logging out shows the login screen, `sudo head -5
  /boot/limine.conf` still has the three options after a kernel update.

### From the platform docs scan (built 2026-11-03)
User's pick of the full Quickshell 0.3.2 / Hyprland 0.57 docs scan's small items:
- The volume and brightness pop-up shows over the lock screen (layer rule `above_lock = 1`);
  the password prompt and Proton Pass are black in screen shares (`no_screen_share`).
- Settings -> Keyboard and mouse -> Pointer: hide while typing (`cursor.hide_on_key_press`) and
  hide when still (`cursor.inactive_timeout`, 3-30 s; `HyprlandConfig.cursorLua`, tested).
- Quick settings' Power mode says why Performance is slowed (too hot, on your lap) and which app
  holds a mode (`PowerProfiles.degradationReason`, `holds`; `PowerModes.note`, tested); the
  System page has the battery's health and the watts it uses or charges at
  (`UPowerDevice.healthPercentage`, `changeRate`; `BatteryTime.details`, tested).
- The Wi-Fi page says when Wi-Fi is off by the laptop's key (`Networking.wifiHardwareEnabled`).
- Apps' bell through Hyprland's own sound (see the review above).
- Not taken: `HyprlandWorkspace.hasFullscreen` (Hyprland's flag likely counts maximized windows,
  which "quiet while fullscreen" leaves out on purpose; untested). The sign-in hint already used
  `Networking.checkConnectivity()`. Hyprland 0.57.1 (fixes a lock screen error when a screen is
  unplugged) comes with the next system update.

### One island, notifications in the corner (built 2026-11-03)
User's picks from the layout research (the volume pop-up stays where it is):
- Notifications popped up in the top-right corner of the focused screen for a day
  (`bar/PopupStack.qml`, removed): up to three at once, with the attention card and the reload
  notice in the same stack, not waiting for menus. With the island down to the time, the corner
  didn't fit (user's review, 2026-11-04): notifications pop out of the island again, one at a
  time, then a window asking for attention (see the decision "Notifications from the island");
  a reload shows "Reloaded" in the time's place, and a failed one opens the island with the
  error (`IslandViews.shown`, tested).
- First built as three pills (workspaces left, time middle, status icons right; the side ones in
  the top corners when attached). The user's review the same day: quick settings belonged in the
  middle, and workspaces, status icons and background apps in the island (or beside it) looked
  uneven. Now one shape (`bar/IslandPill.qml`) under the webcam with only the time (or the
  music's cover) and alerts beside it (`bar/IslandAlerts.qml`: a recording, the timer, the
  microphone, camera or screen in use, a low battery). A click opens today (or media), a
  right-click quick settings (`IslandButton.secondaryActivated`); it morphs into every menu.
- Workspaces: the dots take the time's place for 1.2 s after the workspace changes
  (`Theme.island.workspaceFlash`; longer while the pointer is on them, to click one), and
  scrolling over the island steps through them. All of them and the minimized windows are in the
  overview (Super+Tab); the hover numbers (`WorkspaceNumbers`) are gone.
- Status icons (Wi-Fi, Bluetooth, VPN, airplane, updates, muted) and the battery with its
  percentage are quick settings' top row (`controlcenter/StatusIcons.qml`, `BatteryPill.qml`);
  background apps open from a button in its bottom row (while there are some). The dock and
  island editor's Status icons chips hide them there (and the island's timer).
- Floating by default: a gap above, rounded all round. Attached (the dock and island editor's
  Style, `islandAttached`): it grows out of the top edge as before. The outline is an SVG path
  from `bar/PillPath.js` (tested); `Theme.island.reserved` (gap + height) is what the menus'
  cards, the OSD at the top, the wallpaper strip, launcher, overview, editors and window menu sit
  below.

### The lock screen is your desktop, locked (built 2026-11-04)
User's picks after booting straight to the lock screen: the lock screen should feel like the
desktop, not a screen of its own, and the login screen and the lock screen editor can go.
- The island lock (`lock/LockIsland.qml`): the desktop's island in its place, a lock and the time,
  opening into the password field like its menus (open while something is typed, checked or said,
  and for 10 s after a key or pointer move; the field keeps the keyboard while closed, so the
  first key opens it and counts). A wrong password shakes it; caps lock and the layout show in it.
- The rest is the desktop (`lock/LockContent.qml`): its wallpaper (a live one's still frame),
  sharp, and its widgets at their places on the first screen (`desktop/WidgetStage.qml`, shared
  with the desktop's layer, `locked`): only the media widget takes clicks, the calendar shows
  "Event" for each title and the to-do only how many are open. Hyprland's blur can't reach inside
  the lock surface, so the island and the cards are glass over a blurred copy of the wallpaper,
  masked to their shapes. Settings -> Lock screen keeps the message line and the grace period.
- Gone: the lock screen editor and its looks, the big clock and date, the picture choice, blur
  and darkening, the round widget row and moving parts (`LockClock`, `LockStatus`, `LockWidget`,
  `PartShift`, `PartOutline`, `GlideTranslate`, `MiniClock`, `EditOutline`, `lockLooks` and the
  `lock*` settings). The desktop editor's gallery gained a notifications widget
  (`desktop/NotificationsWidget.qml`: how many wait and from how many apps, never what they say).
  A widget turned on in the gallery goes where it's clear of the ones showing (user's find: the
  new one landed on their moved clock): its own earlier place if free, else beside, below, left
  of or above one of them, else the first free spot from the top left, all at 100 %
  (`DesktopWidgets.freePlace`, tested; a pixel of slack for rounded fractions).
- No login screen: greetd's `default_session` is your own session with `GHOST_AUTOLOGIN=1`, at
  boot and after every logout, locked at once (the greeter, its Hyprland, `ghost greeter`, the
  shared folder and `greeter/sync.sh` are gone; the system module removes their copies). The
  "locked once" mark that lets `hyprland.lua` load the keybinds is per Hyprland instance: the
  runtime folder outlives a logout for a few seconds, and the next session must not find it.
- Also: the Limine `ESP_PATH` read in the system module declares `KERNEL_CMDLINE` as a named array
  first (sourced bare under `set -u` it stopped the module before the boot menu and greetd steps).
  The HP logo still goes blank when the graphics driver takes over (nothing redraws it without
  Plymouth; the user chose to leave it).
- Review of all this (two read-only reviews, findings checked, then fixed): on the lock screen
  the media widget keeps only its playback buttons (it could open the music app or bring the
  player forward) and the weather hides the town; the backup hyprlock loads the keybinds only
  after an unlock with the password (it touched the mark 2 s after starting, unlocked or not);
  the touchpad gestures moved into binds.lua so they wait for the lock too; the first lock reads
  its mark in-process; the boot is greetd's `initial_session` again (a user session; after a
  logout its greeter slot, `Class=greeter`) and neither sees `GREETD_SOCK`. Pop-ups wait while
  locked and through a shell reload, a critical one goes to the back of the line while others
  wait, the first screen counts until Hyprland names one. The lock screen's glass sits on its
  cards (`MultiEffect`'s auto padding stretched the mask). Screen readers hear the lock and its
  messages; disabled locked widgets read as text. Leftovers of the login screen and the lock
  editor removed (Theme tokens, `ProgressRing.span`, `ChoiceCards.chosenValues`, tuigreet
  comments, the Super+U description); the widgets' 100 % sizes are `DesktopWidgets.unit`,
  which Theme scales. Kept on purpose: the lock island's own password field (the shared
  TextField would need hooks for the island's wake keys, Tab and the busy state).
- Settings -> Account (user's request): "Change your password" opens `passwd` in the default
  terminal (`settings/AccountPage.qml`), so the shell never handles the password; it's the one
  for logging in, the lock screen and sudo (sudo asks for your own; a separate root password
  for sudo was offered and not wanted).

### Desktop widgets polish (built 2026-11-04)
The pass the user asked for after the first widgets (2026-10-30), now that they're also the lock
screen. Looked at all eight at once (the Everything layout through the lock preview), in dark
and light mode:
- One family: every widget's big value (the time, the day, the temperature, the counts) is the
  same size and weight (`Theme.desktop.clock`; the temperature was lighter and smaller, and
  shrinks to fit beside the sky's icon now). The to-do on the lock screen shows its count large
  like the notifications widget instead of a small "1 open" in an empty card.
- Thicker glass for the widgets (`Colors.widgetTranslucent`: a third of the way from the panels'
  glass to solid): they sit straight on the wallpaper, and in light mode over a dark picture the
  grey secondary text met a grey card. Panels keep the glass setting as it is.
- The timer's four lengths are tinted buttons (bare text looked unfinished); on the lock screen,
  where widgets take no clicks, it says "Not running" or shows only its ring, no buttons. The
  calendar there says "Nothing coming up" without the setup steps for adding a calendar.
- Then (user's picks: all four suggestions; the month and the to-do list as widgets of their own,
  they don't fit in the island): the media widget's cover fills its card, darkened toward the
  bottom with white text and buttons, like iOS's Now Playing (glass as before without one); a
  medium "Weather, hourly" (`ForecastWidget.qml`: now, high and low, the next six hours from
  open-meteo's hourly forecast, `Weather.hours`, tested); a large size (352 px square at 100 %)
  with "Month" (`MonthWidget.qml`: the month's days, today in the accent, dots on days with an
  event, the next three events) and "To-do list" (`TasksWidget.qml`: the open tasks as rows,
  "+N more", "Clear N done", and a field to add one). The desktop's layer takes no keyboard, so a
  click in the field takes it (`Exclusive` until the window is active, then `OnDemand` until a
  click elsewhere, see NOTES) and Enter on an empty field or Escape gives it back. On the lock
  screen both keep titles to themselves like the medium ones. The drag handle shows only in the
  desktop editor, so the widgets look clean day to day. A "Planner" widget layout (the time, the
  hourly weather, the month and the to-do list on the right).
- Then (user's request): the month calendar and the to-do list left the today menu, which keeps
  the date, the weather, the next events, the note and timer, and notifications. Tasks are added
  in the to-do widgets, so the medium one is the same widget as the large one (`TasksWidget`, its
  field and as many rows as fit; `TodoWidget` is gone).

### Ending and starting the session (built 2026-11-04)
User's find after the lock screen work: logging out and shutting down gave no feedback, and being
let in was just the desktop appearing.
- Log out, Restart and Shut down (`lock/SessionEnd.qml`, `Session.ending`): every screen dims to
  the background color; the focused one says "Shutting down" (or Restarting, Logging out) under
  a turning ring, with "Closing your apps… 1 of 3". Every window is asked to close, like closing
  it by hand, so apps can save; once all are gone it goes ahead (`Session.finish`: systemctl,
  or Hyprland's exit). An app still open after 6 s is listed with "Show it" (stops and brings it
  forward to be answered), beside "Shut down anyway" and Cancel (Escape). The hyprshutdown call
  (never installed here) is gone. Checked on screen with the closing and the shutdown stubbed
  out: both states.
- Being let in: a right password closes the lock island with the lock open in the accent color
  for a moment (`Lock.letIn`, `Theme.lock.opening`; the preview shows it on Enter), then the
  desktop's island greets you (`bar/WelcomeCard.qml`, `Greeting.js`, tested): "Good morning,
  Ghosty" after the login (your account's full name, `Session.userName`; morning, afternoon or
  evening), "Welcome back, Ghosty" after later unlocks, with chips for the weather, waiting
  notifications, the next event, open tasks and a running timer. 4.5 s, or a click for the
  today menu; pop-ups wait for it (`IslandViews.shown`'s "welcome", tested). Checked on screen
  by firing the unlock signal; a real unlock needs your password.
- Hyprland's splash (a random sentence at the bottom of its background, seen for a moment at
  login before the lock screen covers it; user's find) is off: `misc.disable_splash_rendering`
  in look.lua. Fixed after (user's find: a notification's sound, but no pop-up): after the boot's
  unlock the shell still counted the screen as locked (`Session.locked`, which pop-ups and the
  greeting wait on), set only from the lock's change signal, which didn't follow the unlock of
  the lock made while the shell starts; a shell reload reset it. The lock now sets it itself when
  it locks and lets you in (`Lock.mirrorLocked`; verified after a reboot: unlocked, pop-ups show). `qs ipc call island state` prints what decides
  a pop-up, to catch the next one without a reload. Verified by the user: the unlock, the greeting and Cancel work, and the boot now
  goes black (the graphics driver taking over, with Limine's menu skipped), then the theme's plain
  background, then the lock screen.

### The HP logo through the boot (tried and dropped 2026-11-04)
User's pick after the black screen between the firmware and the session: Plymouth's `bgrt` theme
(the HP logo with a spinner until just before Hyprland draws). It worked, but its first version
crashed Hyprland's first start at every boot (`plymouth quit --retain-splash`, NOTES), and once
that was fixed the gain over no splash was a second of logo; the user dropped it ("not worth the
effort"), along with a theme of our own. The system module removes it again (packages, hook,
`splash`, the drop-in). Seen that boot: the RTX missing from the PCI bus after a warm restart (its
slot empty), which Hyprland skips ("Explicit device ... not found"); harmless.

### Not doing (user's call, 2026-10-28)
Hibernation, fingerprint login and dictation (from the Omarchy/Ryoku research): skipped. Letting games take Super (Quickshell's ShortcutInhibitor only covers the shell's own
windows).

## Decisions made

### Hardware and boot

- **External monitors:** keep the RTX in `AQ_DRM_DEVICES` (second, after the iGPU), so outputs wired
  to it work, accepting the battery cost.
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
  Super + left-drag on a tiled window swaps it with the tiled window it's dropped on (`tiling.swap`, tested). Dragging the border itself (without Super) does nothing on tiled windows. `input.float_switch_override_focus = 0`, or focusing a tiled window under a
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
  Super+Shift+Space float or tile, Super+N quick settings, Super+C calendar,
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
  keys (`qs ipc call media`) follow it. Spotify (1.3.4) reports a frozen MPRIS position (equal to the
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
  Appearance -> Shell panels -> Glass turns it off (85 % opaque, no edge). Hyprland's blur is stronger
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

None.
