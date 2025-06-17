return function(control, button)
local windowControl = control:new{}
windowControl.draggable = true
windowControl.text = "Window"
windowControl.label = nil
windowControl.exitButton = nil
windowControl.scaleButton = nil
windowControl.minW = 10
windowControl.minH = 4
windowControl.oldW = 0
windowControl.oldH = 0


windowControl:defineProperty('text', {
    get = function(table) 
        if table.label == nil then
            return table._text 
        else
            return table.label.text
        end
    end,
    set = function(table, value) 
        if table.label == nil then
            table._text = value 
        else
            table.label._text = value
            table._text = ""
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

    self.exitButton = button:new{}
    self:addChild(self.exitButton)
    self.exitButton.text = "x"
    self.exitButton.x = self.w - 1
    self.exitButton.w = 1
    self.exitButton.h = 1
    self.exitButton.propogateFocusUp = true

    self.exitButton.pressed = function(o)
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
    end
end

function windowControl:click()
    --self:toFront()
end

function windowControl:drag(x, y)
    control.drag(self, x, y)
    self.w = self.oldW
    self.h = self.oldH
end

function windowControl:sizeChanged()
    self.exitButton.x = self.w - 1
end
return windowControl
end