local path = ".core."

local objects = require(path .. "objects")
local actives = require(path .. "actives")
input = require(path .. "input")
local utils = require(path .. "utils")
drawutils = require(path .. "drawutils")

local active = actives.new_active()
local canvas = active:new{}
local canvases = {}
renderQueue = {}

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

local collision = require(path .. "collision")

style = objects.new_object()
style.backgroundColor = colors.lightGray
style.borderColor = colors.gray
style.textColor = colors.black
style.border = false

controls = {}

--Objects
objectList = {}
objectList["canvas"] = canvas

function requireObject(name, ...)
    local o = require(path .. "objects." .. name)(...)
    objectList[name] = o
    return o
end

local control = requireObject("control", canvas)

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
main = control:new{}
main.rendering = false
main.text = ""
main.style = mainStyle
main.w = w
main.h = h
main.mouseIgnore = true
main:add()
running = false
backgroundColor = colors.black

function getMain()
    return main
end

function main:getObjects()
	return objectList
end

function main:start()
    running = true
    term.setBackgroundColor(backgroundColor)
    redrawScreen()

    parallel.waitForAny(
        processActives,
        processInput
    )
end

function main:stop()
    running = false
end

function main:setBackgroundColor(value)
    redrawScreen()
    backgroundColor = value
end 

function main:newStyle()
    return style:new{}
end

function main:getDefaultStyle()
    return style
end

function main:getDefaultClickedStyle()
    return clickedStyle
end

--start()

function redrawScreen()
    if not running then return end

    term.setBackgroundColor(backgroundColor)
    main:draw()
    drawChildren(main.children)
    --term.clear()
    --for i = 1, #canvases do
    --    local c = canvases[i]
    --    c:draw()     
    --end
end

function processActives()
    while running do
        for key, value in pairs(renderQueue) do
            redrawScreen() --TODO Replace with redrawArea()
            term.setCursorBlink(false) 
            --drawutils.drawScreen()
            break
        end 
        renderQueue = {}
        main:update()
        processChildren(main.children)
        --actives.process()
        sleep(0.01)
    end
end

function processChildren(c)
    for i = 1, #c do
        if #c[i].children > 0 then
            processChildren(c[i].children)
        end
        c[i]:update()
    end
end

function drawChildren(c)
    for i = 1, #c do
        c[i]:draw()
        if #c[i].children > 0 then
            drawChildren(c[i].children)
        end
    end
end

function processInput()
	input.processInput()
end

return getMain()
