#!/usr/bin/env bash
# Set up (or update) this machine from the dotfiles repo. Safe to re-run.
#
# Usage: ./install.sh [wallpaper | "#rrggbb"]
#   wallpaper  image to generate matugen colors from
#   #rrggbb    seed color to generate them from instead (quote it: # starts a comment)
#   Without either, the first run uses a default seed color.
#
# Run `git pull` before this script, not from it: pulling can change this file mid-run.
set -euo pipefail

cd "$(dirname "$0")"

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

step "Installing packages (packages.txt, aur.txt)"
# steam comes from [multilib]; CachyOS enables it in /etc/pacman.conf by default.
# Packages go in as arguments, not on stdin: pacman and paru read their "Proceed?" prompts
# from stdin, and with the list piped in they'd get end-of-file instead of your answer.
mapfile -t pacman_pkgs < <(grep -v '^[[:space:]]*$' packages.txt)
mapfile -t aur_pkgs    < <(grep -v '^[[:space:]]*$' aur.txt)
sudo pacman -S --needed "${pacman_pkgs[@]}"
# rustup installs no toolchain by itself. Set up stable before the AUR packages: some build
# with Rust (millennium), and so does Haunt (Tauri).
rustup toolchain list | grep -q stable || rustup default stable
paru -S --needed "${aur_pkgs[@]}"

step "GPU udev rule (stable /dev/dri/amd-igpu and /dev/dri/nvidia-dgpu)"
rule=system/etc/udev/rules.d/61-gpu-symlinks.rules
if ! cmp -s "$rule" "/etc/udev/rules.d/$(basename "$rule")"; then
    sudo install -Dm644 "$rule" "/etc/udev/rules.d/$(basename "$rule")"
    sudo udevadm control --reload
    sudo udevadm trigger --subsystem-match=drm
    udevadm settle
fi
# The iGPU is the primary GPU in AQ_DRM_DEVICES: without it Hyprland can't start, so stop here.
[[ -e /dev/dri/amd-igpu ]] || fail "/dev/dri/amd-igpu is missing (udev rule didn't match the AMD card)"
echo "amd-igpu    -> $(readlink -f /dev/dri/amd-igpu)"
# The RTX is only needed for outputs wired to it (HDMI / USB-C), so a missing card is a warning.
# It's missing when the NVIDIA driver didn't load or didn't create a DRM card.
if [[ -e /dev/dri/nvidia-dgpu ]]; then
    [[ $(readlink -f /dev/dri/nvidia-dgpu) != $(readlink -f /dev/dri/amd-igpu) ]] \
        || fail "both GPU symlinks point at $(readlink -f /dev/dri/amd-igpu)"
    echo "nvidia-dgpu -> $(readlink -f /dev/dri/nvidia-dgpu)"
else
    printf '\033[1;33mwarning:\033[0m /dev/dri/nvidia-dgpu is missing; external monitors on the RTX will not work.\n' >&2
    echo "NVIDIA driver status:"
    lspci -k -d 10de::03xx
    lsmod | grep -E '^nvidia' || echo "  (no nvidia kernel modules loaded)"
fi
echo "Compare with the PCI addresses below (1002 = AMD, 10de = NVIDIA):"
lspci -nn -d ::03xx
ls -l /dev/dri/by-path/ | grep -- '-card'

step "Boot: early KMS, no Plymouth splash"
rebuild_boot=false

# Early KMS: load the AMD driver before any services start. CachyOS's chwd removes the kms
# hook on NVIDIA laptops (10-chwd-kms.conf), so without this amdgpu loads late.
kms=system/etc/mkinitcpio.conf.d/20-early-amdgpu.conf
if ! cmp -s "$kms" "/etc/mkinitcpio.conf.d/$(basename "$kms")"; then
    sudo install -Dm644 "$kms" "/etc/mkinitcpio.conf.d/$(basename "$kms")"
    rebuild_boot=true
fi

# Plymouth leaves tty1 in graphics mode when it quits, so tuigreet draws to a console that
# shows nothing (black screen at boot). /etc/default/limine is bash; each
# KERNEL_CMDLINE[default]+= line appends to the kernel command line.
no_splash='KERNEL_CMDLINE[default]+=" plymouth.enable=0"'
if ! grep -qxF "$no_splash" /etc/default/limine; then
    echo "$no_splash" | sudo tee -a /etc/default/limine >/dev/null
    rebuild_boot=true
fi

if $rebuild_boot; then
    # limine-mkinitcpio (CachyOS) rebuilds the initramfs and rewrites the Limine boot entries.
    sudo limine-mkinitcpio
