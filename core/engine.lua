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

local parentTerm = term.current()
local w, h = parentTerm.getSize()
local screenBuffer = window.create(parentTerm, 1, 1, w, h)
term.redirect(screenBuffer) -- NOTE IMPORTANT (Otherwise viewports will draw behind screenbuffer since their parents will be the parent of the screenbuffer)

if __Global == nil then
    __Global = {}
end

__Global.initial = parentTerm
__Global.buffer = screenBuffer
__Global.print = function ()
    printError("Initial: " .. tostring(Global.initial))
    printError("Buffer : " .. tostring(Global.buffer))
end

local root = control:new{}
root.rendering = false
root.text = "root"
--root.style = mainStyle
root.w = w
root.h = h
root.mouseIgnore = true
root:add()
--root.input = input

engine.running = false
engine.backgroundColor = colors.black
engine.root = root

local function onResizeEvent()
    drawutils.resize()
    --redrawScreen() --Very slow, should be called manually
end

local function drawBranch(o)
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

    screenBuffer.setVisible(true)
    term.redirect(parentTerm)
end

engine.start = function()
    if engine.running then return end
    engine.running = true
    engine.input.addResizeEventListener(onResizeEvent)
    
    --term.setCursorBlink(false)
    --term.setBackgroundColor(engine.backgroundColor)
    
    redrawScreen()

    local drawCount = 0
    parallel.waitForAny(
        function ()
            while engine.running do
                for key, value in pairs(engine.renderQueue) do
                    drawCount = drawCount + 1
                    redrawScreen()
                    engine.renderQueue = {}
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


engine.setBackgroundColor = function(value)
    --redrawScreen()
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