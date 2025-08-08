return function(control, button)
local windowControl = control:new{}
windowControl.type = "WindowControl"

windowControl.draggable = true
windowControl.clipText = true
windowControl.text = "Window"
windowControl.label = nil
windowControl.exitButton = nil
windowControl.scaleButton = nil
windowControl.minW = 10
windowControl.minH = 4
windowControl.oldW = 0
windowControl.oldH = 0
windowControl.oldX = 0
windowControl.oldY = 0
windowControl.fullscreen = false
windowControl.closedSignal = windowControl:createSignal()
windowControl.fullscreenChangedSignal = windowControl:createSignal()

windowControl:defineProperty('text', {
    get = function(o)
        if o.label == nil then
            return o._text
        else
            return o.label.text
        end
    end,
    set = function(o, value) 
        if o.label == nil then
            o._text = value
        else
            o.label._text = value
            o._text = ""
        end
    end
}, true)

function windowControl:ready()
    self:refreshMinSize()

    self.label = self:addControl()
    self.label.x = 2
    self.label.w = 1
    self.label.h = 1
    self.label.mouseIgnore = true
    self.label.clipText = true
    self.label.w = self.w - 2

    self.exitButton = button:new{}
    self:addChild(self.exitButton)
    self.exitButton.text = "x"
    self.exitButton.x = self.w - 1
    self.exitButton.w = 1
    self.exitButton.h = 1
    self.exitButton.propogateFocusUp = true

    self.exitButton.pressed = function(o)
        self:close()
    end

    self.scaleButton = control:new{}
    self:addChild(self.scaleButton)
    self.scaleButton.w = 1
    self.scaleButton.h = 1
    self.scaleButton.text = "%"
    self.scaleButton.propogateFocusUp = true

    self.scaleButton.drag = function(o, relativeX, relativeY)
        o.parent:setFullscreen(false, relativeX, relativeY)
    end

    self.scaleButton.doublePressed = function(o)
        o.parent:setFullscreen(true)
    end
end

function windowControl:close()
    self:closed()
    self:emitSignal(self.closedSignal)
    --self.parent:removeChild(self)
    --self:remove()
    self:queueFree() --TODO Re-add
end

function windowControl:setFullscreen(fullscreen, relativeX, relativeY)
    if fullscreen == true then
        local w, h = term.getSize()
        local wi = self
        wi.oldX = wi.x
        wi.oldY = wi.y
        wi.x = 0
        wi.y = 0
        wi.w = w
        wi.h = h
        wi:toFront()
        wi:grabFocus()
        if wi.fullscreen == false then
            wi.fullscreen = true
            self:emitSignal(self.fullscreenChangedSignal)
        end
    else
        local wi = self
        local w = wi.w
        local h = wi.h
        if relativeX ~= nil and relativeY ~= nil then
            wi.w = wi.w - relativeX
            wi.h = wi.h - relativeY
            wi.w = math.max(wi.w, wi.minW)
            wi.h = math.max(wi.h, wi.minH)
            local deltaW = w - wi.w
            local deltaH = h - wi.h
            wi.x = wi.x + deltaW
            wi.y = wi.y + deltaH

            wi.oldW = wi.w
            wi.oldH = wi.h
        else
            wi.w = wi.oldW
            wi.h = wi.oldH
            wi.x = wi.oldX
            wi.y = wi.oldY
        end

        if wi.fullscreen == true then
            wi.fullscreen = false
            wi:emitSignal(wi.fullscreenChangedSignal)
        end
    end
end

function windowControl:click()
    --self:toFront()
end

function windowControl:drag(x, y)
    control.drag(self, x, y)
    self.w = self.oldW
    self.h = self.oldH
    if self.fullscreen == true then
        self.fullscreen = false
        self:emitSignal(self.fullscreenChangedSignal)
    end
end

function windowControl:sizeChanged()
    self.exitButton.x = self.w - 1
    self.label.w = self.w - 2
end

function windowControl:refreshMinSize()
    self.minW, self.minH = math.min(self.minW, self.w), math.min(self.minH, self.h)
    self.oldW, self.oldH = self.w, self.h
end

function windowControl:closed() end

return windowControl
end