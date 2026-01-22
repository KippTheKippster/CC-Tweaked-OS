---@return Control
---@param object Object
---@param engine Engine
---@param style Style
return function(object, engine, style)
---@class Control : Object
local Control = object:newClass()
Control.__type = "Control"

---@type number
Control.globalX = nil
Control._globalX = 0

---@type number
Control.globalY = nil
Control._globalY = 0

---@type number
Control.x = nil
Control._x = 0

---@type number
Control.y = nil
Control._y = 0

---@type number
Control.w = nil
Control._w = 1

---@type number
Control.h = nil
Control._h = 1

---@type number
Control.minW = nil
Control._minW = 1

---@type number
Control.minH = nil
Control._minH = 1

---@type boolean
Control.expandW = nil
Control._expandW = false

---@type boolean
Control.expandH = nil
Control._expandH = false

---@type boolean
Control.fitToText = nil
Control._fitToText = true

---@type string
Control.text = nil
Control._text = "Control"

---@type Style
Control.style = nil
Control._style = style

---@type boolean
Control.visible = nil
Control._visible = true

Control.inheritStyle = true
Control.centerText = false
Control.focus = false
Control.propogateFocusUp = false
Control.propogateInputUp = true
Control.clipText = true
Control.mouseIgnore = false
Control.rendering = true
Control.draggable = false
Control.dragSelectable = false
Control.topLevel = false
Control.children = {}
---@type Control
Control.parent = nil
Control.marginL = 0
Control.marginR = 0
Control.offsetTextX = 0

---@enum Anchor
Control.Anchor = { LEFT = 0, RIGHT = 1, UP = 2, DOWN = 3, CENTER = 4 }

---@type Anchor
Control.anchorW = nil
---@type Anchor
Control.anchorH = nil

---@type Anchor
Control._anchorW = Control.Anchor.LEFT
---@type Anchor
Control._anchorH = Control.Anchor.UP

Control.visibilityChangedSignal = Control:createSignal()
Control.focusChangedSignal = Control:createSignal()
Control.transformChangedSignal = Control:createSignal()

