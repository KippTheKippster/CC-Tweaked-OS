---@return VContainer
return function(container)
---@class VContainer : Container
local VContainer = container:newClass()
VContainer.__type = "VContainer"

VContainer.center = false
VContainer.separation = 0
VContainer.fitToChildrenW = false
VContainer.fitToChildrenH = false

function VContainer:sort()
	self:expandChildren()
	local h = 0
	local x = 0
	for i = 1, #self.children do
		local c = self:getChild(i)
		if c.visible then
			c.y = h
			if self.center == true then
				x = self.gx + math.ceil((self.w - c.w) / 2) + self.marginL
			else
				x = self.gx + self.marginL
			end
			c.gx = x
			h = h + c.h + self.separation
		end
	end
end

function VContainer:expandChildren()
	if #self.children == 0 then
		if self.fitToChildrenW then
			self.w = 0
		end
		if self.fitToChildrenH then
			self.h = 0
		end
	end

	local w = self.w - (self.marginL + self.marginR)
	local minW, minH = self.w, 0
	local expandCount = 0
	for i, c in ipairs(self.children) do
		local _, h = c:getMinimumSize()
		if c.expandH == true then
			expandCount = expandCount + 1
		else
			minH = minH + h
		end

		if c.expandW then
			c.w = w
		end

		local cW, cH = c:getMinimumSize()
		minW = math.max(minW, cW)
	end

	if self.fitToChildrenW then
		self.w = minW
	end

	if self.fitToChildrenH then
		self.h = minH
	else
		self.h = math.max(self.h, minH)
	end

	local dif = self.h - minH
	local expandSize = math.floor(dif / expandCount)
	for i, c in ipairs(self.children) do
		if c.expandH == true then
			c.h = expandSize
		else
			local _, h = c:getMinimumSize()
			c.h = h
		end
	end
end

return VContainer
end