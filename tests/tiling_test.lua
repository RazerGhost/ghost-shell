-- Tests for hypr/.config/hypr/tiling.lua (the tiling layout's arrangements). Run from the repo root:
--   lua tests/tiling_test.lua
package.path = "hypr/.config/hypr/?.lua;" .. package.path
local T = require("tiling")

local failures, count = 0, 0

local function same(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then
        return a == b or (type(a) == "number" and type(b) == "number" and math.abs(a - b) < 1e-9)
    end
    for k, v in pairs(a) do
        if not same(v, b[k]) then
            return false
        end
    end
    for k in pairs(b) do
        if a[k] == nil then
            return false
        end
    end
    return true
end

local function show(v)
    if type(v) ~= "table" then
        return tostring(v)
    end
    local parts = {}
    for k, x in pairs(v) do
        table.insert(parts, tostring(k) .. "=" .. show(x))
    end
    table.sort(parts)
    return "{" .. table.concat(parts, ", ") .. "}"
end

local function test(name, fn)
    count = count + 1
    local ok, err = pcall(fn)
    if not ok then
        failures = failures + 1
        print("FAIL " .. name .. ": " .. tostring(err))
    end
end

local function eq(actual, expected)
    if not same(actual, expected) then
        error("expected " .. show(expected) .. ", got " .. show(actual), 2)
    end
end

-- Column shapes as { rows per column }.
local function shape(state)
    local s = {}
    for i, c in ipairs(state.columns) do
        s[i] = c.rows
    end
    return s
end

local area = { x = 0, y = 0, w = 1200, h = 600 }

test("auto follows the window count", function()
    eq(shape({ columns = T.auto(1) }), { 1 })
    eq(shape({ columns = T.auto(2) }), { 1, 1 })
    eq(shape({ columns = T.auto(3) }), { 1, 2 })
    eq(shape({ columns = T.auto(4) }), { 2, 2 })
    eq(shape({ columns = T.auto(5) }), { 1, 2, 2 })
end)

test("new windows go after the focused one", function()
    local s = T.sync(nil, { "a", "b" }, nil)
    eq(s.slots, { "a", "b" })
    s = T.sync(s, { "a", "b", "c" }, "a")
    eq(s.slots, { "a", "c", "b" })
    eq(shape(s), { 1, 2 })
end)

test("a closed window's space goes to the others", function()
    local s = T.sync(nil, { "a", "b", "c" }, nil)
    s = T.sync(s, { "a", "c" }, nil)
    eq(s.slots, { "a", "c" })
    eq(shape(s), { 1, 1 })
end)

test("resized shares stay while the shape does", function()
    local s = T.sync(nil, { "a", "b" }, nil)
    assert(T.resize(s, "a", "right", 0.1))
    eq(s.columns[1].w, 0.6)
    s = T.sync(s, { "a", "b" }, nil)
    eq(s.columns[1].w, 0.6)
    s = T.sync(s, { "a", "b", "c" }, "b")
    eq(s.columns[1].w, 0.5)
end)

test("snapping a spot picks the arrangement that fits", function()
    local s = T.sync(nil, { "a", "b" }, nil)
    s = T.snap(s, "b", "left-third")
    eq(s.auto, false)
    eq(s.slots, { "b", "a" })
    eq(s.columns[1].w, 1 / 3)
    s = T.sync(nil, { "a", "b", "c" }, nil)
    s = T.snap(s, "c", "left-third")
    eq(s.slots, { "c", "a", "b" })
    eq(shape(s), { 1, 1, 1 })
end)

test("a lone window snapped to a half leaves the other half empty", function()
    local s = T.sync(nil, { "a" }, nil)
    s = T.snap(s, "a", "right")
    eq(s.slots, { false, "a" })
    eq(T.empty(s, area), { { x = 0, y = 0, w = 600, h = 600 } })
    -- A window that comes fills the empty half.
    s = T.sync(s, { "a", "b" }, "a")
    eq(s.slots, { "b", "a" })
    eq(T.empty(s, area), {})
end)

test("windows that don't fit stack in another column", function()
    local s = T.sync(nil, { "a", "b", "c" }, nil)
    s = T.snap(s, "a", "left")
    eq(s.slots, { "a", "b", "c" })
    eq(shape(s), { 1, 2 })
    -- Snapped right, the extra rows go left.
    s = T.snap(s, "a", "right")
    eq(shape(s), { 2, 1 })
    eq(s.slots[3], "a")
end)

test("a chosen arrangement keeps its shape", function()
    local s = T.sync(nil, { "a", "b" }, nil)
    s = T.snap(s, "a", "left-two-thirds")
    -- A third window gets a row in the last column.
    s = T.sync(s, { "a", "b", "c" }, "a")
    eq(shape(s), { 1, 2 })
    eq(s.auto, false)
    -- It leaving takes the row away again.
    s = T.sync(s, { "a", "b" }, nil)
    eq(shape(s), { 1, 1 })
    eq(s.columns[1].w, 2 / 3)
    -- A window alone in its column leaving: back to automatic.
    s = T.sync(s, { "b" }, nil)
    eq(s.auto, true)
    eq(s.slots, { "b" })
end)

test("boxes", function()
    local s = T.sync(nil, { "a", "b", "c" }, nil)
    local boxes = T.boxes(s, area)
    eq(boxes[1], { id = "a", box = { x = 0, y = 0, w = 600, h = 600 } })
    eq(boxes[3], { id = "c", box = { x = 600, y = 300, w = 600, h = 300 } })
end)

test("a dropped window takes the place of the one under the pointer", function()
    local s = T.sync(nil, { "a", "b", "c" }, nil) -- a left, b top right, c bottom right
    eq(T.drop(s, area, "a", { x = 900, y = 450 }), true)
    eq(s.slots, { "c", "b", "a" })
    eq(T.drop(s, area, "a", { x = 900, y = 450 }), false) -- over its own cell
    eq(T.drop(s, area, "a", { x = 1300, y = 100 }), false) -- outside the area
    eq(s.slots, { "c", "b", "a" })
end)

test("resize moves the border on the window's side, or the other one at the edge", function()
    local s = T.sync(nil, { "a", "b", "c" }, nil)
    T.resize(s, "c", "right", 0.1) -- c is in the right column: its left border moves right
    eq(s.columns[1].w, 0.6)
    T.resize(s, "a", "left", 0.1)  -- a is at the left edge: its right border moves left
    eq(s.columns[1].w, 0.5)
    T.resize(s, "b", "down", 0.1)  -- b is the top row: its bottom border moves down
    eq(s.columns[2].h, { 0.6, 0.4 })
    eq(T.resize(s, "a", "up", 0.1), false) -- a is alone in its column
    -- Not past the smallest share.
    eq(T.resize(s, "b", "down", 0.3), false)
end)

test("drag moves a border from where it was at the start", function()
    local s = T.sync(nil, { "a", "b", "c" }, nil)
    local base = T.shares(s)
    assert(T.drag(s, base, "a", "right", 0.1))
    eq(s.columns[1].w, 0.6)
    -- The next step starts from the drag's start again, not from the last step.
    assert(T.drag(s, base, "a", "right", 0.05))
    eq(s.columns[1].w, 0.55)
    -- c's top border is the one between b and c.
    assert(T.drag(s, base, "c", "top", -0.1))
    eq(s.columns[2].h, { 0.4, 0.6 })
    -- Never past the smallest share, and not at the screen's edge.
    assert(T.drag(s, base, "b", "left", 0.9))
    eq(s.columns[2].w, T.min_share)
    eq(T.drag(s, base, "a", "left", 0.1), false)
    eq(T.drag(s, base, "a", "top", 0.1), false)
    -- The arrangement changed: the drag stops.
    s = T.sync(s, { "a", "b", "c", "d" }, "c")
    eq(T.drag(s, base, "a", "right", 0.1), false)
end)

test("move swaps with the neighbour in that direction", function()
    local s = T.sync(nil, { "a", "b", "c" }, nil)
    assert(T.move(s, "c", "left", area))
    eq(s.slots, { "c", "b", "a" })
    assert(T.move(s, "b", "down", area))
    eq(s.slots, { "c", "a", "b" })
    eq(T.move(s, "c", "left", area), false)
end)

test("swap trades two windows' cells", function()
    local s = T.sync(nil, { "a", "b", "c" }, nil)
    assert(T.swap(s, "a", "c"))
    eq(s.slots, { "c", "b", "a" })
    eq(T.swap(s, "a", "z"), false)
end)

test("reset goes back to automatic, keeping the order", function()
    local s = T.sync(nil, { "a" }, nil)
    s = T.snap(s, "a", "right")
    T.reset(s)
    eq(s.auto, true)
    eq(s.slots, { "a" })
    eq(shape(s), { 1 })
    eq(T.empty(s, area), {})
end)

test("unknown spots and windows are errors", function()
    local s = T.sync(nil, { "a" }, nil)
    local result, err = T.snap(s, "a", "diagonal")
    eq(result, nil)
    assert(err:find("unknown spot"))
    result, err = T.snap(s, "z", "left")
    eq(result, nil)
end)

test("the window menu's spots are the layout's", function()
    -- The menu draws its spots from quickshell's SnapLayout.js; each must be one Hyprland knows.
    local js = io.open("quickshell/.config/quickshell/services/SnapLayout.js"):read("a")
    local menu = {}
    for name in js:gmatch('\n%s+"([%w-]+)":%s+{') do
        menu[name] = true
    end
    local spots = {}
    for name in pairs(T.spots) do
        spots[name] = true
    end
    eq(menu, spots)
end)

test("arrangements survive encoding (a config reload)", function()
    local states = {}
    states[1] = T.sync(nil, { "0x1", "0x2", "0x3" }, nil)
    states[2] = T.sync(nil, { "0xa", "0xb" }, nil)
    T.snap(states[2], "0xa", "left-third")
    T.resize(states[2], "0xa", "right", 0.05)
    states[-98] = T.sync(nil, { "0xc" }, nil) -- a special workspace
    local back = T.decode(T.encode(states))
    eq(back, states)
    eq(T.encode(back), T.encode(states))
end)

test("an empty cell and an empty file", function()
    local s = T.sync(nil, { "a", "b", "c", "d" }, nil)
    T.snap(s, "a", "top-left")
    s.slots[2] = false
    eq(T.decode(T.encode({ [3] = s }))[3], s)
    eq(T.decode(""), {})
    eq(T.decode(nil), {})
    eq(T.encode({}), "")
end)

test("damaged lines are left out", function()
    local good = T.encode({ [1] = T.sync(nil, { "a", "b" }, nil) })
    local back = T.decode(good
        .. "2 chosen 0.5:1;0.5:1 a\n"             -- two cells, one window
        .. "3 chosen 2:1 a\n"                     -- a share over 1
        .. "4 sideways 1:1 a\n"                   -- not auto or chosen
        .. "5 auto 1:1 $(rm)\n"                   -- not an id
        .. "nonsense\n")
    eq(back, T.decode(good))
end)

test("special workspaces (by name) aren't saved", function()
    local s = T.sync(nil, { "a" }, nil)
    eq(T.encode({ [1] = s, ["special:magic"] = T.sync(nil, { "b" }, nil) }), T.encode({ [1] = s }))
end)

print(string.format("%d passed, %d failed", count - failures, failures))
os.exit(failures == 0 and 0 or 1)
