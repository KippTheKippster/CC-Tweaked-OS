---@return ScrollContainer
return function(container, input)
---@class ScrollContainer : Container
local ScrollContainer = container:new{}
ScrollContainer.type = "ScrollContainer"

ScrollContainer.scrollY = 0

function ScrollContainer:ready()
	input.addScrollListener(self)
end

function ScrollContainer:scroll(dir, x, y)
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
return ScrollContainer
end