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

    function test_hours() {
        const answer = {
            current: { time: "2026-11-04T22:15" },
            hourly: { time: ["2026-11-04T22:00", "2026-11-04T23:00", "2026-11-05T00:00", "2026-11-05T01:00"],
                      temperature_2m: [9.6, 8.4, 7.5, 7.1], weather_code: [0, 3, 61, 0], is_day: [0, 0, 0, 0] }
        };
        // From the hour after now, across midnight, up to the count.
        compare(Weather.hours(answer, 2), [{ hour: "23", temperature: 8, icon: "cloud" },
                                           { hour: "00", temperature: 8, icon: "rainy" }]);
        compare(Weather.hours(answer, 10).length, 3);
        compare(Weather.hours({ current: {} }, 6), []);
        // Nothing after now.
        answer.current.time = "2026-11-05T01:30";
        compare(Weather.hours(answer, 6), []);
    }
}
