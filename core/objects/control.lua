return function(canvas, engine, style)
local control = canvas:new{}

control._globalX = 0
control._globalY = 0
control._x = 0
control._y = 0
control._w = 13
control._h = 5
control.offsetTextX = 0
control._text = "Control"
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
            table:transformChanged();
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
            table:transformChanged();
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
            table:transformChanged();
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
            table:transformChanged();
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
            table:transformChanged();
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
            table:transformChanged();
            table:sizeChanged();
        end
    end 
})

control:defineProperty('text', {
    get = function(table) return table._text end,
    set = function(table, value) 
        local same = table._text == value
        table._text = value 
        if same == false then
            table:redraw()
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
    table.insert(engine.controls, self)
    canvas.add(self) --super
    self:redraw()
end

function control:remove()
    --for i = 1, #controls do
	--	if controls[i] == self then
    --        --table.remove(controls, i)
	--	end
	--end

    --self:syncChildrenFunction("remove") --TODO reimplement

    for i = 1, #self.parent.children do
		if self.parent.children[i] == self then
            table.remove(self.parent.children, i)
		end
	end

    canvas.remove(self)
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

function redrawArea(x, y, w, h) -- Unused
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

function control:redraw()
    if not engine.running then return end
    engine.renderQueue[self] = true
end

function control:render() -- Determines how the control object is drawn
    --PANEL
    local left = self._globalX + 1
    local up = self._globalY + 1
    local right = self._globalX + self._w
    local down = self._globalY + self._h
    self:drawPanel(left, up, right, down)
    --TEXT
    self:write()
end

function control:draw() -- Draws the control object if it is valid, NOTE this should not be used to redraw object, use 'redraw' instead
    if not engine.running then
        return
    end

    if self.visible == false or self.rendering == false then
        return
    end

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

function control:drawPanel(left, up, right, down)
    if self.background == true then
        engine.drawutils.drawFilledBox(
            left, 
            up,
            right,
            down,
            self._style.backgroundColor
        )
    end
    
    if self._style.border then
        engine.drawutils.drawBox(
            left, 
            up,
            right,
            down,
            self._style.borderColor
        )
    end
end

--[[
function control:drawPanel()
    if self.background == true then
        local left = self._globalX + 1
        local up = self._globalY + 1
        local right = self._globalX + self._w
        local down = self._globalY + self._h
        engine.drawutils.drawFilledBox(
            left, 
            up,
            right,
            down,
            self._style.backgroundColor
        )
    end
    
    if self._style.border then
        engine.drawutils.drawBox(
            left, 
            up,
            right,
            down,
            self._style.borderColor
        )
    end
end
]]--

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
    if self._text == "" or self.text == nil then
        return
    end

    local l = #self.text
    if self.clipText == true then
        l  = math.min(#self.text, self.w - 1)
    end
    local s = self.offsetTextX + 1

    
    term.setCursorPos(self:getTextPosition())
    term.setTextColor(self._style.textColor)

    local x, y = term.getCursorPos()
    local t = self.text:sub(s, s + l)
    for i = 1, #t do
        term.setBackgroundColor(engine.drawutils.getPixel(term.getCursorPos()))
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
        c[key](c)
    end
end

function control:drag(x, y)
    if not self.draggable then return end
    self.x = self.x + x
    self.y = self.y + y
end

function control:toFront()
    if self.parent.children[#self.parent.children] == self then return end
    utils.pushBottom(self.parent.children, self)
    self:redraw()
end

function control:toBack()
    if self.parent.children[1] == self then return end
    utils.pushTop(self.parent.children, self)
    self:redraw()
end

function control:inFocus()
    if self.focus == true then return true end

    for i = 1, #self.children do
        if self.children[i]:inFocus() then 
            return true
        end
    end

    return false 
end

function control:grabFocus()
    engine.input.grabControlFocus(self)
end

--Signal Functions that should be overwritten
function control:click() end
function control:pressed() end
function control:doublePressed() end
function control:up() end
function control:focusChanged() end
function control:positionChanged() end
function control:globalPositionChanged() end
function control:sizeChanged()  end
function control:transformChanged()  end
function control:styleChanged() end
function control:visibilityChanged() end

return control
end