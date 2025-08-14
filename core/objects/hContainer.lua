---@class HContainer
return function(container)
---@class HContainer : Container
local HContainer = container:new{}
HContainer.type = "HContainer"

HContainer.center = false
HContainer.separation = 0

function HContainer:sort()
	self:_expandChildren()

	local w = 0
	local y = 0
	for i = 1, #self.children do
		local c = self.children[i]
		c.x = w
		if self.center == true then
			y = self.globalY + math.ceil((self.h - c.h) / 2)
		else
			y = self.globalY
		end
		c.globalY = y
		w = w + c.w + self.separation
	end
end

function HContainer:_expandChildren()
	local minW = 0
	local expandCount = 0
	for i, c in ipairs(self.children) do
		minW = minW + c:getMinimumSize()
		if c.expandW == true then
			expandCount = expandCount + 1
		end
	end

	local dif = self.w - minW
	local expandSize = math.floor(dif / expandCount)

	if dif > 0 then
		for i, c in ipairs(self.children) do
			if c.expandW == true then
				c.w = expandSize
			else
				c.w = c:getMinimumSize()
			end
		end
	end
end

return HContainer
end