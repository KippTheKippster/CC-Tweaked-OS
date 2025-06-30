return function(control, editStyle, editFocusStyle, input)
local lineEdit = control:new()
lineEdit.normalStyle = editStyle
lineEdit.focusStyle = editFocusStyle

lineEdit.h = 1
lineEdit.w = 12
lineEdit.text = ""
lineEdit.cursorOffset = 0
lineEdit._trueText = ""
control:defineProperty('trueText', {
    get = function(o) return o._trueText end,
    set = function(o, value) 
        local same = o._trueText == value
        o._trueText = value 
        if same == false then
            o:trueTextChanged()
        end
    end 
})
lineEdit.clipText = true
--lineEdit.offsetTextX = 0
lineEdit.lineScroll = 0

function lineEdit:ready()
    input.addCharListener(self)
	input.addKeyListener(self)
    --self.cursor = self:addControl()
    --self.cursor.w = 1
    --self.cursor.h = 1
    --self.cursor.text = "a"
    --self.cursor.visible = false
    self.style = self.normalStyle
    self:redraw()
end


function lineEdit:render()
    control.render(self)
    if self.focus then
        --[[
        term.setCursorPos(self.globalX + #self.text + self.cursorOffset + 1, self.globalY + 1)
        term.setBackgroundColor(self.style.textColor)
        term.setTextColor(self.style.backgroundColor)
        local char = self.trueText:sub(
            #self.text + self.cursorOffset + 1,
            #self.text + self.cursorOffset + 1
        )
        if char == "" then 
            char = " "
        end
        term.write(char)]]--
    end
end

function lineEdit:updateCursor()
    term.setCursorBlink(true)   
    term.setCursorPos(self.globalX + #self.text + self.cursorOffset + 1, self.globalY + 1)
    term.setTextColor(self.style.textColor)
    term.setBackgroundColor(self.style.backgroundColor)
end

function lineEdit:trueTextChanged()
	local w = #self.trueText - self.w + 1
	w = math.max(0, w)
	self.text = self.trueText:sub(w + 1, #self.trueText)
    self:redraw()
end

function lineEdit:char(char)
    if true then return end
    if self.focus == false then return end
    self.trueText = (
        self.trueText:sub(0, #self.trueText + self.cursorOffset) .. 
        char ..
        self.trueText:sub(#self.trueText + self.cursorOffset + 1)
    )
    return
 
end

lineEdit.co = nil

function lineEdit:key(key) 
    if true then return end
    if self.focus == false then return end
	if key == 259 then --Backspace
        if input.isKey(keys.leftCtrl) then
            self.trueText = self.trueText:sub(#self.trueText + self.cursorOffset + 1)
        else
		    self.trueText = (
                self.trueText:sub(0, #self.trueText + self.cursorOffset - 1) .. 
                self.trueText:sub(#self.trueText + self.cursorOffset + 1)
            )
        end
    elseif key == keys.enter then
        self:releaseFocus()
	elseif key == 263 then --Left
		self.cursorOffset = self.cursorOffset - 1
        if self.cursorOffset < -#self.text then 
            self.cursorOffset = -#self.text
        end
        self:redraw()
	elseif key == 262 then --Right
		self.cursorOffset = self.cursorOffset + 1
        if self.cursorOffset > 0 then
            self.cursorOffset = 0
        end
        --self.cursorOffset = min(self.cursorOffset, 0)
        self:redraw()
	end
end

function lineEdit:focusChanged()
    if self.focus then
        self.style = self.focusStyle
        self:grabCursorControl()
        --self.co = coroutine.create(read)
        term.setTextColour(colors.white)
        parallel.waitForAny(function ()
            self.trueText = read()
        end, function ()
            while true do
                sleep(1.0)
            end
        end)
    else
        term.setCursorBlink(false)
        self.style = self.normalStyle
        self:textSubmitted()
        self:releaseCursorControl()
    end
end



function lineEdit:textSubmitted() end

return lineEdit
end