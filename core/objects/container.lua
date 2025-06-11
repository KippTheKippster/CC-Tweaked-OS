return function(control)
local container = control:new{}
container.mouseIgnore = false
container.text = ""
container.visible = true
--container.background = false
container.rendering = false

function container:childrenChanged()
	self:sort()
end

function container:sort() end

return container
end
