#!/usr/bin/env bash
# Checks that everything the repo uses comes from a package some module declares, or from one of
# their dependencies: a QML module the shell imports, or a program its code names. What another
# package or the distro's installer happened to bring along doesn't count: the laptop had Qt
# Multimedia through other packages, and a fresh desktop without them couldn't start the shell
# (2026-11-05). Run from the repo root with `bash tests/deps_test.sh`; `ghost doctor` runs it too.
# It reads this machine's installed packages: a program or QML module that isn't installed here
# is reported as missing only for the shell's imports (programs of modules this machine doesn't
# use can't be checked here).
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
)

declared=$(
    {
        echo base
        cat modules/*/packages.txt modules/*/aur.txt | sed 's/#.*//; s/[[:space:]]//g'
        for script in modules/*/packages.sh; do "$script" --all; done
    } | grep -v '^$' | sort -u
)
# Each declared package that's installed here, with everything it depends on. pactree runs in
# parallel, each into its own file: their outputs on one pipe got mixed up mid-line.
trees=$(mktemp -d)
trap 'rm -rf "$trees"' EXIT
# shellcheck disable=SC2086 # one package name per word
pacman -Qq $declared 2>/dev/null | xargs -r -P "$(nproc)" -I{} sh -c 'pactree -lu "$1" >"$2/$1" 2>/dev/null' _ {} "$trees"
closure=$(cat "$trees"/* | sort -u)
in_closure() { grep -qx "$1" <<<"$closure"; }

problems=0
problem() { echo "$1"; problems=$((problems + 1)); }

# The shell's QML imports: each must be installed and come from a declared package.
for module in $(grep -rhoE '^\s*import\s+[A-Z][A-Za-z0-9.]*' --include='*.qml' quickshell | awk '{print $2}' | sort -u); do
    qmldir=/usr/lib/qt6/qml/${module//.//}/qmldir
    if [[ ! -f $qmldir ]]; then
        problem "QML module $module isn't installed (the shell imports it)"
    else
        owner=$(pacman -Qqo "$qmldir")
        in_closure "$owner" || problem "QML module $module comes from $owner, which no module declares or pulls in"
    fi
done

# Programs: every word in the code (comments left out) that names a program in /usr/bin here.
programs=$(command ls -1 /usr/bin)
words=$(grep -rhvE '^\s*(#|//|--)' --include='*.qml' --include='*.js' --include='*.sh' --include='*.lua' \
            --include='*.fish' --include='.zshrc' --include='*.toml' --include='*.conf' \
            quickshell hypr matugen modules bin zsh fish starship pipewire migrations 2>/dev/null \
        | grep -oE '[A-Za-z0-9][A-Za-z0-9_.+-]*' | sort -u)
used=()
for program in $(comm -12 <(echo "$words") <(echo "$programs")); do
    [[ -n ${ignore[$program]+set} ]] || used+=("/usr/bin/$program")
done
# One pacman call for all of them: "/usr/bin/x is owned by package version".
while read -r path _ _ _ owner _; do
    in_closure "$owner" || problem "${path#/usr/bin/} comes from $owner, which no module declares or pulls in"
done < <(((${#used[@]})) && pacman -Qo "${used[@]}" 2>/dev/null)

if ((problems)); then
    echo "$problems undeclared (add the package to the module that uses it, or to the ignore list with the reason)"
    exit 1
fi
echo "every QML module and program the repo uses is declared"
