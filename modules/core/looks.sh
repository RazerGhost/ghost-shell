#!/usr/bin/env bash
# Your themes and looks across machines (the desktop's themes, each editor's own looks): written
# into the repo as looks.json, to commit and pull on another machine, and merged into that
# machine's settings from there. `ghost looks` runs this; the desktop editor's Themes tab too.
# The merge rules are the shell's customize/LooksFile.js (tested), loaded here with bun.
#
#   ghost looks export   this machine's into looks.json (your home folder written as "~")
#   ghost looks import   looks.json into this machine's: the same name replaces, new ones are
#                        added, the others stay. Through the running shell when there is one
#                        (it owns settings.json while it runs), else into the file.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

file="$PWD/looks.json"
settings="$HOME/.local/state/quickshell/settings.json"
rules="quickshell/.config/quickshell/customize/LooksFile.js"

case ${1:-} in
    export)
        [[ -f $settings ]] || fail "no settings yet ($settings)"
        SETTINGS="$settings" OUT="$file" js_with "$rules" '
            const settings = JSON.parse(fs.readFileSync(process.env.SETTINGS, "utf8"));
            const looks = lib.exported(settings, process.env.HOME);
            fs.writeFileSync(process.env.OUT, JSON.stringify(looks, null, 4) + "\n");
            console.log(`${lib.count(looks)} themes and looks written to looks.json: commit and push it to share them.`);
        '
        ;;
    import)
        [[ -f $file ]] || fail "no looks.json in the repo yet: run \"ghost looks export\" on the machine that has them"
        if qs ipc call customize importLooks "$file" >/dev/null 2>&1; then
            echo "Merged into the running shell's settings."
        else
            SETTINGS="$settings" FILE="$file" js_with "$rules" '
                const path = process.env.SETTINGS;
                const data = fs.existsSync(path) ? JSON.parse(fs.readFileSync(path, "utf8")) : {};
                Object.assign(data, lib.imported(data, JSON.parse(fs.readFileSync(process.env.FILE, "utf8")), process.env.HOME));
                fs.mkdirSync(require("path").dirname(path), { recursive: true });
                fs.writeFileSync(path, JSON.stringify(data, null, 4) + "\n");
            '
            echo "Merged into $settings."
        fi
        ;;
    *)
        fail "usage: ghost looks export | import"
        ;;
esac
