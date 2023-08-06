local path = ".core."
local style = require(path .. "styles.style")
local clickedStyle = style:new{}
clickedStyle.backgroundColor = colors.white
clickedStyle.textColor = colors.orange

return clickedStyle