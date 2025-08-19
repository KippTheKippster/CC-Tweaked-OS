---@return Button
return function(control, style, clickedStyle)
---@class Button : Control 
local Button = control:new{}
Button.type = "Button"

---@param button Button
local function refreshStyle (button)
    if button.isClicked then
        button.style = button.clickedStyle
    else
        button.style = button.normalStyle
    end 
end

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
        refreshStyle(o)
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
        refreshStyle(o)
    end
})

Button.text = "Button"

function Button:click()
    self.style = self.clickedStyle
    self.isClicked = true
end

function Button:up()
    self.style = self.normalStyle
    self.isClicked = false
end

return Button
end