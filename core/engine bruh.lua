local path = ".core."

objects = require(path .. "objects")
actives = require(path .. "actives")
input = require(path .. "input")
utils = require(path .. "utils")
drawutils = require(path .. "drawutils")

active = actives.new_active()
canvas = active:new{}
canvases = {}
renderQueue = {}

function canvas:draw() end
function canvas:add()
    table.insert(canvases, self)  
    active.add(self) --super
end

collision = {}

function collision.inArea(x, y, x1, y1, w, h)
    if (
        x <= x1 + w and
        x >= x1 and 
        y <= y1 + h and
        y >= y1
    ) then
        return true
    else
        return false
    end
end

function collision.overlappingArea(x, y, w, h, x1, y1, w1, h1)
    if (
        x <= x1 + w1 and
        x + w >= x1 and 
        y <= y1 + h1 and
        y + h >= y1
    ) then
        return true
    else
        return false
    end
end

--style = objects.new_object()
--style.backgroundColor = colors.lightGray
--style.borderColor = colors.gray
--style.textColor = colors.black
--style.border = false

controls = {}
local defaultStyle = require(path .. "styles.defaultStyle")
local control = require(path .. "objects.control")
control.style = defaultStyle

--clickedStyle = style:new{}
--clickedStyle.backgroundColor = colors.white
--clickedStyle.textColor = colors.orange


local clickedStyle = require(path .. "styles.clickedStyle")
local button = require(path .. "objects.button")

container = control:new{}
container.mouseIgnore = false
container.text = ""
container.visible = true
--container.background = false
container.rendering = false

function container:update()
	self:sort()
end

function container:sort() end

vContainer = container:new{}
vContainer.center = false

local ew = 1

function vContainer:sort()
	local h = 0
	local x = 0
	for i = 1, #self.children do
		local c = self.children[i]
        c.y = h
		if self.center == true then
			x = math.ceil((self.w - c.w) / 2)
		else
			x = 0
		end
		c.x = x
		h = h + c.h
	end
end

hContainer = container:new{}
hContainer.center = false

function hContainer:sort()
	local w = 0
	local y = 0
	for i = 1, #self.children do
		local c = self.children[i]
		c._globalX = self._globalX + w
		if self.center == true then
			y = self.globalY + math.ceil((self.h - c.h) / 2)
		else
			y = self.globalY
		end
		c.globalY = y
		w = w + c.w
	end
end

flowContainer = container:new{}

function flowContainer:sort()
	local w = 0
	local h = 0
	local nextH = 0
	for i = 1, #self.children do
		local c = self.children[i]
		c.globalX = self.globalX + w
		c.globalY = self.globalY + h
		w = w + c.w + 1
		nextH = math.max(nextH, h + c.h)
		if w > self.w then
			w = 0
			h = nextH + 1
		end
	end
end

scrollContainer = container:new{}
scrollContainer.scrollY = 0

function scrollContainer:ready()
	input.addScrollListener(self)
end

function scrollContainer:scroll(dir, x, y)
    self.scrollY = self.scrollY -  dir
    
    if self.scrollY > 0 then
        self.scrollY = 0
        return
    end

    if self.scrollY < -self.children[1].h then
        self.scrollY = -self.children[1].h
        return
    end

    self.children[1].y = self.scrollY
end

--editStyle = style:new{}
--editStyle.backgroundColor = colors.gray

--editFocusStyle = editStyle:new()
--editFocusStyle.backgroundColor = colors.lightGray

dropdown = button:new{}
dropdown.text = "Drop-down"
dropdown.h = 1
dropdown.list = nil
dropdown.open = false

function dropdown:ready()
    --self.list = self:addVContainer()
    self.list = vContainer:new{}
    self:addChild(v)
    self.list.y = self.h
    self.list.visible = false
end 

