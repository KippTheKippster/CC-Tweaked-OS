-- Handles coroutines of multiple programs

local path = ".core."

local tProcesses = {}
local focusIndex = 1
--local parentTerm = term.current()
local collision = require(path .. "collision")

local function getIndex(p)
    for i = 1, #tProcesses do
        if tProcesses[i] == p then
            return i
        end
    end
end

local function setFocusIndex(n)
    focusIndex = n
end

local function resumeProcess(p, event, ...)
    --term.redirect(p.window)
    return coroutine.resume(p.co, event, ...)
    --p.queueRedraw()
end

local function resumeProcessAtIndex(i, event, ...)
    resumeProcess(tProcesses[i], event, ...)
end

local function resumeProcesses(event, ...)
    for i = 1, #tProcesses do
        resumeProcess(tProcesses[i], event, ...)
    end
end

local i = 0
local function launchProcess(parentTerm, fun, x, y, w, h, ...)
    local p = {}
    local args = table.pack(...)
    p.window = window.create(parentTerm, x, y, w, h, true)
    p.co = coroutine.create(function(args)
        term.redirect(p.window)
        fun(p, table.unpack(args, 1, args.n))
        term.redirect(parentTerm)
    end)
    tProcesses[#tProcesses + 1] = p
    --p.queueRedraw = function() redraw = true end -- Not sure what this does
    --p.resumeProcess = function(event, ...) resumeProcess(p, event, ...) end
    setFocusIndex(#tProcesses)
    return p
end

local function launchProgram(parentTerm, path, x, y, w, h, ...)
    local env = { shell = shell, multishell = multishell }

    env.require, env.package = dofile("rom/modules/main/cc/require.lua").make(env, "")
    local programArgs = table.pack(...)
    return launchProcess(parentTerm, function(p)
        os.run(env, path, table.unpack(programArgs, 1, programArgs.n))
    end, x, y, w, h)
end

local function clearProcess(i, force)
    local force = force or false
    local p = tProcesses[i]
    if coroutine.status(p.co) == "dead" or force == true then
        table.remove(tProcesses, i)
        if nCurrentProcess == nil then
            if i > 1 then
                setFocusIndex(i - 1)
            elseif #tProcesses > 0 then
                setFocusIndex(1)
            end
        end
    end
end

local function clearProcesses(force)
    local force = force or false
    for i = 1, #tProcesses do
        clearProcess(i, force)
    end
end

local function endProcess(p)
    debug.sethook(p.co, function() error("almost dead") end, "l")
    coroutine.resume(p.co)
    --print(coroutine.status(p.co))
end

local function getWindow(x, y)
    for i = 1, #tProcesses do
        local p = tProcesses[#tProcesses - i + 1]
        local window = p.window
        local x1, y1 = window.getPosition()
        local w, h = window.getSize()
        if window.isVisible() and collision.inArea(x, y, x1, y1, w, h) then
            return p
        end
    end

    return nil
end 

--function redrawWindows()
--    for i = 1, #tProcesses do
--        tProcesses[i].window.redraw()
--    end
--end


--local function getFocusIndex()
--    return focusIndex
--end

local function getProcess(i)
    return tProcesses[i]
end

local running = true
local function start() -- Note this goes unused
    term.clear()
    while running do 
        --term.redirect(parentTerm)
        local data = table.pack(os.pullEventRaw())
        local event = data[1]

        if event == "mouse_click" then
            local button, x, y = data[2], data[3], data[4]
            local p = getWindow(x, y)
            if p ~= nil then
                setFocusIndex(getIndex(p))
            end
        end

        if event == "mouse_click" or event == "mouse_drag" or event == "mouse_drag" or event == "mouse_up" then
            --local p = tProcesses[getFocusIndex()]
            local p = tProcesses[1]
            local button, x, y = data[2], data[3], data[4]
            local offsetX, offsetY = p.window.getPosition()
            resumeProcess(p, event, button, x - offsetX + 1, y - offsetY + 1)
        else --if event == "timer" then
            resumeProcesses(event, table.unpack(data, 2, #data))
        end
    end
end

return {
    launchProgram = launchProgram, 
    launchProcess = launchProcess, 
    resumeProcess = resumeProcess,
    resumeProcesses = resumeProcesses,
    start = start,
    endProcess = endProcess,
    resumeProcessAtIndex = resumeProcessAtIndex,
    getProcess = getProcess,
    clearProcesses = clearProcesses
}