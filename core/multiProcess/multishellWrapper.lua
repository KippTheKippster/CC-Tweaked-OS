
local env = __wrapper.env
env.shell = shell
env.multishell = multishell

local args = __wrapper.args

---@type MultiProgram
local mp = __wrapper.mp

_G.__wrapper = nil

local n = multishell.getFocus()
local path = args[1]
if type(path) ~= "string" then
    error("Path arg is not a valid string: " .. type(path))
end

local name = fs.getName(path)
if name:sub(-4) == ".lua" then
    name = name:sub(1, -5)
end

multishell.setTitle(n, name)

term.clear()
term.setCursorPos(1, 1)

local getRunningProgram = shell.getRunningProgram
local program = getRunningProgram()
shell.getRunningProgram = function () -- Fix problem where getRunningProgram would returng multishellWrapper.lua
    local p = getRunningProgram()
    if p == program then -- Shell stores a programStack, so only check if the end of the stack is multishellWrapper.lua
        if path:sub(1,1) == "/" then
            return path:sub(2)
        end
        return path
    end
    return p
end

shell.exit()

if fs.exists(path) then
    local fn, err = mp.loadProgram(env, path)
    if fn == nil then
        error(err, 3)
    end

    local ok, err = fn(table.unpack(args, 2))
    if ok == false then
        error(err)
    end
else
    error("No such program as \"" .. path .. "\"", 0)
end