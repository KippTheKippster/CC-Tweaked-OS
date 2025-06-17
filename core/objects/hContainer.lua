return function(container)
local hContainer = container:new{}
hContainer.center = false
hContainer.separation = 0

function hContainer:sort()
	local w = 0
	local y = 0
	for i = 1, #self.children do
		local c = self.children[i]
		c.globalX = self.globalX + w
		if self.center == true then
			y = self.globalY + math.ceil((self.h - c.h) / 2)
		else
			y = self.globalY
		end
		c.globalY = y
		w = w + c.w + self.separation
	end
end

return hContainer
end