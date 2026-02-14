---@return LineEdit
return function(control, editStyle, editFocusStyle, ghostStyle, input)
---@class LineEdit : Control
local LineEdit = control:newClass()
LineEdit.__type = "LineEdit"

LineEdit.normalStyle = editStyle
LineEdit.focusStyle = editFocusStyle
LineEdit.ghostStyle = ghostStyle

LineEdit.h = 1
LineEdit.w = 12
LineEdit.text = ""
LineEdit.cursorOffset = 0
LineEdit._trueText = ""
LineEdit.inheritStyle = false
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
LineEdit.clipText = true
LineEdit.lineScroll = 0
---@type Style
LineEdit.ghostStyle = nil
LineEdit.fitToText = false

function LineEdit:ready()
    input.addCharListener(self)
	input.addKeyListener(self)
    input.addRawEventListener(self)
    self.style = self.normalStyle
end

function LineEdit:queueFree()
    input.removeRawEventListener(self)
    control.queueFree(self)
end


function LineEdit:updateCursor()
    term.setCursorBlink(true)
    term.setCursorPos(self.globalX + #self.text + self.cursorOffset + 1 + self.marginL, self.globalY + 1)
    term.setTextColor(self.style.textColor)
    term.setBackgroundColor(self.style.backgroundColor)
end

function LineEdit:treeEntered()
    self.style = self.normalStyle
end

function LineEdit:trueTextChanged()
	local w = #self.trueText - self.w + self.marginL + 1
	w = math.max(0, w)
	self.text = self.trueText:sub(w + 1, #self.trueText)
    self:queueDraw()
end

function LineEdit:addText(text, offset)
    self.trueText = (
        self.trueText:sub(0, #self.trueText + offset) ..
        text ..
        self.trueText:sub(#self.trueText + offset + 1)
    )
end

function LineEdit:char(char)
    if self.focus == false then return end
    self:addText(char, self.cursorOffset)
end

LineEdit.co = nil

function LineEdit:key(key)
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
        self:queueDraw()
	elseif key == 262 then --Right
		self.cursorOffset = self.cursorOffset + 1
        if self.cursorOffset > 0 then
            self.cursorOffset = 0
        end
        self:queueDraw()
	end
end

function LineEdit:rawEvent(data)
    if not self:inFocus() then
        return
    end

    if data[1] == "paste" then
        self:addText(data[2], self.cursorOffset)
    end
end

function LineEdit:focusChanged()
    if self.focus then
        self.style = self.focusStyle
        self:grabCursorControl()
    else
        term.setCursorBlink(false)
        self.style = self.normalStyle
        self:textSubmitted()
        self:releaseCursorControl()
    end
end



function LineEdit:textSubmitted() end

return LineEdit
end