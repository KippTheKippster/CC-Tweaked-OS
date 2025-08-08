return function(container)
local hContainer = container:new{}
hContainer.type = "HContainer"

hContainer.center = false
hContainer.separation = 0

function hContainer:sort()
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

function hContainer:_expandChildren()
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

return hContainer
end