local path = ".core."
local control = require(path .. ".objects.control")
local button = control:new{}
button.normalStyle = require(path .. "styles.defaultStyle")
button.clickedStyle = require(path .. "styles.clickedStyle")
button.text = "Button"

function button:click()
    self.style = self.clickedStyle
end

function button:up()
    self.style = self.normalStyle
end

return button