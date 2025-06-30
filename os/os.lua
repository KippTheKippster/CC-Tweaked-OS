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
    if mos.profile[key] == nil then
        mos.profile[key] = value
        return value
    else
        return mos.profile[key]
    end
end

local function validateProfile(profile, defaultProfile)
    for k, v in pairs(defaultProfile) do
        if profile[k] == nil then
            profile[k] = v
        end
    end
end

local defaultProfile = {
    backgroundPath = "os/textures/backgrounds/melvin.nfp",
    backgroundUpdateTime = 0.1,
    programExecptions = {
        nfp = "/rom/programs/fun/advanced/paint.lua",
        txt = "/rom/programs/edit.lua"
    }
}

mos.loadProfile()

validateProfile(mos.profile, defaultProfile)

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
-- windowsContainer.y = 1

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
toolBar.mouseIgnore = true

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

local clock = engine.root:addControl() -- TODO add to topbar instead
clock.x = termW - 5
clock.h = 1

local windows = {}
local windowId = 1
local customTools = {}
local currentWindow = nil

local function windowFocusChanged(window)
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

local function focusChangedEvent(o)
    if utils.contains(windows, o) then
        windowFocusChanged(o)
    end
end

engine.input.addFocusChangedListener(focusChangedEvent)

local function windowClosed(a)
    windowsDropdown:removeFromList(a[2])
    if customTools[a[1]] ~= nil then
        customTools[a[1]](false)
    end
    windows[a[1]] = nil
end

local function windowFullscreenChanged(w)
    --toolBar.rendering = w.fullscreen == false
    background.visible = w.fullscreen == false
    --w.text = ""
    --w.rendering = true
    --clock.visible = w.fullscreen == false
end

local function addWindow(w)
    local count = 1
    for key, _ in pairs(windows) do
        count = count + 1
    end

    local text = w.text
    text = windowId .. "." .. w.text

    windows[text] = w
    w:connectSignal(w.closedSignal, windowClosed, {w, text})
    w:connectSignal(w.fullscreenChangedSignal, windowFullscreenChanged, w)
    w:grabFocus()
    term.setCursorPos(5,5)
    windowsDropdown:addToList(text)

    windowId = windowId + 1
end

local function launchProgram(name, path, x, y, w, h, ...)
    local parentTerm = engine.screenBuffer
    local parent = windowsContainer
    local window = multiWindow.launchProgram(parentTerm, parent, path, {__mos = mos }, x, y, w, h, ...)
    window.text = name
    addWindow(window)
    return window
end

function dropdown:optionPressed(i)
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
        local fileExplorer = launchProgram("File Explorer", "/os/programs/fileExplorer.lua", 7, 2, 35, 15,
            function(path, name, ...) -- This function is called when the user has chosen a file
                if engine.input.isKey(keys.leftCtrl) then -- Lctrl
                    launchProgram("Edit '" .. name .. "'", "/os/programs/multishellEdit.lua", 1, 1, 24, 12, shell, multishell, path)
                else
                    for k, v in pairs(mos.profile.programExecptions) do
                        local suffix = "." .. k
                        if name:sub(-#suffix) == suffix then
                            launchProgram(name, v, 1, 1, 24, 12, path, ...)
                            return
                        end
                    end
                    
                    launchProgram(name, path, 1, 1, 24, 12, ...)
                end
            end
        , mos)
    elseif text == "Settings" then
        local w = launchProgram("Settings", "/os/programs/settings.lua", 20, 5, 30, 13, mos)
        w.text = "Settings"
    end
end

function windowsDropdown:optionPressed(i)
    local text = windowsDropdown:getOptionText(i)
    for name, window in pairs(windows) do
        if name == text then
            window.visible = true
            window:grabFocus()
            window:toFront()
        end
    end
end

local function bindTool(window, callbackFunction)
    customTools[window] = callbackFunction
    callbackFunction(true)
end

local function addToToolbar(control)
    toolBar:addChild(control)
end

local function removeFromToolbar(control)
    toolBar:removeChild(control)
end


local clock_timer_id = os.startTimer(mos.profile.backgroundUpdateTime)
local root = engine.root

engine.input.addResizeEventListener(clock)
engine.input.addRawEventListener(root)

function clock:resizeEvent() 
    self.x = term.getSize() - 5
end

function clock:update()
    self.text = textutils.formatTime(os.time('local'), true)
    clock_timer_id = os.startTimer(mos.profile.backgroundUpdateTime)
    self:redraw() -- Perhaps this shouldn't be a control object
end

function root:rawEvent(data)
    local event = data[1]
    if event == "timer" and data[2] == clock_timer_id then
        clock:update()
    end

    if event == "key" then
        if data[2] == keys.w then
            if engine.input.isKey(keys.leftCtrl) then
                if utils.contains(windows, engine.input.getFocus()) then
                    engine.input.getFocus():close()
                end
            end
        elseif engine.input.isKey(keys.leftAlt) then
            for i = 1, #toolBar.children do
                if data[2] == keys.one + (i - 1) then
                    if toolBar.children[i].next then
                        toolBar.children[i]:next()
                    end
                end
            end
        end
    elseif event == "key_up" then
        if data[2] == keys.leftAlt then
            for i = 1, #toolBar.children do
                if toolBar.children[i] and toolBar.children[i].release then
                    toolBar.children[i]:release()
                end
            end
        end 
    end
end

clock:update()

local frameStyle = engine:newStyle()
frameStyle.backgroundColor = colors.cyan

local bodyStyle = engine:newStyle()
bodyStyle.backgroundColor = colors.lightGray

mos.parentTerm = parentTerm
mos.engine = engine
mos.root = engine.root
mos.addWindow = addWindow
mos.launchProgram = launchProgram
mos.multiWindow = multiWindow
mos.background = background
mos.bindTool = bindTool
mos.addTool = addTool
mos.removeTool = removeTool
mos.addToToolbar = addToToolbar
mos.removeFromToolbar = removeFromToolbar

multiWindow.start(term.current(), engine.start, engine)
