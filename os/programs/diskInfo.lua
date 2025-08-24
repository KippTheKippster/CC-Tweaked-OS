local src = debug.getinfo(1, "S").short_src
local corePath = ".core"

local engine = require(corePath .. ".engine")

local args = {...}
local diskName = args[1]

local style = engine.getDefaultStyle()
style.backgroundColor = colors.white

local main = engine.root:addVContainer()
main.rendering = true
main.expandW = true
main.expandH = true

local function newLine(text)
    local line = main:addControl()
    line.expandW = true
    line.h = 1
    line.text = text
    return line
end

newLine("")
if disk.hasAudio(diskName) then
    newLine(" Title - " .. disk.getAudioTitle(diskName))
    newLine("  Type - Audio")
    newLine("  Port - " .. diskName)
else
    newLine(" Label - " .. disk.getLabel(diskName) .. "\n")
    newLine("  Type - Data")
    newLine(" Space - " .. math.ceil(fs.getFreeSpace(diskName) / 1000) .. "/" .. math.ceil(fs.getCapacity(diskName) / 1000) .. "kB")
    newLine(" Mount - " .. disk.getMountPath(diskName))
    newLine("  Port - " .. diskName)
    newLine("    ID - " .. disk.getID(diskName))
end



engine.start()
