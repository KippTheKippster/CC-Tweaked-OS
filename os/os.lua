print("MOS is Starting...")

local mos = {}

local engine = require(".core.engine")
local utils = require(".core.utils")
local multiWindow = require(".core.multiProcess.multiWindow")(engine)

local termW, termH = term.getSize()

local style = engine:getDefaultStyle()
style.backgroundColor = colors.white

local clickedStyle = engine:getDefaultClickedStyle()
clickedStyle.textColor = colors.black
clickedStyle.backgroundColor = colors.lightBlue

--MOS

--Profile
function mos.loadProfile()
    mos.profile = utils.loadTable("os/profiles/profile.sav")
end

function mos.saveProfile()
    utils.saveTable(mos.profile, "os/profiles/profile.sav")
end

local function getOrAddProfileSetting(key, value)
    mos.profile[key] = value
end

mos.loadProfile()
if mos.profile == nil then
    mos.profile = {}
    mos.profile.backgroundPath = "os/textures/backgrounds/melvin.nfp"
    mos.profile.backgroundUpdateTime = 0.1
end


--Background
local background = engine.getObject("icon"):new{}
background.text = ""

function background:treeEntered()
    self.texture = paintutils.loadImage(mos.profile.backgroundPath)
end

engine.root:addChild(background)
background.y = 1
background.x = 0

local windowsContainer = engine.root:addControl()
windowsContainer.rendering = false
windowsContainer.y = 1

--Main
--local main = engine.root:addVContainer()
--main.expandW = true
--main.y = 0

--function main:update()
--    if engine.input.isKey(keys.leftCtrl) and engine.input.isKey(keys.tab) then
--        local a = b.c
--    end
--end

--Top Bar
local toolBar = engine.root:addHContainer()
toolBar.rendering = true
toolBar.background = true
toolBar.expandW = true
toolBar.h = 1
toolBar.separation = 1

local dropdown = toolBar:addDropdown()
dropdown.text = "MOS"
dropdown.w = 3
--dropdown:addToList("New")
dropdown:addToList("File Explorer")
dropdown:addToList("Settings")
dropdown:addToList("Shell")
dropdown:addToList("Exit")
--dropdown:addToList("-Open Windows-", false)

local windowsDropdown = toolBar:addDropdown()
windowsDropdown.text = "Windows"
windowsDropdown.w = 7

--dropdown:addToList("Exit")
local windows = {}
local customTools = {}
local currentWindow = nil

local function windowFocusChanged(window, focus)
    if focus == false then return end

    if currentWindow ~= window then
        if customTools[currentWindow] ~= nil then
            customTools[currentWindow](false)
        end
        if customTools[window] ~= nil then
            customTools[window](true)
        end
    end

    currentWindow = window
end

local function addWindow(w)
    local count = 1
    for key, _ in pairs(windows) do
        count = count + 1
    end
    local text = count .. "." .. w.text
    windows[text] = w
    w.closed = function(o)
        if customTools[o] ~= nil then
            customTools[o](false)
        end
        windowsDropdown:removeFromList(text)
        windows[text] = nil
    end
    local base = w.focusChanged
    --w.focusChanged = function(o)
    --    base(o)
    --    windowFocusChanged(o, w.focus)
    --end
    base = w.visibilityChanged
    --w.visibilityChanged = function(o)
    --    base(o)
    --    if o.visible == false then
    --        windowFocusChanged(o, false)   
    --    end
    --end
    windowsDropdown:addToList(text)
    w:grabFocus()
    windowsDropdown:toFront()
end

local function launchProgram(name, path, x, y, w, h, ...)
    local parentTerm = engine.screenBuffer
    local parent = windowsContainer
    local window = multiWindow.launchProgram(parentTerm, parent, path, {__mos = mos }, x, y, w, h, ...)
    window.text = name
    addWindow(window)
    return window
end

function dropdown:click()
    engine.getObject("dropdown").click(self)
    dropdown:toFront()
end

function dropdown:optionPressed(i)
    local parentTerm = engine.screenBuffer
    local parent = engine.root
    local text = dropdown:getOptionText(i)
    if text == "New" then
        local w = engine.root:addWindowControl()
    elseif text == "Shell" then
        local w = launchProgram("Shell", "rom/programs/advanced/multishell.lua", 2, 2, 20, 10)
        w.text = "Shell"
    elseif text == "Exit" then
        multiWindow.exit()
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.setCursorPos(1, 1)
        term.setCursorBlink(true)
        term.clear()
        print("MOS Terminated...")
    elseif text == "File Explorer" then
        local fileExplorer = launchProgram("File Explorer", "/os/programs/fileExplorer.lua", 1, 1, 40, 15,
            function(path, name) -- This function is called when the user has chosen a file
                if engine.input.isKey(keys.leftCtrl) then -- Lctrl
                    local w = launchProgram("Edit '" .. name .. "'", "/rom/programs/edit.lua", 0, 0, 30, 18, path)
                    w.text = "Edit '" .. name .. "'" 
                else
                    local w = launchProgram(name, path, 2, 2, 20, 10)
                    w.text = name
                end
            end
        , mos)
        fileExplorer.text = "File Explorer"
    elseif text == "Settings" then
        local w = launchProgram("Settings", "/os/programs/settings.lua", 1, 1, 40, 15, mos)
        w.text = "Settings"
    end
end

function windowsDropdown:optionPressed(i)
    local text = windowsDropdown:getOptionText(i)
    for name, window in pairs(windows) do
        if name == text then
            window.visible = true
            window:toFront()
            window:grabFocus()
        end
    end
end


local function addTool(window, callbackFunction)
    customTools[window] = callbackFunction
    customTools[window](true)
end


local function removeTool(window)
    customTools[window](false)
    customTools[window] = nil
end


local function addToToolbar(control)
    toolBar:addChild(control)
end


local function removeFromToolbar(control)
    toolBar:removeChild(control)
end

local clock = engine.root:addControl() -- TODO add to topbar instead
clock.x = termW - 5

clock.h = 1

local clock_timer_id = os.startTimer(mos.profile.backgroundUpdateTime)

engine.input.addResizeEventListener(clock)
engine.input.addRawEventListener(clock)

function clock:resizeEvent() 
    self.x = term.getSize() - 5
end

function clock:update()
    self.text = textutils.formatTime(os.time('local'), true)
    clock_timer_id = os.startTimer(mos.profile.backgroundUpdateTime)
    self:redraw() -- Perhaps this shouldn't be a control object
end

function clock:rawEvent(data)
    local event, id = data[1], data[2]
    if event == "timer" and id == clock_timer_id then
        self:update()
    end
end

clock:update()

local frameStyle = engine:newStyle()
frameStyle.backgroundColor = colors.cyan

local bodyStyle = engine:newStyle()
bodyStyle.backgroundColor = colors.lightGray



--engine:addChild(programWindow)

mos.parentTerm = parentTerm
mos.engine = engine
mos.root = engine.root
mos.addWindow = addWindow
mos.launchProgram = launchProgram
mos.multiWindow = multiWindow
mos.background = background
mos.addTool = addTool
mos.removeTool = removeTool
mos.addToToolbar = addToToolbar
mos.removeFromToolbar = removeFromToolbar

multiWindow.start(term.current(), engine.start, engine)
