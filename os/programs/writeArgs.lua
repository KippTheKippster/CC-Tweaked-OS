local src = debug.getinfo(1, "S").short_src
local corePath = "." .. fs.getDir(fs.getDir(fs.getDir(src))) .. "core"

local engine = require(corePath .. ".engine")


local args = {...}
local callbackFunction = args[1]
local startText = args[2]
local splitText = args[3]
if splitText == nil then
    splitText = true
end
local mos = __mos
local window = __window

local edit = engine.root:addLineEdit()
edit.expandW = true
edit:grabFocus()
edit.trueText = startText or ""

function edit:textSubmitted()
    --local a = e.c
    if splitText then
        local split = engine.utils.split(edit.text, " ")
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
    else
        callbackFunction(edit.text)
    end

    window:close()
end

engine.start()
