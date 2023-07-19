local engine = require(".core.engine")

term.clear()

local b = engine:addButton()

function b:ready()
    print("ASD")
end

function b:pressed()
    print("DAUSIOJHDIOASi")
    self:remove()
end

local c = engine:addButton()

c.x = 8

engine:start()
