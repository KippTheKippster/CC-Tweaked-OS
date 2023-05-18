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

style = objects.new_object()
style.backgroundColor = colors.lightGray
style.borderColor = colors.gray
style.textColor = colors.black
style.border = false

controls = {}

control = canvas:new{}
control._globalX = 0
control._globalY = 0
control._x = 0
control._y = 0
control._w = 13
control._h = 5
control.offsetTextX = 0
control.text = "Control"
control._style = style
control.centerText = false
control.background = true
control.focus = false
control.clipText = false
control.mouseIgnore = false
control._visible = true
control.rendering = true
control.draggable = false
control.children = {}
control.parent = nil


control:defineProperty('globalX', {
    get = function(table) return table._globalX end,
    set = function(table, value) 
        local same = table._globalX == value
        table._globalX = value 
        if same == false then
            table:updateGlobalPosition();
            table:globalPositionChanged();
        end
    end 
})

control:defineProperty('globalY', {
    get = function(table) return table._globalY end,
    set = function(table, value) 
        local same = table._globalY == value
        table._globalY = value 
        if same == false then
            table:updateGlobalPosition();
            table:globalPositionChanged();
        end
    end 
})

function control:updateGlobalPosition()
    for i = 1, #self.children do
        local c = self.children[i]
        c.globalX = self.globalX + c.x
        c.globalY = self.globalY + c.y 
    end

    self:redraw()
end

control:defineProperty('x', {
    get = function(table) return table._x end,
    set = function(table, value) 
        local value = value
        local same = table._x == value
        table._x = value 
        if same == false then
            table:udpatePosition()
            table:positionChanged();
        end
    end 
})

control:defineProperty('y', {
    get = function(table) return table._y end,
    set = function(table, value) 
        local value = value 
        local same = table._y == value
        table._y = value 
        if same == false then
            table:udpatePosition()
            table:positionChanged();
        end
    end 
})

function control:udpatePosition()
    self.globalX = self.parent.globalX + self.x
    self.globalY = self.parent.globalY + self.y
    self:redraw()
end

control:defineProperty('w', {
    get = function(table) return table._w end,
    set = function(table, value) 
        local same = table._w == value
        table._w = value 
        if same == false then
            table:redraw()
            table:sizeChanged();
        end
    end 
})

control:defineProperty('h', {
    get = function(table) return table._h end,
    set = function(table, value) 
        local same = table._h == value
        table._h = value 
        if same == false then
            table:redraw()
            table:sizeChanged();
        end
    end 
})

control:defineProperty('visible', {
    get = function(table) return table._visible end,
    set = function(table, value) 
        local same = table._visible == value
        table._visible = value 
        if same == false then
            table:syncChildrenKey("visible", table._visible)
            table:visibilityChanged();
        end
    end 
})

control:defineProperty('style', {
    get = function(table) return table._style end,
    set = function(table, value) 
        local same = table._style == value
        table._style = value 
        if same == false then
            table:syncChildrenKey("style", table._style)
            table:redraw()
            table:styleChanged();
        end
    end 
})

function control:add()
    table.insert(controls, self)
    canvas.add(self) --super
    self:draw()
end

function getControl(x, y, w, h, whitelist, p)
    local list = {}
    for i = 1, #controls do
        local c = controls[i]
        if whitelist[i] == nil and collision.overlappingArea(x, y, w, h, c.globalX, c.globalY, c.w, c.h) then
            --table.insert(list, c)
            --print(tostring(c) .. " : " .. i)
            if p then
                print(c)
            end 
            list[i] = c
            --print(list[i])
        end
    end
    return list
end

function redrawArea(x, y, w, h)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 4)

    local list = getControl(x, y, w, h, {}, false)
    for k, v in pairs(list) do
        local newList = getControl(v._globalX, v._globalY, v._w, v._h, list, true)
        for kn, vn in pairs(list) do
            --list[kn] = vn
        end
    end
    
    for k, v in pairs(list) do
        list[k]:draw()
    end
    
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.red)
    for k, v in pairs(list) do
        --list[k]:draw()
    end
end

