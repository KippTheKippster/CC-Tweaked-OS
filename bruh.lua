local objects = require(".core.objects")
local utils = require(".core.utils")

local object = objects.new_object()
object._globalX = 1
object:defineProperty('globalX', {
    get = function(table) return table._globalX end,
    set = function(table, value) 
        table._globalX = value 
    end 
})

object:defineSignal("start")
object.x = 2

function object:create()
    self:connectSignal("start", self, "onStart")
end

function object:onStart()
    print("Start: " .. self.x)
end



object:create()

o1 = object:new{}
o1.x = 32
o1:create()

object:callSignal("start")


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