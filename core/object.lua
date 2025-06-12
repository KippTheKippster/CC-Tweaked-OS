local path = ".core."
local utils = require(".core.utils")

local object = {}

--Get key from object
local function object__index(table, key)
    --print("INDEX: " .. tostring(table) .. " key: " .. key)
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

    local mt = table
    while true do
        mt = getmetatable(mt)
        if mt == nil then
            break
        end
        if rawget(mt, "base")[key] ~= nil then
            return rawget(mt, "base")[key]
        end
    end

    return nil
end

--Set key from object
local function object__newindex(table, key, value)
    --print("newINDEX: " .. tostring(table) .. " key: " .. key)
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

--Creates a new object, copying properties and signals to the new object
function object:new(o)
    local o = o or {}
    local mt = 
    { 
        base = self, 
        __index = object__index,    
        __newindex = object__newindex,
    }

    setmetatable(o, mt)   
    o.__properties = self.__properties or {} 
    --o.__signals = self.__signals or {}
    o.__signals = {}
    return o 
end

function object:remove()
    for k in pairs (self) do
        self [k] = nil
    end

    self = nil
end

--Defines a new property
function object:defineProperty(key, methods, redefine)
    if self.__properties[key] ~= nil and redefine ~= true then
        error("Attempting to define an already defined property: " .. key .. " " .. tostring(self) .. " . " .. tostring(redefine) , 2)
    end

    if key == nil then
        error("Attemting to define property with key nil " .. tostring(self), 2)
    end
    
    self.__properties[key] = methods
end

--Defines a new signal
function object:defineSignal(key)
    if self.__signals[key] ~= nil then
        error("Attempting to define an already defined signal: " .. key .. " " .. tostring(self), 2)
    end

    if key == nil then
        error("Attemting to define signal with key nil " .. tostring(self), 2)
    end
    
    self.__signals[key] = 
    {
        objects = {}
    }
end

--Connect a signal to method
function object:connectSignal(key, o, method)
    if self.__signals[key] == nil then
        error("Attempting to connect a signal that does not exist: " .. key .. " " .. tostring(self), 2)
    end
    
    local signal = self.__signals[key]
    local objects = signal.objects
    if objects[o] == nil then
        objects[o] = {}
    end
    if objects[o][key] == nil then
        objects[o][key] = {}
    end
    table.insert(objects[o][key], method)
    --table.insert(signal.methods, 
end

function object:emitSignal(key)
    local signal = self.__signals[key]
    if signal == nil then
        error("Attempting to emit a signal that does not exist: " .. key .. " " .. tostring(self), 2)
    end

    for object, signals in pairs(signal.objects) do
        for _, method in pairs(signals[key]) do
            object[method](object)
        end
    end
end

--Returns the base object
function object:base()
    --Double base since
    return getmetatable(getmetatable(self).base).base 
end

local function new_object()
    return object:new{}
end

local function getObject()
    return object
end

return object
