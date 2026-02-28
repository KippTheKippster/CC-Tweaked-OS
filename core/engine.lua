local src = debug.getinfo(1, "S").source:sub(2)
local corePath = fs.getDir(src)
local coreDotPath = "." .. corePath:gsub("/", ".") 

---@class Engine
local engine = {}
---@type MultiProgram?
engine.mp = nil
---@type Process?
engine.p = nil

---@type Object
local object = require(coreDotPath .. ".object")
local collision = require(coreDotPath .. ".collision")
---@type Input
local input = require(coreDotPath .. ".input")(engine, collision)
---@type Utils
local utils = require(coreDotPath .. ".utils")

---@type Input
engine.input = input
---@type Utils
engine.utils = utils
engine.freeQueue = {}

---@type Style
local style = require(coreDotPath .. ".style")(object)
engine.normalStyle = style

---@param base Style?
---@return Style
local function newStyle(base)
    if base then
        return base:new()
    end
    return style:new()
end
engine.newStyle = newStyle

engine.clickStyle = newStyle()
engine.clickStyle.backgroundColor = colors.white
engine.clickStyle.textColor = colors.orange

engine.focusStyle = newStyle()
engine.focusStyle.backgroundColor = colors.gray

engine.editStyle = newStyle()
engine.editStyle.backgroundColor = colors.gray

engine.editFocusStyle = newStyle()
engine.editFocusStyle.backgroundColor = colors.lightGray

engine.dropdownOptionNormalStyle = newStyle()
engine.dropdownOptionClickStyle = newStyle(engine.clickStyle)

local windowStyle = newStyle()
engine.windowNormalStyle = newStyle(windowStyle)
engine.windowFocusStyle = newStyle(windowStyle)
engine.windowClickStyle = newStyle()
engine.windowExitButtonStyle = newStyle()

--Objects
local function requireObject(name, ...)
    return require(coreDotPath .. ".objects." .. name)(...)
end

---@type Control
engine.Control = requireObject("control", object, engine, style)
---@type Button
engine.Button = requireObject("button", engine.Control, style, engine.clickStyle)
---@type Dropdown
engine.Dropdown = requireObject("dropdown", engine.Button, input, utils, engine.dropdownOptionNormalStyle,
    engine.dropdownOptionClickStyle)
---@type ColorPicker
engine.ColorPicker = requireObject("colorPicker", engine.Control, input, style, utils)
---@type Container
engine.Container = requireObject("container", engine.Control)
---@type VContainer
engine.VContainer = requireObject("vContainer", engine.Container)
---@type HContainer
engine.HContainer = requireObject("hContainer", engine.Container)
---@type FlowContainer
engine.FlowContainer = requireObject("flowContainer", engine.Container)
---@type ScrollContainer
engine.ScrollContainer = requireObject("scrollContainer", engine.Container, collision, input)
---@type WindowControl
engine.WindowControl = requireObject("windowControl", engine.Control, engine.Button, engine.windowNormalStyle,
    engine.windowFocusStyle, engine.windowClickStyle, engine.windowExitButtonStyle)
---@type LineEdit
engine.LineEdit = requireObject("lineEdit", engine.Control, engine.input, engine.editStyle, engine.editFocusStyle)
---@type Icon
engine.Icon = requireObject("icon", engine.Control)

local parentTerm = term.current()
local initialW, initialH = parentTerm.getSize()
local screenBuffer = window.create(parentTerm, 1, 1, initialW, initialH)

--[[
local bufferLines = {}
local bufferWrite = screenBuffer.write
screenBuffer.write = function (text)
    local x, y = screenBuffer.getCursorPos()
    local c = screenBuffer.getBackgroundColor()
    if bufferLines[y] == nil or bufferLines[y][x] == nil then
    else
        bufferLines[y][x] = c
    end
    bufferWrite(text)
end
]] --

engine.parentTerm = parentTerm
engine.screenBuffer = screenBuffer          

