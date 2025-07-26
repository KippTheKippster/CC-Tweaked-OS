-- Extends control, draws the inbuilt cc-tweaked window object on to a control object.

return function(control, multiProgram, input)
    local programViewport = control:new{}
    programViewport.rendering = false
    programViewport.mouseIgnore = false
    programViewport.program = nil
    programViewport.parentTerm = nil
    programViewport.terminated = false
    programViewport.skipEvent = false
    
    function programViewport:draw()
        if self.program == nil then return end
        self:updateWindow()
    end

    function programViewport:visibilityChanged()
        if self:isVisible() == false then
            self:updateWindow()
        end
    end

    function programViewport:launchProgram(parentTerm, programPath, extraEnv, ...)
        self.parentTerm = parentTerm
        self.program = multiProgram.launchProgram(parentTerm, programPath, extraEnv, function (data)
            return self:unhandledEvent(data)
        end, self.globalX + 1, self.globalY + 1, self.w, self.h, ...)
    end

    function programViewport:endProcess()
        multiProgram.endProcess(self.program)
    end

    local function resumeProcess(viewport, data)
        return table.pack(multiProgram.resumeProcess(viewport.program, data))
    end

    function programViewport:unhandledEvent(data)
        if self.program == nil then return end
        if self.skipEvent == true then
            self.skipEvent = false
            return
        end

        local event = data[1]
        local result = nil

        if self.terminated == true then
            term.setTextColor(colors.white)
            if event == "key" and self.parent:inFocus() then
                self.parent:close()
            end
            return true
        end

        if coroutine.status(self.program.co) == "dead" and self.terminated == false then
            term.redirect(self.program.window)
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
            print("Press any key to close window.")

            self.terminated = true
            --self:endProcess()

            term.redirect(self.parentTerm)
            return true
        end

        if event == "mouse_click" or event == "mouse_drag" or event == "mouse_up" or event == "mouse_scroll" then
            if self.parent:inFocus() == false then return end
            if input.isInputConsumed() == true then return end

            local button, x, y = data[2], data[3], data[4]
            local offsetX, offsetY = self.program.window.getPosition()
            
            result = resumeProcess(self, table.pack(event, button, x - offsetX + 1, y - offsetY + 1))

        elseif event == 'key' or event == 'key_up' or event == "char" then
            if self.parent:inFocus()  == false then return end
            if input.isInputConsumed() == true then return end

            result = resumeProcess(self, data)
        else
            result = resumeProcess(self, data)
        end

        return table.unpack(result)
    end

    function programViewport:updateWindow()
        if self.program == nil then return end
        if self:isVisible() == false then
            self.program.window.setVisible(false)
            return
        end

        term.redirect(self.program.window)
        self.program.window.reposition(self.globalX + 1, self.globalY + 1, self.w, self.h) --, self.program.window)
        multiProgram.resumeProcess(self.program, {"term_resize"})

        self.program.window.setVisible(true)
        if self.parent:inFocus() == false then -- This makes it so that only the focused viewport is constantly drawn (unfocused windows have to wait for next redraw)
            self.program.window.setVisible(false)
        end
        term.redirect(self.parentTerm)
    end

    return programViewport
end