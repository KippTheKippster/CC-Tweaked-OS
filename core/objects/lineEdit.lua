return function(control, editStyle, editFocusStyle)
local lineEdit = control:new()
lineEdit.style = editStyle
lineEdit.normalStyle = editStyle
lineEdit.focusStyle = editFocusStyle
lineEdit.h = 1
lineEdit.w = 12
lineEdit.text = ""
lineEdit.cursorOffset = 0
lineEdit._trueText = ""
control:defineProperty('trueText', {
    get = function(table) return table._trueText end,
    set = function(table, value) 
        local same = table._trueText == value
        table._trueText = value 
        if same == false then
            table:trueTextChanged()
        end
    end 
})
lineEdit.clipText = true
--lineEdit.offsetTextX = 0
lineEdit.cursora = nil

function lineEdit:ready()
    input.addCharListener(self)
	input.addKeyListener(self)
    self.cursor = self:addControl()
    self.cursor.w = 1
    self.cursor.h = 1
    self.cursor.text = "a"
    self.cursor.visible = false
    self:redraw()
end

--[[
function lineEdit:draw()
	if self.visible == false or self.rendering == false then
        return
    end

	self:drawPanel()
	self:write()
end
]]--

function lineEdit:trueTextChanged()
	local w = #self.trueText - self.w + 1
	w = math.max(0, w)
	self.text = self.trueText:sub(w + 1, #self.trueText)
end

function lineEdit:char(char)
    if self.focus == false then return end
	self.trueText = self.trueText .. char
end

function lineEdit:key(key) 
    if self.focus == false then return end
	if key == 259 then --Backspace
		self.trueText = self.trueText:sub(0, #self.trueText - 1)
	elseif key == 263 then --Left
		self.cursorOffset = self.cursorOffset - 1
	elseif key == 262 then --Right
		self.cursorOffset = self.cursorOffset + 1
	end
end

function lineEdit:focusChanged()
    if self.focus then
        self.style = self.focusStyle
    else
        self.style = self.normalStyle
    end
end

return lineEdit
end