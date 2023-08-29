
local engine = require(".core.engine")
local multiWindow = require(".core.multiProcess.multiWindow")(engine)
multiWindow.launchProgram("rom/programs/shell.lua", 2, 2, 20, 10, "shell")

engine:start()