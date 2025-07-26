local env = __wrapper.env
env.shell = shell
env.multishell = multishell

local args = __wrapper.args

term.clear()
term.setCursorPos(1, 1)

os.run(env, table.unpack(args))

shell.exit()