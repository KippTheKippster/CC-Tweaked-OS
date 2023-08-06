function contains(t, v)
    for _, x in pairs(t) do
        if v == x then 
            return true
        end
    end
    return false
end

function combine(first, second)
	for k,v in pairs(second) do 
		table.insert(first, v)
	end
end

function move(tb, object, position)
	for i = 1, #tb do
		if tb[i] == object then
			tb[i] = tb[i + position] --sets the current position to the object that is occupying the wanted position
			tb[i + position] = object --sets the wanted position to the wanted object
		end
	end
end

function split(s, c)
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

function hasTag(data, tag)
	tags = data["tags"]
	if tags[tag] == true then
		return true
	else
		return false
	end
end

function printTable(table, recursive, prefix)
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

function clamp(value, min, max)
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

function getDir(value)
    local value = clamp(value, -1, 1)
    --value = math.min(value + 0.5)
    return value
end

function capitaliseFirst(text)
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

function pushUp(table, object)
	return push(table, object, -1)
end

function pushDown(table, object)
	return push(table, object, 1)
end

function pushTop(table, object)
	repeat until pushUp(table, object) == 1
end

function pushBottom(table, object)
	repeat until pushDown(table, object) == #table
end

return{
	contains = contains,
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
	pushBottom = pushBottom
}
