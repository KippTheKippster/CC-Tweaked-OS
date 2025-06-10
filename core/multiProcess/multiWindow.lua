-- This seems kinda pointless, might remove

return function(engine)
local path = ".core.multiProcess."
local multiProgram = require(path .. "multiProgram")    
local programViewport = require(path .. "programViewport")(engine:getObjects()["control"], multiProgram, term.current())
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
local function launchProgram(parent, programPath, x, y, w, h, ...)
    --multiProgram.launchProgram(path, x, y, w, h, ...)
    local window = programWindow:new{}
    parent:addChild(window)
    window:toFront()

    local viewport = programViewport:new{}
    window:addViewport(viewport)
    viewport:launchProgram(programPath, x, y, w, h, ...)
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

local function launchProcess(fun, x, y, w, h, ...) -- Launch a windowless process 
    local process = multiProgram.launchProcess(fun, x, y, w, h, ...)
    table.insert(nvProcesses, process)
    return process
end

local function start(fun, ...)
    term.clear()
    local w, h = term.getSize()
    local main = launchProcess(fun, 1, 1, w, h, ...)
    running = true
    while running do
        local data = table.pack(os.pullEventRaw())
        local event = data[1]

        for i = 1, #viewports do
            viewports[i]:unhandledEvent(event, data)
        end

        for i = 1, #nvProcesses do
            local ok, err = multiProgram.resumeProcess(nvProcesses[i], event, table.unpack(data, 2, #data)) --Fix!
            if ok == false then
                term.setCursorPos(1, 1)
                term.setBackgroundColor(colors.black)
                printError(err)
                return
            end
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