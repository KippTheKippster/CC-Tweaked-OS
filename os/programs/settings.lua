local engine = require(".core.engine")
local args = {...}
local mos = args[1]

term.setTextColor(colors.white)

local main = engine.root:addVContainer()
local changeBackground = main:addButton()
local fileExplorer = nil
changeBackground.text = "Change Background"
changeBackground.h = 1

function changeBackground:click()
    if fileExplorer ~= nil then return end

    fileExplorer = mos.multiWindow.launchProgram(mos.root, "/os/programs/fileExplorer.lua", 3, 3, 24, 12, function (path, name)
        fileExplorer:close()
        fileExplorer = nil
        local suffix = ".nfp"
        if path:sub(-#suffix) == suffix then
            mos.background.texture = paintutils.loadImage(path)
            mos.profile.backgroundPath = path
            mos.saveProfile()  
        else -- Why isn't this working?
            local w = mos.engine:addWindowControl()
            mos.addWindow(w)
        end
    end)
    fileExplorer.text = "Choose Background"
    mos.addWindow(fileExplorer)
end

engine.start()