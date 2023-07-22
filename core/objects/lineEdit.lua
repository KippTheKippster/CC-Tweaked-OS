return function(control, editStyle, editFocusStyle)
local lineEdit = control:new()
lineEdit.style = editStyle
lineEdit.normalStyle = editStyle
lineEdit.focusStyle = editFocusStyle
lineEdit.h = 0
lineEdit.w = 12
lineEdit.clipText = true
lineEdit.offsetTextX = 0
lineEdit.cursor = 1

function lineEdit:ready()
    input.addCharListener(self)
	input.addKeyListener(self)
	self.cursor = #self.text - 1
end

function lineEdit:char(char)
    if self.focus == true then
        self.text = self.text .. char
		self.cursor = math.min(self.cursor + 1, self.w - 1)
		self.offsetTextX = #self.text - self.cursor - 1
		print(self.cursor .. " : " .. #self.text .. " : " ..  self.cursor - #self.text)
		 
    end
end

function lineEdit:key(key) 
	if self.focus == true then
		
	end
end

function lineEdit:draw()
	--self:base():draw()
	control.draw(self)
	if self.focus == true then
		local x, y = self:getTextPosition()
		term.setCursorPos(x + self.cursor + 1, y)
		term.setBackgroundColor(colors.white)
		local t = self.text:sub(self.cursor + self.offsetTextX + 2, self.cursor + self.offsetTextX + 2)
		local b = string.byte(t)
		--print(b)
		if b == nil then
			t = " " 
		end
		term.write(t)
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