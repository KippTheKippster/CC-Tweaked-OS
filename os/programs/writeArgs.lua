local engine = require(".core.engine")
local utils = require(".core.utils")

local args = {...}
local callbackFunction = args[1]
local mos = __mos
local window = __window

local edit = engine.root:addLineEdit()
edit.expandW = true
edit:grabFocus()

function edit:textSubmitted()
    --local a = e.c
    local split = utils.split(edit.text, " ")
    local returnArgs = {}
    for i = 1, #split do 
        local str = split[i]
        local number = tonumber(str)
        if number ~= nil then
            table.insert(returnArgs, number)
        else
            table.insert(returnArgs, str)
        end
    end
    callbackFunction(table.unpack(returnArgs))
    window:close()
end

engine.start()
