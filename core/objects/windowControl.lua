---@return WindowControl
return function(control, button, normalStyle, focusStyle, clickStyle, exitButtonStyle)
---@class WindowControl : Control
local WindowControl = control:newClass()
WindowControl.__type = "WindowControl"

WindowControl.draggable = true
WindowControl.clipText = true
WindowControl.text = "Window"
WindowControl.label = nil
WindowControl.exitButton = nil
WindowControl.scaleButton = nil
WindowControl.minW = 10
WindowControl.minH = 4
WindowControl.oldW = 0
WindowControl.oldH = 0
WindowControl.fullscreen = false
WindowControl.closedSignal = WindowControl:createSignal()
WindowControl.fullscreenChangedSignal = WindowControl:createSignal()
WindowControl.shadow = true

WindowControl.focusedStyle = focusStyle
WindowControl.unfocusedStyle = normalStyle

WindowControl:defineProperty('text', {
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

function WindowControl:init()
    self:refreshMinSize()

    self.label = self:addControl()
    self.label.x = 2
    self.label.w = 1
    self.label.h = 1
    self.label.mouseIgnore = true
    self.label.clipText = true
    self.label.w = self.w - 2

    self.exitButton = self:addButton()
    self.exitButton.text = "x"
    self.exitButton.x = self.w - 1
    self.exitButton.w = 1
    self.exitButton.h = 1
    self.exitButton.propogateFocusUp = true
    self.exitButton.normalStyle = normalStyle
    self.exitButton.clickStyle = exitButtonStyle

    self.exitButton.pressed = function(o)
        self:close()
    end

    self.scaleButton = control:new()
    self:addChild(self.scaleButton)
    self.scaleButton.w = 1
    self.scaleButton.h = 1
    self.scaleButton.text = "%"
    self.scaleButton.propogateFocusUp = true

    self.scaleButton.drag = function(o, b, x, y, rx, ry)
        local gx = x + self.gx - 1
        local gy = y + self.gy - 1

        local dx = self.gx - gx
        local dy = self.gy - gy

        local w = self.w + dx
        local h = self.h + dy

        if w >= self.minW then
            self.gx = gx
            self.w = self.w + dx
            self.oldW = self.w
        end

        if h >= self.minH then
            self.gy = gy
            self.h = self.h + dy
            self.oldH = self.h
        end
    end

    self.scaleButton.doublePressed = function(o)
        o.parent:setFullscreen(true)
    end
end

function WindowControl:close()
    self:closed()
    self:emitSignal(self.closedSignal)
    self:queueFree()
end

function WindowControl:setFullscreen(fullscreen)
    local wi = self
    if wi.fullscreen == fullscreen then
        return
    end

    wi.fullscreen = fullscreen
    if fullscreen == true then
        local w, h = term.getSize()
        wi.gx = 0
        wi.gy = 0
        wi.w = w
        wi.h = h
        wi:toFront()
        wi:grabFocus()
        self:emitSignal(self.fullscreenChangedSignal)
    else
        wi.w = self.oldW
        wi.h = self.oldH
        wi:emitSignal(wi.fullscreenChangedSignal)
    end
end

function WindowControl:drag(b, x, y, rx, ry)
    control.drag(self, b, x, y, rx, ry)
    if self.fullscreen == true then
        local tw = self.w
        self:setFullscreen(false)
        local gx = x + self.gx - 1
        self.gx = math.floor(gx - self.w * (x / tw) + 0.5)
    end
end

function WindowControl:sizeChanged()
    self.exitButton.x = self.w - 1
    self.label.w = self.w - 2
end

function WindowControl:refreshMinSize()
    self.minW, self.minH = math.min(self.minW, self.w), math.min(self.minH, self.h)
    self.oldW, self.oldH = self.w, self.h
end

function WindowControl:focusChanged()
    self:updateFocus()
end

function WindowControl:updateFocus()
    if self:inFocus() then
        self.style = self.focusedStyle
        self:toFront()
        self:grabCursor()
    else
        self.style = self.unfocusedStyle
        self:releaseCursor()
    end
end

function WindowControl:closed() end

return WindowControl
end