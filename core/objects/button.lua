---@return Button
return function(control, style, clickedStyle)
---@class Button : Control 
local Button = control:new{}
Button.type = "Button"

Button.normalStyle = style
Button.clickedStyle = clickedStyle
Button.text = "Button"

function Button:click()
    self.style = self.clickedStyle
end

function Button:up()
    self.style = self.normalStyle
end

return Button
end