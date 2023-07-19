objects = require("objects")
utils = require("utils")

function throwReadOnlyError(table, key, value)
    local s = debug.traceback()
    local _, c = s:gsub(":","")
    c = c / 2
    error("Attempting to assign read-only property '" .. key .. "' of " .. tostring(table) .. " with value '" .. tostring(value) .. "'.", 3)
    --error("as", 4)
end

function getsetIndex(table, key)
    --print("__index: " .. key .. " : " .. tostring(table))

    if key == "__getset" then
        return rawget(table, "__getset")
    end

    --print("table: " .. tostring(table))
    local gs = table.__getset
    --local metags = getmetatable(table).__getset
    --print(key)
    if key == "__index" or key == "__newindex" then
        return rawget(getmetatable(table), "__" .. key)
    end

    local methods = gs.methods[key]
    if methods and methods.get then
        return table.__getset.methods[key].get()
    end

    local old__index = gs.old__index
    if old__index then
        --print("Using old index function: " .. key)
        return old__index[key]
    end

    return nil
end

function getsetNewindex(table, key, value)
    --print("__newindex: " .. key .. " : " .. tostring(table))
    local gs = table.__getset
    
    if key == "__newindex" or key == "__index" then
        print("returning!!!!")
        print(value)
        rawset(table, key, value)
        return
    end

    --print(key)
    local methods = gs.methods[key]
    if methods then
        if methods.set then
            return methods.set(value)
        else
            throwReadOnlyError(table, key, value)
        end
    end

    local old__newindex = gs.old__newindex
    if old__newindex then
        --print("Using old newindex function: " .. key)
        old__newindex[key](table, key, value)
    end

    --print("Using rawset: " .. key)
    rawset(table, key, value)
end

function getsetInit(table)
    --if rawget(table, __getset) then print("table is already ready") return end
    if table.__getset then
        print("table is already ready") 
        return 
    end
    
    local mt = getmetatable(table)

    local old__index
    local old__newindex

    if mt then
        old__index = mt.__index
        old__newindex = mt.__newindex
    else
        mt = {}
        setmetatable(table, mt);
    end

    --table.__index = table
    mt.__index = getsetIndex
    mt.__newindex = getsetNewindex

    local type = tostring(table)

    rawset(table, "__getset",
    {
        methods = {},
        old__index = old__index,
        old__newindex = oold_newindex,
        type = type
    })

    return table
end

function defineProperty(table, key, methods)
    getsetInit(table)
    --local value = table[key]
    table.__getset.methods[key] = methods
    --print("Table " .. tostring(table) .. " is defining " .. key)
    rawset(table, key, nil) --Remove the property variable from table 
    --table[key] = nil
    --getsetNewindex(table, key, value) --Call the new property set to set the 'private' variable --TODO CALLS WETHER OR NOT PROPERTY HAS A SET METHOD! 
end

function inheritGetset(table)
    --[[
    local mt = getmetatable(table)
    local old__index = mt.old__index
    local old__newindex = mt.old__newindex

    mt.__index = getsetindex
    mt.__newindex = getsetNewindex

    --mt.__getset.old__index = old__index
    --mt.__getset.old__newindex = old__newindex

    rawset(mt.__getset, "old__index", old__index)
    rawset(mt.__getset, "old__newindex", old__newindex)

    rawset(table, "__getset", mt.__getset)
    --rawset(mt, "__getset", nil)
    ]]--

    getmetatable(table).__index = nil
    getmetatable(table).__newindex = nil
    getmetatable(table).__getset = nil
    --getsetInit(table)
end

--------------------------------------------------------------------------------------------------------------------------------


function baller1()
    print("Baller 1")
end

function baller2()
    print("Baller 2")
end 


term.clear()

object = objects.new_object()   
object._x = 2

--[[
defineProperty(object, 'x', {
    get = function()
        print("getting x!") 
        return object._x 
    end,
    set = function(value)
        print("setting x!")
        object._x = value
    end
})
]]--

print("{")
utils.printTable((getmetatable(object)))
print("}")

o1 = object:new{}

--local mt = getmetatable(o1)
--rawset(mt, "__index", baller1)
print("{")
utils.printTable(((getmetatable(o1))))
print("}")

o2 = o1:new{}

--local mt = getmetatable(o2)
--rawset(mt, "__index", baller2)
print("{")
utils.printTable(((getmetatable(o2))))
print("}")










--[[
object.x = 9
print(object.x)
print("-------------------")

utils.printTable(object)

print("----Creating o1----")
o1 = object:new{}
inheritGetset(o1)
--print("------------")
--utils.printTable(object)
print("------------")
utils.printTable(o1)
print("------------")
print("\n\n\n")
print("------------")
utils.printTable(o1)
print("------------")
utils.printTable(getmetatable(o1))

print("------------")
print(o1.x)
object.x = 32
print(o1.x)

--print("---------oo1----------")
--oo1 = o1:new{}
--getsetInit(oo1)
--utils.printTable(getmetatable(getmetatable(oo1)))
--print(oo1.x)
--oo1.x = 2
]]--

return { defineProperty = defineProperty }