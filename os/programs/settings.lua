local engine = require(".core.engine")
local args = {...}
local mos = args[1]

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
settingsButton.expandW = true
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

local function addSettingsButton(text)
    local button = settingsButton:new{}
    main:addChild(button)
    button.text = text
    button.style = buttonStyle
    return button
end

local fileExplorer = nil

local changeBackground = addSettingsButton("Change Background Texture")


function changeBackground:pressed()
    if fileExplorer ~= nil then
        --fileExplorer:remove()
        --fileExplorer = nil
    end

    fileExplorer = mos.launchProgram("Choose .nfp", "/os/programs/fileExplorer.lua", 3, 3, 24, 12, function (path, name)
        --fileExplorer:close()
        --fileExplorer = nil
        local suffix = ".nfp"
        if path:sub(-#suffix) == suffix then
            mos.background.texture = paintutils.loadImage(path)
            mos.profile.backgroundPath = path
            mos.saveProfile()  
        else
            --local w = mos.engine:addWindowControl()
            --mos.addWindow(w)
        end
    end)
end

local changeUpdateTime = addSettingsButton("Change Background Update Time")

function changeUpdateTime:pressed()
    mos.profile.backgroundUpdateTime = 1.0
end

engine.start()