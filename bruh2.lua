
local engine = require(".core.engine")
utils = require(".core.utils")

local e = engine:addLineEdit()
e.w = 16
e.x = 2
e.y = 4

local b = engine:addButton()
b.x = 20
b.h = 20
--local b1 = b:addButton()
--b1.y = 5

local d = b:addDropdown()
d.y = 10
d:addToList("test")
d:addToList("test2")


term.clear()
engine:start()