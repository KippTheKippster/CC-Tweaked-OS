local src = debug.getinfo(1, "S").short_src
local corePath = ".core"

local engine = require(corePath .. ".engine")

---@type MOS
local mos = __mos

if mos == nil then
    printError("Settings must be opened with MOS!")
    return
end

term.setTextColor(colors.white)

local backgroundStyle = engine.newStyle()
backgroundStyle.backgroundColor = colors.black

local background = engine.root:addControl()
background.expandW = true
background.expandH = true
background.text = ""
background.style = backgroundStyle

local main = engine.root:addVContainer()
main.expandW = true
main.expandH = true

local buttonStyle = engine.newStyle()
buttonStyle.backgroundColor = colors.white
buttonStyle.textColor = colors.black

local clickedStyle = engine:newStyle()
clickedStyle.backgroundColor = colors.lightBlue
clickedStyle.textColor = colors.black

local settingsButton = engine.getObject("button"):new{}
settingsButton.h = 1
settingsButton.fitToText = true
settingsButton.normalStyle = buttonStyle
settingsButton.clickedStyle = clickedStyle

local seperatorStyle = engine.newStyle()
seperatorStyle.backgroundColor = colors.white
seperatorStyle.textColor = colors.gray

local appearanceSeperator = main:addControl()
appearanceSeperator.h = 1
appearanceSeperator.expandW = true
appearanceSeperator.text = "-Appearance-"
appearanceSeperator.centerText = true
appearanceSeperator.style = seperatorStyle


---comment
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

local reset

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

    reset = picker:addButton()
    reset.x = -1
    reset.h = 1
    reset.w = 1
    reset.text = "x"
    reset.inheritStyle = false
    reset.normalStyle = buttonStyle
    reset.clickedStyle = clickedStyle

    picker.reset = picker

    reset.visible = mos.profile.backgroundColor ~= nil
    if mos.profile.backgroundColor ~= nil then
        picker.style.backgroundColor = mos.profile.backgroundColor
    end

    reset.pressed = function (o)
        ---@type Profile
        mos.profile.backgroundColor = nil
        mos.engine.backgroundColor = mos.theme.backgroundColor
        mos.refreshTheme()
        o.visible = false
        picker.style.backgroundColor = colors.white
    end

    return picker
end

local fileExplorer = nil

local changeTheme = addSettingsButton("Theme", "[Browse]")

function changeTheme:pressed()
    fileExplorer = mos.launchProgram("Choose .thm", "/os/programs/fileExplorer.lua", 3, 3, 24, 12, function (name, path)
        local suffix = ".thm"
        if path:sub(-#suffix) == suffix then
            mos.loadTheme(path)
            mos.engine.root:redraw()
            fileExplorer:close()
        end
    end, "os/themes/")
end

local changeBackground = addSettingsButton("Background Image", "[Browse]")

function changeBackground:pressed()
    fileExplorer = mos.launchProgram("Choose .nfp", "/os/programs/fileExplorer.lua", 3, 3, 24, 12, function (name, path)
        mos.backgroundIcon.texture = paintutils.loadImage(path)
        mos.profile.backgroundIcon = path
    end, "os/textures/backgrounds/")
end

local changeBackgroundColor = addSettingsColor("Background Color")

function changeBackgroundColor:optionPressed(i)
    local color = changeBackgroundColor:getColor()
    mos.profile.backgroundColor = color
    mos.engine.backgroundColor = color
    local style = self:getOption(i).style:new()
    self.normalStyle = style
    self.clickedStyle = style
    reset.visible = true
end


engine.start()