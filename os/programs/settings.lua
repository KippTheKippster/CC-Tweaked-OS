local corePath = __Global.coreDotPath

---@type Engine
local engine = require(corePath .. ".engine")

---@type MOS
local mos = __mos

if mos == nil then
    printError("Settings must be opened with MOS!")
    return
end

local buttonStyle = mos.styles.style
local clickedStyle = mos.styles.clickStyle
local seperatorStyle = mos.styles.style:new()
seperatorStyle.textColor = colors.gray

local scrollContainer = engine.root:addScrollContainer()
scrollContainer.marginR = 1
scrollContainer.expandW = true
scrollContainer.expandH = true

local main = scrollContainer:addVContainer()
main.expandW = true
main.expandH = true
main.rendering = true
main.style = buttonStyle


local settingsButton = engine.Button:new()
settingsButton.h = 1
settingsButton.normalStyle = buttonStyle
settingsButton.clickedStyle = clickedStyle


local function addSeperator(text)
    local seperator = main:addControl()
    seperator.h = 2
    seperator.expandW = true
    seperator.centerText = true
    seperator.style = seperatorStyle
    seperator.text = text
    return seperator
end


---@param text string
local function addLabel(text)
    ---@type Control
    local label = main:addControl()
    label.text = text
    label.expandW = true
    label.h = 1
    label.style = buttonStyle

    return label
end

---@param o Control
local function addReset(o)
    local reset = o:addButton()
    reset.x = -1
    reset.h = 1
    reset.w = 1
    reset.text = "x"
    reset.inheritStyle = false
    reset.normalStyle = buttonStyle
    reset.clickedStyle = clickedStyle
    return reset
end

local function addSettingsInfo(text, infoText)
    local label = addLabel(text)
    ---@type Button
    local info = engine.Control:new()
    label:addChild(info)
    info.text = infoText
    info.style = buttonStyle
    info.h = 1
    info.anchorW = info.Anchor.RIGHT
    return info
end


local function addSettingsButton(text, buttonText)
    local label = addLabel(text)

    ---@type Button
    local button = settingsButton:new()
    label:addChild(button)
    button.text = buttonText
    button.dragSelectable = true
    button.style = buttonStyle
    button.anchorW = button.Anchor.RIGHT
    return button
end

local function addSettingsColor(text)
    local label = addLabel(text)

    local picker = label:addColorPicker()
 
    local pickerStyle = buttonStyle:new()
    picker.style = pickerStyle
    --picker.normalStyle = pickerStyle
    --picker.clickedStyle = pickerStyle
    picker.text = "[      ]"
    picker.anchorW = picker.Anchor.RIGHT
    picker.dragSelectable = true

    return picker
end


local function addSettingsLineEdit(text, editText)
    local label = addLabel(text)

    local edit = label:addLineEdit()
    edit.w = 16
    edit.trueText = editText
    edit.dragSelectable = true
    edit.normalStyle.backgroundColor = colors.gray
    edit.normalStyle.textColor = colors.white
    edit.focusStyle.backgroundColor = colors.lightGray
    edit.focusStyle.textColor = colors.black
    edit.style = edit.normalStyle
    edit.anchorW = edit.Anchor.RIGHT
    return edit
end

local fileExplorer = nil

addSeperator("-MOS-")
addSettingsInfo("Version", tostring(mos.getVersion()))
local installerText = "[Install]"
if fs.exists("/mosInstaller.lua") then
    installerText = "[Run]"
end
local versionButton = addSettingsButton("Installer", installerText)
function versionButton:pressed()
    if fs.exists("/mosInstaller.lua") then
        mos.openProgram("mosInstaller.lua").text = "MOS Installer"
    else
        mos.openProgram("/rom/programs/http/pastebin.lua", "get", "Wa0niW8x", "mosInstaller.lua").text = "Downloading MOS Installer"
        versionButton.text = "[Run]"
        versionButton.parent:_expandChildren()
    end
end

addSeperator("-Computer-")
local labelEdit = addSettingsLineEdit("Label", os.getComputerLabel())
local freeSpace = math.floor(fs.getFreeSpace("") / 1000.0)
local capacity = math.floor(fs.getCapacity("") / 1000.0)
addSettingsInfo("ID", "#" .. tostring(os.getComputerID()))
addSettingsInfo("Space", capacity - freeSpace .. "/" .. capacity  .. "KB")
function labelEdit:textSubmitted()
    os.setComputerLabel(labelEdit.text)
end


addSeperator("-Appearance-")

local changeTheme = addSettingsButton("Theme", "[Browse]")

function changeTheme:pressed()
    fileExplorer = mos.openFileDialogue("Choose .thm", function (path)
        local suffix = ".thm"
        if path:sub(-#suffix) == suffix then
            mos.loadTheme(path)
            mos.engine.root:redraw()
            engine.root:redraw()
            fileExplorer:close()
        end
    end, false, "/mos/os/themes/")
end

local changeBackground = addSettingsButton("Background Image", "[Browse]")

local imageReset = addReset(changeBackground)
imageReset.visible = mos.profile.backgroundIcon ~= nil


function changeBackground:pressed()
    fileExplorer = mos.openFileDialogue("Choose .nfp", function (path)
        mos.backgroundIcon.texture = paintutils.loadImage(path)
        mos.profile.backgroundIcon = path
        imageReset.visible = true
    end, false)
end

function imageReset:pressed()
    mos.profile.backgroundIcon = nil
    mos.backgroundIcon.texture = nil
    imageReset.visible = false
end

local picker = addSettingsColor("Background Color")

local colorReset = addReset(picker)

colorReset.visible = mos.profile.backgroundColor ~= nil
if mos.profile.backgroundColor ~= nil then
    picker.style.backgroundColor = mos.profile.backgroundColor
end

colorReset.pressed = function (o)
    ---@type Profile
    mos.profile.backgroundColor = nil
    mos.engine.backgroundColor = mos.theme.backgroundColor
    mos.refreshTheme()
    o.visible = false
    picker.style.backgroundColor = colors.white
end


function picker:colorClicked(color)
    mos.profile.backgroundColor = color
    mos.engine.backgroundColor = color
    mos.engine.root:redraw()
    colorReset.visible = true
end

addSeperator("-File Explorer-")

local dotFiles = addSettingsButton("Show dot Files", "[ ]")
if mos.profile.showDotFiles then
    dotFiles.text = "[x]"
end

dotFiles.pressed = function (o)
    mos.profile.showDotFiles = mos.profile.showDotFiles == false
    os.queueEvent("mos_refresh_files")
    if mos.profile.showDotFiles then
        o.text = "[x]"
    else
        o.text = "[ ]"
    end
end


local mosFiles = addSettingsButton("Show mos Files", "[ ]")
if mos.profile.showMosFiles then
    mosFiles.text = "[x]"
end

mosFiles.pressed = function (o)
    mos.profile.showMosFiles = mos.profile.showMosFiles == false
    os.queueEvent("mos_refresh_files")
    if mos.profile.showMosFiles then
        o.text = "[x]"
    else
        o.text = "[ ]"
    end
end


local romFiles = addSettingsButton("Show rom Files", "[ ]")
if mos.profile.showRomFiles then
    romFiles.text = "[x]"
end

romFiles.pressed = function (o)
    mos.profile.showRomFiles = mos.profile.showRomFiles == false
    os.queueEvent("mos_refresh_files")
    if mos.profile.showRomFiles then
        o.text = "[x]"
    else
        o.text = "[ ]"
    end
end

engine.start()