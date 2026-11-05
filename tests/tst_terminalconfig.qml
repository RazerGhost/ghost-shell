import QtQuick
import QtTest
import "../quickshell/.config/quickshell/settings/TerminalConfig.js" as TerminalConfig

TestCase {
    name: "TerminalConfig"

    function test_ghostty() {
        // Both on by default (a settings file from before they existed).
        const both = TerminalConfig.ghostty({});
        verify(both.includes("custom-shader = shaders/cursor-trail.glsl"));
        verify(both.includes("notify-on-command-finish = unfocused"));
        verify(both.includes("notify-on-command-finish-action = no-bell,notify"));
        // Each off on its own.
        const noTrail = TerminalConfig.ghostty({ terminalCursorTrail: false });
        verify(!noTrail.includes("custom-shader"));
        verify(noTrail.includes("notify-on-command-finish = unfocused"));
        const quiet = TerminalConfig.ghostty({ terminalNotify: false });
        verify(quiet.includes("custom-shader"));
        verify(!quiet.includes("notify-on-command-finish"));
    }

    function test_prompts() {
        compare(Object.keys(TerminalConfig.prompts), ["pills", "minimal", "two-line"]);
        compare(TerminalConfig.prompts.pills, "starship.toml");
    }
}
