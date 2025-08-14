---@return Dropdown
return function(button, input, utils)
---@class Dropdown : Button
local Dropdown = button:new{}
Dropdown.type = "Dropdown"

Dropdown.text = "Drop-down"
Dropdown.h = 1
Dropdown._fitToText = true
Dropdown.list = nil
Dropdown.open = false
Dropdown.dragSelectable = true
Dropdown.listQueue = nil
Dropdown.shortcutSelection = nil
Dropdown.optionNormalStyle = Dropdown.normalStyle
Dropdown.optionClickedStyle = Dropdown.clickedStyle
Dropdown.optionShadow = Dropdown.clickedStyle

function Dropdown:ready()
    self.list = self:addVContainer()
    self.list.inheritStyle = false
    self.list.style = self.normalStyle
    --self.list.style.shadowColor = colors.black
    self.list.render = function (o)
        o:drawShadow()
    end
    self.list.rendering = true
    self.list.y = self.h
    self.list.w = 0
    self.list.h = 0
    self.list.inheritStyle = false
    self.list.visible = false
    self.list.propogateFocusUp = true
    self.list.dragSelectable = true
    self.list.shadow = self.optionShadow
    self.list.mouseIgnore = true

    self.fitToText = true

    --self.list.rendering = true

    input.addRawEventListener(self)

    self.listQueue = self.listQueue or {}
    for i = 1, #self.listQueue do
        local option = self.listQueue[i]
        self:addToList(option.text, option.clickable)
    end

    self.listQueue = {}
end

function Dropdown:isOpened()
   return self.list.visible == true
end

function Dropdown:close()
    self.list.visible = false
    self.shortcutSelection = nil
end

function Dropdown:rawEvent(data)
    local event = data[1]
    if event == "mouse_up" then
        self:close()
    end
end

function Dropdown:focusChanged()
    if self.focus == false then
        self:up()
        if self.shortcutSelection ~= nil then
            self.shortcutSelection:up()
        end
        self:close()
    end
end

function Dropdown:addToList(text, clickable)
    --sleep(0.1)
    if clickable == nil then
        clickable = true
    end

    if self.list == nil then
        self.listQueue = self.listQueue or {}
        table.insert(self.listQueue, { text = text, clickable = clickable })
        return
    end

    local b = nil
    if clickable == true then
        b = self.list:addButton()
        b.optionSelectable = true
    else
        b = self.list:addControl()
    end
    self.list.visible = false
    b.shadow = false
    b.inheritStyle = false
    b.style = self.optionNormalStyle
    b.normalStyle = self.optionNormalStyle
    b.clickedStyle = self.optionClickedStyle
    b.text = text
    b.h = 1
    b.fitToText = true
    b.dragSelectable = true
    b.propogateFocusUp = true
    b.marginL = 1
    b.marginR = 1
    b.expandW = true
    local click = b.click
    b.click = function(o)
        if self.shortcutSelection then
            self.shortcutSelection:up()
        end
        click(o)
        self.shortcutSelection = o
    end
    b.pressed = function(o)
        for i = 1, #o.parent.children do
            if o.parent.children[i] == o then
                o.parent.parent:optionPressed(i)
                break
            end
        end
    end

    self.list:sort()

    return b
end

function Dropdown:removeFromList(o)
    if type(o) == "string" then
        for i = 1, #self.list.children do
            if self.list.children[i].text == o then
                self.list.children[i]:queueFree()
                break
            end
        end
    else
        --local i = utils.find(self.list.children, o)
        self.list:removeChild(o)
    end
end

function Dropdown:clearList()
    if self.list == nil then return end
    for i = 1, #self.list.children do
        self.list:removeChild(self.list.children[1])
    end
end

function Dropdown:click()
    button.click(self)
    self.list.visible = true
    if self.shortcutSelection and self.shortcutSelection ~= self then
        self.shortcutSelection:up()
    end

    self.shortcutSelection = self
end

function Dropdown:getOptionText(i)
    return self.list.children[i].text
end

function Dropdown:getOption(i)
    return self.list.children[i]
end

function Dropdown:getOptionsTextList()
    local textList = {}
    for i = 1, #self.list.children do
        table.insert(textList, self.list.children[i].text)
    end
    return textList
end

function Dropdown:next()
    self.list.visible = true
    if self:isOpened() == false then
        if self.shortcutSelection ~= nil then
            self.shortcutSelection:releaseFocus()
        end
        self.shortcutSelection = nil
    end

    if self.shortcutSelection ~= nil then
        self.shortcutSelection:up()
        local idx = utils.find(self.list.children, self.shortcutSelection)

        if idx == nil then
            self.shortcutSelection = self.list.children[1]
        else
            self.shortcutSelection = nil
            for i = 1, #self.list.children - idx do
                local next = self.list.children[idx + i]
                if next ~= nil and next.optionSelectable == true then
                    self.shortcutSelection = next
                    break
                end
            end
        end
    end

    if self.shortcutSelection == nil then
        self.shortcutSelection = self
    end

    self.shortcutSelection:click()
    self.shortcutSelection:grabFocus()
end

function Dropdown:release()
    if self:isOpened() == true then
        if self.shortcutSelection ~= nil then
            self.shortcutSelection:up()
            self.shortcutSelection:pressed()
        end

        self:close()
    end
    self.shortcutSelection = nil
end

function Dropdown:optionPressed(i) end

return Dropdown
end