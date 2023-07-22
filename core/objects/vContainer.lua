return function(container)
local vContainer = container:new{}
vContainer.center = false

function vContainer:sort()
	local h = 0
	local x = 0
	for i = 1, #self.children do
		local c = self.children[i]
        c.y = h
		if self.center == true then
			x = math.ceil((self.w - c.w) / 2)
		else
			x = 0
		end
		c.x = x
		h = h + c.h
	end
end

return vContainer
end