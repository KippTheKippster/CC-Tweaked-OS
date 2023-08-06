return function(container)
local hContainer = container:new{}
hContainer.center = false

function hContainer:sort()
	local w = 0
	local y = 0
	for i = 1, #self.children do
		local c = self.children[i]
		c._globalX = self._globalX + w
		if self.center == true then
			y = self.globalY + math.ceil((self.h - c.h) / 2)
		else
			y = self.globalY
		end
		c.globalY = y
		w = w + c.w
	end
end

return hContainer
end