return function(button)
local dropdown = button:new{}
dropdown.text = "Drop-down"
dropdown.h = 1
dropdown.list = nil
dropdown.open = false
dropdown.dragSelectable = false

function dropdown:ready()
    self.list = self:addVContainer()
    self.list.y = self.h
    self.list.visible = false
    --self.list.mouseIgnore = true
end 

function dropdown:addToList(text, clickable)
    local b 
    if clickable == nil or clickable == true then
        b = self.list:addButton()
        b.dragSelectable = false
    else
        b = self.list:addControl()
    end
    self.list.visible = false
    b.visible = false
    b.text = text
    b.h = 1
    b.pressed = function(o)
        for i = 1, #o.parent.children do
            if o.parent.children[i] == o then
                o.parent.parent:optionPressed(i)
                break
            end
        end
    end
end

function dropdown:removeFromList(text)
    for i = 1, #self.list.children do
        if self.list.children[i].text == text then
            self.list.children[i]:remove()
            break
        end
    end
end

function dropdown:draw()
    button.draw(self)
    local maxLength = self.w
    for i = 1, #self.list.children do
        maxLength = math.max(#self.list.children[i].text, maxLength)
    end

    for i = 1, #self.list.children do
        self.list.children[i].w = maxLength
    end
end

function dropdown:pressed()
    button.pressed(self)
    self.list.visible = true
end


function dropdown:up()
    button.up(self)
    self.list.visible = false
end

function dropdown:getOptionText(i)
    return self.list.children[i].text
end

function dropdown:getOption(i)
    return self.list.children[i]
end

function dropdown:getOptionsTextList()
    local textList = {}
    for i = 1, #self.list.children do
        table.insert(textList, self.list.children[i].text)
    end
    return textList
end

function dropdown:optionPressed(i) end

return dropdown
end