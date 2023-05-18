print("os starting...")
engine = require(".core.engine")
utils = require(".core.utils")
multiProgram = require(".core.multiProgram")

local style = engine:getDefaultStyle()
style.backgroundColor = colors.lightGray

local clickedStyle = engine:getDefaultClickedStyle()
clickedStyle.textColor = colors.black
clickedStyle.backgroundColor = colors.white


--Background
local background = engine:addIcon()
background.y = 1
background.x = 0
function background:update() --TODO, fix it so it textures can be loaded at startup
    if self.texture == nil then
        self.texture = paintutils.loadImage("os/textures/backgrounds/melvin.nfp") 
    end
end 

--Main
local main = engine:addVContainer()
main.y = 0

input.addKeyListener(main)

function main:key(k)
    --print("YEEE")
end

--Top Bar
local topBar = main:addHContainer()
topBar.rendering = true
topBar.background = true
topBar.w = 51
topBar.h = 0

local dropdown = topBar:addDropdown()
dropdown:addToList("New")
dropdown:addToList("Shell")
dropdown:addToList("Exit")

function dropdown:optionPressed(i)
    local text = dropdown:getOptionText(i)
    if text == "Shell" then
        local w, h = term.getSize()
        multiProgram.launchProgram("rom/programs/shell.lua", 5, 5, w - 5, h - 5, "shell")
        --multiProgram.launchProgram("rom/programs/fun/advanced/paint.lua", 5, 5, 30, 10, "multiPaint")
    elseif text == "Exit" then
        multiProgram.exit()
    end
end

local clock = topBar:addControl()
clock.h = 1

local frameStyle = engine:newStyle()
frameStyle.backgroundColor = colors.cyan

local a = engine:addControl()
a.draggable = true
a.text = "% Window    x"
a.x = 10
a.y = 3
--a.style = frameStyle

local bodyStyle = engine:newStyle()
bodyStyle.backgroundColor = colors.lightGray


local programViewport = engine:getObjects()["control"]:new{}
programViewport.rendering = false
local i = 0
function programViewport:update()
    if i == 3 then
        programViewport.program = multiProgram.launchProgram("rom/programs/shell.lua", 5, 5, 16, 16, "shell")
    end
end
programViewport:add()


--[[
function programViewport:globalPositionChanged()
    --self.program.window.reposition(self.globalX, self.globalY, self.w, self.h)
end
]]--

function clock:update()
    self.text = textutils.formatTime(os.time('local'), true)
    --self:redraw()
end

local w, h = term.getSize()
multiProgram.launchProcess(engine.start, 1, 1, w, h, engine)
--multiProgram.launchProgram("rom/programs/fun/advanced/paint.lua", 5, 5, 30, 10, "multiPaint")
--multiProgram.launchProgram("rom/programs/shell.lua", 1, 2, 30, 10, "shell")
--multiProgram.setFocus(1)
multiProgram.start()
