import QtQuick
import QtTest
import "../quickshell/.config/quickshell/services/Weather.js" as Weather

TestCase {
    name: "Weather"

    function test_describe() {
        compare(Weather.describe(0, true).icon, "sunny");
        compare(Weather.describe(0, false).icon, "clear_night");
        compare(Weather.describe(2, true).label, "Partly cloudy");
        compare(Weather.describe(63, true).label, "Rain");
        compare(Weather.describe(81, true).label, "Rain");
        compare(Weather.describe(75, true).icon, "weather_snowy");
        compare(Weather.describe(95, true).label, "Thunderstorm");
        compare(Weather.describe(42, true).label, ""); // unknown code
    }

    function test_place() {
        compare(Weather.place({ results: [{ name: "Utrecht", latitude: 52.09, longitude: 5.12, country: "Netherlands" }] }),
                { name: "Utrecht", latitude: 52.09, longitude: 5.12 });
        compare(Weather.place({}), null); // no results key when nothing matched
    }

    function test_forecast() {
        const answer = {
            current: { temperature_2m: 12.6, weather_code: 3, is_day: 1 },
            daily: { temperature_2m_max: [15.2], temperature_2m_min: [7.8], weather_code: [61] }
        };
        compare(Weather.forecast(answer), { temperature: 13, high: 15, low: 8, icon: "cloud", label: "Cloudy", sunrise: null, sunset: null });
        answer.daily.sunrise = ["2026-10-29T07:45"];
        answer.daily.sunset = ["2026-10-29T17:21"];
        compare(Weather.forecast(answer).sunrise, 465);
        compare(Weather.forecast(answer).sunset, 1041);
        compare(Weather.forecast({ current: {} }), null);
    }
}
