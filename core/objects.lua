local path = ".core."

utils = require(path .. "utils")

object = {}

function object:new(o)
    local o = o or {}
    mt = 
    { 
        base = self, 
        __index = object__index,
        __newindex = object__newindex,
    }

    setmetatable(o, mt)   
    o.__properties = self.__properties or {} 
    return o 
end

function object:defineProperty(key, methods)
    if self.__properties[key] ~= nil then
        error("Attempting to define an already defined property: " .. key .. " " .. tostring(self), 2)
    end

    if key == nil then
        error("Attemting to define propert with key nil " .. tostring(self), 2)
    end
    
    self.__properties[key] = methods
end

function object:base()
    --Double base since
    return getmetatable(getmetatable(self).base).base 
end

function object__index(table, key)
    local __properties = rawget(table, "__properties")
    if __properties ~= nil and __properties[key] ~= nil then
        if table.__properties[key].get == nil then
            error("Attempting to read property with missing get function: " .. key .. " " .. tostring(table))
        end

        return table.__properties[key].get(table)
    end 

    if rawget(table, key) ~= nil then
        return rawget(table, key)
    end

    local mt = getmetatable(table)
    if rawget(mt, "base")[key] ~= nil then
        return rawget(mt, "base")[key]
    end

    return nil
end

function object__newindex(table, key, value)
    --print("object_newindex: " .. key .. " = " .. tostring(value) .. " " .. tostring(table))

    local __properties = rawget(table, "__properties")
    if __properties ~= nil and __properties[key] ~= nil  then
        if table.__properties[key].set == nil then
            error("Attempting to assign read-only property: " .. key .. " " .. tostring(table) .. " with value " .. tostring(value) .. ".", 2)
        end
        table.__properties[key].set(table, value)
        return
    end 

    rawset(table, key, value)
end

function new_object()
    return object:new{}
end

function getObject()
    return object
end

return { 
    new_object = new_object, 
    getObject = getObject
}
