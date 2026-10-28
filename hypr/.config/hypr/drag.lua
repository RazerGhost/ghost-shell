-----------------------------
---- RESIZING BY DRAGGING ----
-----------------------------
-- Super + right-drag on a tiled window moves the borders nearest the pointer (bound in
-- binds.lua). Hyprland doesn't tell Lua layouts how far a window is dragged, so while the button
-- is held a timer follows the pointer, changes the arrangement's shares (tiling.drag) and asks
-- the layout (layout.lua) to place the windows again.
local tiling = require("tiling")
local layout = require("layout")

-- The drag in progress, if any.
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

local function end_drag()
    if drag then
        drag.timer:set_enabled(false)
        drag = nil
    end
end

return { start = start_drag, stop = end_drag }
