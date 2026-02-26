local corePath = __Global.coreDotPath

local engine = require(corePath .. ".engine")

local args = {...}
local diskName = args[1] or ""

if not disk.isPresent(diskName) then
    error("Disk '" .. diskName .. "' is not present", 0)
end

if __mos then
    __mos.applyTheme(engine)
end

local style = engine.getDefaultStyle()
style.backgroundColor = colors.white

local main = engine.root:addVContainer()
main.rendering = true
main.expandW = true
main.expandH = true

local Line = engine.Control:new()
Line.expandW = true
Line.h = 1
Line.text = text

local function newLine(text)
    local l = Line:new()
    l.text = text
    return l
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
