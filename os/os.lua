print("os starting...")
local engine = require(".core.engine")
local utils = require(".core.utils")
local multiWindow = require(".core.multiProcess.multiWindow")(engine)
local parentTerm = term.current()

local style = engine:getDefaultStyle()
style.backgroundColor = colors.lightGray

local clickedStyle = engine:getDefaultClickedStyle()
clickedStyle.textColor = colors.black
clickedStyle.backgroundColor = colors.white

--Background
local background = engine:addIcon()
background.y = 1
background.x = 0
background.text = "a"
function background:update() --TODO, fix it so it textures can be loaded at startup
    if self.texture == nil then
        self.texture = paintutils.loadImage("os/textures/backgrounds/melvin.nfp")
    end
end

--Main
local main = engine:addVContainer()
main.y = 0

--Top Bar
local topBar = main:addHContainer()
topBar.rendering = true
topBar.background = true
topBar.w = 51
topBar.h = 0

local dropdown = topBar:addDropdown()
dropdown.text = "MOS"
--dropdown:addToList("New")
dropdown:addToList("File Explorer")
dropdown:addToList("Shell")
--dropdown:addToList("Exit")

function dropdown:optionPressed(i)
    local text = dropdown:getOptionText(i)
    if text == "New" then
        local wi = engine:addWindowControl()
    elseif text == "Shell" then
        multiWindow.launchProgram("rom/programs/shell.lua", 2, 2, 20, 10)
    elseif text == "Exit" then
        shell.run("rom/programs/shell.lua")
        multiWindow.exit()
    elseif text == "File Explorer" then
        multiWindow.launchProgram("/os/programs/fileExplorer.lua", 1, 1, 40, 15, 
        function(name, ctrl)
            if ctrl then
                local w = multiWindow.launchProgram("/rom/programs/edit.lua", 0, 0, 30, 18, name)
            else
                local w = multiWindow.launchProgram(name, 2, 2, 20, 10)
            end
        end)
    end
end

local clock = topBar:addControl()
clock.h = 1

local frameStyle = engine:newStyle()
frameStyle.backgroundColor = colors.cyan

local bodyStyle = engine:newStyle()
bodyStyle.backgroundColor = colors.lightGray

function clock:update()
    self.text = textutils.formatTime(os.time('local'), true)
    --self:redraw()
end

--engine:addChild(programWindow)

local w, h = term.getSize()
--multiWindow.launchProcess(engine.start, 1, 1, w, h, engine)
multiWindow.start(engine.start, engine)