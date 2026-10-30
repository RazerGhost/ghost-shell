# Shared by bin/.local/bin/ghost and the modules' setup scripts (sourced, not run).

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

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

# The repo's Stow packages, one per line: every top-level folder but the ones that aren't
# (system/ mirrors /, the rest are the setup, tests and docs). Run from the repo's root.
stow_packages() {
    local pkg
    for pkg in */; do
        pkg=${pkg%/}
        [[ $pkg == system || $pkg == tests || $pkg == modules || $pkg == docs ]] || echo "$pkg"
    done
}
