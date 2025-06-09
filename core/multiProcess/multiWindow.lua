-- This seems kinda pointless, might remove

return function(engine)
local path = ".core.multiProcess."
local multiProgram = require(path .. "multiProgram")    
local programViewport = require(path .. "programViewport")(engine:getObjects()["control"], multiProgram, term.current())
local programWindow = require(path .. "programWindow")(engine:getObjects()["windowControl"], programViewport)

local viewports = {}
local nvProcesses = {}

local focusedWindowStyle = engine:newStyle()
focusedWindowStyle.backgroundColor = colors.blue
focusedWindowStyle.textColor = colors.white
local unfocusedWindowStyle = engine:newStyle()
unfocusedWindowStyle.backgroundColor = colors.white
unfocusedWindowStyle.textColor = colors.black

local function launchProgram(programPath, x, y, w, h, ...)
    --multiProgram.launchProgram(path, x, y, w, h, ...)
    local window = programWindow:new{}
    engine.root:addChild(window)
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

local updating = false

local function start(fun, ...)
    term.clear()
    local w, h = term.getSize()
    local main = launchProcess(fun, 1, 1, w, h, ...)

    --local baseDrawPixel = paintutils.drawPixelInternal
    --paintutils.drawPixelInternal = function(x, y, color)
    --    baseDrawPixel(1, 1, color)
    --    if updating then return end
    --    updating = true
    --    for i = 1, #viewports do
    --        viewports[i]:updateWindow()
    --    end
    --    updating = false
    --end

    while true do 
        local data = table.pack(os.pullEventRaw())
        local event = data[1]

        --local w = nil
        --if event == "mouse_click" then
        --    local button, x, y = data[2], data[3], data[4]
        --    w = getWindow(x, y)
        --    if w ~= nil then    
        --    --    setFocusIndex(getIndex(w))
        --    end
        --    --local process = multiProgram.getProcess(getIndex(w))
        --    for i = 1, #viewports do
        --        if viewports[i].program == w then
        --            --viewports[i]:grabFocus()
        --        end
        --    end
        --end

        for i = 1, #viewports do
            if viewports[i] == w then
                --viewports[i]:grabFocus()
            end
            viewports[i]:unhandledEvent(event, data)
        end

        for i = 1, #nvProcesses do
            multiProgram.resumeProcess(nvProcesses[i], event, table.unpack(data, 2, #data)) --Fix!
        end

        --multiProgram.resumeProcessAtIndex(1, event, table.unpack(data, 2, #data)) --Fix!
        --multiProgram.resumeProcesses(event, table.unpack(data, 2, #data))
    end
end

--[[
            if event == "mouse_click" or event == "mouse_drag" or event == "mouse_drag" or event == "mouse_up" then
            --local p = tProcesses[1]
            local p = main
            for i = 1, #viewports do
                if viewports[i].focus == true then
                    p = viewports[i].program
                end
            end
            local button, x, y = data[2], data[3], data[4]
            if p ~= getWindow(x, y) then
                p = main
            end 
            local offsetX, offsetY = p.window.getPosition()
            multiProgram.resumeProcess(p, event, button, x - offsetX + 1, y - offsetY + 1)
        else
            multiProgram.resumeProcesses(event, table.unpack(data, 2, #data))
        end
]]

return 
{
    launchProgram = launchProgram,
    launchProcess = launchProcess,
    start = start
}
end