local path = ".core."

local engine = {}

local object = require(path .. "object")
local collision = require(path .. "collision")
local input = require(path .. "input")(engine, collision)
local utils = require(path .. "utils")

engine.input = input
engine.utils = utils

local renderQueue = {}

engine.renderQueue = renderQueue

local style = object:new{}
style.backgroundColor = colors.lightGray
style.borderColor = colors.gray
style.textColor = colors.black
style.border = false


--Objects
local objectList = {}

local function requireObject(name, ...)
    local o = require(path .. "objects." .. name)(...)
    objectList[name] = o
    return o
end

local control = requireObject("control", object, engine, style) -- Should it only be engine as argument?

local clickedStyle = style:new{}
clickedStyle.backgroundColor = colors.white
clickedStyle.textColor = colors.orange

local button = requireObject("button", control, style, clickedStyle)
local dropdown = requireObject("dropdown", button, input, utils)
local container = requireObject("container", control)
local vContainer = requireObject("vContainer", container)
local hContainer = requireObject("hContainer", container)
local flowContainer = requireObject("flowContainer", container)
local scrollContainer = requireObject("scrollContainer", container)
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

if __Global == nil then
    __Global = {}
end

__Global.initial = parentTerm
__Global.buffer = screenBuffer
__Global.print = function ()
    printError("Initial: " .. tostring(__Global.initial))
    printError("Buffer : " .. tostring(__Global.buffer))
end

local root = control:new{}
root.rendering = false
root.text = "root"
root.w = initialW
root.h = initialH
root.mouseIgnore = true
root:add()

engine.running = false
engine.backgroundColor = colors.black
engine.root = root

local function onResizeEvent()
    local w, h = parentTerm.getSize()
    screenBuffer.reposition(1, 1, w, h)
    engine.root.w, engine.root.h = w, h
end

local function drawBranch(o)
    if o.visible == false then return end
    o:draw()
    local c = o.children
    for i = 1, #c do
        drawBranch(c[i])
    end
end

local function redrawScreen()
    term.redirect(screenBuffer)
    screenBuffer.setVisible(false)

    drawBranch(engine.root)


    if input.getCursorControl() == nil then
        term.setCursorBlink(false)
    else
        input.getCursorControl():updateCursor()
    end

    screenBuffer.setVisible(true)
    term.redirect(parentTerm)
end

engine.start = function()
    if engine.running then return end
    engine.running = true
    engine.input.addResizeEventListener(onResizeEvent)
    engine.root:_expandChildren() -- HACK this should be called automatically 

    redrawScreen()

    local drawCount = 0
    parallel.waitForAny(
        function ()
            while engine.running do
                for key, value in pairs(engine.renderQueue) do
                    drawCount = drawCount + 1
                    redrawScreen()
                    engine.renderQueue = {}
                    break
                end
                sleep(0.0001)
            end
        end,
        function ()
            while engine.running do
                input.processInput()
            end
        end
    )
end

engine.stop = function()
    engine.running = false
end

engine.getObjects = function()
	return objectList
end

engine.getObject = function(name)
	return objectList[name]
end

engine.newStyle = function()
    return style:new{}
end

engine.getDefaultStyle = function()
    return style
end

engine.getDefaultClickedStyle = function()
    return clickedStyle
end

return engine