local engine = require(".core.engine")
local args = {...}

local main = engine.root:addVContainer()
local changeBackground = main:addButton()
changeBackground.text = "Change Background"
changeBackground.h = 1


engine.start()