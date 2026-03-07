---@return Style
return function(object)
---@class Style : Object
local Style = object:newClass()
Style.__type = "Style"
Style.__name = "Style"
Style.backgroundColor = colors.lightGray
Style.borderColor = colors.gray
Style.textColor = colors.black
Style.background = true
Style.border = false
Style.shadowColor = colors.gray
Style.shadowOffsetL = 0
Style.shadowOffsetR = 0
Style.shadowOffsetU = 0
Style.shadowOffsetD = 0

return Style
end