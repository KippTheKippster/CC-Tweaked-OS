local path = ".core."

local engine = {}

local object = require(path .. "object")
local collision = require(path .. "collision")
local input = require(path .. "input")(engine, collision)
local utils = require(path .. "utils")

engine.input = input
engine.utils = utils

engine.freeQueue = {}

local style = require(path .. "styles.style")(object)
local clickedStyle = require(path .. "styles.style")(style)

--Objects
local objectList = {}

local function requireObject(name, ...)
    local o = require(path .. "objects." .. name)(...)
    objectList[name] = o
    engine[name] = o
    return o
end

local control = requireObject("control", object, engine, style) -- Should it only be engine as argument?

local button = requireObject("button", control, style, clickedStyle)
local dropdown = requireObject("dropdown", button, input, utils)
local container = requireObject("container", control)
local vContainer = requireObject("vContainer", container)
local hContainer = requireObject("hContainer", container)
local flowContainer = requireObject("flowContainer", container)
local scrollContainer = requireObject("scrollContainer", container, input)
local windowControl = requireObject("windowControl", control, button)

local editStyle = style:new{}
editStyle.backgroundColor = colors.gray
editStyle.centerText = false

local editFocusStyle = editStyle:new()
editFocusStyle.backgroundColor = colors.lightGray

local lineEdit = requireObject("lineEdit", control, editStyle, editFocusStyle, input)
local icon = requireObject("icon", control)

--Engine
--Adds 'add' functions for all control objects Example: control:addButton()
for k, v in pairs(objectList) do
    control["add" .. utils.capitaliseFirst(k)] = function(o)
        local c = objectList[k]:new{}
        o:addChild(c)
        return c
    end
end

local parentTerm = term.current()
local initialW, initialH = parentTerm.getSize()
local screenBuffer = window.create(parentTerm, 1, 1, initialW, initialH)
--term.redirect(screenBuffer) -- NOTE IMPORTANT (Otherwise viewports will draw behind screenbuffer since their parents will be the parent of the screenbuffer)
--NOTE This in no longer needed since the parent term is now passed through as an argument when creating viewports

engine.parentTerm = parentTerm
engine.screenBuffer = screenBuffer

local globalRoot = false

if __Global == nil then
    globalRoot = true
    __Global = {}
    __Global.nextID = 0
    __Global.logFile = fs.open(".logs/" .. tostring(os.epoch("utc")) .. ".log", "w")
    __Global.log = function (...)
        local line = ""
        local data = table.pack(...)
        for k, v in ipairs(data) do
            line = line .. tostring(v) .. " "
        end
        line = line .. '\n'

        __Global.logFile.write(line)
        __Global.logFile.flush()
    end
end

local root = control:new{}
root.rendering = false
root.text = "root"
root.w = initialW
root.h = initialH
root.mouseIgnore = true
root:add()

engine.running = false
engine.queueRedraw = false
engine.background = true
engine.backgroundColor = colors.black
engine.root = root

local function onResizeEvent ()
    local w, h = parentTerm.getSize()
    screenBuffer.reposition(1, 1, w, h)
    engine.root.w, engine.root.h = w, h
end

local function drawTree (o)
    if o.visible == false then return end
    o:draw()
    local c = o.children
    for i = 1, #c do
        drawTree(c[i])
    end
end

local function redrawScreen ()
    term.redirect(screenBuffer)
    screenBuffer.setVisible(false)

    if engine.background == true then
        term.setBackgroundColor(engine.backgroundColor)
        term.clear()
    end

    drawTree(engine.root)

    if input.getCursorControl() == nil then
        term.setCursorBlink(false)
        term.setCursorPos(1, 1) -- Forces error messages to display at correct position
    else
        input.getCursorControl():updateCursor()
    end

    screenBuffer.setVisible(true)
    term.redirect(parentTerm)
end

engine.drawCount = 0
engine.start = function ()
    if engine.running then return end
    engine.running = true
    engine.input.addResizeEventListener(onResizeEvent)
    engine.root:_expandChildren() -- HACK this should be called automatically 

    redrawScreen()

    local function freeControl(c)
        for i, child in ipairs(c.children) do
            freeControl(child)
        end
        c:free()
    end

    local function freeQueue()
        for i, c in ipairs(engine.freeQueue) do
            if c.parent then
                c.parent:removeChild(c)
            end
            freeControl(c)
        end

        engine.freeQueue = {}
    end

    --[[
    while engine.running do
        input.processInput()
        redrawScreen()
    end
    ]]--

    local exception = dofile("rom/modules/main/cc/internal/tiny_require.lua")("cc.internal.exception")
    local barrier_ctx = { co = coroutine.running() }

    local drawTimerID = 0
    local id = __Global.nextID
    __Global.nextID = __Global.nextID + 1

    local fnDraw = function ()
        while engine.running do
            if engine.queueRedraw == true then
                engine.drawCount = engine.drawCount + 1
                redrawScreen()
                engine.queueRedraw = false
            end

            drawTimerID = os.startTimer(0.05)
            coroutine.yield()
        end
    end

    local fnInput = function ()
        while engine.running do
            input.processInput()
        end
    end

    local coDraw = coroutine.create(function() return exception.try_barrier(barrier_ctx, fnDraw) end)
    local coInput = coroutine.create(function() return exception.try_barrier(barrier_ctx, fnInput) end)

    coroutine.resume(coDraw)
    while engine.running do
        freeQueue()
        local data = table.pack(os.pullEventRaw())
        local ok, err = false, nil
        if data[1] == "timer" and data[2] == drawTimerID then
            ok, err = coroutine.resume(coDraw, table.unpack(data))
        else
            ok, err = coroutine.resume(coInput, table.unpack(data))
        end

        if ok == false then
            local current = term.current()
            term.redirect(engine.screenBuffer)
            term.setCursorPos(1, 1)
            engine.stop()
            term.redirect(current)
            error("Engine: " .. tostring(err), 0)
        end
    end

    engine.stop()
end

engine.stop = function ()
    engine.running = false

    if globalRoot then
        __Global.logFile.close()
    end
end

engine.getObjects = function ()
	return objectList
end

engine.getObject = function (name)
	return objectList[name]
end

engine.newStyle = function ()
    return style:new{}
end

engine.getDefaultStyle = function ()
    return style
end

engine.getDefaultClickedStyle = function ()
    return clickedStyle
end

engine.getFocus = function ()
    return input.getFocus()
end

return engine