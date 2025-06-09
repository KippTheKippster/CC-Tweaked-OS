local path = ".core."

local objects = require(path .. "objects")
local active = objects.new_object()
local actives = {}
active.name = 'active'

--active:defineSignal("readyEvent")
--active:connectSignal("readyEvent", active, "ready")

function active:add()
    table.insert(actives, self)
    self:defineSignal("readyEvent") 
    self:connectSignal("readyEvent", self, "ready")
    self:emitSignal("readyEvent")
    --self:ready()
end

function active:remove()
    for i = 1, #actives do
		if actives[i] == self then
            table.remove(actives, i)
		end
	end
    
    --utils.printTable(getmetatable(self).base)
    --print(getmetatable(self).base)

    --rawset(self, nil)
    --rawset(self, "self", nil)
end

function active:ready() end
function active:update() end

local function process()
    for i = 1, #actives do
        local a = actives[i]
        a:update() 
    end  
end

local function new_active()
    return active:new()
end

local function get_list()
    return actives
end

return {
        new_active = new_active,
        active = active,
        process = process,
        get_list = get_list
    }
