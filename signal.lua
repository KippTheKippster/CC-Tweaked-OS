local path = ".core."
local object = require(path .. "object")

local a = object:new{}
a.signal = a:createSignal()

local b = object:new{}
b.a = 5
function b:tested(e)
    print("woop")
    print(self.a)
    print(e)
end

local c = a:new{}


a:connectSignal(a.signal, b.tested, b)

a:emitSignal(a.signal, "EEEEEee")
c:emitSignal(a.signal)
