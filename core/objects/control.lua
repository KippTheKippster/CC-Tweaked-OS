return function(object, engine, style)
local control = object:new{}
control.type = "Control"

control._globalX = 0
control._globalY = 0
control._x = 0
control._y = 0
control._w = 13
control._h = 5
control._expandW = false
control._expandH = false
control._fitToText = false
control.offsetTextX = 0
control._text = "Control"
control._style = style
control.inheritStyle = true
control.centerText = false
control.focus = false
control.propogateFocusUp = false
control.propogateInputUp = true
control.clipText = true
control.mouseIgnore = false
control._visible = true
control.rendering = true
control.draggable = false
control.dragSelectable = false
control.children = {}
control.parent = nil
control.marginL = 0
control.marginR = 0

control.anchor = { LEFT = 0, RIGHT = 1, UP = 2, DOWN = 3, CENTER = 4 }

control._anchorW = control.anchor.LEFT
control._anchorH = control.anchor.UP

control.visibilityChangedSignal = control:createSignal()
control.focusChangedSignal = control:createSignal()
control.transformChangedSignal = control:createSignal()

control:defineProperty('globalX', {
    get = function(o) return o._globalX end,
    set = function(o, value)
        local same = o._globalX == value
        o._globalX = value
        if same == false then
            o:updateGlobalPosition()
            o:transformChanged()
            o:globalPositionChanged()
            o:emitSignal(o.transformChanged)
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
            o:emitSignal(o.transformChanged)
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
        local same = o._x == value
        o._x = value
        if same == false then
            o:updatePosition()
            o:transformChanged()
            o:positionChanged()
            o:emitSignal(o.transformChanged)
        end
    end
})

