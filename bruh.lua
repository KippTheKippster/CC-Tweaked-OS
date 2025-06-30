local engine = require(".core.engine")
local utils = require(".core.utils")
local multiWindow = require(".core.multiProcess.multiWindow")(engine)

local engine = require(".core.engine")

local button = engine.root:addButton()
button.y = 2

function button:pressed()
    engine.stop()
end

local edit = engine.root:addLineEdit()

engine.start()
