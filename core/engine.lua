local path = ".core."

local engine = {}

local objects = require(path .. "objects")
local actives = require(path .. "actives")
local collision = require(path .. "collision")
local input = require(path .. "input")(engine, collision)
local utils = require(path .. "utils")
local drawutils = require(path .. "drawutils")

engine.input = input
engine.drawutils = drawutils

local active = actives.new_active()
local canvas = active:new{}
local canvases = {}
local renderQueue = {}

engine.renderQueue = renderQueue

function canvas:toFront()
    utils.move(canvases, self, 1)
end

function canvas:draw() end
function canvas:add()
    table.insert(canvases, self)  
    active.add(self) --super
end

function canvas:remove()
    for i = 1, #canvases do
		if canvases[i] == self then
            table.remove(canvases, i)
		end
	end
    active.remove(self)
end

local style = objects.new_object()
style.backgroundColor = colors.lightGray
style.borderColor = colors.gray
style.textColor = colors.black
style.border = false

local controls = {}
engine.controls = controls

--Objects
local objectList = {}
objectList["canvas"] = canvas

local function requireObject(name, ...)
    local o = require(path .. "objects." .. name)(...)
    objectList[name] = o
    return o
end

local control = requireObject("control", canvas, engine, style) -- Should it only be engine as argument?

local clickedStyle = style:new{}
clickedStyle.backgroundColor = colors.white
clickedStyle.textColor = colors.orange

local button = requireObject("button", control, style, clickedStyle)
local dropdown = requireObject("dropdown", button)
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

local lineEdit = requireObject("lineEdit", control, editStyle, editFocusStyle)
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

local w, h = term.getSize()
local screenBuffer = window.create(term.current(), 1, 1, w, h)
term.redirect(screenBuffer)
local root = control:new{}
root.rendering = false
root.text = ""
--root.style = mainStyle
root.w = w
root.h = h
root.mouseIgnore = true
root:add()
root.input = input

engine.running = false

engine.backgroundColor = colors.black

engine.root = root

local function onResizeEvent()
    drawutils.resize()
    --redrawScreen() --Very slow, should be called manually
end

local function drawChildren(c)
    for i = 1, #c do
        c[i]:draw()
        if #c[i].children > 0 then
            drawChildren(c[i].children)
        end
    end
end

local function redrawScreen()
    if not engine.running then return end
    local old = term.current()
    term.redirect(screenBuffer)
    screenBuffer.setVisible(false)
    term.setBackgroundColor(engine.backgroundColor)
    term.setCursorBlink(false)
    engine.root:draw()
    drawChildren(engine.root.children)
    screenBuffer.setVisible(true)
    term.redirect(old)
    --term.current().setVisible(true)
    --term.current().setVisible(false)
    --term.clear()
    --for i = 1, #canvases do
    --    local c = canvases[i]
    --    c:draw()     
    --end
end

local function processChildren(c)
    for i = 1, #c do
        if #c[i].children > 0 then
            processChildren(c[i].children)
        end
        c[i]:update()
    end
end


local function processActives()
    while engine.running do
        for key, value in pairs(engine.renderQueue) do
            redrawScreen() --TODO Replace with redrawArea()
            --
            --drawutils.drawScreen()
            break
        end 
        engine.renderQueue = {}
        engine.root:update()
        processChildren(engine.root.children)
        --actives.process()
        sleep(0.0001)
    end
end

local function processInput()
	input.processInput()
end

engine.start = function()
    engine.running = true
    engine.input.addResizeEventListener(onResizeEvent)
    term.setBackgroundColor(engine.backgroundColor)
    redrawScreen()

    parallel.waitForAny(
        processActives,
        processInput
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


engine.setBackgroundColor = function(value)
    redrawScreen()
    engine.backgroundColor = value
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