------------------------------------
---- DRAGGING TILED WINDOWS ----
------------------------------------
-- Hyprland doesn't tell Lua layouts where a tiled window is dragged, so these follow the pointer
-- themselves (bound in binds.lua, next to Hyprland's own drag and resize for floating windows):
-- - Super + right-drag moves the borders nearest the pointer: while the button is held a timer
--   changes the arrangement's shares (tiling.drag) and asks the layout (layout.lua) to place the
--   windows again.
-- - Super + left-drag swaps the window with the tiled one it's dropped on.
local tiling = require("tiling")
local layout = require("layout")

-- The drag in progress, if any.
local drag

local function contains(window, pos)
    return pos.x >= window.at.x and pos.x < window.at.x + window.size.x
        and pos.y >= window.at.y and pos.y < window.at.y + window.size.y
end

-- A window drawn on screen now: mapped, not a group's hidden tab, on a shown workspace (a
-- pinned one shows on every workspace).
local function shown(window)
    local ws = window.workspace
    return window.mapped and not window.hidden and (window.pinned or (ws and ws.visible))
end

-- The tiled window under `pos`, other than `except` (the one being dragged sits under the
-- pointer too). None where a floating window covers `pos`: floating windows sit above tiled
-- ones, so the drag is Hyprland's own resize or move of that window, not one for the window
-- underneath.
local function tiled_window_at(pos, except)
    local found
    for _, window in ipairs(hl.get_windows()) do
        local ws = window.workspace
        if shown(window) and contains(window, pos) then
            if window.floating then
                return nil
            elseif not found and ws and not ws.special and window.address ~= except then
                found = window
            end
        end
    end
    return found
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

local function end_drag()
    if drag then
        drag.timer:set_enabled(false)
        drag = nil
    end
end

local function start_drag()
    -- A drag whose release never came (Super let go first) would otherwise keep its timer
    -- running for good once this one replaces it.
    end_drag()
    local pos = hl.get_cursor_pos()
    local window = pos and tiled_window_at(pos)
    local state, area = layout.workspace(window and window.workspace.id)
    if not (window and state and area) then
        return -- a floating window: Hyprland's own resize bind handles it
    end
    -- The layout message goes to the focused workspace, so focus the window being resized.
    hl.dispatch(hl.dsp.focus({ window = "address:" .. window.address }))
    drag = {
        state = state,
        base = tiling.shares(state),
        area = area,
        id = window.address,
        start = { x = pos.x, y = pos.y },
        -- The borders on the pointer's side of the window's middle, like resizing from a corner.
        side_x = pos.x > window.at.x + window.size.x / 2 and "right" or "left",
        side_y = pos.y > window.at.y + window.size.y / 2 and "bottom" or "top",
        timer = hl.timer(follow_pointer, { timeout = 16, type = "repeat" }),
    }
end

-- The window being moved by Super + left-drag, if it's tiled.
local moving

local function start_move()
    local pos = hl.get_cursor_pos()
    local window = pos and tiled_window_at(pos)
    moving = window and window.address
    if moving then
        -- The layout message goes to the focused workspace.
        hl.dispatch(hl.dsp.focus({ window = "address:" .. moving }))
    end
end

local function end_move()
    local pos = hl.get_cursor_pos()
    local target = moving and pos and tiled_window_at(pos, moving)
    if target then
        hl.dispatch(hl.dsp.layout("swap " .. moving .. " " .. target.address))
    end
    moving = nil
end

return { start = start_drag, stop = end_drag, start_move = start_move, stop_move = end_move }
