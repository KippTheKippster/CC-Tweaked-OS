local env = __wrapper.env
env.shell = shell
env.multishell = multishell

local args = __wrapper.args

local mp = __wrapper.mp

_G = __wrapper._G

__wrapper = nil

local n = multishell.getFocus()
local path = args[1]
local name = fs.getName(path)
if name:sub(-4) == ".lua" then
    name = name:sub(1, -5)
end

multishell.setTitle(n, name)

term.clear()
term.setCursorPos(1, 1)

shell.exit()

env._G = _G

local ok, err = pcall(mp.runProgram, env, table.unpack(args))

if ok == false then
    error(err, 3)
end