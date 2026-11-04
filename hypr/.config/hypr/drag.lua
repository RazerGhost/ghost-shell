------------------------------------
---- DRAGGING TILED WINDOWS ----
------------------------------------
-- Hyprland doesn't tell Lua layouts where a tiled window is dragged, so these follow the pointer
-- themselves (bound in binds.lua, next to Hyprland's own drag and resize for floating windows):
-- - Super + right-drag moves the borders nearest the pointer: while the button is held a timer
--   changes the arrangement's shares (tiling.drag) and asks the layout (layout.lua) to place the
--   windows again.
-- - Super + left-drag swaps the window with the tiled one it's dropped on.
-- - Super + Shift + left-drag takes a tiled window out of the tiling: it floats at its size where
--   it is and follows the pointer (a timer, as above); dropped over a tiled window, a floating one goes back
--   into the tiling in that window's place (the two swap), dropped anywhere else it stays floating.
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

-- The tiled window under `pos`, leaving out `except` (the one being dragged sits under the
-- pointer too). None where a floating window covers `pos`: floating windows sit above tiled
-- ones, so the drag is Hyprland's own resize or move of that window, not one for the window
-- underneath.
local function tiled_window_at(pos, except)
    local found
    for _, window in ipairs(hl.get_windows()) do
        local ws = window.workspace
        if window.address ~= except and shown(window) and contains(window, pos) then
            if window.floating then
                return nil
            elseif not found and ws and not ws.special then
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
    local state, area = layout.workspace(window and layout.key(window.workspace))
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

-- Hyprland's own drag (bound beside this) takes the tiled window out of the layout while it's
-- carried and gives it back when it's let go, after this release bind; the layout adds a window
-- that comes back at the end (the right). So the swap waits until it's back, then puts it in the
-- place of whichever tiled window is under the pointer (none where it already is).
local function end_move()
    local pos, address = hl.get_cursor_pos(), moving
    moving = nil
    if not (pos and address) then
        return
    end
    hl.timer(function()
        local target = tiled_window_at(pos, address)
        if target then
            hl.dispatch(hl.dsp.layout("swap " .. address .. " " .. target.address))
        end
    end, { timeout = 50, type = "oneshot" })
end

-- The topmost window under `pos`: a floating one before the tiled one under it.
local function window_at(pos)
    local tiled
    for _, window in ipairs(hl.get_windows()) do
        local ws = window.workspace
        if shown(window) and contains(window, pos) and ws and not ws.special then
            if window.floating then
                return window
            end
            tiled = tiled or window
        end
    end
    return tiled
end

-- The window carried by Super + Shift + left-drag: its address, its size, and where the pointer
-- holds it (from its top-left corner).
local pop

-- Floating a window in a bind sets its own size and place after the bind returns (centred on the
-- pointer at its last floating size), so the size is set from the timer, which also carries it.
local function follow_pop()
    local pos = hl.get_cursor_pos()
    local window = pop and pos and hl.get_window("address:" .. pop.address)
    if not window then
        return
    end
    local target = "address:" .. pop.address
    if window.size.x ~= pop.size.x or window.size.y ~= pop.size.y then
        hl.dispatch(hl.dsp.window.resize({ window = target, x = pop.size.x, y = pop.size.y }))
    end
    local x, y = pos.x - pop.grab.x, pos.y - pop.grab.y
    if window.at.x ~= x or window.at.y ~= y then
        hl.dispatch(hl.dsp.window.move({ window = target, x = x, y = y }))
    end
end

local function end_pop()
    if not pop then
        return
    end
    pop.timer:set_enabled(false)
    local address, pos = pop.address, hl.get_cursor_pos()
    pop = nil
    if not (pos and tiled_window_at(pos, address)) then
        return -- let go over no tiled window: it stays floating there
    end
    -- Back into the tiling; once the layout has placed it, it swaps with whichever tiled window is
    -- under the pointer then, so it ends up where it was let go.
    local target = "address:" .. address
    hl.dispatch(hl.dsp.window.float({ window = target, action = "disable" }))
    hl.dispatch(hl.dsp.focus({ window = target }))
    hl.timer(function()
        local over = tiled_window_at(pos, address)
        if over then
            hl.dispatch(hl.dsp.layout("swap " .. address .. " " .. over.address))
        end
    end, { timeout = 50, type = "oneshot" })
end

local function start_pop()
    end_pop() -- one whose release never came
    local pos = hl.get_cursor_pos()
    local window = pos and window_at(pos)
    if not window then
        return
    end
    if not window.floating then
        hl.dispatch(hl.dsp.window.float({ window = "address:" .. window.address, action = "enable" }))
    end
    pop = {
        address = window.address,
        size = { x = window.size.x, y = window.size.y },
        grab = { x = pos.x - window.at.x, y = pos.y - window.at.y },
        timer = hl.timer(follow_pop, { timeout = 16, type = "repeat" }),
    }
end

return { start = start_drag, stop = end_drag, start_move = start_move, stop_move = end_move,
         start_pop = start_pop, stop_pop = end_pop }
