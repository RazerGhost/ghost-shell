-----------------------------
---- WINDOW BEHAVIOUR ----
-----------------------------
-- Windows / macOS-style window handling on top of Hyprland's defaults.

-- Whatever gets focus comes to the front: Hyprland raises a floating window when it's clicked,
-- but not when focus moves by a key, by closing another window or from the shell. Without a
-- window argument, alter_zorder acts on the active window, which is the one just focused.
hl.on("window.active", function()
    hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)

-- Apps reopen where you last had them, like on Windows and macOS. When a floating window closes,
-- its position and size are saved per app (window class); when the app opens again, it goes back
-- there. Only if no other window of that app is open: dialogs and second windows keep the default
-- (centered) placement instead of landing on top of the first one.
local positions_file = os.getenv("HOME") .. "/.local/state/hypr/window-positions"
local positions = {}

-- One line per app: class, x, y, width, height, separated by tabs.
local function load_positions()
    local file = io.open(positions_file, "r")
    if not file then
        return
    end
    for line in file:lines() do
        local class, x, y, w, h = line:match("^(.-)\t(-?%d+)\t(-?%d+)\t(%d+)\t(%d+)$")
        if class then
            positions[class] = { x = tonumber(x), y = tonumber(y), w = tonumber(w), h = tonumber(h) }
        end
    end
    file:close()
end

local function save_positions()
    os.execute("mkdir -p '" .. positions_file:match("^(.*)/") .. "'")
    local file = io.open(positions_file, "w")
    if not file then
        print("windows.lua: can't write " .. positions_file)
        return
    end
    for class, p in pairs(positions) do
        file:write(string.format("%s\t%d\t%d\t%d\t%d\n", class, p.x, p.y, p.w, p.h))
    end
    file:close()
end

-- Whether a rectangle lies on one of the monitors (a saved spot can be off-screen after
-- unplugging one).
local function on_screen(p)
    for _, m in ipairs(hl.get_monitors()) do
        local mw, mh = m.width / m.scale, m.height / m.scale
        if p.x >= m.x and p.y >= m.y and p.x + p.w <= m.x + mw and p.y + p.h <= m.y + mh then
            return true
        end
    end
    return false
end

local function others_open(window)
    for _, w in ipairs(hl.get_windows()) do
        if w.class == window.class and w.address ~= window.address then
            return true
        end
    end
    return false
end

load_positions()

hl.on("window.close", function(window)
    local workspace = window.workspace and window.workspace.name or ""
    if window.class == "" or not window.floating or window.fullscreen ~= 0
        or workspace:find("^special:") then
        return
    end
    positions[window.class] = { x = window.at.x, y = window.at.y, w = window.size.x, h = window.size.y }
    save_positions()
end)

hl.on("window.open", function(window)
    local p = positions[window.class]
    if not p or not window.floating or others_open(window) or not on_screen(p) then
        return
    end
    local target = "address:" .. window.address
    hl.dispatch(hl.dsp.window.resize({ window = target, x = p.w, y = p.h }))
    hl.dispatch(hl.dsp.window.move({ window = target, x = p.x, y = p.y }))
end)
