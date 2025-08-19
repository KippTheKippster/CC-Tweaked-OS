---@return ColorPicker
return function(control, flowContainer, input, style)
---@class ColorPicker : Control
local ColorPicker = control:new{}
ColorPicker.type = "ColorPicker"
ColorPicker.list = nil
ColorPicker.h = 1
ColorPicker._fitToText = true
ColorPicker.list = nil
ColorPicker.open = false
ColorPicker.dragSelectable = true
ColorPicker.listQueue = nil
ColorPicker.shortcutSelection = nil
ColorPicker.optionNormalStyle = ColorPicker.normalStyle
ColorPicker.optionClickedStyle = ColorPicker.clickedStyle
ColorPicker.optionShadow = false

---@param picker ColorPicker
---@param color integer
local function addColor(picker, color)
    ---@type Control
    local b = picker.list:addControl()
    local colorStyle = style:new{}
    colorStyle.backgroundColor = color
    colorStyle.textColor = colors.black
    b.inheritStyle = false
    b.style = colorStyle
    b.w = 1
    b.h = 1
    b.text = ""
    b.dragSelectable = true
    b.propogateFocusUp = true
    b.click = function (self)
        picker.style = self.style
    end
    b.pressed = function (self)
        picker:releaseFocus()
        picker:colorPressed(self.style.backgroundColor)
    end
end

function ColorPicker:ready()
    ---@type FlowContainer
    self.list = self:addFlowContainer()
    self.list.expandW = true
    self.list.h = 1
    self.list.visible = false
    self.list.rendering = false
    self.list.propogateFocusUp = true
    self.list.dragSelectable = true
    self.list.mouseIgnore = true

    self.list.y = 1
    for i = 0, 15 do
        addColor(self, 2 ^ i)
    end

    ---@type Input
    input.addMouseEventListener(self)
end

function ColorPicker:sizeChanged()
    self.list:sort()
end

function ColorPicker:click()
    self.list.visible = true
end

function ColorPicker:focusChanged()
    if self.focus == false then
        self.list.visible = false
    end
end

function ColorPicker:mouseEvent(event, button)
    if event == "mouse_up" then
        self.list.visible = false
    end
end

function ColorPicker:colorPressed(color) end

return ColorPicker
end
