---@return Style
return function(object)
---@class Style : Object
local style = object:new{}
style.backgroundColor = colors.lightGray
style.borderColor = colors.gray
style.textColor = colors.black
style.background = true
style.border = false
--style.shadow = false
style.shadowColor = colors.gray

return style
end