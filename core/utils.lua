local function contains(t, v)
    for _, x in pairs(t) do
        if v == x then
            return true
        end
    end
    return false
end

local function find(t, v)
    for i, o in ipairs(t) do
		if o == v then
			return i
		end
	end
    return nil
end

local function combine(first, second)
	for k,v in pairs(second) do
		table.insert(first, v)
	end
end

local function move(tb, object, position)
	for i = 1, #tb do
		if tb[i] == object then
			tb[i] = tb[i + position] --sets the current position to the object that is occupying the wanted position
			tb[i + position] = object --sets the wanted position to the wanted object
		end
	end
end

--[[
local function split(s, c)
    local strings = {}
    local start = 1
    for i = 1, #s do
        if s:sub(i, i) == c or i == #s then
            local str = s:sub(start, i)
			str = str:gsub(' ', '')
            table.insert(strings, str)
            start = i
        end
    end
    return strings
end
]]--
local function split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end


local function printTable(table, recursive, prefix)
	if table == nil then error("Atempting to print a nil value", 2) end
	if prefix == nil then prefix = "" end
	print(prefix .. "{")
	for k, v in pairs(table) do
		print(prefix .. tostring(k) .. " = " .. tostring(v))
		if recursive and type(v) == "table" then 
			printTable(v, prefix .. "   ")
		end
	end
	print(prefix .. "}")
end

local function clamp(value, min, max)
    if max == nil or min == nil then
        error("Attempting to clamp nil value", 2)
    end
    if value > max then
        return max
    elseif value < min then
        return min
    else
        return value
    end
end

local function getDir(value)
    value = clamp(value, -1, 1)
    return value
end

local function capitaliseFirst(text)
	return (text:gsub("^%l", string.upper))
end

local function push(table, object, dir)
	for i = 1, #table do
		if table[i] == object then
			if i + dir < 1 or i + dir > #table then return i end
			local o1 = table[i + dir]
			table[i] = o1
			table[i + dir] = object
			return i + dir
		end
	end

	return nil
end

local function pushUp(table, object)
	return push(table, object, -1)
end

local function pushDown(table, object)
	return push(table, object, 1)
end

local function pushTop(table, object)
	repeat until pushUp(table, object) == 1
end

local function pushBottom(table, object)
	repeat until pushDown(table, object) == #table
end

local function saveTable(tbl, file, compact, allowRepetitions)
    compact = compact or false
    allowRepetitions = allowRepetitions or true
    local f = fs.open(file, "w")
    if f == nil then return false end
    local data = textutils.serialize(tbl, {compact = compact, allow_repetitions  = allowRepetitions })
    f.write(data)
    f.close()
    return true
end

local function loadTable(file)
    local f = fs.open(file, "r")
    if f == nil then return nil end
    local data = f.readAll()
    f.close()
    return textutils.unserialise(data)
end

---@class Utils
local Utils = {
	contains = contains,
    find = find,
	split = split,
	combine = combine,
	printTable = printTable,
	clamp = clamp,
	getDir = getDir,
	capitaliseFirst = capitaliseFirst,
	move = move,
	pushUp = pushUp,
	pushDown = pushDown,
	pushTop = pushTop,
	pushBottom = pushBottom,
	saveTable = saveTable,
	loadTable = loadTable
}

---@type Utils
return Utils