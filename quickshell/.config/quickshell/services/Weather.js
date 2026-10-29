// Reading open-meteo's answers for services/Weather.qml. Plain JavaScript, so it can be tested on
// its own (tests/tst_weather.qml).
.pragma library

// WMO weather codes (open-meteo's weather_code) as a Material Symbols icon and a label.
function describe(code, isDay) {
    if (code === 0)
        return { icon: isDay ? "sunny" : "clear_night", label: "Clear" };
    if (code === 1 || code === 2)
        return { icon: isDay ? "partly_cloudy_day" : "partly_cloudy_night", label: "Partly cloudy" };
    if (code === 3)
        return { icon: "cloud", label: "Cloudy" };
    if (code === 45 || code === 48)
        return { icon: "foggy", label: "Fog" };
    if (code >= 51 && code <= 57)
        return { icon: "rainy", label: "Drizzle" };
    if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82))
        return { icon: "rainy", label: "Rain" };
    if ((code >= 71 && code <= 77) || code === 85 || code === 86)
        return { icon: "weather_snowy", label: "Snow" };
    if (code >= 95 && code <= 99)
        return { icon: "thunderstorm", label: "Thunderstorm" };
    return { icon: "cloud", label: "" };
}

// The first place of a geocoding search ({ results: [{ name, latitude, longitude, country }] }),
// as { name, latitude, longitude }; null when nothing matched.
function place(answer) {
    const first = answer && answer.results && answer.results[0];
    return first ? { name: first.name, latitude: first.latitude, longitude: first.longitude } : null;
}

// "2026-10-29T07:45" (open-meteo's local times) -> minutes since midnight; null if missing.
function minutesOf(time) {
    const match = /T(\d\d):(\d\d)/.exec(time ?? "");
    return match ? Number(match[1]) * 60 + Number(match[2]) : null;
}

// A forecast answer as { temperature, high, low, icon, label, sunrise, sunset } (rounded °C;
// sunrise and sunset in minutes since midnight, or null); null if incomplete.
function forecast(answer) {
    const now = answer && answer.current;
    const day = answer && answer.daily;
    if (!now || !day || typeof now.temperature_2m !== "number")
        return null;
    const kind = describe(now.weather_code, now.is_day === 1);
    return {
        temperature: Math.round(now.temperature_2m),
        high: Math.round(day.temperature_2m_max[0]),
        low: Math.round(day.temperature_2m_min[0]),
        icon: kind.icon,
        label: kind.label,
        sunrise: minutesOf(day.sunrise?.[0]),
        sunset: minutesOf(day.sunset?.[0])
    };
}
