print("os starting...")
local engine = require(".core.engine")
local utils = require(".core.utils")
local multiProgram = require(".core.multiProgram")
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
    if text == "New" then
        local wi = windowControl:new{}
        engine:addChild(wi)
    elseif text == "Shell" then
        local pv = programWindow:new{}
        pv.text = "  Shell"
        engine:addChild(pv)
        pv:launchProgram("rom/programs/shell.lua", "shell")
    elseif text == "Exit" then
        shell.run("rom/programs/shell.lua")
        multiProgram.exit()
    end
end

local clock = topBar:addControl()
clock.h = 1

local frameStyle = engine:newStyle()
frameStyle.backgroundColor = colors.cyan

--Window
windowControl = engine:getObjects()["control"]:new{}
windowControl.draggable = true
windowControl.text = "  Window"
windowControl.exitButton = nil
windowControl.scaleButton = nil
windowControl.minW = 10
windowControl.minH = 4
windowControl.oldW = 0
windowControl.oldH = 0

function windowControl:ready()
    self.oldW = self.w
    self.oldH = self.h

    self.exitButton = self:addButton()
    self.exitButton.text = "x"
    self.exitButton.x = self.w - 1
    self.exitButton.w = 1
    self.exitButton.h = 1

    self.exitButton.pressed = function(o)
        o.parent:remove()
    end

    self.scaleButton = self:addControl()
    self.scaleButton.w = 1
    self.scaleButton.h = 1
    self.scaleButton.text = "%"
    self.scaleButton.drag = function(o, relativeX, relativeY)
        local wi = o.parent
        local w = wi.w
        local h = wi.h
        wi.w = wi.w - relativeX
        wi.h = wi.h - relativeY
        wi.w = math.max(wi.w, wi.minW)
        wi.h = math.max(wi.h, wi.minH)
        local deltaW = w - wi.w
        local deltaH = h - wi.h
        wi.x = wi.x + deltaW
        wi.y = wi.y + deltaH

        wi.oldW = wi.w
        wi.oldH = wi.h
    end

    self.scaleButton.doublePressed = function(o)
        local w, h = term.getSize()
        local wi = o.parent
        wi.x = 0
        wi.y = 0
        wi.w = w
        wi.h = h
    end
end

function windowControl:drag(x, y)
    engine.getObjects()["control"].drag(self, x, y)
    self.w = self.oldW
    self.h = self.oldH
end

function windowControl:sizeChanged()
    self.exitButton.x = self.w - 1
end

--local wi = windowControl:new{}
--engine:addChild(wi)

local bodyStyle = engine:newStyle()
bodyStyle.backgroundColor = colors.lightGray

programViewport = engine:getObjects()["control"]:new{}
programViewport.rendering = false
programViewport.style = engine:newStyle()
programViewport.style.backgroundColor = colors.red
programViewport.mouseIgnore = false
programViewport.program = nil

function programViewport:ready()
    input.addMouseEventListener(self)
end

function programViewport:launchProgram(path, ...)
    self.program = multiProgram.launchProgram(path, self.globalX, self.globalY, self.w, self.h, ...)
    self:redraw()
end

function programViewport:draw()
    self:base().draw(self)
    if self.program == nil then return end
    self:updateWindow()
    --self.program.window.redraw()
end

function programViewport:sizeChanged()
    self.resize = true
end

function programViewport:mouseEvent(event, data)
    if self.program == nil then return end
    if self.focus == false then return end
    --self:toFront()
    local button, x, y = data[2], data[3], data[4]
    local offsetX, offsetY= self.program.window.getPosition()
    self.program.resumeProcess(event, button, x - offsetX + 1, y - offsetY + 1)
end

function programViewport:updateWindow()
    if self.program == nil then return end
    term.redirect(self.program.window)
    self.program.window.reposition(self.globalX + 1, self.globalY + 1, self.w, self.h, parentTerm) --, self.program.window)
    multiProgram.resumeProcess(self.program, "term_resize")
    term.redirect(parentTerm)
    --self.program.queueRedraw()
end

programWindow = windowControl:new{}
programWindow.programViewport = nil
function programWindow:ready()
    self:base().ready(self)
    local pv = programViewport:new{}
    self.programViewport = pv
    self:addChild(pv)
    pv.y = 1
    pv.h = pv.h - 1

    self.exitButton.pressed = function(o)
        multiProgram.endProcess(o.parent.programViewport.program)
        o.parent:remove()
        --o.remove(o)
        --print(o.parent.programViewport)
    end
end

function programWindow:launchProgram(path, ...)
    self.programViewport:launchProgram(path, ...)
end

function programWindow:sizeChanged()
    self:base().sizeChanged(self)
    self.programViewport.w = self.w
    self.programViewport.h = self.h - 1
end

function clock:update()
    self.text = textutils.formatTime(os.time('local'), true)
    --self:redraw()
end

local w, h = term.getSize()
multiProgram.launchProcess(engine.start, 1, 1, w, h, engine)
multiProgram.start()