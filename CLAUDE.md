# dotfiles

Arch Linux + Hyprland dotfiles, deployed with GNU Stow.

- Each top-level directory is a Stow package mirroring `$HOME`, e.g. `hypr/.config/hypr/hyprland.lua`.
- `packages.txt` lists pacman packages; `aur.txt` lists AUR packages (installed with paru).
- `install.sh` sets up the laptop: packages, the udev rule, greetd, `stow` for every package, a matugen run. Keep it re-runnable and extend it when a phase needs new setup steps.
- `system/` is not a Stow package: it mirrors `/` and its files are installed by hand with `sudo install` (e.g. udev rules).
- matugen (`matugen/`) generates colors from the wallpaper for Quickshell, Hyprland, Ghostty, GTK and Yazi. Templates are committed; generated output is gitignored.
- Hyprland and Quickshell only run on the laptop, so changes can't be tested here.
- Files use LF line endings (enforced in `.gitattributes`), even when edited on Windows.

@ENGINEERING_PRINCIPLES.md