fi
# Stop if the option didn't reach the boot entries: greetd would boot to a black screen.
sudo grep -rqs --include=limine.conf 'plymouth.enable=0' /boot \
    || fail "plymouth.enable=0 is not in /boot's limine.conf; check /etc/default/limine and run sudo limine-mkinitcpio"

step "Login manager (greetd)"
sudo install -Dm644 system/etc/greetd/config.toml /etc/greetd/config.toml
sudo install -Dm644 system/etc/systemd/system/greetd.service.d/after-plymouth.conf \
    /etc/systemd/system/greetd.service.d/after-plymouth.conf
sudo systemctl daemon-reload
# Enable only, don't start: starting it now would take over tty1 under the running session.
# It takes effect on the next boot.
sudo systemctl enable greetd.service

step "Services the Quickshell bar reads"
# Network, Bluetooth and power profile modules talk to these over D-Bus.
# UPower (battery) is started on demand by D-Bus, so it needs no enabling.
sudo systemctl enable --now NetworkManager.service bluetooth.service power-profiles-daemon.service

step "Spotify: let Spicetify patch it"
# Spicetify rewrites files in /opt/spotify. Its docs make the folder writable for everyone;
# owning it as this user is enough. Spotify updates replace the files, so run
# `spicetify backup apply` after one.
sudo chown -R "$USER" /opt/spotify

step "Linking configs with stow"
# Every top-level directory is a Stow package, except system/ (installed above) and tests/.
# -R re-links, so files added to an already-stowed package get linked too.
# If stow reports a conflict, move the existing file aside and re-run.
for pkg in */; do
    pkg=${pkg%/}
    [[ $pkg == system || $pkg == tests ]] && continue
    echo "$pkg"
    stow -R -t "$HOME" "$pkg"
done
# Quickshell fills this in for the QML language server; it's gitignored.
touch quickshell/.config/quickshell/.qmlls.ini

step "GTK dark mode, theme and icons"
# adw-gtk3 makes GTK3 apps match libadwaita (GTK4) ones; GTK4 apps follow color-scheme.
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
# Colloid icons (user's choice); Quickshell gets the same theme from QS_ICON_THEME in env.lua.
gsettings set org.gnome.desktop.interface icon-theme Colloid-Dark
# Pictures (screenshots too) open in Loupe; Settings -> Default apps can change it.
xdg-mime default org.gnome.Loupe.desktop image/png image/jpeg image/gif image/webp image/bmp \
    image/tiff image/avif image/heic image/svg+xml image/x-icon
# Title bar buttons for apps that draw their own bar (GTK apps, Ghostty). No minimize: Hyprland
# ignores apps' minimize requests (Super+Down or the window menu minimizes instead).
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:maximize,close'

step "Wallpaper folder"
# The wallpaper picker (quick settings) shows the pictures in here.
mkdir -p "$HOME/Pictures/Wallpapers"

