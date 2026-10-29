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
            + "&timezone=auto&forecast_days=1", answer => {
            root.current = WeatherJs.forecast(answer);
            root.error = root.current ? "" : "Unexpected answer from the weather service";
        });
    }

    onLocationChanged: refresh()
    Component.onCompleted: refresh()

    Timer {
        interval: 30 * 60 * 1000
        running: root.place !== null
        repeat: true
        // Offline (or the service was down) last time: start over with the place lookup.
        onTriggered: root.current ? root.update() : root.refresh()
    }
}
