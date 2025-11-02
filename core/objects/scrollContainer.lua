---@return ScrollContainer
return function(container, input)
---@class ScrollContainer : Container
local ScrollContainer = container:new{}
ScrollContainer.type = "ScrollContainer"

ScrollContainer.ScrollMode = { VERTICAL = 0, HORIZONTAL = 1 }
ScrollContainer.scrollMode = ScrollContainer.ScrollMode.VERTICAL
ScrollContainer.scrollY = 0
ScrollContainer.scrollX = 0
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

    paintutils.drawLine(startX, startY, endX, endY, colors.green)

end

function ScrollContainer:scroll(dir, x, y)
    local child = self.children[1]
    child.y = child.y - dir

    if child.y > 0 then
        child.y = 0
        return
    end

    term.setTextColor(colors.red)

    local dif = self.h - child.h
    if child.y < self.h - child.h then
        child.y = dif
        return
    end

end
return ScrollContainer
end