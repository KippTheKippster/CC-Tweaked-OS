local path = ".core."
local utils = require(".core.utils")

local object = {}
object.__properties = {}

--Get key from object
local function object__index(o, key)
    local __properties = rawget(o, "__properties")
    if __properties ~= nil and __properties[key] ~= nil then
        if o.__properties[key].get == nil then
            error("Attempting to read property with missing get function: " .. key .. " " .. tostring(o))
        end

        return o.__properties[key].get(o)
    end

    if rawget(o, key) ~= nil then
        return rawget(o, key)
    end

    local mt = getmetatable(o)
    while mt ~= nil do
        local raw = rawget(mt, "base")[key]
        if raw ~= nil then
            return raw
        end
        mt = getmetatable(mt)
    end

    return nil
end

--Set key from object
local function object__newindex(o, key, value)
    --print("newINDEX: " .. tostring(table) .. " key: " .. key)
    local __properties = o.__properties--rawget(o, "__properties")
    if __properties ~= nil and __properties[key] ~= nil  then
        if o.__properties[key].set == nil then
            error("Attempting to assign read-only property: " .. key .. " " .. tostring(o) .. " with value " .. tostring(value) .. ".", 2)
        end
        o.__properties[key].set(o, value)
        return
    end

    rawset(o, key, value)
end

local function properties__index(o, key)
    local mt = getmetatable(o)
    while mt ~= nil do
        local raw = rawget(mt, "base")[key]
        if raw ~= nil then
            return raw
        end
        mt = getmetatable(mt)
    end
end

local function properties__newindex(o, key, value)
    rawset(o, key, value)
end

--Creates a new object, copying properties and signals to the new object
function object:new(o)
    o = o or {}
    local mt = {
        base = self,
        __index = object__index,
        __newindex = object__newindex,
    }

    setmetatable(o, mt)
    
    o.__properties = {}
    mt = {
        base = self.__properties,
        __index = properties__index,
        __newindex = properties__newindex,
    }

    setmetatable(o.__properties, mt)

    o.__connections = {}
    --o.__signals = {}
    return o
end

function object:remove()
    for k in pairs (self) do
        self[k] = nil
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

function object:createSignal()
    local signal = {}
    signal.connections = {}
    --[[
    signal.connect = function (signal, method, ...)
        local connection = {
            method = method,
            binds = table.pack(...)
        }
        table.insert(signal.connections, connection)
    end
    signal.emit = function (signal, ...)
        for i = 1, #signal.connections do
            local connection = signal.connections[i]
            connection.method(table.unpack(connection.binds), ...)
        end
    end
    ]]
    --table.insert(self.__signals)
    return signal
end

function object:connectSignal(signal, method, ...)
    if self.__connections[signal] == nil then
        self.__connections[signal] = {}
    end
    local connection = {
        method = method,
        binds = table.pack(...)
    }
    table.insert(self.__connections[signal], connection)
end

function object:disconnectSignal(signal, method)
    local connections = self.__connections[signal]
    if self.__connections[signal] == nil then 
        return
    end

    for i = 1, #connections do
        local connection = connections[i]
        if connection.method == method then
            self.__connections[signal][i] = nil
            return
        end
    end
end

function object:emitSignal(signal, ...)
    local connections = self.__connections[signal]
    if connections ~= nil then
        for i = 1, #connections do
            local connection = connections[i]
            local args = {}
            for j = 1, #connection.binds do
                table.insert(args, connection.binds[j])
            end
            local a = table.pack(...)
            for j = 1, #a do
                table.insert(args, a[j])
            end
            connections[i].method(table.unpack(args))
        end
    end
end

--Defines a new signal
--[[
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
]]--

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
