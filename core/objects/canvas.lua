local path = ".core."
local active = require(path .. "actives").new_active()
local canvas = active:new{}

function canvas:draw() end
function canvas:add()
    table.insert(canvases, self)  
    active.add(self) --super
end

return canvas