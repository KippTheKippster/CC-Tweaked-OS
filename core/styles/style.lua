local path = ".core."
local objects = require(path .. "objects")
local style = objects.new_object()
style.backgroundColor = colors.lightGray
style.borderColor = colors.gray
style.textColor = colors.black
style.border = false
--style.shadow = false
style.shadowColor = colors.gray

return style