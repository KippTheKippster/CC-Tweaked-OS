return function(button)
local dropdown = button:new{}
dropdown.text = "Drop-down"
dropdown.h = 1
dropdown.list = nil
dropdown.open = false

function dropdown:ready()
    self.list = self:addVContainer()
    self.list.y = self.h
    self.list.visible = false
    --self.list.mouseIgnore = true
end 

function dropdown:addToList(text)
    local b = self.list:addButton()
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

function dropdown:pressed()
    self.list.visible = self.list.visible == false
end

function dropdown:getOptionText(i)
    return self.list.children[i].text
end

function dropdown:getOption(i)
    return self.list.children[i]
end

function dropdown:optionPressed(i) end

return dropdown
end