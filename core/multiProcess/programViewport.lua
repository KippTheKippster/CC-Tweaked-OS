-- Extends control, draws the inbuilt cc-tweaked window object on to a control object.

return function(control, multiProgram)
    local programViewport = control:new{}
    programViewport.rendering = false
    programViewport.style.backgroundColor = colors.red
    programViewport.mouseIgnore = false
    programViewport.program = nil
    programViewport.parentTerm = nil
    
    function programViewport:draw()
        if self.program == nil then return end
        self:updateWindow()
    end

    function programViewport:launchProgram(parentTerm, programPath, ...)
        self.parentTerm = parentTerm
        self.program = multiProgram.launchProgram(parentTerm, programPath, self.globalX + 1, self.globalY + 1, self.w, self.h, ...)
        --self:redraw()
        --term.redirect(self.program.window) -- If term isn't redirected this way then if file explorer creates a window the windows term will be incorrect, why?
        --term.redirect(self.parentTerm)
    end

    function programViewport:endProcess()
        multiProgram.endProcess(self.program)
    end

    function programViewport:unhandledEvent(event, data)
        if self.program == nil then return end
        if event == "mouse_click" or event == "mouse_drag" or event == "mouse_up" then
            if self.parent:inFocus() == false then return end
            if event == "mouse_drag" and not self:inFocus() then return end

            term.redirect(self.program.window)

            local button, x, y = data[2], data[3], data[4]
            local offsetX, offsetY = self.program.window.getPosition()
            
            multiProgram.resumeProcess(self.program, event, button, x - offsetX + 1, y - offsetY + 1)
        elseif event == 'key' or event == 'key_up' or event == "char" then
            if self.parent:inFocus()  == false then return end
            term.redirect(self.program.window)
            
            multiProgram.resumeProcess(self.program, event, table.unpack(data, 2, #data))
        else
            term.redirect(self.program.window)
            
            multiProgram.resumeProcess(self.program, event, table.unpack(data, 2, #data))
        end

        term.redirect(self.parentTerm)
    end
    
    function programViewport:updateWindow()
        if self.program == nil then return end
        if self.visible == false then 
            self.program.window.setVisible(false)
            return 
        end

        self.program.window.reposition(self.globalX + 1, self.globalY + 1, self.w, self.h) --, self.program.window)
        multiProgram.resumeProcess(self.program, "term_resize")

        self.program.window.setVisible(true)
        if self.parent:inFocus() == false then -- This makes it so that only the focused viewport is constantly drawn (unfocused windows have to wait for next redraw)
            self.program.window.setVisible(false)
        end
        term.redirect(self.parentTerm)
    end

    return programViewport
end