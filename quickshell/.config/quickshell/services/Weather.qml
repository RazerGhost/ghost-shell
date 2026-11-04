// The weather where you are, for the today menu: open-meteo (free, no account). The town comes
// from Settings (weatherLocation, set in the today menu); open-meteo's own place search turns it
// into coordinates, so no IP lookup service is involved. Updated every 30 minutes.
pragma Singleton

import QtQuick
import Quickshell
import "Weather.js" as WeatherJs

Singleton {
    id: root

    readonly property string location: Settings.values.weatherLocation
    property var place: null   // { name, latitude, longitude }
    property var current: null // { temperature, high, low, icon, label, sunrise, sunset }
    property var hours: []     // the coming hours: [{ hour, temperature, icon }] (the hourly widget)
    property string error: ""

    function get(url: string, done: var): void {
        const request = new XMLHttpRequest();
        request.onreadystatechange = () => {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;
            if (request.status !== 200) {
                root.error = "Couldn't reach the weather service";
                return;
            }
            try {
                done(JSON.parse(request.responseText));
            } catch (e) {
                root.error = "Unexpected answer from the weather service";
            }
        };
        request.open("GET", url);
        request.send();
    }

    // Look the town up again, then the weather.
    function refresh(): void {
        error = "";
        if (location === "") {
            place = null;
            current = null;
            return;
        }
        get("https://geocoding-api.open-meteo.com/v1/search?count=1&name=" + encodeURIComponent(location), answer => {
            root.place = WeatherJs.place(answer);
            if (!root.place) {
                root.error = "Couldn't find " + root.location;
                root.current = null;
                return;
            }
            update();
        });
    }

    function update(): void {
        if (!place)
            return;
        get(`https://api.open-meteo.com/v1/forecast?latitude=${place.latitude}&longitude=${place.longitude}`
            + "&current=temperature_2m,weather_code,is_day&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset"
            + "&hourly=temperature_2m,weather_code,is_day" // two days, so late in the evening has hours ahead
            + "&timezone=auto&forecast_days=2"
            + (root.fahrenheit ? "&temperature_unit=fahrenheit" : ""), answer => {
            root.current = WeatherJs.forecast(answer);
            root.hours = WeatherJs.hours(answer, 6);
            root.error = root.current ? "" : "Unexpected answer from the weather service";
        });
    }

    // Settings -> Weather and clock: °F instead of °C (open-meteo converts).
    readonly property bool fahrenheit: Settings.values.temperatureUnit === "fahrenheit"
    onFahrenheitChanged: update()

    onLocationChanged: refresh()
    Component.onCompleted: refresh()

    Timer {
        interval: 30 * 60 * 1000
        // While a town is set, also when its lookup failed (offline at login): otherwise nothing
        // would try again until the town changed.
        running: root.location !== ""
        repeat: true
        // Offline (or the service was down) last time: start over with the place lookup.
        onTriggered: root.current ? root.update() : root.refresh()
    }
}
