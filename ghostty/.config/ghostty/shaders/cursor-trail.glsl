// A short trail behind the cursor when it jumps (a click, a jump to the end of a line, a new
// prompt), in the cursor's color: the wallpaper's accent, which matugen gives Ghostty's theme.
// Typing (the cursor moving one or two cells) leaves none. Loaded by ../config (custom-shader).
// Ghostty runs it Shadertoy-style: iChannel0 is the terminal as drawn, coordinates are pixels
// with y going up, and iCurrentCursor / iPreviousCursor are each cursor's top-left corner (xy)
// and size (zw); iTimeCursorChange is when it last moved.

const float DURATION = 0.2;  // seconds the trail takes to catch up and fade
const float OPACITY = 0.6;   // the trail's strength at its start

// How far p is from the segment a-b, and where along it (0 at a, 1 at b).
vec2 segment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 0.0001), 0.0, 1.0);
    return vec2(length(pa - ba * h), h);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 screen = texture(iChannel0, fragCoord / iResolution.xy);
    fragColor = screen;

    // Unfocused, the time since the last frame can be huge: no trail then.
    float t = (iTime - iTimeCursorChange) / DURATION;
    if (iFocus == 0 || t >= 1.0)
        return;

    vec4 cur = iCurrentCursor;
    vec4 prev = iPreviousCursor;
    vec2 head = cur.xy + vec2(cur.z, -cur.w) * 0.5;
    vec2 start = prev.xy + vec2(prev.z, -prev.w) * 0.5;
    float cell = max(cur.w * 0.5, 1.0); // about a cell's width, whatever the cursor's style
    if (distance(head, start) < cell * 2.5)
        return;

    // The tail eases from where the cursor was toward where it is, fading as it goes.
    float eased = 1.0 - pow(1.0 - t, 3.0);
    vec2 tail = mix(start, head, eased);
    vec2 d = segment(fragCoord, tail, head);
    float radius = cur.w * mix(0.12, 0.4, d.y); // thin at the tail, a cursor's height at the head
    float alpha = smoothstep(radius, radius - 1.5, d.x) * (1.0 - eased) * OPACITY;

    // The cursor itself stays as it is.
    bool inCursor = fragCoord.x >= cur.x && fragCoord.x <= cur.x + cur.z
                 && fragCoord.y <= cur.y && fragCoord.y >= cur.y - cur.w;
    if (inCursor)
        alpha = 0.0;

    vec3 color = iCurrentCursorColor.rgb;
    fragColor = vec4(screen.rgb * (1.0 - alpha) + color * alpha, screen.a * (1.0 - alpha) + alpha);
}
