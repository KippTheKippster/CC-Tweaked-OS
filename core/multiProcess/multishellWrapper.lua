local env = __wrapper.env
env.shell = shell
env.multishell = multishell

local args = __wrapper.args

local mp = __wrapper.mp

__wrapper = nil

local n = multishell.getFocus()
local path = args[1]
local name = fs.getName(path)
if name:sub(-4) == ".lua" then
    name = name:sub(1, -5)
end

multishell.setTitle(n, name)

--[[
local setTitle = multishell.setTitle
multishell.setTitle = function (id, title)
    print("DJSAIODJSIAO")
    setTitle(id, title)
    env.__window.text = title
    --local a = b.c
end


local setFocus = multishell.setFocus
multishell.setFocus = function (id)
    local title = multishell.getTitle(id)
    env.__window.text = title
    setFocus(id)

end
]]--

term.clear()
term.setCursorPos(1, 1)

shell.exit()

local ok, err = pcall(mp.runProgram, env, table.unpack(args))

if ok == false then
    error(err, 3)
end