---@type Control
local root = engine.Control:new()
root.rendering = false
root.__name = "root"
root.w = initialW
root.h = initialH
root.mouseIgnore = true
root:add()

engine.running = false
engine.queueRedraw = false
engine.background = true
engine.backgroundColor = colors.black
engine.root = root

local function resizeBuffer(w, h)
    screenBuffer.reposition(1, 1, w, h)
    engine.root.w, engine.root.h = w, h
    --[[
    for y = 1, h do
        if bufferLines[y] == nil then
            bufferLines = {}
        end
        for x = 1, h do
            if bufferLines[x] == nil then
                bufferLines[y] = engine.backgroundColor
            end
        end
    end
    ]] --
end

---@param o Control
---@param topLevelList table?
local function drawTree(o, topLevelList)
    if o.visible == false then return end
    if o.topLevel and topLevelList then
        table.insert(topLevelList, o) -- TODO make list persistent
    else
        o:draw()
        local c = o.children
        for i = 1, #c do
            drawTree(c[i], topLevelList)
        end
    end
end

local function redrawScreen()
    term.redirect(screenBuffer)
    screenBuffer.setVisible(false)

    if engine.background == true then
        term.setBackgroundColor(engine.backgroundColor)
        term.clear()
    end

    local topLevelList = {}
    drawTree(engine.root, topLevelList)
    for i, control in ipairs(topLevelList) do
        drawTree(control, nil)
    end

    if input.getCursorControl() == nil then
        term.setCursorBlink(false)
        term.setCursorPos(1, 1) -- Forces error messages to display at correct position
    else
        input.getCursorControl():updateCursor()
    end

    screenBuffer.setVisible(true)
    term.redirect(parentTerm)
end

local drawTimerID = 0
local function fnDraw()
    while engine.running do
        if engine.queueRedraw == true then
            engine.drawCount = engine.drawCount + 1
            redrawScreen()
            engine.queueRedraw = false
        end

        if engine.mp then
            drawTimerID = engine.mp.startTimer(engine.p, 0.05)
        else
            drawTimerID = os.startTimer(0.05)
        end
        coroutine.yield()
    end
end

local fnInput = function()
    while engine.running do
        term.redirect(parentTerm)
        local event = input.processInput()
        if event == "term_resize" then
            resizeBuffer(parentTerm.getSize())
        elseif event == "terminate" then
            engine.stop()
        end
    end
end

engine.drawCount = 0
function engine.start()
    if engine.running then return end

    --[[
        error = function (msg, lvl)
            term.setBackgroundColor(colors.black)
            term.redirect(parentTerm)
            term.setCursorPos(1, 1)
            lvl = lvl or 1
            fnError(msg, lvl + 1)
        end
        ]] --

    if __mp and __p then
        engine.mp = __mp
        engine.p = __p
    end

    engine.running = true
    resizeBuffer(screenBuffer.getSize())
    redrawScreen()

    local function freeTree(c)
        for _, child in ipairs(c.children) do
            freeTree(child)
        end
        c:free()
    end

    local function freeQueue()
        for _, c in ipairs(engine.freeQueue) do
            if c ~= nil and c:isValid() then
                if c.parent then
                    c.parent:removeChild(c)
                end
                freeTree(c)
            end
        end

        engine.freeQueue = {}
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
            error("Engine: " .. tostring(err), 0)
            engine.stop()
            local current = term.current()
            term.redirect(engine.screenBuffer)
            term.setCursorPos(1, 1)
            term.redirect(current)
        end
    end

    engine.stop()
end

function engine.stop()
    engine.running = false
end

function engine.newMultiProgram()
    return require(coreDotPath .. ".multiProcess.multiProgram")
end

---@param mp MultiProgram
---@return string?
function engine.startMultiProgram(mp)
    engine.mp = mp
    engine.p = mp.launchProcess(engine.screenBuffer, engine.start, nil, 1, 1, screenBuffer.getSize())

    local err = mp.start()
    return err
end

---@return Engine
return engine
