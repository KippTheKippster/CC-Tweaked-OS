---@type MOS
local mos = __mos
---@type ProgramWindow
local window = __mosWindow
if mos == nil then
    printError("Settings must be opened with MOS!")
    return
end

---@type Engine
local engine = require(mos.mosDotPath .. ".core.engine")
local args = {...}

---@type Engine
mos.applyTheme(engine)
local main = engine.root:addVContainer()
main.fitToChildrenW = true
main.fitToChildrenH = true

for _, err in ipairs(args) do
    local c = main:addControl()
    c.text = tostring(err)
    c.marginL = 1
    c.marginR = 1
end

window.minW = main.w
window.minH = main.h + 1
window.w = window.minW
window.h = window.minH
window.oldW = window.w
window.oldH = window.h

engine.start()