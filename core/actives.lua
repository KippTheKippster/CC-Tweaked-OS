local path = ".core."

objects = require(path .. "objects")
active = objects.new_object()
actives = {}
active.name = 'active'

function active:add()
    table.insert(actives, self) 
    self:ready()
end

function active:ready() end
function active:update() end

function process()
    for i = 1, #actives do
        local a = actives[i]
        a:update() 
    end  
end

function new_active()
    return active:new()
end

function get_list()
    return actives
end

return {
        new_active = new_active,
        active = active,
        process = process,
        get_list = get_list
    }
