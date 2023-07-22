return function(control, style, clickedStyle)
local button = control:new{}
button.normalStyle = style
button.clickedStyle = clickedStyle
button.text = "Button"

function button:click()
    self.style = self.clickedStyle
end

function button:up()
    self.style = self.normalStyle
end

return button
end