return function(control)
local icon = control:new{}
icon.type = "Icon"

icon._texture = nil
icon._centered = false
icon.offsetX = 0
icon.offsetY = 0

icon:defineProperty('texture', {
    get = function(o) return o._texture end,
    set = function(o, value)
        local same = o._texture == value
        o._texture = value
        if same == false then
            o.w, o.h = o:getTextureSize()
            o:redraw()
        end
    end
})

icon:defineProperty('centered', {
    get = function(o) return o._centered end,
    set = function(o, value)
        local same = o._centered == value
        o._centered = value
        if same == false then
            o:centerPosition()
        end
    end
})

function icon:treeEntered()
    if self.centered == true then
        self:centerPosition()
    end
end

function icon:render()
    if self.texture == nil then return end
	paintutils.drawImage(self.texture, self.globalX + 1 + self.offsetX, self.globalY + 1 + self.offsetY)
end

function icon:getTextureSize()
    if self.texture == nil then
        return 0, 0
    end
	local w = 0
	local h = #self.texture
	for i = 1, #self.texture do
		w = math.max(w, #self.texture[i])
	end

	return w, h
end

function icon:centerPosition()
    if self.parent == nil then return end
    local pW, pH = self.parent.w, self.parent.h
    self.x = (pW - self.w) / 2.0 + self.offsetX
    self.y = (pH - self.h) / 2.0 + self.offsetY
end

function icon:transformChanged()
    if self.centered  == true then
        self:centerPosition()
    end
end

return icon
end