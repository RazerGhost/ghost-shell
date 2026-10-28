import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/EmojiData.js" as EmojiData

TestCase {
    name: "EmojiData"

    // A slice of emoji-test.txt, in its real format.
    readonly property string sample: [
        "# emoji-test.txt",
        "# group: Smileys & Emotion",
        "# subgroup: face-smiling",
        "1F600                                                  ; fully-qualified     # 😀 E1.0 grinning face",
        "1F601                                                  ; fully-qualified     # 😁 E0.6 beaming face with smiling eyes",
        "263A FE0F                                              ; fully-qualified     # ☺️ E0.6 smiling face",
        "263A                                                   ; unqualified         # ☺ E0.6 smiling face",
        "# group: People & Body",
        "1F44B                                                  ; fully-qualified     # 👋 E0.6 waving hand",
        "1F44B 1F3FB                                            ; fully-qualified     # 👋🏻 E1.0 waving hand: light skin tone",
        "# group: Component",
        "1F3FB                                                  ; component           # 🏻 E1.0 light skin tone",
        "1F9B0                                                  ; fully-qualified     # 🦰 E11.0 red hair",
        "# group: Animals & Nature",
        "1F431                                                  ; fully-qualified     # 🐱 E0.6 cat face",
        "1F408                                                  ; fully-qualified     # 🐈 E0.7 cat",
        ""
    ].join("\n")

    function test_parse() {
        const emoji = EmojiData.parse(sample);
        compare(emoji.map(e => e.emoji), ["😀", "😁", "☺️", "👋", "🐱", "🐈"]);
        compare(emoji[0].name, "grinning face");
        compare(emoji[0].group, "Smileys & Emotion");
        compare(emoji[5].group, "Animals & Nature");
    }

    function test_parseSkipsSkinTonesAndComponents() {
        const names = EmojiData.parse(sample).map(e => e.name);
        verify(!names.some(n => n.includes("skin tone")));
        verify(!names.includes("red hair"));
    }

    function test_filterRanksBestFirst() {
        const emoji = EmojiData.parse(sample);
        // "cat" starts "cat face" and is the whole "cat": both rank 0, Unicode order kept.
        compare(EmojiData.filter(emoji, "cat").map(e => e.emoji), ["🐱", "🐈"]);
        // A word in the middle ("smiling") ranks below names starting with the query.
        compare(EmojiData.filter(emoji, "smil").map(e => e.emoji), ["☺️", "😁"]);
    }

    function test_filterKeepsUnicodeOrderForTies() {
        // Many names starting the same way: they must stay in their original order.
        const emoji = [];
        for (let i = 0; i < 40; i++)
            emoji.push({ emoji: String(i), name: "grinning face " + i, group: "" });
        compare(EmojiData.filter(emoji, "grinning face").map(e => e.emoji), emoji.map(e => e.emoji));
    }

    function test_filterNeedsEveryWord() {
        const emoji = EmojiData.parse(sample);
        compare(EmojiData.filter(emoji, "face smiling").map(e => e.emoji), ["😁", "☺️"]);
        compare(EmojiData.filter(emoji, "face dog").length, 0);
    }

    function test_emptyQueryKeepsAll() {
        const emoji = EmojiData.parse(sample);
        compare(EmojiData.filter(emoji, "  ").length, emoji.length);
    }
}
