---@return ScrollContainer
return function(container, input)
---@class ScrollContainer : Container
local ScrollContainer = container:newClass()
ScrollContainer.__type = "ScrollContainer"

ScrollContainer.ScrollMode = { VERTICAL = 0, HORIZONTAL = 1 }
ScrollContainer.scrollMode = ScrollContainer.ScrollMode.VERTICAL
ScrollContainer.rendering = true

function ScrollContainer:render()
    local child = self.children[1]
    local startX = self.globalX + self.w
    local endX = startX
    local startY = self.globalY + 1
    local endY = startY + self.h - 1
    paintutils.drawLine(startX, startY, endX, endY, colors.gray)

    local steps = math.max(0, child.h - self.h)
    local stepAmount = math.min(1.0, ((self.h - 1) / steps))
    local offset = child.y * stepAmount
    local size = math.max(0, self.h - steps - 1)
    local round = math.floor
    if -math.floor(offset) == self.h - 1 then -- Do this better
        round = math.ceil
    end
    startY = startY - round(offset)
    endY = startY + size

    paintutils.drawLine(startX, startY, endX, endY, colors.lightGray)

end

function ScrollContainer:sort()
    local child = self.children[1]
    if child == nil then
        return
    end

    child:_expandChildren()
    if child.y >= 0 then
        child.y = 0
        return
    end

    local dif = self.h - child.h
    if child.y < self.h - child.h then
        child.y = dif
        return
    end
end

function ScrollContainer:scroll(dir, x, y)
    local child = self.children[1]
    child.y = child.y - dir
    self:sort()
end

function ScrollContainer:setScroll(position)
    local child = self.children[1]
    child.y = position
    self:sort()
end


return ScrollContainer
end