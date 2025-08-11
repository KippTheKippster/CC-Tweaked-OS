-- Extends windowControl, attaches a programViewport to a window.

return function(windowControl, programViewport)
local programWindow = windowControl:new{}
programWindow.type = "ProgramWindow"

programWindow.programViewport = nil
programWindow.minimizeButton = nil
programWindow.focusedStyle = nil
programWindow.unfocusedStyle = nil
programWindow._clickedStyle = nil
programWindow:defineProperty('clickedStyle', {
    get = function(o) return o._clickedStyle end,
    set = function(o, value)
        o._clickedStyle = value
        o.minimizeButton.clickedStyle = value
        o.splitLeftButton.clickedStyle = value
        o.splitRightButton.clickedStyle = value
        o.minimizeButton.normalStyle = o.focusedStyle
        o.splitLeftButton.normalStyle = o.focusedStyle
        o.splitRightButton.normalStyle = o.focusedStyle
    end
})

programWindow.showShadow = true

local function addButton (w)
    local b = w:addButton()
    b.clickedStyle = w.clickedStyle
    return b
end

function programWindow:ready()
    windowControl.ready(self)

    self.minimizeButton = addButton(self)
    self.minimizeButton.w = 1
    self.minimizeButton.h = 1
    self.minimizeButton.text = "-"
    self.minimizeButton.propogateFocusUp = true

    self.splitLeftButton = addButton(self)
    self.splitLeftButton.x = self.w - 4
    self.splitLeftButton.w = 1
    self.splitLeftButton.h = 1
    self.splitLeftButton.text = "<"
    --self.splitLeftButton.propogateFocusUp = true

    self.splitLeftButton.pressed = function(o)
        o.parent:enableLeftSplitScreen()
    end

    self.splitRightButton = addButton(self)
    self.splitRightButton.x = self.w - 3
    self.splitRightButton.w = 1
    self.splitRightButton.h = 1
    self.splitRightButton.text = ">"
    --self.splitRightButton.propogateFocusUp = true

    self.splitRightButton.pressed = function(o)
        self:releaseFocus()
        self:enableRightSplitScreen()
    end

    self.minimizeButton.pressed = function(o)
        self.visible = false
    end

    self.exitButton.pressed = function(o)
        self:close()
    end

    self.scaleButton.up = function(o)
        o.parent:redraw()
    end
end

function programWindow:enableLeftSplitScreen()
    local w, h = term.getSize()
    self.x = 0
    self.y = 1
    self.w = math.ceil(w/2)
    self.h = h-1
    self.showShadow = false
    self:toFront()
    self:grabFocus()
end

function programWindow:enableRightSplitScreen()
    local w, h = term.getSize()
    self.x = math.ceil(w/2)
    self.y = 1
    self.w = math.ceil(w/2)
    self.h = h-1
    self.showShadow = false
    self:toFront()
    self:grabFocus()
end


function programWindow:close()
    self.programViewport.terminated = true
    self.programViewport:endProcess()
    windowControl.close(self)
end


function programWindow:render()
    --SHADOW
    if self.showShadow == true then
        self:drawShadow()
    end
    --PANEL
    local left = self._globalX + 1
    local up = self._globalY + 1
    local right = self._globalX + self._w
    local down = self._globalY + 1 --draw only the top of the window, the rest is hidden by the program viewport
    self:drawPanel(left, up, right, down)

    --TEXT
    self:write()
end

function programWindow:addViewport(pv)
    self.programViewport = pv
    self:addChild(pv)
    pv.y = 1
    pv.h = pv.h - 1
    pv.propogateFocusUp = true
    --self.programViewport.click = function(o)
    --    o.parent:toFront()
    --end

    --self.programViewport.focusChanged = function(o)
    --    o.parent:updateFocus()
    --end
end

function programWindow:click()
    windowControl.click(self)
    self:toFront()
end

--function programWindow:launchProgram(path, ...)
--    self.programViewport:launchProgram(path, ...)
--end

function programWindow:sizeChanged()
    windowControl.sizeChanged(self)
    self.minimizeButton.x = self.w - 2
    self.programViewport.w = self.w
    self.programViewport.h = self.h - 1
    self.splitLeftButton.x = self.w - 4
    self.splitRightButton.x = self.w - 3
    self.showShadow = true
end

function programWindow:focusChanged()
    self:updateFocus()
end

function programWindow:updateFocus()
    if self:inFocus() then -- or (self.programViewport ~= nil and self.programViewport:inFocus()) then
        self.style = self.focusedStyle
        --term.setCursorBlink(true)
        self:toFront()
        self:grabCursorControl()
    else
        self.style = self.unfocusedStyle
        self:releaseCursorControl()
        --term.setCursorBlink(false)
    end
end

function programWindow:updateCursor()
    local window = self.programViewport.program.window
    local parentTerm = term.current()
    term.redirect(window)
    term.setCursorPos(window.getCursorPos())
    term.setCursorBlink(window.getCursorBlink())
    term.setTextColor(window.getTextColor())
    term.redirect(parentTerm)
end

function programWindow:closed() end

return programWindow
end
