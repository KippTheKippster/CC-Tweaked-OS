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
        local pv = programWindow:new{}
        engine:addChild(pv)
        pv:launchProgram("rom/programs/shell.lua", "shell")
    elseif text == "Exit" then
        multiProgram.exit()
    end
end

local clock = topBar:addControl()
clock.h = 1

local frameStyle = engine:newStyle()
frameStyle.backgroundColor = colors.cyan

local window = engine:getObjects()["control"]:new{}
window.draggable = true
window.text = "% Window"
--a.style = frameStyle

function window:ready()
end

local bodyStyle = engine:newStyle()
bodyStyle.backgroundColor = colors.lightGray

programViewport = engine:getObjects()["control"]:new{}
programViewport.rendering = false
programViewport.style = engine:newStyle()
programViewport.style.backgroundColor = colors.gray
programViewport.mouseIgnore = true
programViewport.program = nil


function programViewport:launchProgram(path, ...)
    self.program = multiProgram.launchProgram(path, self.globalX, self.globalY, self.w, self.h, ...)
    self:redraw()   
end

function programViewport:draw()
    self:base().draw(self)
    self:updateWindow()
end

function programViewport:updateWindow()
    if self.program == nil then return end
    self.program.window.reposition(self.globalX + 1, self.globalY + 1, self.w, self.h)
    self.program.queueRedraw()
end

programWindow = window:new{}
function programWindow:ready()
    self:base():ready()

    local pv = programViewport:new{}
    self.programViewport = pv
    self:addChild(pv)
    pv.y = 1
    pv.h = pv.h - 1

    local b = self:addButton()
    b.w = 1
    b.pressed = function(o)
        multiProgram.endProcess(o.parent.programViewport.program)
        --print(o.parent.programViewport)
    end
end

function programWindow:launchProgram(path, ...)
    self.programViewport:launchProgram(path, ...)
end

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