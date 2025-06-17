return function(object, engine, style)
local control = object:new{}

control._globalX = 0
control._globalY = 0
control._x = 0
control._y = 0
control._w = 13
control._h = 5
control.expandW = false
control.expandH = false
control.offsetTextX = 0
control._text = "Control"
control._style = style
control.centerText = false
control.background = true
control.focus = false
control.propogateFocusUp = false
control.clipText = false
control.mouseIgnore = false
control._visible = true
control.rendering = true
control.draggable = false
control.dragSelectable = false
control.children = {}
control.parent = nil

control:defineProperty('globalX', {
    get = function(o) return o._globalX end,
    set = function(o, value) 
        local same = o._globalX == value
        o._globalX = value 
        if same == false then
            o:updateGlobalPosition()
            o:transformChanged()
            o:globalPositionChanged()
        end
    end 
})

control:defineProperty('globalY', {
    get = function(o) return o._globalY end,
    set = function(o, value) 
        local same = o._globalY == value
        o._globalY = value 
        if same == false then
            o:updateGlobalPosition()
            o:transformChanged()
            o:globalPositionChanged()
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
    get = function(o) return o._x end,
    set = function(o, value)
        local value = value
        local same = o._x == value
        o._x = value 
        if same == false then
            o:updatePosition()
            o:transformChanged()
            o:positionChanged()
        end
    end
})

control:defineProperty('y', {
    get = function(o) return o._y end,
    set = function(o, value) 
        local value = value 
        local same = o._y == value
        o._y = value 
        if same == false then
            o:updatePosition()
            o:transformChanged()
            o:positionChanged()
        end
    end 
})

function control:updatePosition()
    self.globalX = self.parent.globalX + self.x
    self.globalY = self.parent.globalY + self.y
    self:redraw()
end

control:defineProperty('w', {
    get = function(o) return o._w end,
    set = function(o, value) 
        local same = o._w == value
        o._w = value 
        if same == false then
            o:redraw()
            o:transformChanged()
            o:_expandChildren()
            o:sizeChanged()
        end
    end
})

control:defineProperty('h', {
    get = function(o) return o._h end,
    set = function(o, value) 
        local same = o._h == value
        o._h = value 
        if same == false then
            o:redraw()
            o:transformChanged()
            o:_expandChildren()
            o:sizeChanged()
        end
    end
})

control:defineProperty('expandW', {
    get = function(o) return o._expandW end,
    set = function(o, value) 
        local same = o._expandW == value
        o._expandW = value 
        if same == false and o._expandW == true then
            if o.parent ~= nil then
                o.parent:_expandChildren()
            end
        end
    end
})

control:defineProperty('expandH', {
    get = function(o) return o._expandH end,
    set = function(o, value) 
        local same = o._expandH == value
        o._expandH = value 
        if same == false then
            o.parent:_expandChildren()
        end
    end
})

function control:_expandChildren()
    for i = 1, #self.children do
        local c = self.children[i]
        if c.expandH then
            c.h = self.h
        end
        if c.expandW then
            c.w = self.w
        end
    end
end

control:defineProperty('text', {
    get = function(o) return o._text end,
    set = function(o, value) 
        local same = o._text == value
        o._text = value 
        if same == false then
            o:redraw()
        end
    end 
})

control:defineProperty('visible', {
    get = function(o) return o._visible end,
    set = function(o, value) 
        local same = o._visible == value
        o._visible = value 
        if same == false then
            o:syncChildrenKey("visible", o._visible)
            o:visibilityChanged();
        end
    end
})

control:defineProperty('style', {
    get = function(o) return o._style end,
    set = function(o, value) 
        local same = o._style == value
        o._style = value 
        if same == false then
            o:syncChildrenKey("style", o._style)
            o:redraw()
            o:styleChanged();
        end
    end 
})

function control:add()
    --table.insert(engine.controls, self)
    --engine.controls[self] = 
    self:ready()
    self:redraw()
end

function control:remove()
    --for i = 1, #self.children do
    --    self.children[i]:remove()
    --end

    for i = 1, #self.parent.children do
	    if self.parent.children[i] == self then
            table.remove(self.parent.children, i)
		end
	end

    self.parent:childrenChanged()
    --self = {}
    --object.remove(self)
end

function control:redraw()
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

    if self.visible == false or self.rendering == false or self.parent == nil then
        return
    end

    self:render()
end


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
    o.treeEntered(o) -- TODO Maybe make recursive
    self:childrenChanged()
    self:_expandChildren()
    --self:syncChildrenKey("style", self._style)
end

function control:removeChild(o)
    for i = 1, #self.children do
        if self.children[i] == o then
            table.remove(self.children, i)
            break
        end
    end

    o.parent = nil
    self:childrenChanged()
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
function control:ready() end
function control:treeEntered() end
function control:childrenChanged() end
function control:click() end
function control:pressed() end
function control:doublePressed() end
function control:up() end
function control:scroll(dir) end
function control:focusChanged() end
function control:positionChanged() end
function control:globalPositionChanged() end
function control:sizeChanged()  end
function control:transformChanged()  end
function control:styleChanged() end
function control:visibilityChanged() end

return control
end