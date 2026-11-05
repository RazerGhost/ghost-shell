// Settings -> Terminal's Ghostty options, written by GhosttySettings.qml into
// ~/.config/ghostty/shell-settings (gitignored), which Ghostty's config includes before your own
// `local`. The prompt's style isn't here: .zshrc reads `terminalPrompt` from settings.json at
// every prompt. Plain JavaScript, tested (tests/tst_terminalconfig.qml).
.pragma library

// The prompt styles: Starship's config file for each, under ~/.config.
const prompts = { pills: "starship.toml", minimal: "starship/minimal.toml", "two-line": "starship/two-line.toml" };

// The file's text for the settings `v` (an object with Settings' values).
function ghostty(v) {
    const lines = ["# Written by the shell from Settings -> Terminal (settings/GhosttySettings.qml); don't edit:",
                   "# it's replaced. Your own settings go in `local`.", ""];
    if (v.terminalCursorTrail !== false)
        lines.push("# A short trail in the accent color when the cursor jumps.", "custom-shader = shaders/cursor-trail.glsl", "");
    if (v.terminalNotify !== false)
        lines.push("# A notification when a command that ran 10 s or more ends while its window isn't focused",
                   "# (shell integration marks where commands start and end).",
                   "notify-on-command-finish = unfocused",
                   "notify-on-command-finish-action = no-bell,notify",
                   "notify-on-command-finish-after = 10s", "");
    return lines.join("\n");
}
