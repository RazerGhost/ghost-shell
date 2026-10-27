# dotfiles

Arch Linux + Hyprland dotfiles, deployed with GNU Stow.

- Each top-level directory is a Stow package mirroring `$HOME`, e.g. `hypr/.config/hypr/hyprland.lua`.
- `packages.txt` lists pacman packages; `aur.txt` lists AUR packages (installed with paru).
- `system/` is not a Stow package: it mirrors `/` and its files are installed by hand with `sudo install` (e.g. udev rules).
- matugen (`matugen/`) generates colors from the wallpaper for Quickshell, Hyprland and Ghostty. Templates are committed; generated output is gitignored.
- Hyprland and Quickshell only run on the laptop, so changes can't be tested here.
- Files use LF line endings (enforced in `.gitattributes`), even when edited on Windows.

@ENGINEERING_PRINCIPLES.md