control:defineProperty('y', {
    get = function(o) return o._y end,
    set = function(o, value) 
        local same = o._y == value
        o._y = value 
        if same == false then
            o:updatePosition()
            o:transformChanged()
            o:positionChanged()
            o:emitSignal(o.transformChanged)
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
            o:emitSignal(o.transformChanged)
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
            o:emitSignal(o.transformChanged)
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
            c.h = self.h - c.y
        end
        if c.expandW then
            c.w = self.w - self.marginR - c.x
        end
        if c.anchorW == control.anchor.RIGHT then
            c.x = self.w - c.w
            --local a = e.e
        elseif c.anchorW == control.anchor.CENTER then
            c.x = math.floor(self.w / 2 + 0.5) -  math.floor(c.w / 2 + 0.5)
        end

        if c.anchorH == control.anchor.DOWN then
            c.y = self.h - c.h
        elseif c.anchorH == control.anchor.CENTER then
            c.y = math.floor(self.h / 2 + 0.5) - math.floor(c.w / 2 + 0.5)
        end
        
    end
end

function control:_resize()
    self.w, self.h = self:getMinimumSize()

    --[[
    if self._expandW then
        self.w = self.parent.w
    end

    if self._expandH then
        self.h = self.parent.h
    end
    ]]--
end

function control:getMinimumSize()
    if self._fitToText then
        return #self.text + self.marginL + self.marginR, 1
    else
        return 0, 0
    end
end

control:defineProperty('fitToText', {
    get = function(o) return o._fitToText end,
    set = function(o, value)
        o._fitToText = value
        if value == true then
            o.w = #o.text + o.marginL + o.marginR
        end
    end
})


control:defineProperty('text', {
    get = function(o) return o._text end,
    set = function(o, value)
        local same = o._text == value
        o._text = value
        if same == false then
            if o._fitToText == true then
                o.w = #o.text + o.marginL + o.marginR
            end
            o:redraw()
        end
    end
})

local function propogateVisiblity(o)
    for i = 1, #o.children do
        local c = o.children[i]
        if c.visible == true then
            c:visibilityChanged()
            c:emitSignal(o.visibilityChangedSignal)
            propogateVisiblity(c)
        end
    end
end

control:defineProperty('visible', {
    get = function(o) return o._visible end,
    set = function(o, value) 
        local same = o._visible == value
        o._visible = value 
        if same == false then
            --o:syncChildrenKey("visible", o._visible)
            o:visibilityChanged()
            o:emitSignal(o.visibilityChangedSignal)
            propogateVisiblity(o)
            o:redraw()
        end
    end
})

control:defineProperty('style', {
    get = function(o) return o._style end,
    set = function(o, value) 
        local same = o._style == value
        o._style = value 
        if same == false then
            for i = 1, #o.children do
                local c = o.children[i]
                if c.inheritStyle == true then
                    c.style = o._style
                end
            end
            o:redraw()
            o:styleChanged();
        end
    end
})

control:defineProperty('anchorW', {
    get = function(o) return o._anchorW end,
    set = function(o, value) 
        local same = o._anchorW == value
        o._anchorW = value
        if same == false then
            o.parent:_expandChildren()
        end
    end
})

control:defineProperty('anchorH', {
    get = function(o) return o._anchorH end,
    set = function(o, value) 
        local same = o._anchorH == value
        o._anchorH = value
        if same == false then
            o.parent:_expandChildren()
        end
    end
})

--[[
control:defineProperty('marginR', {
    get = function(o) return o._marginR end,
    set = function(o, value) 
        local old = o._marginR
        o._marginR = value
        if old ~= value then
            o.w = o.w + (value - old)
        end
    end
})

control:defineProperty('marginL', {
    get = function(o) return o._marginL end,
    set = function(o, value) 
        local old = o._marginL
        o._marginL = value
        if old ~= value then
            o.w = o.w + (value - old)
        end
    end
})
]]--

control.shadow = false -- Change this to style

function control:add()
    self:ready()
    self:redraw()
    self.add = function () end -- A bit of a ugly hack to prevent add being called multiple times
end

function control:remove()
    --[[
    --for i = 1, #self.children do
    --    self.children[i]:remove()
    --end

    if self.parent then
        for i = 1, #self.parent.children do
            if self.parent.children[i] == self then
                table.remove(self.parent.children, i)
            end
	    end
    end
    
    if engine.input.getCursorControl() == self then
        self:releaseCursorControl()
    end

    --self.parent:childrenChanged()
    --self:redraw()
    --self = {}
    object.remove(self)
    ]]--
    self:queueFree()
end

function control:queueFree()
    table.insert(engine.freeQueue, self)
end

function control:redraw()
    engine.queueRedraw = true
    --engine.renderQueue[self] = true
end

function control:render() -- Determines how the control object is drawn
    --SHADOW
    self:drawShadow()
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
    if self.visible == false or self.rendering == false or self.parent == nil then
        return
    end

    self:render()
end

function control:drawShadow()
    if self.shadow ~= true then return end
    if self.w == 0 or self.h == 0 then return end

    local startX = self.globalX + self.w + 1
    local startY = self.globalY + 2
    local endX = startX
    local endY = startY + self.h - 1

    --term.setCursorPos(startX, startY)
    
    term.setTextColor(colors.black)
    term.setBackgroundColor(self._style.shadowColor)

    for i = 2, self.h + 1 do
        term.setCursorPos(self.globalX + self.w + 1, self.globalY + i)
        term.write("\127")
    end

    for i = 2, self.w do
        term.setCursorPos(self.globalX + i, self.globalY + self.h + 1)
        term.write("\127")
    end
    --term.write(text)
    --paintutils.drawLine(startX, startY, endX, endY, self._style.shadowColor)

    startY = endY
    endX = startX - 1
    startX = self.globalX + 2

    --paintutils.drawLine(startX, startY, endX, endY, self._style.shadowColor)
end


function control:drawPanel(left, up, right, down)
    if self._style.background == true or self._style.background == nil then
        paintutils.drawFilledBox(
            left,
            up,
            right,
            down,
            self._style.backgroundColor
        )
    end

    if self._style.border then
        paintutils.drawBox(
            left, 
            up,
            right,
            down,
            self._style.borderColor
        )
    end
end

local function getTextPosition(_x, _y, _w, _h, center, text)
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

function control:getTextPosition()
    return getTextPosition(self._globalX, self._globalY, self._w, self._h, self.centerText, self.text)
end

function control:write()
    if self._text == "" or self.text == nil then
        return
    end

    local l = #self.text + self.marginR
    if self.clipText == true then
        l = math.min(#self.text, self.w - 1 - self.marginR)
    end
    local s = self.offsetTextX + 1

    local _x, _y = self:getTextPosition()
    _x = _x + self.marginL

    term.setCursorPos(_x, _y)
    term.setTextColor(self._style.textColor)

    local x, y = term.getCursorPos()
    local t = self.text:sub(s, s + l)
    for i = 1, #t do
        --term.setBackgroundColor(engine.drawutils.getPixel(term.getCursorPos()))
        term.write(t:sub(i, i))
        x = x + 1
        term.setCursorPos(x, y)
    end
    --term.write(t)
end

function control:addChild(o)
	local t = {}

	for i = 1, #self.children do
		--t[i] = self.children[i]
        table.insert(t, self.children[i])
	end
    table.insert(t, o)
	--t[#self.children + 1] = o
	self.children = t
    o:add()
	o.parent = self
    o.style = self.style
    o.globalX = self.globalX + o.x
    o.globalY = self.globalY + o.y
    o.treeEntered(o) -- TODO Maybe make recursive
    self:childrenChanged()
    self:_expandChildren()
    self:redraw()
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
    self:redraw()
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

function control:drag(x, y, button)
    if not self.draggable then return end
    self.x = self.x + x
    self.y = self.y + y
end

function control:toFront()
    if self.parent.children[#self.parent.children] == self then return end
    engine.utils.pushBottom(self.parent.children, self)
    self:redraw()
end

function control:toBack()
    if self.parent.children[1] == self then return end
    engine.utils.pushTop(self.parent.children, self)
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

function control:isVisible()
    if self.visible == false then return false end
    if self.parent == nil then return true end
    return self.parent:isVisible()
end


function control:grabFocus()
    engine.input.grabControlFocus(self)
end

function control:releaseFocus()
    engine.input.releaseControlFocus(self)
end

function control:grabCursorControl()
    engine.input.setCursorControl(self)
    self:updateCursor()
end

function control:releaseCursorControl()
    engine.input.setCursorControl(nil)
end

--Event Functions that should be overwritten
function control:ready() end
function control:treeEntered() end
function control:childrenChanged() end
function control:click(button, x, y) end
function control:pressed(button, x, y) end
function control:doublePressed() end
function control:up() end
function control:scroll(dir) end
function control:focusChanged() end
function control:updateCursor() end
function control:positionChanged() end
function control:globalPositionChanged() end
function control:sizeChanged()  end
function control:transformChanged()  end
function control:styleChanged() end
function control:visibilityChanged() end

return control
end