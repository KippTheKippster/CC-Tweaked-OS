-- Extends control, draws the inbuilt cc-tweaked window object on to a control object.

return function(control, multiProgram, input)
    local programViewport = control:new{}
    programViewport.type = "ProgramViewport"

    programViewport.rendering = false
    programViewport.mouseIgnore = false
    programViewport.program = nil
    programViewport.parentTerm = nil
    programViewport.terminated = false
    programViewport.skipEvent = false
    programViewport.oldW = 0
    programViewport.oldH = 0
    programViewport.queueResizeEvent = false
    
    function programViewport:treeEntered()
        self.oldW = self.w
        self.oldH = self.h
    end

    function programViewport:draw()
        if self.program == nil then return end
        self:updateWindow()
    end

    function programViewport:visibilityChanged()
        if self:isVisible() == false then
            self:updateWindow()
        end
    end

    function programViewport:transformChanged()
        if self.oldH ~= self.h or self.oldW ~= self.w then
            self.queueResizeEvent = true
        end
        self.oldW, self.oldH = self.w, self.h
    end

    function programViewport:launchProgram(parentTerm, programPath, extraEnv, ...)
        self.parentTerm = parentTerm
        self.program = multiProgram.launchProgram(parentTerm, programPath, extraEnv, function (data)
            --if self:isValid() == false then return nil end
            return self:unhandledEvent(data)
        end, self.globalX + 1, self.globalY + 1, self.w, self.h, ...)
    end

    function programViewport:endProcess()
        --term.redirect(self.program.co.window)
        multiProgram.endProcess(self.program)
        --term.redirect(self.parentTerm)
    end

    local function drawChildren(viewport)
        for i = 1, #viewport.children do
            viewport.children[i]:draw()
        end
    end

    local function resumeProcess(viewport, data)
        local result = table.pack(multiProgram.resumeProcess(viewport.program, data))
        --drawChildren(viewport)
        return result
    end

    function programViewport:unhandledEvent(data)
        if self.program == nil then return end

        local event = data[1]
        local result = nil

        if self.skipEvent == true and event ~= "timer" then -- TODO add a more robust way of skipping input
            self.skipEvent = false
            return true
        end

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

            term.redirect(self.parentTerm)
            return true
        end

        if event == "mouse_click" or event == "mouse_drag" or event == "mouse_up" then
            if self.parent:inFocus() == false then return end
            if input.isInputConsumed() == true then return end

            local button, x, y = data[2], data[3], data[4]
            local offsetX, offsetY = self.program.window.getPosition()

            result = resumeProcess(self, table.pack(event, button, x - offsetX + 1, y - offsetY + 1))
        elseif event == "mouse_scroll" then
            if input.isInputConsumed() == true then return end

            local button, x, y = data[2], data[3], data[4]
            local offsetX, offsetY = self.program.window.getPosition()

            result = resumeProcess(self, table.pack(event, button, x - offsetX + 1, y - offsetY + 1))
            self:redraw()
        elseif event == 'key' or event == 'key_up' or event == "char" then
            if self.parent:inFocus()  == false then return end
            if input.isInputConsumed() == true then return end

            result = resumeProcess(self, data)
        else
            result = resumeProcess(self, data)
        end

        local ok, err = result[1], result[2]
        if ok == false then
            term.redirect(self.program.window)
            term.setCursorPos(1, 1)
            printError("Viewport Result: ", err)
            __Global.log("Viewport Error: ", err)
            term.redirect(self.parentTerm)
            return true
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
        if self.queueResizeEvent == true then
            multiProgram.resumeProcess(self.program, {"term_resize"})
            self.queueResizeEvent = false
        end

        self.program.window.setVisible(true)
        drawChildren(self)

        if self.parent:inFocus() == false then -- This makes it so that only the focused viewport is constantly drawn (unfocused windows have to wait for next redraw)
            self.program.window.setVisible(false)
        end

        term.redirect(self.parentTerm)
    end

    return programViewport
end