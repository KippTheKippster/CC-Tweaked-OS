-- This seems kinda pointless, might remove

return function(engine)
local path = ".core.multiProcess."
local multiProgram = require(path .. "multiProgram")    
local programViewport = require(path .. "programViewport")(engine:getObjects()["control"], multiProgram)
local programWindow = require(path .. "programWindow")(engine:getObjects()["windowControl"], programViewport)

local viewports = {}
local nvProcesses = {}

local running = false

local focusedWindowStyle = engine:newStyle()
focusedWindowStyle.backgroundColor = colors.blue
focusedWindowStyle.textColor = colors.white
local unfocusedWindowStyle = engine:newStyle()
unfocusedWindowStyle.backgroundColor = colors.white
unfocusedWindowStyle.textColor = colors.black

-- I don't like having parent here
local function launchProgram(parentTerm, parentControl, programPath, x, y, w, h, ...)
    --multiProgram.launchProgram(path, x, y, w, h, ...)
    local window = programWindow:new{}
    parentControl:addChild(window)
    --window:toFront()

    local viewport = programViewport:new{}
    window:addViewport(viewport)
    viewport:launchProgram(parentTerm, programPath, x, y, w, h, ...)
    --viewport.program = multiProgram.launchProgram(programPath, x, y, w, h, ...)

    table.insert(viewports, viewport)

    window.x = x
    window.y = y
    window.w = w
    window.h = h
    window.style = focusedWindowStyle
    window.focusedStyle = focusedWindowStyle
    window.unfocusedStyle = unfocusedWindowStyle
    window.oldW = w --Fix bug so that the window doesn't resize to default size
    window.oldH = h

    return window
end

local function launchProcess(parentTerm, fun, x, y, w, h, ...) -- Launch a windowless process 
    local process = multiProgram.launchProcess(parentTerm, fun, x, y, w, h, ...)
    table.insert(nvProcesses, process)
    return process
end

local function start(parentTerm, fun, ...)
    term.clear()
    local w, h = term.getSize()
    local main = launchProcess(parentTerm, fun, 1, 1, w, h, ...)
    running = true
    while running do
        local data = table.pack(os.pullEventRaw())
        local event = data[1]

        for i = 1, #nvProcesses do -- NOTE this is only called for windowless processes (aka the processes from 'launchProcess' NOT 'launchProgram')
            --term.redirect(nvProcesses[i].window)
            local ok, err = coroutine.resume(nvProcesses[i].co, event, table.unpack(data, 2, #data)) --multiProgram.resumeProcess(nvProcesses[i], event, table.unpack(data, 2, #data)) --Fix!
            if ok == false then
                term.setCursorPos(1, 1)
                term.setBackgroundColor(colors.black)
                printError(err)
                return
            end
        end

        for i = 1, #viewports do
            viewports[i]:unhandledEvent(event, data)
        end
    end
end

local function exit()
    running = false
end

return
{
    launchProgram = launchProgram,
    launchProcess = launchProcess,
    start = start,
    exit = exit
}
end