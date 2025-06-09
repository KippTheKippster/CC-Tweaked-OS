local engine = require(".core.engine")
local utils = require(".core.utils")
local multiWindow = require(".core.multiProcess.multiWindow")(engine)

print("A")
local engine = require(".core.engine")
print("B")
print(engine)
print(engine.root)
engine.setBackgroundColor(colors.red)
local button = engine.root:addButton()

function button:pressed()
    local a = b.c
end

multiWindow.start(engine.start, engine)
