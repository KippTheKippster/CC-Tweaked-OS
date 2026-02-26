---@param container Container
---@param collision Collision
---@param input Input
---@return ScrollContainer
return function(container, collision, input)
---@class ScrollContainer : Container
local ScrollContainer = container:newClass()
ScrollContainer.__type = "ScrollContainer"

ScrollContainer.ScrollMode = { VERTICAL = 0, HORIZONTAL = 1 }
ScrollContainer.scrollMode = ScrollContainer.ScrollMode.VERTICAL
ScrollContainer.rendering = true
ScrollContainer.barStartX = 0
ScrollContainer.barStartY = 0
ScrollContainer.barEndX = 0
ScrollContainer.barEndY = 0
ScrollContainer.barPressed = false
ScrollContainer.dynamicBar = true
ScrollContainer.mOffset = 0

function ScrollContainer:init(...)
    input.addRawEventListener(self)
    container.init(self, ...)
end

function ScrollContainer:queueFree()
    input.removeRawEventListener(self)
    container.queueFree(self)
end

function ScrollContainer:render()
    local child = self.children[1]

    local steps = math.max(0, child.h - self.h)
    local stepAmount = math.min(1.0, ((self.h - 1) / steps))
    local offset = child.y * stepAmount
    local size = math.max(0, self.h - steps - 1)

    if self.dynamicBar then        
        if size == self.h - 1 then -- No scroll
            self.marginR = 0
            return
        else
            if self.marginR == 0 then
                self.marginR = 1
                self:queueDraw()
                self:sort()
                self:_expandChildren()
            end
        end
    end

    local startX = self.gx + self.w
    local endX = startX
    local startY = self.gy + 1
    local endY = startY + self.h - 1
    paintutils.drawLine(startX, startY, endX, endY, colors.gray)


    local round = math.floor
    if -math.floor(offset) == self.h - 1 then -- Do this better
        round = math.ceil
    end
    startY = startY - round(offset)
    endY = startY + size

    local color = colors.lightGray
    if self.barPressed then
        color = colors.orange
    end

    paintutils.drawLine(startX, startY, endX, endY, color)

    term.setCursorPos(startX, startY + math.floor((endY - startY) / 2 + 0.5))
    --term.write("I")

    self.barStartX = startX
    self.barStartY = startY
    self.barEndX = endX
    self.barEndY = endY
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

function ScrollContainer:scroll(dir, _, _)
    local child = self.children[1]
    child.y = child.y - dir
    self:sort()
end

function ScrollContainer:setScroll(position)
    local child = self.children[1]
    child.y = position
    self:sort()
end

function ScrollContainer:transformChanged()
    self:sort()
end

function ScrollContainer:rawEvent(data)
    local event = data[1]
    if event == "mouse_click" then
        local x = data[3]
        local y = data[4]
        if collision.inArea(x, y, self.barStartX, self.barStartY, self.barEndX - self.barStartX, self.barEndY - self.barStartY) then
            self.barPressed = true
            self:queueDraw()
            self.mOffset = self.barStartY - y - 1
        end
    elseif event == "mouse_up" then
        self.barPressed = false
        self:queueDraw()
    elseif event == "mouse_drag" then
        if self.barPressed then
            local x = data[3]
            local y = data[4]
            self:setScroll(self.gy - y - self.mOffset)
        end
    end
end

return ScrollContainer
end