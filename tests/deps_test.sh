#!/usr/bin/env bash
# Checks that everything the repo uses comes from a package the right module declares, or from
# one of its dependencies: a QML module the shell imports, or a program its code names. What
# another package or the distro's installer happened to bring along doesn't count: the laptop had
# Qt Multimedia through other packages, and a fresh desktop without them couldn't start the shell;
# zenity came only with Steam (the gaming module), so a machine without it couldn't pick files
# (2026-11-05). Run from the repo root with `bash tests/deps_test.sh`; `ghost doctor` runs it too.
#
# Which packages count where: code every machine runs (the shell, Hyprland's config, bin/, the
# core and system modules) may use core's and system's packages; a module's own scripts also its
# own. The shell uses a few optional modules' programs only when they're there: `optional` lists
# them with their module. It reads this machine's installed packages: a program that isn't
# installed here can't be checked here (another machine's modules).
set -uo pipefail
cd "$(dirname "$0")/.."

# Words that match a program's name but aren't used as one, and programs used only when they're
# there (each checked with command -v or a file test first).
declare -A ignore=(
    [less]="the today menu's \"Show less\""
    [hostname]="Starship's \$hostname"
    [host]="a word"
    [named]="a word"
    [talk]="a word"
    [chat]="a word"
    [man]="MANPAGER in .zshrc, for man when it's installed"
    [ufw]="the phone module opens its ports only while ufw runs (CachyOS turns it on)"
    [limine-mkinitcpio]="the system module's boot steps, only with Limine"
    [limine-entry-tool]="the system module's boot steps, only with Limine"
    [limine-enroll-config]="the system module's boot steps, only with Limine"
    [limine]="the system module's word for Limine's files"
    [7z]="an archive type the launcher's file search knows"
    [btrfs]="a Settings search word"
    [cargo]="~/.cargo/bin in .zshrc's path"
    [clear]="a QML function's name"
    [compare]="a word"
    [count]="a word"
    [display]="a word"
    [dot]="a QML id"
    [gm]="a regex flag"
    [import]="QML's import"
    [lit]="a word"
    [node]="a PipeWire node"
    [not]="a word"
    [opt]="the /opt folder"
    [steam]="Steam's folders (steamapps); the app itself is the gaming module's"
    [tabs]="a word"
    [transform]="a QML property"
    [wheel]="a word"
    [gamescope]="a window rule's class"
)

# Programs of optional modules that the shared code uses only when the module is there (the
# shell's phone page, calendar, capture tools...): the module whose packages bring them.
declare -A optional=(
    [kdeconnect-cli]=phone [kdeconnect-indicator]=phone [localsend]=phone
    [khal]=calendar [vdirsyncer]=calendar
    [gpu-screen-recorder]=capture [tesseract]=capture [zbarimg]=capture [hyprpicker]=capture [satty]=capture
    [snapper]=snapshots [btrfs-assistant]=snapshots
    [spicetify]=spotify [vesktop]=discord [spotify]=spotify
    [nautilus]=apps [micro]=apps [zeditor]=apps [yazi]=apps [zen-browser]=apps
    [openxlr]=wave3
)

# A module's declared packages (all of packages.sh's, whatever this machine's hardware).
declared_of() {
    {
        cat "modules/$1/packages.txt" "modules/$1/aur.txt" 2>/dev/null | sed 's/#.*//; s/[[:space:]]//g'
        [[ -x modules/$1/packages.sh ]] && "modules/$1/packages.sh" --all
    } | grep -v '^$'
}

# Every declared package that's installed here, with everything it depends on, one file each.
# pactree runs in parallel, each into its own file: their outputs on one pipe got mixed up mid-line.
trees=$(mktemp -d)
trap 'rm -rf "$trees"' EXIT
modules=$(cd modules && for m in */; do echo "${m%/}"; done)
all=$( { echo base; for m in $modules; do declared_of "$m"; done; } | sort -u)
# shellcheck disable=SC2086 # one package name per word
pacman -Qq $all 2>/dev/null | xargs -r -P "$(nproc)" -I{} sh -c 'pactree -lu "$1" >"$2/$1" 2>/dev/null' _ {} "$trees"
# The packages a module's packages bring (installed ones only).
closure_of() {
    local pkg
    for pkg in "$@"; do
        [[ -f $trees/$pkg ]] && cat "$trees/$pkg"
    done | sort -u
}
# shellcheck disable=SC2046 # one package name per word
shared=$(closure_of base $(declared_of core) $(declared_of system))
declare -A module_closure=()
for m in $modules; do
    # shellcheck disable=SC2046
    module_closure[$m]=$(closure_of $(declared_of "$m"))
done
in_list() { grep -qx "$1" <<<"$2"; }

problems=0
problem() { echo "$1"; problems=$((problems + 1)); }

# The shell's QML imports: each must be installed and come from core's or system's packages.
for module in $(grep -rhoE '^\s*import\s+[A-Z][A-Za-z0-9.]*' --include='*.qml' quickshell | awk '{print $2}' | sort -u); do
    qmldir=/usr/lib/qt6/qml/${module//.//}/qmldir
    if [[ ! -f $qmldir ]]; then
        problem "QML module $module isn't installed (the shell imports it)"
    else
        owner=$(pacman -Qqo "$qmldir")
        in_list "$owner" "$shared" || problem "QML module $module comes from $owner, which core doesn't declare or pull in"
    fi
done

programs=$(command ls -1 /usr/bin)
# The programs a set of files names (comments left out) that exist here, minus the ignored words.
programs_in() {
    local program
    for program in $(grep -rhvE '^\s*(#|//|--)' --include='*.qml' --include='*.js' --include='*.sh' --include='*.lua' \
                         --include='*.fish' --include='.zshrc' --include='*.toml' --include='*.conf' "$@" 2>/dev/null \
                     | grep -oE '[A-Za-z0-9][A-Za-z0-9_.+-]*' | sort -u | comm -12 - <(echo "$programs")); do
        [[ -n ${ignore[$program]+set} ]] || echo "/usr/bin/$program"
    done
}
# Checks programs against what may bring them: `$1` names the place, `$2` the allowed packages.
check_programs() {
    local where=$1 allowed=$2 path owner name
    shift 2
    # One pacman call for all of them: "/usr/bin/x is owned by package version".
    while read -r path _ _ _ owner _; do
        name=${path#/usr/bin/}
        in_list "$owner" "$allowed" && continue
        # The shared code's guarded use of an optional module's program.
        if [[ $where == shared && -n ${optional[$name]+set} ]]; then
            in_list "$owner" "${module_closure[${optional[$name]}]}" \
                || problem "$name comes from $owner, not from the ${optional[$name]} module it's listed under"
            continue
        fi
        problem "$name ($where) comes from $owner, which ${where/shared/core} doesn't declare or pull in"
    done < <((($#)) && pacman -Qo "$@" 2>/dev/null)
}

mapfile -t used < <(programs_in quickshell hypr matugen bin zsh fish starship pipewire migrations modules/lib.sh modules/core modules/system)
check_programs shared "$shared" "${used[@]}"
for m in $modules; do
    [[ $m == core || $m == system ]] && continue
    mapfile -t used < <(programs_in "modules/$m")
    check_programs "$m" "$(printf '%s\n%s\n' "$shared" "${module_closure[$m]}")" "${used[@]}"
done

if ((problems)); then
    echo "$problems undeclared (add the package to the module that uses it, or to a list above with the reason)"
    exit 1
fi
echo "every QML module and program the repo uses is declared by the module that uses it"