function dropdown:addToList(text)
    local b = self.list:addButton()
    b.visible = false
    b.text = text
    b.h = 1
    b.pressed = function(o)
        for i = 1, #o.parent.children do
            if o.parent.children[i] == o then
                o.parent.parent:optionPressed(i)
                break
            end
        end
    end
end

function dropdown:pressed()
    self.list.visible = self.list.visible == false
end

function dropdown:getOptionText(i)
    return self.list.children[i].text
end

function dropdown:getOption(i)
    return self.list.children[i]
end

function dropdown:optionPressed(i) end

edit = control:new()
edit.style = editStyle
edit.normalStyle = editStyle
edit.focusStyle = editFocusStyle
edit.h = 0
edit.w = 12
edit.clipText = true
edit.offsetTextX = 0
edit.cursor = 1

function edit:ready()
    input.addCharListener(self)
	input.addKeyListener(self)
	self.cursor = #self.text - 1
end

function edit:char(char)
    if self.focus == true then
        self.text = self.text .. char
		self.cursor = math.min(self.cursor + 1, self.w - 1)
		self.offsetTextX = #self.text - self.cursor - 1
		print(self.cursor .. " : " .. #self.text .. " : " ..  self.cursor - #self.text)
		 
    end
end

function edit:key(key) 
	if self.focus == true then
		
	end
end

function edit:draw()
	--self:base():draw()
	control.draw(self)
	if self.focus == true then
		local x, y = self:getTextPosition()
		term.setCursorPos(x + self.cursor + 1, y)
		term.setBackgroundColor(colors.white)
		local t = self.text:sub(self.cursor + self.offsetTextX + 2, self.cursor + self.offsetTextX + 2)
		local b = string.byte(t)
		--print(b)
		if b == nil then
			t = " " 
		end
		term.write(t)
	end
end

function edit:focusChanged()
    if self.focus then
        self.style = self.focusStyle
    else
        self.style = self.normalStyle
    end
end

icon = control:new{}
icon.texture = nil -- = paintutils.loadImage("test.nfp")

function icon:draw()
    if self.texture == nil then return end
	paintutils.drawImage(self.texture, self.globalX + 1, self.globalY + 1)
end

function icon:getSize()
	local w = 0
	local h = #self.texture
	for i = 1, #self.texture do
		w = math.max(w, #self.texture[i])
	end
	
	return w, h
end

--Engine
objectList = {}
objectList["canvas"] = canvas
objectList["control"] = control
objectList["style"] = style
objectList["clickedStyle"] = clickedStyle
objectList["icon"] = icon
objectList["button"] = button
objectList["dropdown"] = dropdown
objectList["container"] = container
objectList["vContainer"] = vContainer
objectList["hContainer"] = hContainer
objectList["flowContainer"] = flowContainer
objectList["scrollContainer"] = scrollContainer
objectList["edit"] = edit

--Adds 'add' functions for all control objects Example: control:addButton()
for k, v in pairs(objectList) do
    control["add" .. utils.capitaliseFirst(k)] = function(o)
        print(k)
        local c = objectList[k]:new{}
        o:addChild(c)
        return c
    end
end

main = control:new{}
main.rendering = false
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
    return require(path .. "styles.defaultStyle"):new{}
end

function main:getDefaultStyle()
    return defaultStyle
end

function main:getDefaultClickedStyle()
    return clickedStyle
end

--start()

function redrawScreen()
    if not running then return end

    term.setBackgroundColor(backgroundColor)
    --term.clear()
    for i = 1, #canvases do
        local c = canvases[i]
        c:draw()     
    end
end

function processActives()
    while running do
        --term.setBackgroundColor(colors.black)
        --term.clear()
        for key, value in pairs(renderQueue) do
            redrawScreen() --TODO Replace with redrawArea()
            --drawutils.drawScreen()
            break
        end 
        renderQueue = {}

        actives.process()
        --redrawScreen()
        sleep(0.01)
    end
end

function processInput()
	input.processInput()
end

return getMain()
