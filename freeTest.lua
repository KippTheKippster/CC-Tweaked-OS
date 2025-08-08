local engine = require("core.engine")

local c = engine.root:addControl()
local c2 = engine.root:addControl()
print(c)
print(c:isValid())
--c:free()
print(c)
print(c:isValid())

function c2:woop()
    print(self:isValid(), "woop")
    print(self.text)
end

local a = c:createSignal()
c:connectSignal(a, c2.woop, c2)
c2:free()
print(c2)
c:emitSignal(a)
