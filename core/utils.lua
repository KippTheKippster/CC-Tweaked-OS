local function contains(t, v)
    for _, x in pairs(t) do
        if v == x then 
            return true
        end
    end
    return false
end

local function find(t, v)
    for i = 1, #t do
        if t[i] == v then
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

local function hasTag(data, tag)
	tags = data["tags"]
	if tags[tag] == true then
		return true
	else
		return false
	end
end

local function printTable(table, recursive, prefix)
	if table == nil then error("Atempting to print a nil value", 2) end
	if prefix == nil then prefix = "" end
	print(prefix .. "{")
	for k, v in pairs(table) do
		print(prefix .. tostring(k) .. " = " .. tostring(v))
		if recursive and type(v) == "table" then 
			--print(prefix .. "{")
			printTable(v, prefix .. "   ")
			--print(prefix .. "}")
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
    local value = clamp(value, -1, 1)
    --value = math.min(value + 0.5)
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

-- Salt Taken from https://github.com/VaiN474/salt/tree/master
local function saveTable(tbl,file,compressed)

    local f,err = io.open(file,"w")
    if err or f == nil then print(err) return end
    local indent = 1

    -- local functions to make things easier
    local function exportstring(s)
        s=string.format("%q",s)
        s=s:gsub("\\\n","\\n")
        s=s:gsub("\r","")
        s=s:gsub(string.char(26),"\"..string.char(26)..\"")
        return s
    end
    local function serialize(o)
        if type(o) == "number" then
            f:write(o)
        elseif type(o) == "boolean" then
            if o then f:write("true") else f:write("false") end
        elseif type(o) == "string" then
            f:write(exportstring(o))
        elseif type(o) == "table" then
            f:write("{" .. (compressed and "" or "\n"))
            indent = indent + 1
            local tab = ""
            for i=1,indent do tab = tab .. "    " end
            for k,v in pairs(o) do
                f:write((compressed and "" or tab) .. "[")
                serialize(k)
                f:write("]" .. (compressed and "=" or " = "))
                serialize(v)
                f:write("," .. (compressed and "" or "\n"))
            end
            indent = indent - 1
            tab = ""
            for i=1,indent do tab = tab .. "    " end
            f:write((compressed and "" or tab) .. "}")
        else
            print("unable to serialzie data: "..tostring(o))
            f:write("nil," .. (compressed and "" or " -- ***ERROR: unsupported data type: "..type(o).."!***"))
        end
    end

    f:write("return {" .. (compressed and "" or "\n"))
    local tab = "    "
    for k,v in pairs(tbl) do
        f:write((compressed and "" or tab) .. "[")
        serialize(k)
        f:write("]" .. (compressed and "=" or " = "))
        serialize(v)
        f:write("," .. (compressed and "" or "\n"))
    end
    f:write("}")
    f:close()
end

local function loadTable(file)
    local data,err = loadfile(file)
    if err or data == nil then return nil,err else return data() end
end
--



return{
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
