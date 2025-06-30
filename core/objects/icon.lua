return function(control)
local icon = control:new{}
icon._texture = nil -- = paintutils.loadImage("test.nfp")

icon:defineProperty('texture', {
    get = function(table) return table._texture end,
    set = function(table, value) 
        local same = table._texture == value
        table._texture = value 
        if same == false then
            table:redraw()
        end
    end 
})

function icon:render()
    if self.texture == nil then return end
	paintutils.drawImage(self.texture, self.globalX + 1, self.globalY + 1)
end

function icon:getSize()
	local w = 0
	local h = #self.texture
	for i = 1, #self.texture do
		w = math.max(w, #self.texture[i])
	end
	
	return w, h
end

return icon
end