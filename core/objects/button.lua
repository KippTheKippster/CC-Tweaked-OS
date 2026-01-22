---@return Button
return function(control, style, clickedStyle)
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

Button._clickedStyle = clickedStyle
---@type Style
Button.clickedStyle = nil
Button:defineProperty("clickedStyle", {
    get = function (o)
        return o._clickedStyle
    end,
    set = function (o, value)
        o._clickedStyle = value
        o:refreshStyle(o)
    end
})

function Button:refreshStyle ()
    if self.isClicked then
        self.style = self.clickedStyle
    else
        self.style = self.normalStyle
    end
end

function Button:treeEntered()
    self:refreshStyle()
end

Button.text = "Button"

function Button:click()
    self.isClicked = true
    self:refreshStyle()
end

function Button:up()
    self.isClicked = false
    self:refreshStyle()
end

return Button
end