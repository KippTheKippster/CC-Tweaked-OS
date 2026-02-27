---@class Object
local Object = {}
Object.__name = ""
Object.__type = "Object"
Object.__properties = {}
Object.__connections = {}

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
        local raw = rawget(mt, "__base")[key]
        if raw ~= nil then
            return raw
        end
        mt = getmetatable(mt)
    end

    return nil
end

--Set key from object
local function object__newindex(o, key, value)
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
        local raw = rawget(mt, "__base")[key]
        if raw ~= nil then
            return raw
        end
        mt = getmetatable(mt)
    end
end

local function properties__newindex(o, key, value)
    rawset(o, key, value)
end

local function free__index(o, key)
    if key == "isValid" then
        return function ()
            return false
        end
    elseif key == "__type" then
        return rawget(o, "__type")
    elseif key == "__name" then
        return rawget(o, "__name")
    end

    error("\nAttempting to access value from the previously freed object: " .. tostring(o), 2)
end

local function free__newindex(o, key, value)
    error("Attempting to assign value to the previously freed object: " .. tostring(o), 2)
end

--Creates a new object, copying properties and signals to the new object
---@return table
function Object:new(...)
    local o = self:newClass()
    o:init(...)
    return o
end

function Object:newClass()
    local o = {}
    local mt = {
        __base = self,
        __index = object__index,
        __newindex = object__newindex,
    }

    setmetatable(o, mt)

    o.__properties = {}
    mt = {
        __base = self.__properties,
        __index = properties__index,
        __newindex = properties__newindex,
    }

    setmetatable(o.__properties, mt)

    o.__connections = {}
    return o
end

function Object:init(...) end

function Object:remove()
    for k in pairs (self) do
        self[k] = nil
    end

    self = nil
end

function Object:isValid()
    return true
end

function Object:free()
    for k, v in pairs(self.__connections) do
        self:disconnectSignal(k, v.method)
    end

    local __type = self.__type
    local __name = self.__name
    for k in pairs (self) do
        self[k] = nil
    end
    self.__type = __type
    self.__name = __name

    local mt = {
        __index = free__index,
        __newindex = free__newindex
    }

    setmetatable(self, mt)
end

---Defines a new get set property
---@param key string
---@param methods table
---@param redefine boolean?
function Object:defineProperty(key, methods, redefine)
    if self.__properties[key] ~= nil and redefine ~= true then
        error("Attempting to define an already defined property: " .. key .. " " .. tostring(self) .. " . " .. tostring(redefine) , 2)
    end

    if key == nil then
        error("Attemting to define property with key nil " .. tostring(self), 2)
    end

    self.__properties[key] = methods
end

---@return Signal
function Object:createSignal()
    ---@class Signal
    local signal = {}
    return signal
end

---@param signal Signal
---@param method function
---@param ... any
function Object:connectSignal(signal, method, ...)
    if self.__connections[signal] == nil then
        self.__connections[signal] = {}
    end
    local connection = {
        method = method,
        binds = table.pack(...)
    }
    table.insert(self.__connections[signal], connection)
end

---@param signal Signal
---@param method function
function Object:disconnectSignal(signal, method)
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

---@param signal Signal
---@param ... any
function Object:emitSignal(signal, ...)
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

---@return Object
return Object
