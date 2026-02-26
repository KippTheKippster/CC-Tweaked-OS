---@return Button
return function(control, style, clickStyle)
---@class Button : Control 
local Button = control:newClass()
Button.__type = "Button"


Button.isClicked = false
Button._normalStyle = style
---@type Style
Button.normalStyle = nil
Button:defineProperty("normalStyle", {
    get = function (o)
        return o._normalStyle
    end,
    set = function (o, value)
        o._normalStyle = value
        o:refreshStyle(o)
    end
})

Button._clickStyle = clickStyle
---@type Style
Button.clickStyle = nil
Button:defineProperty("clickStyle", {
    get = function (o)
        return o._clickStyle
    end,
    set = function (o, value)
        o._clickStyle = value
        o:refreshStyle(o)
    end
})

function Button:refreshStyle ()
    if self.isClicked then
        self.style = self.clickStyle
    elseif self.inheritStyle then
        self.style = self.parent.style
    else
        self.style = self.normalStyle
    end
end

function Button:treeEntered()
    self:refreshStyle()
end

Button.text = "Button"

function Button:down(b, x, y)
    self.isClicked = true
    self:refreshStyle()
end

function Button:up(b, x, y)
    self.isClicked = false
    self:refreshStyle()
end

return Button
end