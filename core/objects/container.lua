return function(control)
local container = control:new{}
container.type = "Container"

container.mouseIgnore = false
container.text = ""
container.visible = true
--container.background = false
container.rendering = false
container.sortOnTransformChanged = false

function container:childrenChanged()
	self:sort()
end

function container:transformChanged()
	if self.sortOnTransformChanged == true then
		self:sort()
	end
end

function container:sort() end

return container
end
