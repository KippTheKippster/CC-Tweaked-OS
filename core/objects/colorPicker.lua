---@return ColorPicker
return function(dropdown, input, style)
---@class ColorPicker : Dropdown
local ColorPicker = dropdown:new{}
ColorPicker.type = "ColorPicker"

function ColorPicker:treeEntered()
    --dropdown.ready(self)
    self.list.expandW = true
    for i = 0, 15 do
        self:addToList("", true, 2 ^i)
    end
end

function ColorPicker:addToList(text, clickable, color)
    if self.list == nil then
        return
    end

    local b = dropdown.addToList(self, text, clickable)
    local colorStyle = style:new{}
    colorStyle.backgroundColor = color
    colorStyle.textColor = colors.black
    b.style = colorStyle
    b.normalStyle = colorStyle
    b.clickedStyle = colorStyle
    b.expandW = true
    local click = b.click
    b.click = function (o)
        click(o)
        self.style = b.normalStyle
    end
end

function ColorPicker:getColor()
    return self.style.backgroundColor
end

return ColorPicker
end
