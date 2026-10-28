import QtQuick
import QtTest
import "../quickshell/.config/quickshell/launcher/Calc.js" as Calc

TestCase {
    name: "Calc"

    function test_isExpression() {
        verify(Calc.isExpression("2^10"));
        verify(Calc.isExpression("5 km in miles"));
        verify(Calc.isExpression("20 usd to eur"));
        verify(Calc.isExpression("sqrt(16)"));
        verify(Calc.isExpression("20% of 80"));
        verify(Calc.isExpression("12 - 4"));
        verify(!Calc.isExpression("firefox"));
        verify(!Calc.isExpression("2048"));      // a game, not a sum
        verify(!Calc.isExpression("steam"));
    }

    function test_prepare() {
        compare(Calc.prepare("5 km in miles"), "5 km to -miles");
        compare(Calc.prepare("20 usd to eur"), "20 usd to -eur");
        compare(Calc.prepare("1 h to -min"), "1 h to -min");
        compare(Calc.prepare("2^10"), "2^10");
    }

    function test_answer() {
        compare(Calc.answer("3.106855961 mi\n", "5 km in miles"), "3.106855961 mi");
        compare(Calc.answer("warning: something\n1024\n", "2^10"), "1024");
        compare(Calc.answer("", "2^"), "");
        compare(Calc.answer("Unrecognized option.\n", "x"), "");
        compare(Calc.answer("12\n", "12"), "");
    }
}
