-- The arrangements behind the "shell" layout (layout.lua), as plain Lua with no Hyprland calls, so
-- it can be tested on its own: lua tests/tiling_test.lua.
--
-- A workspace's arrangement is a list of columns, each { w = share of the width, rows = n,
-- h = { share of the height per row } }, and `slots`: the window in each cell, column by column
-- (false for an empty cell). Windows are identified by any string (layout.lua uses addresses).
local M = {}

-- The arrangements the window menu's spots belong to, as { width share, rows } per column.
M.arrangements = {
    full               = { { 1, 1 } },
    halves             = { { 1 / 2, 1 }, { 1 / 2, 1 } },
    thirds             = { { 1 / 3, 1 }, { 1 / 3, 1 }, { 1 / 3, 1 } },
    ["third-two-thirds"] = { { 1 / 3, 1 }, { 2 / 3, 1 } },
    ["two-thirds-third"] = { { 2 / 3, 1 }, { 1 / 3, 1 } },
    quarters           = { { 1 / 2, 2 }, { 1 / 2, 2 } },
    ["main-stack"]     = { { 1 / 2, 1 }, { 1 / 2, 2 } },
}

-- The window menu's spots (the names in quickshell's snap/SnapLayouts.qml), each as the
-- arrangements that have it: { arrangement, column, row }. A spot in more than one picks the one
-- that fits the number of windows best (see snap).
M.spots = {
    ["left"]             = { { "halves", 1, 1 } },
    ["right"]            = { { "halves", 2, 1 } },
    ["top-left"]         = { { "quarters", 1, 1 } },
    ["bottom-left"]      = { { "quarters", 1, 2 } },
    ["top-right"]        = { { "quarters", 2, 1 } },
    ["bottom-right"]     = { { "quarters", 2, 2 } },
    ["left-third"]       = { { "third-two-thirds", 1, 1 }, { "thirds", 1, 1 } },
    ["center-third"]     = { { "thirds", 2, 1 } },
    ["right-third"]      = { { "two-thirds-third", 2, 1 }, { "thirds", 3, 1 } },
    ["left-two-thirds"]  = { { "two-thirds-third", 1, 1 } },
    ["right-two-thirds"] = { { "third-two-thirds", 2, 1 } },
}

-- The smallest share a column or row can be resized to.
M.min_share = 0.15

local function even(n)
    local h = {}
    for i = 1, n do
        h[i] = 1 / n
    end
    return h
end

local function columns_of(spec)
    local columns = {}
    for i, c in ipairs(spec) do
        columns[i] = { w = c[1], rows = c[2], h = even(c[2]) }
    end
    return columns
end

local function cell_count(columns)
    local n = 0
    for _, c in ipairs(columns) do
        n = n + c.rows
    end
    return n
end

local function index_of(list, value)
    for i, v in ipairs(list) do
        if v == value then
            return i
        end
    end
end

-- The cell index (in `slots`) of column `col`, row `row`.
local function cell_index(columns, col, row)
    local i = 0
    for c = 1, col - 1 do
        i = i + columns[c].rows
    end
    return i + row
end

-- The column and row of cell index `i`.
local function cell_position(columns, i)
    for c, column in ipairs(columns) do
        if i <= column.rows then
            return c, i
        end
        i = i - column.rows
    end
end

-- Arranging by the number of windows: one fills the screen, two side by side, three as one big
-- and two stacked, more in a grid of columns (the later columns get the extra rows).
function M.auto(n)
    if n <= 1 then
        return columns_of(M.arrangements.full)
    elseif n == 2 then
        return columns_of(M.arrangements.halves)
    elseif n == 3 then
        return columns_of(M.arrangements["main-stack"])
    end
    local cols = math.ceil(math.sqrt(n))
    local base, extra = n // cols, n % cols
    local spec = {}
    for c = 1, cols do
        spec[c] = { 1 / cols, base + ((c > cols - extra) and 1 or 0) }
    end
    return columns_of(spec)
end

