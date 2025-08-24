local src = debug.getinfo(1, "S").short_src
local corePath = ".core"

---@class Engine
local engine = {}

local object = require(corePath .. ".object")
local collision = require(corePath .. ".collision")
local input = require(corePath .. ".input")(engine, collision)
local utils = require(corePath .. ".utils")

engine.input = input
engine.utils = utils
engine.freeQueue = {}

---@type Style
local style = require(corePath .. ".styles.style")(object)
---@type Style
local clickedStyle = require(corePath .. ".styles.style")(style)
---@type Style
local editStyle = style:new()
editStyle.backgroundColor = colors.gray
---@type Style
local editFocusStyle = editStyle:new()
editFocusStyle.backgroundColor = colors.lightGray


--Objects
local objectList = {}

local function requireObject(name, ...)
    local o = require(corePath .. ".objects." .. name)(...)
    objectList[name] = o
    return o
end

---@type Control
engine.Control = requireObject("control", object, engine, style)
---@type Button
engine.Button = requireObject("button", engine.Control, style, clickedStyle)
---@type Dropdown
engine.Dropdown = requireObject("dropdown", engine.Button, input, utils)
---@type ColorPicker
engine.ColorPicker = requireObject("colorPicker", engine.Control, engine.FlowContainer, input, style, utils)
---@type Container
engine.Container = requireObject("container", engine.Control)
---@type VContainer
engine.VContainer = requireObject("vContainer", engine.Container)
---@type HContainer
engine.HContainer = requireObject("hContainer", engine.Container)
---@type FlowContainer
engine.FlowContainer = requireObject("flowContainer", engine.Container)
---@type ScrollContainer
engine.ScrollContainer = requireObject("scrollContainer", engine.Container, input)
---@type WindowControl
engine.WindowControl = requireObject("windowControl", engine.Control, engine.Button)
---@type LineEdit
engine.LineEdit = requireObject("lineEdit", engine.Control, editStyle, editFocusStyle, input)
---@type Icon
engine.Icon = requireObject("icon", engine.Control)

local parentTerm = term.current()
local initialW, initialH = parentTerm.getSize()
local screenBuffer = window.create(parentTerm, 1, 1, initialW, initialH)

engine.parentTerm = parentTerm
engine.screenBuffer = screenBuffer

local globalRoot = false

if __Global == nil then
    globalRoot = true
    __Global = {}
    __Global.nextID = 0
    local dest = ".logs/"
    if fs.exists(dest) then
        local logs = fs.list(dest)
        for i = 1, #logs - 4 do
            fs.delete(fs.combine(dest, logs[i]))
        end 
    end

    __Global.logFile = fs.open(fs.combine(dest, tostring(os.epoch("utc")) .. ".log"), "w")
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
    --__Global.log = function () end
end

---@type Control
local root = engine.Control:new{}
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

    local coDraw = coroutine.create(fnDraw)
    local coInput = coroutine.create(fnInput)

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

---@return Control 
engine.getObject = function (name)
	return objectList[name]
end

---@return Style
engine.newStyle = function ()
    return style:new{}
end

---@return Style
engine.getDefaultStyle = function ()
    return style
end

---@return Style
engine.getDefaultClickedStyle = function ()
    return clickedStyle
end

---@return Control
engine.getFocus = function ()
    return input.getFocus()
end

---@return Engine
return engine