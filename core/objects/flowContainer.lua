---@return FlowContainer
return function(container)
---@class FlowContainer : Container 
local FlowContainer = container:new{}
FlowContainer.type = "FlowContainer"

function FlowContainer:sort()
	local w = 0
	local h = 0
	local nextH = 0
	for i = 1, #self.children do
		local c = self.children[i]
		c.globalX = self.globalX + w
		c.globalY = self.globalY + h
		w = w + c.w + 1
		nextH = math.max(nextH, h + c.h)
		if w > self.w then
			w = 0
			h = nextH + 1
		end
	end
end

return FlowContainer
end