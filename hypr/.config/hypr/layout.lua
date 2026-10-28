---------------------------
---- TILING LAYOUT ----
---------------------------
-- The "shell" layout (look.lua sets it as lua:shell): windows tile in our own arrangements
-- instead of dwindle's splits. The arrangements are in tiling.lua; this file connects them to
-- Hyprland. Floating windows (dialogs, and any window floated from the window menu) aren't part
-- of it.
--
-- Arranged by the number of windows until you pick a spot for one (Super+Left/Right or the
-- window menu); the shell sends that as a layout message:
--   snap <spot> [address]   put the window (default: the focused one) in a spot: left, right,
--                           top-left, left-third, right-two-thirds... (tiling.spots)
--   resize <direction>      move the focused window's border: left, right, up, down
--   move <direction>        swap the focused window with its neighbour that way
--   auto                    back to arranging by the number of windows
--   place                   place the windows again (after a mouse drag changed the shares)
-- e.g. hyprctl dispatch 'hl.dsp.layout("snap left")'.
local tiling = require("tiling")

-- Each workspace's arrangement and its last area, by workspace id.
local states, areas = {}, {}

-- How far one resize step moves a border, as a share of the screen.
local resize_step = 0.05

local function workspace_of(ctx)
    local target = ctx.targets[1]
    local window = target and target.window
    return window and window.workspace and window.workspace.id
end

-- Windows by address; a target without a window (rare, see the wiki) gets a stand-in.
local function id_of(target)
    return target.window and target.window.address or ("target-" .. target.index)
end

-- The workspace's state, brought up to date with its windows. Returns the state, the targets
-- by id and the focused window's id.
local function current(ctx)
    local ws = workspace_of(ctx)
    if not ws then
        return nil
    end
    local ids, targets, focused = {}, {}, nil
    for _, target in ipairs(ctx.targets) do
        local id = id_of(target)
        table.insert(ids, id)
        targets[id] = target
        if target.window and target.window.active then
            focused = id
        end
    end
    states[ws] = tiling.sync(states[ws], ids, focused)
    areas[ws] = ctx.area
    return states[ws], targets, focused
end

hl.layout.register("shell", {
    recalculate = function(ctx)
        local state, targets = current(ctx)
        if not state then
            return
        end
        for _, cell in ipairs(tiling.boxes(state, ctx.area)) do
            if cell.id and targets[cell.id] then
                targets[cell.id]:place(cell.box)
            end
        end
    end,

    layout_msg = function(ctx, msg)
        local state, _, focused = current(ctx)
        if not state then
            return "shell layout: no tiled windows here"
        end
        local command, arg, address = msg:match("^(%S+)%s*(%S*)%s*(%S*)")
        if command == "snap" then
            local result, err = tiling.snap(state, address ~= "" and address or focused, arg)
            return result and true or "shell layout: " .. err
        elseif command == "resize" then
            return tiling.resize(state, focused, arg, resize_step) or "shell layout: nothing to resize that way"
        elseif command == "move" then
            return tiling.move(state, focused, arg, ctx.area) or "shell layout: no window that way"
        elseif command == "auto" then
            tiling.reset(state)
            return true
        elseif command == "place" then
            return true -- the shares changed (a mouse drag); Hyprland places the windows again
        end
        return "shell layout: expected snap, resize, move, auto or place"
    end,
})

-- Super + right-drag on a tiled window moves the borders nearest the pointer (binds.lua). Hyprland
-- doesn't tell Lua layouts how far a window is dragged, so while the button is held a timer
-- follows the pointer and asks the layout to place the windows again.
local drag

local function tiled_window_at(pos)
    for _, window in ipairs(hl.get_windows()) do
        local ws = window.workspace
        if not window.floating and ws and ws.visible and not ws.special
            and pos.x >= window.at.x and pos.x < window.at.x + window.size.x
            and pos.y >= window.at.y and pos.y < window.at.y + window.size.y then
            return window
        end
    end
end

local function follow_pointer()
    local pos = hl.get_cursor_pos()
    if not (drag and pos) then
        return
    end
    local dx = (pos.x - drag.start.x) / drag.area.w
    local dy = (pos.y - drag.start.y) / drag.area.h
    if dx == drag.dx and dy == drag.dy then
        return
    end
    drag.dx, drag.dy = dx, dy
    local moved = tiling.drag(drag.state, drag.base, drag.id, drag.side_x, dx)
    moved = tiling.drag(drag.state, drag.base, drag.id, drag.side_y, dy) or moved
    if moved then
        hl.dispatch(hl.dsp.layout("place"))
    end
end

local function start_drag()
    local pos = hl.get_cursor_pos()
    local window = pos and tiled_window_at(pos)
    local ws = window and window.workspace.id
    if not (window and states[ws] and areas[ws]) then
        return -- a floating window: Hyprland's own resize bind handles it
    end
    -- The layout message goes to the focused workspace, so focus the window being resized.
    hl.dispatch(hl.dsp.focus({ window = "address:" .. window.address }))
    drag = {
        state = states[ws],
        base = tiling.shares(states[ws]),
        area = areas[ws],
        id = window.address,
        start = { x = pos.x, y = pos.y },
        -- The borders on the pointer's side of the window's middle, like resizing from a corner.
        side_x = pos.x > window.at.x + window.size.x / 2 and "right" or "left",
        side_y = pos.y > window.at.y + window.size.y / 2 and "bottom" or "top",
        timer = hl.timer(follow_pointer, { timeout = 16, type = "repeat" }),
    }
end

local function end_drag()
    if drag then
        drag.timer:set_enabled(false)
        drag = nil
    end
end

-- For the shell's Snap Assist: the empty cells of a workspace as a JSON list of
-- { "x", "y", "width", "height" } (without gaps). JSON, so even no cells is an answer: hyprctl
-- prints "unknown request" for an empty string. hyprctl repl 'return ShellLayout.empty(1)'
ShellLayout = {
    start_drag = start_drag,
    end_drag = end_drag,

    empty = function(ws)
        local state, area = states[ws], areas[ws]
        local cells = {}
        local round = function(v) return math.floor(v + 0.5) end
        for _, box in ipairs(state and area and tiling.empty(state, area) or {}) do
            table.insert(cells, string.format('{"x":%d,"y":%d,"width":%d,"height":%d}',
                round(box.x), round(box.y), round(box.w), round(box.h)))
        end
        return "[" .. table.concat(cells, ",") .. "]"
    end,
}
