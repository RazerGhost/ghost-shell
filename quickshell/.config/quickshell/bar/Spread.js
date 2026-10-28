// Spacing for the closed island's two sides: the workspace dots and the status icons are given the
// same width, and the narrower group spreads its items out to fill it, so the island is symmetric
// and the time sits exactly in the middle.
.pragma library

// The width of items laid out `minSpacing` apart.
function naturalWidth(widths, minSpacing) {
    if (widths.length === 0)
        return 0;
    return widths.reduce((sum, w) => sum + w, 0) + minSpacing * (widths.length - 1);
}

// The spacing that makes the items exactly `width` wide, but never less than `minSpacing`.
function spacing(widths, minSpacing, width) {
    if (widths.length < 2)
        return minSpacing;
    const items = widths.reduce((sum, w) => sum + w, 0);
    return Math.max(minSpacing, (width - items) / (widths.length - 1));
}
