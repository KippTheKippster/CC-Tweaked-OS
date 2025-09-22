local src = debug.getinfo(1, "S").short_src
local corePath = ".core"

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
local seperatorStyle = mos.styles.style

local main = engine.root:addVContainer()
main.expandW = true
main.expandH = true
main.style = buttonStyle
main.rendering = true


local settingsButton = engine.Button:new{}
settingsButton.h = 1
settingsButton.fitToText = true
settingsButton.normalStyle = buttonStyle
settingsButton.clickedStyle = clickedStyle


local function addSeperator(text)
    local seperator = main:addControl()
    seperator.h = 1
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
    label.fitToText = true
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
    local info = engine.Control:new{}
    label:addChild(info)
    info.text = infoText
    info.style = buttonStyle
    info.h = 1
    info.fitToText = true
    info.anchorW = info.anchor.RIGHT
    return info
end


local function addSettingsButton(text, buttonText)
    local label = addLabel(text)

    ---@type Button
    local button = settingsButton:new{}
    label:addChild(button)
    button.text = buttonText
    button.dragSelectable = true
    button.style = buttonStyle
    button.anchorW = button.anchor.RIGHT
    return button
end

local function addSettingsColor(text)
    local label = addLabel(text)

    local picker = label:addColorPicker()
    local pickerStyle = buttonStyle:new()
    picker.style = pickerStyle
    picker.normalStyle = pickerStyle
    picker.clickedStyle = pickerStyle
    picker.text = "[      ]"
    picker.anchorW = picker.anchor.RIGHT
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
    edit.anchorW = edit.anchor.RIGHT
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
        mos.openProgram("MOS Installer", "mosInstaller.lua")
    else
        mos.openProgram("Downloading MOS Installer", "/rom/programs/http/pastebin.lua", false, "get", "Wa0niW8x", "mosInstaller.lua")
        versionButton.text = "[Run]"
        versionButton.parent:_expandChildren()
    end
end

addSeperator("-Computer-")
addSettingsInfo("ID", "#" .. tostring(os.getComputerID()))
local labelEdit = addSettingsLineEdit("Label", os.getComputerLabel())
function labelEdit:textSubmitted()
    os.setComputerLabel(labelEdit.text)
end

addSeperator("-Appearance-")

local changeTheme = addSettingsButton("Theme", "[Browse]")

function changeTheme:pressed()
    fileExplorer = mos.launchProgram("Choose .thm", "/os/programs/fileExplorer.lua", 3, 3, 24, 12, function (name, path)
        local suffix = ".thm"
        if path:sub(-#suffix) == suffix then
            mos.loadTheme(path)
            mos.engine.root:redraw()
            engine.root:redraw()
            fileExplorer:close()
        end
    end, "os/themes/")
end

local changeBackground = addSettingsButton("Background Image", "[Browse]")

local imageReset = addReset(changeBackground)
imageReset.visible = mos.profile.backgroundIcon ~= nil


function changeBackground:pressed()
    fileExplorer = mos.launchProgram("Choose .nfp", "/os/programs/fileExplorer.lua", 3, 3, 24, 12, function (name, path)
        mos.backgroundIcon.texture = paintutils.loadImage(path)
        mos.profile.backgroundIcon = path
        imageReset.visible = true
    end, "os/textures/backgrounds/")
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


function picker:colorPressed(color)
    mos.profile.backgroundColor = color
    mos.engine.backgroundColor = color
    colorReset.visible = true
end

local dotFiles = addSettingsButton("Show '.' Files", "[ ]")
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


engine.start()