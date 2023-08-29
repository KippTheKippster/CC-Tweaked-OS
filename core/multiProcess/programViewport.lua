return function(control, multiProgram, parentTerm)
    local programViewport = control:new{}
    programViewport.rendering = false
    programViewport.style.backgroundColor = colors.red
    programViewport.mouseIgnore = false
    programViewport.program = nil
    
    --function programViewport:ready()
    --    input.addMouseEventListener(self)
    --end
    
    --function programViewport:launchProgram(path, ...)
    --    self.program = multiProgram.launchProgram(path, self.globalX, self.globalY, self.w, self.h, ...)
    --    self:redraw()
    --end
    
    function programViewport:draw()      
        if self.program == nil then return end
        self:updateWindow()
        --self.program.window.redraw()
    end

    function programViewport:endProcess()
        multiProgram.endProcess(self.program)
    end
    
    function programViewport:sizeChanged()
        self.resize = true --???
    end

    function programViewport:unhandledEvent(event, data)
        if self.program == nil then return end
        if event == "mouse_click" or event == "mouse_drag" or event == "mouse_drag" or event == "mouse_up" then
            if self.parent:inFocus() == false then return end
            local button, x, y = data[2], data[3], data[4]
            local offsetX, offsetY = self.program.window.getPosition()
            multiProgram.resumeProcess(self.program, event, button, x - offsetX + 1, y - offsetY + 1)
        elseif event == 'key' or event == 'key_up' or event == "char" then
            if self.parent:inFocus()  == false then return end
            multiProgram.resumeProcess(self.program, event, table.unpack(data, 2, #data))
        else
            multiProgram.resumeProcess(self.program, event, table.unpack(data, 2, #data))
        end
    end
    
    function programViewport:updateWindow()
        if self.program == nil then return end
        term.redirect(self.program.window)
        self.program.window.reposition(self.globalX + 1, self.globalY + 1, self.w, self.h, parentTerm) --, self.program.window)
        multiProgram.resumeProcess(self.program, "term_resize")
        term.redirect(parentTerm)
    end
    return programViewport
end