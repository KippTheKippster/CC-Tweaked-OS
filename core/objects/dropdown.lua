return function(button, input, utils)
local dropdown = button:new{}
dropdown.text = "Drop-down"
dropdown.h = 1
dropdown.list = nil
dropdown.open = false
dropdown.dragSelectable = true
dropdown.listQueue = nil
dropdown.shortcutSelection = nil

function dropdown:ready()
    self.list = self:addVContainer()
    self.list.y = self.h
    self.list.inheritStyle = false
    self.list.visible = false
    self.list.propogateFocusUp = true
    self.list.dragSelectable = true
    self.list.shadow = true

    input.addRawEventListener(self)

    self.listQueue = self.listQueue or {}
    for i = 1, #self.listQueue do
        self:addToList(self.listQueue[i])
    end

    self.listQueue = {}
end

function dropdown:isOpened()
   return self.list.visible
end

function dropdown:close()
    self.list.visible = false
end

function dropdown:rawEvent(data)
    local event = data[1]
    if event == "mouse_up" then
        self:close()
    end
end

function dropdown:focusChanged()
    if self.focus == false then
        self.list.visible = false
        self:up()
        if self.shortcutSelection ~= nil then
            self.shortcutSelection:up()
        end
    end
end

function dropdown:addToList(text, clickable)
    --sleep(0.1)
    if self.list == nil then
        self.listQueue = self.listQueue or {}
        table.insert(self.listQueue, text)
        return
    end

    local b = nil
    if clickable == nil or clickable == true then
        b = self.list:addButton()
    else
        b = self.list:addControl()
    end
    self.list.visible = false
    b.inheritStyle = false
    b.text = text
    b.h = 1
    b.dragSelectable = true
    b.propogateFocusUp = true
    b.shadow = true
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
            self.list:removeChild(self.list.children[i])
            --self.list.children[i]:remove() TODO Reimplement? (Or is this automatically removed by garbage collection?)
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

function dropdown:click()
    button.click(self)
    self.list.visible = true
end


function dropdown:up()
    button.up(self)
    --self.list.visible = false
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

function dropdown:next()
    if self:isOpened() == false then
        if self.shortcutSelection ~= nil then
            self.shortcutSelection:releaseFocus()
        end
        self.shortcutSelection = nil
    end
    
    if self.shortcutSelection ~= nil then
        self.shortcutSelection:up()
        local i = utils.find(self.list.children, self.shortcutSelection)
        if i == nil then
            self.shortcutSelection = self.list.children[1]
        else
            self.shortcutSelection = self.list.children[i + 1]
        end
    end

    if self.shortcutSelection == nil then
        self.shortcutSelection = self
    end

    self.shortcutSelection:click()
    self.shortcutSelection:grabFocus()
end

function dropdown:release()
    if self:isOpened() == true then
        self.shortcutSelection:up()
        self.shortcutSelection:pressed()
        self:close()
    end
    self.shortcutSelection = nil
end

function dropdown:optionPressed(i) end

return dropdown
end