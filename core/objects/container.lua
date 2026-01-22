---@return Container
return function(control)
---@class Container : Control
local Container = control:newClass()
Container.__type = "Container"

Container.mouseIgnore = false
Container.text = ""
Container.visible = true
Container.rendering = false
Container.sortOnTransformChanged = true
Container.fitToText = false

function Container:childrenChanged()
	self:sort()
end

function Container:transformChanged()
	if self.sortOnTransformChanged == true then
		self:sort()
	end
end

function Container:sort() end

return Container
end