step "Generating colors with matugen"
# Without a wallpaper, matugen builds the scheme from one seed color.
# #6750a4 is the Material baseline purple, the same scheme as the fallbacks in Colors.qml.
default_seed="#6750a4"
if [[ $# -ge 1 && $1 == \#* ]]; then
    matugen color hex "$1" -m dark
elif [[ $# -ge 1 ]]; then
    [[ -f $1 ]] || fail "wallpaper not found: $1"
    matugen image "$1" -m dark --source-color-index 0
    # Also make it the wallpaper Quickshell draws (services/Wallpaper.qml reads this file).
    WALLPAPER="$(realpath "$1")" node -e '
        const fs = require("fs");
        const file = process.env.HOME + "/.local/state/quickshell/wallpaper.json";
        fs.mkdirSync(require("path").dirname(file), { recursive: true });
        fs.writeFileSync(file, JSON.stringify({ path: process.env.WALLPAPER }, null, 4) + "\n");
    '
elif [[ -f $HOME/.local/state/quickshell/colors.json ]]; then
    echo "Colors already generated; pass a wallpaper or a hex color to regenerate."
else
    echo "No wallpaper given, using seed color $default_seed"
    matugen color hex "$default_seed" -m dark
fi

step "Dev tools: Docker"
# docker.socket starts Docker on first use instead of at every boot.
sudo systemctl enable --now docker.socket
# The docker group lets you run docker without sudo. Membership is equivalent to root access
# (containers can mount /), so only your own user is added. It applies after logging in again.
id -nG "$USER" | grep -qw docker || sudo usermod -aG docker "$USER"

# Clone a repo, or fast-forward it if it's already there.
clone_or_pull() {
    if [[ -d $2/.git ]]; then
        git -C "$2" pull --ff-only
    else
        git clone "$1" "$2"
    fi
}

step "Discord: Vencord with the Ghost theme plugin, for Vesktop"
# Third-party Vencord plugins only load from a source build, so build Vencord with Ghost
# (github.com/RazerGhost/discord-ghost) as a userplugin and point Vesktop at that build.
# Re-run this script to update both. Enable the plugin in Vesktop: Settings -> Plugins -> Ghost.
vencord_dir="$HOME/.local/share/vencord"
ghost_dir="$HOME/.local/share/discord-ghost"
clone_or_pull https://github.com/Vendicated/Vencord "$vencord_dir"
clone_or_pull https://github.com/RazerGhost/discord-ghost "$ghost_dir"
(cd "$ghost_dir" && npm ci && node build.mjs --vencord "$vencord_dir")
(cd "$vencord_dir" && pnpm install --frozen-lockfile && pnpm build)
# Vesktop's "Vencord location" setting (Developer options) is vencordDir in state.json.
# Vesktop reads it at startup, so restart Vesktop after the first run.
VESKTOP_STATE="$HOME/.config/vesktop/state.json" VENCORD_DIST="$vencord_dir/dist" node -e '
    const fs = require("fs");
    const path = process.env.VESKTOP_STATE;
    const state = fs.existsSync(path) ? JSON.parse(fs.readFileSync(path, "utf8")) : {};
    state.vencordDir = process.env.VENCORD_DIST;
    fs.mkdirSync(require("path").dirname(path), { recursive: true });
    fs.writeFileSync(path, JSON.stringify(state, null, 4));
'
# Vesktop and Vencord settings, merged so your other choices survive re-runs:
# - nativeTitleBar: Vesktop stops drawing Discord's minimize/maximize/close (Hyprland draws no
#   decorations; Super+drag moves the window).
# - the "Ghost matugen" theme on (matugen writes it, see templates/vesktop-ghost.css), and the
#   Ghost plugin's defaults on first run only: on, accent and colors from matugen, Hyprland's
#   rounding. Change them in Vesktop's settings afterwards.
VESKTOP_DIR="$HOME/.config/vesktop" node -e '
    const fs = require("fs"), { dirname } = require("path");
    const dir = process.env.VESKTOP_DIR;
    const edit = (path, change) => {
        const data = fs.existsSync(path) ? JSON.parse(fs.readFileSync(path, "utf8")) : {};
        change(data);
        fs.mkdirSync(dirname(path), { recursive: true });
        fs.writeFileSync(path, JSON.stringify(data, null, 4));
    };
    edit(dir + "/settings.json", (s) => { s.nativeTitleBar = true; });
    edit(dir + "/settings/settings.json", (s) => {
        s.enabledThemes = [...new Set([...(s.enabledThemes ?? []), "ghost-matugen.css"])];
        s.plugins ??= {};
        s.plugins.Ghost ??= { enabled: true, accentSource: "matugen", matugenColors: true, radius: 10, gap: 10 };
    });
'

step "Spotify: the Ghost Spicetify theme"
# github.com/RazerGhost/spicetify-ghost. Its installer loads the theme from GitHub, so it
# updates itself. Spicetify needs Spotify's prefs file, which Spotify writes on first start.
if [[ -f $HOME/.config/spotify/prefs ]]; then
    # Spicetify patches a backup of the original Spotify; the first run has to make it.
    # The [Backup] version in its config stays empty until then.
    if ! grep -A1 '^\[Backup\]' "$HOME/.config/spicetify/config-xpui.ini" 2>/dev/null | grep -q 'version *= *[0-9]'; then
        spicetify backup apply
    fi
    curl -fsSL https://raw.githubusercontent.com/RazerGhost/spicetify-ghost/main/install.sh | sh
    # Ghost's installer just replaced its color.ini; put matugen's [matugen] scheme back in and
    # select it (matugen runs the same hook on every wallpaper change).
    sh "$HOME/.config/matugen/hooks/spicetify-ghost.sh"
else
    echo "Skipped: open Spotify once and log in, then re-run this script."
fi

step "Login screen (Quickshell greeter)"
# After matugen, so the login screen gets the current colors. Settings, colors and the wallpaper
# reach it by themselves afterwards; re-run update-greeter.sh alone after changing the shell's code.
./update-greeter.sh

step "Done"
echo "Log out and back in if this was the first run or env.lua changed (GPU settings apply at Hyprland start)."
