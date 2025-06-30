return function(control, button)
local windowControl = control:new{}
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
    self.oldW = self.w
    self.oldH = self.h

    self.label = self:addControl()
    self.label.x = 2
    self.label.w = 1
    self.label.h = 1
    self.label.mouseIgnore = true
    self.label.clipText = true

    self.exitButton = button:new{}
    self:addChild(self.exitButton)
    self.exitButton.text = "x"
    self.exitButton.x = self.w - 1
    self.exitButton.w = 1
    self.exitButton.h = 1
    self.exitButton.propogateFocusUp = true

    self.exitButton.pressed = function(o)
        o.parent:emitSignal(o.parent.closedSignal)
        o.parent:remove()
    end

    self.scaleButton = control:new{}
    self:addChild(self.scaleButton)
    self.scaleButton.w = 1
    self.scaleButton.h = 1
    self.scaleButton.text = "%"
    self.scaleButton.propogateFocusUp = true

    self.scaleButton.drag = function(o, relativeX, relativeY)
        local wi = o.parent
        local w = wi.w
        local h = wi.h
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

        if wi.fullscreen == true then
            wi.fullscreen = false
            wi:emitSignal(wi.fullscreenChangedSignal)
        end
    end

    self.scaleButton.doublePressed = function(o)
        local w, h = term.getSize()
        local wi = o.parent
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
return windowControl
end