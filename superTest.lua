objects = require("objects")

object = objects.new_object()

super = object:new{}
super.a = 1
--super.b = function return self.a end

function super:func()
    print("super " .. self.a)
end

sub = super:new{}
sub.a = 22
sub.t = nil

function sub:func()
    self.t = {} 
    --self.t.__index = self.t
    self.t[#self.t + 1] = "aa"
    --print("sub " .. textutils.serialise(self.t))
    super.func(self)
end

function sub:func2()
    self.t[#self.t + 1] = "bb"
    print(textutils.serialise(self.t))
end

s1 = sub:new{}
s2 = sub:new{}

--s1:func()
--s2:func()
--s1:func2()
--s2:func2(


--[[
q = {}
q.mt = {}

setmetatable(q, q.mt) 

q.mt.__index = function(table, key)
    print("baller")
    return 2
end

print(mt)
print(q)

print(textutils.serialise(q))
]]--
getsetIndex = function(table, key)
    print("baller")
    if table.__getset.methods[key] then
        return table.__getset.methods[key].get()
    end
end

getsetNewindex = function(table, key)
    print("baller new")
    if table.__getset.methods[key] then
        return table.__getset.methods[key].set()
    end
end

function getsetInit(table)
    if table.__getset then return end

    local mt = {}
    setmetatable(table, mt);
    rawset(table, "__getset",
    {
        methods = {}
    })
    mt.__index = getsetIndex
    return table
end

function defineProperty(table, key, methods)
    getsetInit(table)
    table.__getset.methods[key] = methods
    --rawset(table, key, nil)
end

a = {}
a._x = 0
defineProperty(a, 'x', { 
    get = function() 
        return a._x
    end,
    set = function()
    
    end})

print(a.x)