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
    print("__index: " .. key .. " : " .. tostring(table))
    --print("table: " .. tostring(table))
    local gs = table.__getset
    --local metags = getmetatable(table).__getset
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
    print("__newindex: " .. key .. " : " .. tostring(table))
    local gs = table.__getset
    
    if key == "__newindex" or key == "__index" then
        print(value)
    end

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

--------------------------------------------------------------------------------------------------------------------------------

term.clear()

object = objects.getObject()   
object._x = 2

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

object.x = 9
print(object.x)
print("-------------------")

utils.printTable(object)

print("----Creating o1----")
o1 = object:new{}
--rawset(o1, "__getset", rawget(getmetatable(o1), "__getset"))
--rawset(getmetatable(o1), "__getset", nil)
--getsetInit(o1)
print("--------------")
utils.printTable(o1)
print("--------------")
print(o1.x)
o1.x = 322
print(object.x)
print(o1._x)
print(object._x)

--print("---------oo1----------")
--oo1 = o1:new{}
--getsetInit(oo1)
--utils.printTable(getmetatable(getmetatable(oo1)))
--print(oo1.x)
--oo1.x = 2

return { defineProperty = defineProperty }