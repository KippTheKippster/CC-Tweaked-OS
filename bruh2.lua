
local engine = require(".core.engine")
utils = require(".core.utils")

local e = engine:addLineEdit()
e.w = 32
e.h = 6

term.clear()

engine:start()