-- Gives `column` another row at the bottom (for a window that doesn't fit the arrangement).
local function add_row(column)
    column.rows = column.rows + 1
    column.h = even(column.rows)
end

-- Removes row `row` from `column`, giving its share to the others.
local function remove_row(column, row)
    local share = table.remove(column.h, row)
    column.rows = column.rows - 1
    for i = 1, column.rows do
        column.h[i] = column.h[i] / (1 - share)
    end
end

-- Keeps `state` (nil for a new workspace) in step with the windows there now, `ids` in Hyprland's
-- order; new windows go after `focused`. Returns the state.
--
-- Arranged automatically (state.auto), the arrangement follows the number of windows, keeping
-- resized shares while the shape stays the same. A chosen arrangement keeps its shape: a new
-- window fills an empty cell, else gets a row in the last column; a closing window's row goes
-- away, unless it was alone in its column: then it's back to automatic.
function M.sync(state, ids, focused)
    state = state or { auto = true, columns = {}, slots = {} }
    local present = {}
    for _, id in ipairs(ids) do
        present[id] = true
    end

    -- Windows that left.
    local back_to_auto = false
    for i = #state.slots, 1, -1 do
        local id = state.slots[i]
        if id and not present[id] then
            local c, r = cell_position(state.columns, i)
            if state.auto or state.columns[c].rows == 1 then
                state.slots[i] = false
                back_to_auto = back_to_auto or not state.auto
            else
                remove_row(state.columns[c], r)
                table.remove(state.slots, i)
            end
        end
    end

    -- Windows that came: after the focused one, in an empty cell, or in a new row.
    local new = {}
    for _, id in ipairs(ids) do
        if not index_of(state.slots, id) then
            table.insert(new, id)
        end
    end

    if state.auto or back_to_auto then
        local order = {}
        for _, id in ipairs(state.slots) do
            if id then
                table.insert(order, id)
            end
        end
        for _, id in ipairs(new) do
            local after = focused and index_of(order, focused)
            table.insert(order, after and after + 1 or #order + 1, id)
        end
        local columns = M.auto(#order)
        if state.auto and #columns == #state.columns then
            -- Same shape as before: keep the resized shares.
            local same = true
            for c, column in ipairs(columns) do
                same = same and column.rows == state.columns[c].rows
            end
            if same then
                columns = state.columns
            end
        end
        state.auto, state.columns, state.slots = true, columns, order
        return state
    end

    for _, id in ipairs(new) do
        local empty = index_of(state.slots, false)
        if empty then
            state.slots[empty] = id
        else
            add_row(state.columns[#state.columns])
            table.insert(state.slots, id)
        end
    end
    return state
end

-- Puts window `id` in `spot` (a key of M.spots), switching to an arrangement that has it; the
-- other windows fill the remaining cells in their current order, and ones that don't fit get rows
-- in another column. Cells left over stay empty (Snap Assist offers windows for them). Returns
-- the state, or nil and an error for an unknown spot or window.
function M.snap(state, id, spot)
    local options = M.spots[spot]
    if not options then
        return nil, "unknown spot: " .. tostring(spot)
    end
    if not (state and index_of(state.slots, id)) then
        return nil, "not a tiled window here: " .. tostring(id)
    end

    local others = {}
    for _, other in ipairs(state.slots) do
        if other and other ~= id then
            table.insert(others, other)
        end
    end

    -- The smallest arrangement with room for every window, else the biggest.
    local n = #others + 1
    local choice
    for _, option in ipairs(options) do
        local cells = cell_count(columns_of(M.arrangements[option[1]]))
        local best = choice and cell_count(columns_of(M.arrangements[choice[1]]))
        if not choice
            or (cells >= n and (best < n or cells < best))
            or (cells < n and best < n and cells > best) then
            choice = option
        end
    end

    local columns = columns_of(M.arrangements[choice[1]])
    local target = cell_index(columns, choice[2], choice[3])
    local slots = {}
    for i = 1, cell_count(columns) do
        slots[i] = false
    end
    slots[target] = id
    for _, other in ipairs(others) do
        local empty = index_of(slots, false)
        if empty then
            slots[empty] = other
        else
            -- Full: a row in the last column that isn't the snapped window's.
            local c = #columns == choice[2] and #columns - 1 or #columns
            if c < 1 then
                c = 1
            end
            add_row(columns[c])
            table.insert(slots, cell_index(columns, c, columns[c].rows), other)
        end
    end

    state.auto, state.columns, state.slots = false, columns, slots
    return state
end

-- Every cell's rectangle in `area` ({ x, y, w, h }), as { id or false, box }, in slot order.
function M.boxes(state, area)
    local result = {}
    local x = area.x
    local i = 0
    for _, column in ipairs(state.columns) do
        local w = area.w * column.w
        local y = area.y
        for r = 1, column.rows do
            local h = area.h * column.h[r]
            i = i + 1
            table.insert(result, { id = state.slots[i] or false, box = { x = x, y = y, w = w, h = h } })
            y = y + h
        end
        x = x + w
    end
    return result
end

-- Moves the border of window `id`'s cell that lies in `direction` ("left", "right", "up",
-- "down") by `step` (a share of the screen), or its opposite border when that side is the
-- screen's edge: Super+Alt+Right grows a left window and shrinks a right one. Returns false when
-- there's no border to move (one column, or one row for up/down).
function M.resize(state, id, direction, step)
    local i = index_of(state.slots, id)
    if not i then
        return false
    end
    local c, r = cell_position(state.columns, i)
    local horizontal = direction == "left" or direction == "right"
    local shares = horizontal and {} or state.columns[c].h
    if horizontal then
        for k, column in ipairs(state.columns) do
            shares[k] = column.w
        end
    end
    local at = horizontal and c or r
    if #shares < 2 then
        return false
    end
    local towards_end = direction == "right" or direction == "down"
    -- The border between `a` and `a + 1` moves by +step (towards the end) or -step.
    local a = towards_end and (at < #shares and at or at - 1) or (at > 1 and at - 1 or at)
    local delta = towards_end and step or -step
    if shares[a] + delta < M.min_share or shares[a + 1] - delta < M.min_share then
        return false
    end
    shares[a] = shares[a] + delta
    shares[a + 1] = shares[a + 1] - delta
    if horizontal then
        for k, column in ipairs(state.columns) do
            column.w = shares[k]
        end
    end
    return true
end

-- A copy of the column widths and every column's row heights, for M.drag.
function M.shares(state)
    local shares = { w = {}, h = {} }
    for c, column in ipairs(state.columns) do
        shares.w[c] = column.w
        shares.h[c] = { table.unpack(column.h) }
    end
    return shares
end

-- Mouse resizing: the border on `side` ("left", "right", "top", "bottom") of window `id`'s cell,
-- moved by `delta` (a share of the screen) from where it was in `base` (M.shares at the start of
-- the drag), stopping before a column or row gets smaller than M.min_share. Returns false when
-- that side is the screen's edge, or the arrangement changed since `base`.
function M.drag(state, base, id, side, delta)
    local i = index_of(state.slots, id)
    if not i or #base.w ~= #state.columns then
        return false
    end
    for k, column in ipairs(state.columns) do
        if #base.h[k] ~= column.rows then
            return false
        end
    end
    local c, r = cell_position(state.columns, i)
    local horizontal = side == "left" or side == "right"
    local from = horizontal and base.w or base.h[c]
    local a = (side == "right" or side == "bottom") and (horizontal and c or r) or (horizontal and c or r) - 1
    if a < 1 or a >= #from then
        return false
    end
    local d = math.max(M.min_share - from[a], math.min(delta, from[a + 1] - M.min_share))
    local shares = { table.unpack(from) }
    shares[a], shares[a + 1] = from[a] + d, from[a + 1] - d
    if horizontal then
        for k, column in ipairs(state.columns) do
            column.w = shares[k]
        end
    else
        state.columns[c].h = shares
    end
    return true
end

-- Swaps window `id` with the cell next to it in `direction`, measured on the boxes of
-- M.boxes (so it works across columns with different rows). Returns false if there's none.
function M.move(state, id, direction, area)
    local boxes = M.boxes(state, area)
    local i = index_of(state.slots, id)
    if not i then
        return false
    end
    local from = boxes[i].box
    local cx, cy = from.x + from.w / 2, from.y + from.h / 2
    local best, best_distance
    for j, cell in ipairs(boxes) do
        local b = cell.box
        local x, y = b.x + b.w / 2, b.y + b.h / 2
        local ahead = (direction == "left" and x < cx - 1) or (direction == "right" and x > cx + 1)
            or (direction == "up" and y < cy - 1) or (direction == "down" and y > cy + 1)
        -- Overlapping on the other axis, so "right" doesn't jump to a cell diagonally away.
        local overlaps
        if direction == "left" or direction == "right" then
            overlaps = b.y < from.y + from.h and from.y < b.y + b.h
        else
            overlaps = b.x < from.x + from.w and from.x < b.x + b.w
        end
        if j ~= i and ahead and overlaps then
            local distance = math.abs(x - cx) + math.abs(y - cy)
            if not best or distance < best_distance then
                best, best_distance = j, distance
            end
        end
    end
    if not best then
        return false
    end
    state.slots[i], state.slots[best] = state.slots[best], state.slots[i]
    return true
end

-- Back to arranging by the number of windows, keeping their order (resized shares reset).
function M.reset(state)
    local order = {}
    for _, id in ipairs(state.slots) do
        if id then
            table.insert(order, id)
        end
    end
    state.auto, state.columns, state.slots = true, M.auto(#order), order
    return state
end

-- Empty cells' rectangles (Snap Assist fills them).
function M.empty(state, area)
    local result = {}
    for _, cell in ipairs(M.boxes(state, area)) do
        if not cell.id then
            table.insert(result, cell.box)
        end
    end
    return result
end

return M
