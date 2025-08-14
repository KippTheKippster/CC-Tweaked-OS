---@return ColorPicker
return function(dropdown, style)
---@class ColorPicker : Dropdown
local ColorPicker = dropdown:new{}
ColorPicker.type = "ColorPicker"

function ColorPicker:ready()
    dropdown.ready(self)
    for i = 0, 16 do
        
    end
end

function dropdown:addToList(text, color)
    ---@class ColorPicker
    local b = dropdown.addToList(self, text, true)
    local colorStyle = style:new{}
    colorStyle.backgroundColor = color
    colorStyle.textColor = colors.black
    b.style = colorStyle
    b.normalStyle = colorStyle
    b.clickedStyle = colorStyle
end

return ColorPicker
end
