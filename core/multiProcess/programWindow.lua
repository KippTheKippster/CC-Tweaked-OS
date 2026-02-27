-- Extends windowControl, attaches a programViewport to a window.
---@return ProgramWindow
---@param windowControl WindowControl
---@param input Input
return function(windowControl, input)
---@class ProgramWindow : WindowControl
local ProgramWindow = windowControl:newClass()
ProgramWindow.__type = "ProgramWindow"

---@type ProgramViewport
ProgramWindow.programViewport = nil
ProgramWindow.minimizeButton = nil
ProgramWindow.focusedStyle = nil
ProgramWindow.unfocusedStyle = nil
ProgramWindow._clickStyle = nil
ProgramWindow:defineProperty('clickStyle', {
    get = function(o) return o._clickStyle end,
    set = function(o, value)
        o._clickStyle = value
        --
        o.minimizeButton.clickStyle = value
        o.splitLeftButton.clickStyle = value
        o.splitRightButton.clickStyle = value
        o.splitUpButton.clickStyle = value
        o.splitDownButton.clickStyle = value
        --
        o.minimizeButton.normalStyle = o.focusedStyle
        o.splitLeftButton.normalStyle = o.focusedStyle
        o.splitRightButton.normalStyle = o.focusedStyle
        o.splitUpButton.normalStyle = o.focusedStyle
        o.splitDownButton.normalStyle = o.focusedStyle
    end
})

ProgramWindow.showShadow = true

---@return Button
local function addButton (wi)
    local b = wi:addButton()
    b.clickStyle = wi.clickStyle
    return b
end

local function addSplit (wi, h, fn)
    local split = addButton(wi)
    split.visible = false
    split.centerText = true
    if h then
        split.expandH = true
        split.w = 1
    else
        split.expandW = true
        split.h = 1
    end

    split.pressed = function ()
        fn(wi)
    end

    return split
end

function ProgramWindow:init(text)
    windowControl.init(self, text)

    self.minimizeButton = addButton(self)
    self.minimizeButton.w = 1
    self.minimizeButton.h = 1
    self.minimizeButton.text = "-"
    self.minimizeButton.propogateFocusUp = true

    self.splitLeftButton = addSplit(self, true, self.enableLeftSplitScreen)
    self.splitLeftButton.x = -1
    self.splitLeftButton.text = "\17"

    self.splitRightButton = addSplit(self, true, self.enableRightSplitScreen)
    self.splitRightButton.x = self.w + 1
    self.splitRightButton.text = "\16"

    self.splitUpButton = addSplit(self, false, self.enableUpSplitScreen)
    self.splitUpButton.y = -1
    self.splitUpButton.text = "\30"

    self.splitDownButton = addSplit(self, false, self.enableDownSplitScreen)
    self.splitDownButton.y = self.h + 1
    self.splitDownButton.text = "\31"

    self.minimizeButton.pressed = function(o)
        self.visible = false
    end

    self.minimizeButton.dragSelectable = true
    self.exitButton.dragSelectable = true
    self.splitLeftButton.dragSelectable = true
    self.splitRightButton.dragSelectable = true

    input.addRawEventListener(self)
end

function ProgramWindow:queueFree()
   windowControl.queueFree(self)
   input.removeRawEventListener(self)
end

function ProgramWindow:setSplitButtonsVisible(visible)
    self.splitLeftButton.visible = visible
    self.splitRightButton.visible = visible
    self.splitUpButton.visible = visible
    self.splitDownButton.visible = visible
end

function ProgramWindow:rawEvent(data)
    local event = data[1]
    local key = data[2]
    if event == "key" then
        if key == keys.leftAlt and self:inFocus() then
            self:setSplitButtonsVisible(true)
        end
    elseif event == "key_up" then
        if key == keys.leftAlt then
            self:setSplitButtonsVisible(false)
        end
    end
end

function ProgramWindow:enableLeftSplitScreen()
    local w, h = term.getSize()
    self.x = 0
    self.y = 1
    self.w = math.ceil(w/2)
    self.h = h-1
    self.showShadow = false
end

function ProgramWindow:enableRightSplitScreen()
    local w, h = term.getSize()
    self.x = math.ceil(w/2)
    self.y = 1
    self.w = math.ceil(w/2)
    self.h = h-1
    self.showShadow = false
end

function ProgramWindow:enableUpSplitScreen()
    local w, h = term.getSize()
    self.x = 0
    self.y = 1
    self.w = w
    self.h = math.ceil(h/2)
    self.showShadow = false
end

function ProgramWindow:enableDownSplitScreen()
    local w, h = term.getSize()
    self.x = 0
    self.y = math.ceil(h/2) - 1
    self.w = w
    self.h = math.ceil(h/2)
    self.showShadow = false
end

function ProgramWindow:close()
    self.programViewport.terminated = true
    self.programViewport:endProcess()
    windowControl.close(self)
end


function ProgramWindow:render()
    --SHADOW
    if self.showShadow == true then
        self:drawShadow()
    end
    --PANEL
    local left = self._gx + 1
    local up = self._gy + 1
    local right = self._gx + self._w
    local down = self._gy + 1 --draw only the top of the window, the rest is hidden by the program viewport
    self:drawPanel(left, up, right, down)
end

function ProgramWindow:addViewport(pv)
    self.programViewport = pv
    self:addChild(pv)
    pv.y = 1
    pv.h = pv.h - 1
    pv.propogateFocusUp = true
end

function ProgramWindow:down()
    windowControl.down(self)
    self:toFront()
end

function ProgramWindow:sizeChanged()
    windowControl.sizeChanged(self)
    self.minimizeButton.x = self.w - 2
    self.programViewport.w = self.w
    self.programViewport.h = self.h - 1
    self.splitRightButton.x = self.w
    self.splitDownButton.y = self.h
    self.showShadow = true
end


function ProgramWindow:updateCursor()
    local window = self.programViewport.program.window
    local parentTerm = term.current()
    term.redirect(window)
    term.setCursorPos(window.getCursorPos())
    term.setCursorBlink(window.getCursorBlink())
    term.setTextColor(window.getTextColor())
    term.redirect(parentTerm)
end

---comment
---@param visible boolean
function ProgramWindow:setHeaderVisibility(visible)
    self.rendering = visible
    self.mouseIgnore = visible == false
    self.scaleButton.visible = visible
    self.exitButton.visible = visible
    self.minimizeButton.visible = visible
end

function ProgramWindow:closed() end

return ProgramWindow
end
