return function(container)
local vContainer = container:new{}
vContainer.type = "VContainer"

vContainer.center = false

function vContainer:sort()
	local w = self.w
	if self.expandW == false then
		w = 0
	end
	local h = 0
	local x = 0
	for i = 1, #self.children do
		local c = self.children[i]
		--c:_resize()
        c.y = h
		if self.center == true then
			x = math.ceil((self.w - c.w) / 2)
		else
			x = 0
		end
		c.x = x
		h = h + c.h
		w = math.max(w, c:getMinimumSize())
	end

	for i = 1, #self.children do
		local c = self.children[i]
		if c.expandW then
			c.w = w
		end
	end
	--self.h = #self.children
	self.w = w
	self.h = h
end



return vContainer
end