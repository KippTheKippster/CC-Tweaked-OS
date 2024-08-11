local actives = require(".core.actives")
local utils = require(".core.utils")

local a = actives.new_active()
print(a)

function a:ready()
    print("WAAAAAAY")
end

a:add()

local a1 = a:new{}

a1:add()


--a1:add()

--object:callSignal("start")

--[[
object:defineSignal("test")

local o1 = object:new{}
local ba = o1:new{}

print("o1: " .. tostring(o1))
print("object: " .. tostring(object))
object:connectSignal("test", o1, "onSignal")
object:connectSignal("test", o1, "onSignala")
object:connectSignal("test", o1, "onSignalb")
object:connectSignal("test", ba, "onSignal")
function o1:onSignal()
    print("Eh, what the flip?")
end
function o1:onSignala()
    print("Eh, what the florp?")
end
function o1:onSignalb()
    print("Eh, what the frick?")
end
function ba:onSignal()
    print("BALLLER")
end
object:callSignal("test")
]]--
