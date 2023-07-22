return function(container)
local scrollContainer = container:new{}
scrollContainer.scrollY = 0

function scrollContainer:ready()
	input.addScrollListener(self)
end

function scrollContainer:scroll(dir, x, y)
    self.scrollY = self.scrollY -  dir
    
    if self.scrollY > 0 then
        self.scrollY = 0
        return
    end

    if self.scrollY < -self.children[1].h then
        self.scrollY = -self.children[1].h
        return
    end

    self.children[1].y = self.scrollY
end
return scrollContainer
end