i = 0
function control:redraw()
    if not running then return end
    renderQueue[self] = true
    i = i + 1
end

function control:render()
    if not running then
        return
    end

    if self.visible == false or self.rendering == false then
        return
    end
    --PANEL
    if self.background == true then
        local left = self._globalX + 1
        local up = self._globalY + 1
        local right = self._globalX + self._w
        local down = self._globalY + self._h
        drawutils.drawFilledBox(
            left, 
            up,
            right,
            down,
            self._style.backgroundColor
        )
    end
    
    if self._style.border then
        drawutils.drawBox(
            left, 
            up,
            right,
            down,
            self._style.borderColor
        )
    end
    --TEXT
    self:write()
end

function control:draw()
    self:render()
end

--function control:getTextPosition()
--    local x = 0
--    local y = 0
--    if self.centerText == false then
--        x = self._globalX
--        y = self._globalY
--    else
--        x = self._globalX + math.ceil((self._w - #self.text) / 2)
--        y = self._globalY + math.floor((self._h) / 2)
--    end
--	
--    return x + 1, y + 1
--end

function control:getTextPosition()
    return getTextPosition(self._globalX, self._globalY, self._w, self._h, self.centerText, self.text)
end

function getTextPosition(_x, _y, _w, _h, center, text)
    local x = 0
    local y = 0
    if center == false then
        x = _x
        y = _y
    else
        x = _x + math.ceil((_w - #text) / 2)
        y = _y + math.floor((_h) / 2)
    end
	
    return x + 1, y + 1
end

function control:write()
    if self.text == "" or self.text == nil then
        return
    end

    local l = #self.text
    if self.clipText == true then
        l  = math.min(#self.text, self.w+1)
    end
    local s = self.offsetTextX + 1

    
    term.setCursorPos(self:getTextPosition())
    term.setTextColor(self._style.textColor)

    local x, y = term.getCursorPos()
    local t = self.text:sub(s, s + l)
    for i = 1, #t do
        term.setBackgroundColor(drawutils.getPixel(term.getCursorPos()))
        term.write(t:sub(i, i))
        x = x + 1
        term.setCursorPos(x, y)
    end
    --term.write(t)
end

function control:addChild(o)
	local t = {}
	for i = 1, #self.children do
		t[i] = self.children[i]
	end
	t[#self.children + 1] = o
	self.children = t
    o:add()
	o.parent = self
    o.style = self.style
    o.globalX = self.globalX + o.x
    o.globalY = self.globalY + o.y
    --self:syncChildrenKey("style", self._style)
end

function control:syncChildrenKey(key, value)
    for i = 1, #self.children do
        local c = self.children[i]
        --if (c[key] == nil) then
            c[key] = value
        --end
    end
end 

function control:syncChildrenFunction(key)
    for i = 1, #self.children do
        local c = self.children[i]
        c[key]()
    end
end

function control:drag(x, y)
    if not self.draggable then return end
    self.x = self.x + x
    self.y = self.y + y
end

function control:toBack()
    utils.move(actives.get_list(), self, 1)
end

function control:click() end
function control:pressed() end
function control:doublePressed() end
function control:up() end
function control:focusChanged() end
function control:positionChanged() end
function control:globalPositionChanged() end
function control:sizeChanged()  end
function control:styleChanged() end
function control:visibilityChanged() end

clickedStyle = style:new{}
clickedStyle.backgroundColor = colors.white
clickedStyle.textColor = colors.orange

button = control:new{}
button.normalStyle = style
button.clickedStyle = clickedStyle
button.text = "Button"

function button:click()
    self.style = self.clickedStyle
end

function button:up()
    self.style = self.normalStyle
end

dropdown = button:new{}
dropdown.text = "Drop-down"
dropdown.h = 1
dropdown.list = nil
dropdown.open = false

function dropdown:ready()
    self.list = self:addVContainer()
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

editStyle = style:new{}
editStyle.backgroundColor = colors.gray
editStyle.centerText = false

editFocusStyle = editStyle:new()
editFocusStyle.backgroundColor = colors.lightGray

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
