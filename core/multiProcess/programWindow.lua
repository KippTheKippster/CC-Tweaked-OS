return function(windowControl, programViewport)
local programWindow = windowControl:new{}
programWindow.programViewport = nil

function programWindow:ready()
    --self:base().ready(self)
    windowControl.ready(self)
    self.exitButton.pressed = function(o)
        self.programViewport:endProcess()
        o.parent:remove()
    end

    self.scaleButton.up = function(o)
        o.parent:redraw()
        o.parent.programViewport:updateWindow() --TODO FIX!!!
    end
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
    self.programViewport.w = self.w
    self.programViewport.h = self.h - 1
end
return programWindow
end