Control:defineProperty('globalX', {
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

Control:defineProperty('globalY', {
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

function Control:updateGlobalPosition()
    for i = 1, #self.children do
        local c = self.children[i]
        c.globalX = self.globalX + c.x
        c.globalY = self.globalY + c.y
    end

    self:redraw()
end

Control:defineProperty('x', {
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

Control:defineProperty('y', {
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

function Control:updatePosition()
    if self.parent == nil then
        error("Unable to update position of orphan control (parent == nil)", 2)
    end

    self.globalX = self.parent.globalX + self.x
    self.globalY = self.parent.globalY + self.y
    self:redraw()
end

Control:defineProperty('w', {
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

Control:defineProperty('h', {
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

Control:defineProperty('minW', {
    get = function(o) return o._minW end,
    set = function(o, value) 
        local same = o._minW == value
        o._minW = value
        if same == false then
            o:_resize()
        end
    end
})

Control:defineProperty('minH', {
    get = function(o) return o._minH end,
    set = function(o, value) 
        local same = o._minH == value
        o._minH = value
        if same == false then
            o:_resize()
        end
    end
})


Control:defineProperty('expandW', {
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

Control:defineProperty('expandH', {
    get = function(o) return o._expandH end,
    set = function(o, value)
        local same = o._expandH == value
        o._expandH = value
        if same == false then
            o.parent:_expandChildren()
        end
    end
})

function Control:_expandChildren()
    for i = 1, #self.children do
        local c = self.children[i]
        if c.expandH then
            c.h = self.h - c.y
        end
        if c.expandW then
            c.w = self.w - self.marginR - c.x
            c.w = math.min(c.w, self.w)
        end
        if c.anchorW == Control.Anchor.RIGHT then
            c.x = self.w - c.w
        elseif c.anchorW == Control.Anchor.CENTER then
            c.x = math.floor(self.w / 2 + 0.5) -  math.floor(c.w / 2 + 0.5)
        end

        if c.anchorH == Control.Anchor.DOWN then
            c.y = self.h - c.h
        elseif c.anchorH == Control.Anchor.CENTER then
            c.y = math.floor(self.h / 2 + 0.5) - math.floor(c.h / 2 + 0.5)
        end
    end
end

function Control:_resize()
    self.w, self.h = self:getMinimumSize()
    if self.parent then
        self.parent:_expandChildren()
    end
end

function Control:getMinimumSize()
    local minW = self.minW + self.marginL + self.marginR
    local minH = self.minH
    if self._fitToText then
        minW = math.max(#self.text + self.marginL + self.marginR, minW)
        minH = math.max(1, minH)
    end

    return minW, minH
end


Control:defineProperty('fitToText', {
    get = function(o) return o._fitToText end,
    set = function(o, value)
        o._fitToText = value
        o:_resize()
    end
})



Control:defineProperty('text', {
    get = function(o) return o._text end,
    set = function(o, value)
        local same = o._text == value
        o._text = value
        if same == false then
            o:_resize()
            o:redraw()
        end
    end
})

---@param o Control
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

Control:defineProperty('visible', {
    get = function(o) return o._visible end,
    set = function(o, value)
        local same = o._visible == value
        o._visible = value
        if same == false then
            o:visibilityChanged()
            o:emitSignal(o.visibilityChangedSignal)
            propogateVisiblity(o)
            o:redraw()
        end
    end
})

Control:defineProperty('style', {
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

Control:defineProperty('anchorW', {
    get = function(o) return o._anchorW end,
    set = function(o, value) 
        local same = o._anchorW == value
        o._anchorW = value
        if same == false then
            o.parent:_expandChildren()
        end
    end
})

Control:defineProperty('anchorH', {
    get = function(o) return o._anchorH end,
    set = function(o, value) 
        local same = o._anchorH == value
        o._anchorH = value
        if same == false then
            o.parent:_expandChildren()
        end
    end
})

Control.shadow = false -- Change this to style

function Control:add()
    self:ready()
    self:redraw()
    self.add = function () end -- A bit of a ugly hack to prevent add being called multiple times
end

function Control:remove()
    self:queueFree()
end

function Control:queueFree()
    table.insert(engine.freeQueue, self)
end

function Control:redraw()
    engine.queueRedraw = true
end

function Control:render() -- Determines how the control object is drawn
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

function Control:draw() -- Draws the control object if it is valid, NOTE this should not be used to redraw object, use 'redraw' instead
    if self.visible == false or self.rendering == false or self.parent == nil then
        return
    end

    self:render()
end

function Control:drawShadow()
    if self.shadow ~= true then return end
    if self.w == 0 or self.h == 0 then return end

    term.setTextColor(colors.black)
    term.setBackgroundColor(self._style.shadowColor)

    for i = 2 - self._style.shadowOffsetU, self.h + 1 + self._style.shadowOffsetD do
        term.setCursorPos(self.globalX + self.w + 1, self.globalY + i)
        term.write(string.char(127))
    end

    for i = 2 - self._style.shadowOffsetL, self.w + self._style.shadowOffsetR do
        term.setCursorPos(self.globalX + i, self.globalY + self.h + 1)
        term.write(string.char(127))
    end
end

---@param left number 
---@param up number 
---@param right number 
---@param down number 
function Control:drawPanel(left, up, right, down)
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

function Control:getTextPosition()
    return getTextPosition(self._globalX, self._globalY, self._w, self._h, self.centerText, self.text)
end

function Control:write()
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
        term.write(t:sub(i, i))
        x = x + 1
        term.setCursorPos(x, y)
    end
end

---@param o Control
function Control:addChild(o)
	local t = {}

	for i = 1, #self.children do
        table.insert(t, self.children[i])
	end
    table.insert(t, o)
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
end

---@return Control
---@param i integer
function Control:getChild(i)
	return self.children[i]
end

---@param o Control
function Control:removeChild(o)
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

function Control:clearAndFreeChildren()
    for i, b in ipairs(self.children) do
        b:queueFree()
    end
    self.children = {}
end

---@param x number
---@param y number
---@param button integer
function Control:drag(x, y, button)
    if not self.draggable then return end
    self.x = self.x + x
    self.y = self.y + y
end

function Control:toFront()
    if self.parent.children[#self.parent.children] == self then return end
    engine.utils.pushBottom(self.parent.children, self)
    self:redraw()
end

function Control:toBack()
    if self.parent.children[1] == self then return end
    engine.utils.pushTop(self.parent.children, self)
    self:redraw()
end

---@return boolean
function Control:inFocus()
    if self.focus == true then return true end

    for i = 1, #self.children do
        if self.children[i]:inFocus() then
            return true
        end
    end

    return false
end

---@return boolean
function Control:isVisible()
    if self.visible == false then return false end
    if self.parent == nil then return true end
    return self.parent:isVisible()
end

---@return boolean
function Control:isOnScreen()
    local w, h = engine.screenBuffer.getSize()
    return (
        self.globalX >= 0 and
        self.globalY >= 0 and
        self.globalX + self.w <= w and
        self.globalY + self.h <= h)
end

function Control:grabFocus()
    engine.input.grabControlFocus(self)
end

function Control:releaseFocus()
    engine.input.releaseControlFocus(self)
end

function Control:grabCursorControl()
    engine.input.setCursorControl(self)
    self:updateCursor()
end

function Control:releaseCursorControl()
    engine.input.setCursorControl(nil)
end

--Event Functions that should be overwritten
function Control:ready() end
function Control:treeEntered() end
function Control:childrenChanged() end
function Control:click(button, x, y) end
function Control:pressed(button, x, y) end
function Control:doublePressed() end
function Control:up() end
function Control:scroll(dir) end
function Control:focusChanged() end
function Control:updateCursor() end
function Control:positionChanged() end
function Control:globalPositionChanged() end
function Control:sizeChanged()  end
function Control:transformChanged()  end
function Control:styleChanged() end
function Control:visibilityChanged() end

---@param p Control
---@param c Control
local function addControl(p, c)
    local child = c:new()
    p:addChild(child)
    return child
end

---@return Control
function Control:addControl()
    return addControl(self, engine.Control)
end

---@return Button
function Control:addButton()
    return addControl(self, engine.Button)
end

---@return ColorPicker
function Control:addColorPicker()
    return addControl(self, engine.ColorPicker)
end

---@return Container
function Control:addContainer()
    return addControl(self, engine.Container)
end

---@return Dropdown
function Control:addDropdown()
    return addControl(self, engine.Dropdown)
end

---@return FlowContainer
function Control:addFlowContainer()
    return addControl(self, engine.FlowContainer)
end

---@return HContainer
function Control:addHContainer()
    return addControl(self, engine.HContainer)
end

---@return Icon
function Control:addIcon()
    return addControl(self, engine.Icon)
end

---@return LineEdit
function Control:addLineEdit()
    return addControl(self, engine.LineEdit)
end

---@return ScrollContainer
function Control:addScrollContainer()
    return addControl(self, engine.ScrollContainer)
end

---@return VContainer
function Control:addVContainer()
    return addControl(self, engine.VContainer)
end

---@return WindowControl
function Control:addWindowControl()
    return addControl(self, engine.WindowControl)
end

return Control
end