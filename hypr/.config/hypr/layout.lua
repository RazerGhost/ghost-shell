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
--   swap <address> <address>  swap two windows (dragging one onto the other)
--   auto                    back to arranging by the number of windows
--   place                   place the windows again (after a mouse drag changed the shares)
-- e.g. hyprctl dispatch 'hl.dsp.layout("snap left")'.
local tiling = require("tiling")

-- Each workspace's arrangement and its last area, by workspace id; special workspaces (the
-- scratchpad) by name: Hyprland 0.57.1's Lua gives them no id (nil), and the layout skipped
-- their windows, which kept a size of -10 x -10 (the drop-down terminal didn't show; user's
-- find, 2026-11-04). Only the numbered ones are saved (tiling.encode).
local states, areas = {}, {}

-- A config reload runs this file again, which emptied `states`: every workspace went back to
-- arranging by the number of windows whenever the shell changed a Hyprland setting (game mode,
-- gaps, the windows editor...). So the arrangements are kept in a file and read back here. In
-- $XDG_RUNTIME_DIR (gone at logout) and per Hyprland instance: windows are known by their
-- addresses, which only mean something in this session.
local saved_path = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-tiling-"
    .. (os.getenv("HYPRLAND_INSTANCE_SIGNATURE") or "default")
-- After a reload Hyprland hands each workspace's windows to the layout one at a time, and a
-- chosen arrangement seeing only its first window would fall back to automatic. So the saved
-- arrangements wait here until all their windows are back (or a few seconds pass: a window may
-- have closed meanwhile), and the workspace is placed from a copy until then.
local restored = {}
do
    local file = io.open(saved_path)
    if file then
        restored = tiling.decode(file:read("a"))
        file:close()
    end
end
hl.timer(function() restored = {} end, { timeout = 3000, type = "oneshot" })

local function copy_of(ws, state)
    return tiling.decode(tiling.encode({ [ws] = state }))[ws]
end

local function all_back(state, ids)
    local here = {}
    for _, id in ipairs(ids) do
        here[id] = true
    end
    for _, id in ipairs(state.slots) do
        if id and not here[id] then
            return false
        end
    end
    return true
end

-- Written at most once a second, only when the text changed (a mouse drag changes the shares
-- every frame). The timer stops itself if a later load of this file took over, in case a reload
-- leaves the old one running with its old tables.
local saved_text, dirty = nil, false
GhostTilingLoad = (GhostTilingLoad or 0) + 1
local this_load = GhostTilingLoad
local save_timer
save_timer = hl.timer(function()
    if this_load ~= GhostTilingLoad then
        save_timer:set_enabled(false)
        return
    end
    if not dirty or next(restored) then
        return -- nothing new, or windows are still coming back (a copy's placement)
    end
    dirty = false
    local text = tiling.encode(states)
    if text == saved_text then
        return
    end
    local file = io.open(saved_path .. ".tmp", "w")
    if file then
        file:write(text)
        file:close()
        os.rename(saved_path .. ".tmp", saved_path)
        saved_text = text
    end
end, { timeout = 1000, type = "repeat" })

-- How far one resize step moves a border, as a share of the screen.
local resize_step = 0.05

local function key_of(workspace)
    return workspace and (workspace.id or workspace.name)
end

local function workspace_of(ctx)
    local target = ctx.targets[1]
    local window = target and target.window
    return window and key_of(window.workspace)
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
    local saved = restored[ws]
    if saved and all_back(saved, ids) then
        states[ws], restored[ws] = saved, nil
    elseif saved then
        states[ws] = copy_of(ws, saved)
    end
    states[ws] = tiling.sync(states[ws], ids, focused)
    areas[ws] = ctx.area
    dirty = true
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
        elseif command == "swap" then
            return tiling.swap(state, arg, address) or "shell layout: not two tiled windows here"
        elseif command == "auto" then
            tiling.reset(state)
            return true
        elseif command == "place" then
            return true -- the shares changed (a mouse drag); Hyprland places the windows again
        end
        return "shell layout: expected snap, resize, move, swap, auto or place"
    end,
})

-- For the shell's Snap Assist: the empty cells of a workspace as a JSON list of
-- { "x", "y", "width", "height" } (without gaps). JSON, so even no cells is an answer: hyprctl
-- prints "unknown request" for an empty string. hyprctl repl 'return ShellLayout.empty(1)'
ShellLayout = {
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

-- For drag.lua: a workspace's arrangement and the area it was last placed in (nil, nil before
-- the workspace had tiled windows).
return {
    key = key_of,
    workspace = function(ws)
        return states[ws], areas[ws]
    end,
}
