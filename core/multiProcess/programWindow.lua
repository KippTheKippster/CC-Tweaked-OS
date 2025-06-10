-- Extends windowControl, attaches a programViewport to a window.

return function(windowControl, programViewport)
local programWindow = windowControl:new{}
programWindow.programViewport = nil
programWindow.minimizeButton = nil
programWindow.focusedStyle = nil
programWindow.unfocusedStyle = nil

function programWindow:ready()
    --self:base().ready(self)
    windowControl.ready(self)

    self.minimizeButton = self:addButton()
    self.minimizeButton.w = 1
    self.minimizeButton.h = 1
    self.minimizeButton.text = "-"

    self.minimizeButton.pressed = function(o)
        self.visible = false
    end

    self.exitButton.pressed = function(o)
        self:close()
    end


    self.scaleButton.up = function(o)
        o.parent:redraw()
        self.programViewport:updateWindow() --TODO FIX!!!
    end
end


function programWindow:close()
    self.programViewport:endProcess()
    self:remove()
    self:closed()
end


function programWindow:render()
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
    self.programViewport.click = function(o)
        o.parent:toFront()
    end

    self.programViewport.focusChanged = function(o)
        o.parent:updateStyle()
    end
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
end

function programWindow:focusChanged()
    self:updateStyle()
end

function programWindow:updateStyle()
    if self:inFocus() then -- or (self.programViewport ~= nil and self.programViewport:inFocus()) then
        self.style = self.focusedStyle
    else
        self.style = self.unfocusedStyle
    end
end

function programWindow:closed() end

return programWindow
end
