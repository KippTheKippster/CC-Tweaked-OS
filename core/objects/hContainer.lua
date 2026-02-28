---@class HContainer
return function(container)
---@class HContainer : Container
local HContainer = container:newClass()
HContainer.__type = "HContainer"

HContainer.center = false
HContainer.separation = 0

function HContainer:sort()
	self:_expandChildren()

	local w = 0
	local y = 0
	for i = 1, #self.children do
		local c = self:getChild(i)
		c.x = w
		if self.center == true then
			y = self.gy + math.ceil((self.h - c.h) / 2)
		else
			y = self.gy
		end
		c.gy = y
		w = w + c.w + self.separation
	end
end

function HContainer:_expandChildren()
	local minW = 0
	local expandCount = 0
	for i, c in ipairs(self.children) do
		if c.expandW == true then
			expandCount = expandCount + 1
		else
			minW = minW + c:getMinimumSize()
		end

		if c.expandH then
			c.h = self.h
		end
	end

	local dif = self.w - minW
	local expandSize = math.floor(dif / expandCount)

	--if dif > 0 then -- TODO Check if this is needed
		for i, c in ipairs(self.children) do
			local minW, minH = c:getMinimumSize() 
			if c.expandW == true then
				c.w = expandSize
			else
				c.w = minW
			end
		end
	--end
end

return HContainer
end