---@return Style
return function(object)
---@class Style : Object
local style = object:new{}
style.backgroundColor = colors.lightGray
style.borderColor = colors.gray
style.textColor = colors.black
style.background = true
style.border = false
style.shadowColor = colors.gray
style.shadowOffsetL = 0
style.shadowOffsetR = 0
style.shadowOffsetU = 0
style.shadowOffsetD = 0

return style
end