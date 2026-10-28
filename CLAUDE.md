# dotfiles

Arch Linux + Hyprland dotfiles, deployed with GNU Stow.

- Each top-level directory except `modules/`, `system/`, `tests/` and `docs/` is a Stow package mirroring `$HOME`, e.g. `hypr/.config/hypr/hyprland.lua`. Don't move or rename these while the desktop runs from them: the links break for a moment (Hyprland once lost hyprland.lua that way).
- `modules/<name>/` holds one part of the setup each: its packages (`packages.txt` for pacman, `aur.txt` for paru) and its setup (`setup.sh`, re-runnable). The modules are core, system, apps, dev, gaming, discord, spotify, zen, haunt, capture and phone; `modules/lib.sh` (`step`, `fail`, `clone_or_pull`, `clone_at`, `json_edit`) is shared. New packages and setup steps go in the module they belong to (or a new one, added to `all_modules` and `about` in `bin/.local/bin/dots`).
- `dots` (`bin/.local/bin/dots`, a Stow package) runs everything: `install [module...] [--theme X]`, `update` (refuses with uncommitted changes rather than stashing), `theme`, `greeter`, `doctor`, `modules`, `keybinds`. `install.sh` is only the first-run bootstrap for `dots install`. A machine picks its modules in `~/.config/dots/modules` (not in git); without it, all.
- Setting the wallpaper and colors goes through `matugen/.config/matugen/wallpaper.sh`, used by `dots theme`, the core module and the shell's wallpaper picker. matugen hooks only deliver colors; setting an app up belongs in its module's `setup.sh`.
- `modules/core/greeter.sh` (`dots greeter`; the core module runs it) sets up the Quickshell login screen: copies the shell to `/etc/greetd/quickshell/` and creates `/var/lib/qs-greeter/shared/`, which the shell keeps filled with the user's settings, colors and lock screen picture (`greeter/sync.sh`). Run it after changing the shell's code, since the login screen runs its own copy.
- Machine-local overrides, gitignored and loaded last: `hypr/.config/hypr/local.lua`, `ghostty/.config/ghostty/local`, `fish/.config/fish/conf.d/local.fish`. Machine-specific things go there, not in the repo's files.
- `system/` is not a Stow package: it mirrors `/` and the system module (`modules/system/setup.sh`) copies its files into place with `sudo install` (udev rule, greetd config and drop-in, mkinitcpio drop-in); it also appends `plymouth.enable=0` to `/etc/default/limine` (Plymouth breaks tuigreet).
- matugen (`matugen/`) generates colors from the wallpaper for Quickshell, Hyprland, Ghostty, GTK, Yazi, Spotify, Discord, MangoHud, Zed, Steam and Zen (list in its `config.toml`). Templates are committed; generated output is gitignored.
- Browser is Zen (`zen-browser-bin` from the AUR), not Firefox. Use it wherever a browser is launched or set as default.
- Hyprland and Quickshell run on the laptop (CachyOS). A session on the laptop can run and test changes directly (`qs`, `hyprctl`, `journalctl`); a session on another machine can't, and hands the user a test checklist instead.
- Commit and push after each phase or fix; the user may pull on another machine.
- `tests/` holds QML tests (not a Stow package). Run them with `QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests`, and the tiling layout's Lua test with `lua tests/tiling_test.lua`.
- Files use LF line endings (enforced in `.gitattributes`), even when edited on Windows.
- `ROADMAP.md` has the phase plan, decisions and open issues. Update it when a phase finishes or a decision changes.
- `NOTES.md` has the verified Quickshell/Hyprland API facts and how to test on the laptop. Read it before using an API it might cover, and add facts you verify.

@ENGINEERING_PRINCIPLES.md
@ROADMAP.md
