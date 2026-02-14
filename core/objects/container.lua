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
Container._sortQueued = false

function Container:childrenChanged()
	self:queueSort()
end

function Container:transformChanged()
	if self.sortOnTransformChanged == true then
		self:queueSort()
	end
end

function Container:queueSort()
	self._sortQueued = true
end

function Container:draw()
	control.draw(self)
	if self._sortQueued then
		self:sort()
	end
end

function Container:sort() end

return Container
end
