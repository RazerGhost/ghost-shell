# Shared by bin/.local/bin/ghost and the modules' setup scripts (sourced, not run).

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# This machine's hardware (bin/.local/bin/ghost-hw: `hw laptop`, `hw nvidia-display`, `hw match
# <model>`...), from the repo, so it works before stow has linked it.
hw() { "$(dirname "${BASH_SOURCE[0]}")/../bin/.local/bin/ghost-hw" "$@"; }

# Clone a repo, or fast-forward it if it's already there.
clone_or_pull() {
    if [[ -d $2/.git ]]; then
        git -C "$2" pull --ff-only
    else
        git clone "$1" "$2"
    fi
}

# Clone a repo at a fixed tag or commit, or move an existing clone there. For third-party code
# that runs on this machine: an update is a deliberate change of the ref in the setup script, not
# whatever the repo's main branch holds when the script runs.
clone_at() {
    [[ -d $2/.git ]] || git clone --quiet "$1" "$2"
    git -C "$2" fetch --quiet --tags origin
    git -C "$2" -c advice.detachedHead=false checkout --quiet "$3"
}

# Changes a JSON file in place, keeping everything else in it: `data` is the file's content ({}
# when it doesn't exist yet) and $2 is JavaScript that changes it. Values come in through
# environment variables, so paths never need quoting inside the code:
#   VENCORD_DIST=... json_edit ~/.config/vesktop/state.json 'data.vencordDir = process.env.VENCORD_DIST'
json_edit() {
    JSON_FILE="$1" JSON_CHANGE="$2" bun -e '
        const fs = require("fs"), { dirname } = require("path");
        const path = process.env.JSON_FILE;
        const data = fs.existsSync(path) ? JSON.parse(fs.readFileSync(path, "utf8")) : {};
        new Function("data", process.env.JSON_CHANGE)(data);
        fs.mkdirSync(dirname(path), { recursive: true });
        fs.writeFileSync(path, JSON.stringify(data, null, 4) + "\n");
    '
}

# Runs bun code ($2) with a QML JavaScript library's functions in scope ($1: the shell's tested
# .js files; their ".pragma library" and ".import" lines are QML's, so they're dropped, and they
# mustn't need what they import). Paths and data go in through the environment, never into the
# code: JS_LIB is the library's path. `fs` is there too.
js_with() {
    JS_LIB="$1" bun -e "
        const fs = require('fs');
        const source = fs.readFileSync(process.env.JS_LIB, 'utf8').replace(/^\.(pragma|import) .*\$/gm, '');
        const names = [...source.matchAll(/^(?:function|const)\s+(\w+)/gm)].map(m => m[1]);
        const lib = new Function(source + '\nreturn { ' + names.join(', ') + ' };')();
        $2
    "
}

# Makes Hyprland start what a module starts: links modules/<module>/autostart.lua into
# ~/.config/hypr/autostart.d/, whose files hypr/autostart.lua runs at Hyprland's start. Run from
# the repo's root. Only the modules a machine installs are linked, so the shared config never
# starts a program that isn't there.
module_autostart() {
    mkdir -p "$HOME/.config/hypr/autostart.d"
    ln -sfn "$PWD/modules/$1/autostart.lua" "$HOME/.config/hypr/autostart.d/$1.lua"
}

# Packages stow may link as whole folders (~/.config/quickshell -> the repo's folder): folders only
# this repo writes into (and its own generated, gitignored files), where a file added by a git
# pull must work at once (a new QML file the shell imports). Every other package is linked file
# by file (--no-folding), into real folders: other programs write into those (installers into
# ~/.local/bin, Zed its keymaps, fish and Nautilus their state), and with a whole folder linked
# their files landed in the repo. A new file there needs `ghost install core` (or `ghost update`)
# to be linked.
folded_packages=(quickshell hypr matugen ghostty starship fastfetch)

stow_flags() {
    [[ " ${folded_packages[*]} " == *" $1 "* ]] || echo --no-folding
}

# Links a package into $HOME (run from the repo's root). A file-by-file package that an earlier
# version linked as whole folders is unlinked first, and what other programs wrote into those
# folders (in the repo now, untracked) moves back out to the real folders before it's linked again.
stow_package() {
    local pkg=$1 dir folded=false file
    if [[ -n $(stow_flags "$pkg") ]]; then
        while IFS= read -r -d '' dir; do
            [[ -L $HOME/${dir#"$pkg"/} ]] && folded=true
        done < <(find "$pkg" -mindepth 1 -type d -print0)
    fi
    if $folded; then
        stow -D -t "$HOME" "$pkg"
        while IFS= read -r -d '' file; do
            mkdir -p "$HOME/$(dirname "${file#"$pkg"/}")"
            mv -n "$file" "$HOME/${file#"$pkg"/}"
        done < <(git ls-files --others -z -- "$pkg")
    fi
    # shellcheck disable=SC2046 # no flag or one
    stow -R $(stow_flags "$pkg") -t "$HOME" "$pkg"
}

# The repo's Stow packages, one per line: every top-level folder but the ones that aren't
# (system/ mirrors /, the rest are the setup, tests and docs). Run from the repo's root.
stow_packages() {
    local pkg
    for pkg in */; do
        pkg=${pkg%/}
        [[ $pkg == system || $pkg == tests || $pkg == modules || $pkg == docs || $pkg == machines || $pkg == migrations ]] || echo "$pkg"
    done
}
