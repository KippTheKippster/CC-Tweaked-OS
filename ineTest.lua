local engine = require(".core.engine")
local utils = require(".core.utils")
local multiWindow = require(".core.multiProcess.multiWindow")(engine)

print("A")
local engine = require(".core.engine")
print("B")
print(engine)
print(engine.root)
engine.setBackgroundColor(colors.red)
local container = engine.root:addVContainer()
container.expandW = false
container.w = 64
local button = container:addButton()
button.h = 1
button.expandW = true

function button:render()
    term.setBackgroundColor(colors.lightBlue)
    term.clear()
    engine.getObject("button").render(self)
end

function button:pressed()
    --local a = b.c
end

multiWindow.start(engine.parentTerm, engine.start, engine)
