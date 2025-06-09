local engine = require(".core.engine")
local utils = require(".core.utils")
local multiWindow = require(".core.multiProcess.multiWindow")(engine)

print("A")
local engine = require(".core.engine")
print("B")
print(engine)
print(engine.root)
engine.setBackgroundColor(colors.red)
engine.root:addWindowControl()
local button = engine.root:addButton()
button.pressed = function (o)
    local w = multiWindow.launchProgram("rom/programs/shell.lua", 2, 2, 20, 10)
    w.text = "Shell"
end

multiWindow.start(engine.start, engine)