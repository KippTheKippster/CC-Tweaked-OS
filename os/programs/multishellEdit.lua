local args = {...}
local parentShell = args[1]
local parentMultishell = args[2]
local path = args[3]

local env = { shell = parentShell, multishell = nil }
env.require, env.package = dofile("rom/modules/main/cc/require.lua").make(env, "")
env.multishell = nil
term.redirect(__window.programViewport.program.window)
local w = window.create(__window.programViewport.program.window, 4, 4, 20, 20)
term.redirect(w)

os.run(env, "rom/programs/edit.lua", path)