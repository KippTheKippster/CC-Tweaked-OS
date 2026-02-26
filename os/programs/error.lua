local corePath = ".mos.core"
if _G.__Global then corePath =_G.__Global.coreDotPath end
---@type ProgramWindow
local window = __window
---@type MOS
local mos = __mos

local args = {...}

---@type Engine
local engine = require(corePath .. ".engine")
mos.applyTheme(engine)
local main = engine.root:addVContainer()
main.expandW = true
main.expandH = true

for _, err in ipairs(args) do
    local c = main:addControl()
    c.text = tostring(err)
    c.expandW = true
    c.centerText = true
    window.minW = math.max(#c.text, window.minW)
end
window.minH = #args + 1

window.w = window.minW + 2
window.h = window.minH
window.oldW = window.w
window.oldH = window.h

engine.start()