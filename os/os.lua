print("MOS is Starting...")

local mos = {}

local engine = require(".core.engine")
local utils = require(".core.utils")
local multiProgram = require(".core.multiProcess.multiProgram")

local termW, termH = term.getSize()

local style = engine:getDefaultStyle()
style.backgroundColor = colors.white

local clickedStyle = engine:getDefaultClickedStyle()
clickedStyle.textColor = colors.black
clickedStyle.backgroundColor = colors.lightBlue

--MOS

--Profile
local function validateProfile(profile, defaultProfile)
    for k, v in pairs(defaultProfile) do
        if profile[k] == nil then
            profile[k] = v
        end
    end
end

function mos.loadProfile(defaultProfile)
    mos.profile = utils.loadTable("os/profiles/profile.sav") or {}
    validateProfile(mos.profile, defaultProfile)
end

function mos.saveProfile()
    utils.saveTable(mos.profile, "os/profiles/profile.sav")
end

local defaultProfile = {
    backgroundPath = "os/textures/backgrounds/melvin.nfp",
    backgroundUpdateTime = 0.1,
    fileExecptions = {
        nfp = "/rom/programs/fun/advanced/paint.lua",
        txt = "/rom/programs/edit.lua"
    }
}

mos.loadProfile(defaultProfile)

--Background
local background = engine.getObject("icon"):new{}
background.text = ""

function background:treeEntered()
    self.texture = paintutils.loadImage(mos.profile.backgroundPath)
end

engine.root:addChild(background)
background.y = 1
background.x = 0

local focusContainer = engine.root:addControl()
focusContainer.expandW = true
focusContainer.mouseIgnore = true
focusContainer.rendering = false

local windowsContainer = focusContainer:addControl()
windowsContainer.mouseIgnore = true
windowsContainer.rendering = false
-- windowsContainer.y = 1

--Top Bar
local topBar = focusContainer:addControl()
topBar.rendering = false
topBar.mouseIgnore = true
topBar.expandW = true

--Tool Bar
local toolBar = topBar:addHContainer()
toolBar.rendering = true
toolBar.background = true
toolBar.expandW = true
toolBar.h = 1
toolBar.separation = 1
toolBar.mouseIgnore = true

local dropdown = engine.getObject("dropdown")

local mosDropdown = dropdown:new{}
mosDropdown.text = "MOS"
mosDropdown.w = 3
--dropdown:addToList("Test")
mosDropdown:addToList("File Explorer")
mosDropdown:addToList("Settings")
mosDropdown:addToList("Shell")
mosDropdown:addToList("Exit")


local windowsDropdown = dropdown:new{}
windowsDropdown.text = "="
windowsDropdown.w = #windowsDropdown.text

local clock = topBar:addControl() -- TODO add to topbar instead
clock.x = termW - 5
clock.h = 1

local windows = {}
local windowId = 1
local customTools = {}
local currentWindow = nil

local function isFullscreen()
    local fullscreen = false
    for k, v in pairs(windows) do
        if v.fullscreen == true then
            fullscreen = true
            break
        end
    end
    return fullscreen
end

local function setFullscreenMode(fullscreen)
    background.visible = fullscreen == false
    if fullscreen == true then
        topBar:toFront()
    else
        windowsContainer:toFront()
    end
end

local function windowFullscreenChanged(w)
    setFullscreenMode(isFullscreen())
    --local render = w.fullscreen == false
    --w.rendering = render
    --w.label.visible = render
   -- w.scaleButton.visible = render
    --w.exitButton.visible = render
    --w.minimizeButton.visible = render

end

local function windowClosed(w, text)
    w.fullscreen = false
    if isFullscreen() == false then
        setFullscreenMode(false)
    end
    windowsDropdown:removeFromList(text)
    if customTools[w] ~= nil then
        customTools[w](false)
    end
    windows[w] = nil

    for i = 1, #windowsContainer.children do
        local nextW = windowsContainer.children[i]
        if nextW.visible == true then
            engine.input.consumeInput()
            nextW.programViewport.skipEvent = true
            nextW:grabFocus()
            break
        end
    end
end

local function windowVisibilityChanged(w)
    if currentWindow == w then
        if customTools[w] ~= nil then
            --customTools[w](w.visible)
        end
    end
end

local function windowFocusChanged(window)
    if window.focus == false then
        return false
    end

    if currentWindow ~= window then
        if customTools[currentWindow] ~= nil then
            customTools[currentWindow](false)
        end
        if customTools[window] ~= nil then
            customTools[window](true)
        end
    end

    currentWindow = window
    if isFullscreen() == false then
        windowsContainer:toFront()
    end
    window:redraw()
end

local function addWindow(w)
    local count = 1
    for key, _ in pairs(windows) do
        count = count + 1
    end

    local text = w.text
    text = windowId .. "." .. w.text

    windows[text] = w
    w:connectSignal(w.closedSignal, windowClosed, w, text)
    w:connectSignal(w.fullscreenChangedSignal, windowFullscreenChanged, w)
    w:connectSignal(w.visibilityChangedSignal, windowVisibilityChanged, w)
    w:connectSignal(w.focusChangedSignal, windowFocusChanged, w)
    w:grabFocus()

    windowsDropdown:addToList(text)

    windowId = windowId + 1
    w:redraw()
end

local function toolbarChildFocusChanged(c)
    if c.focus == true then
        topBar:toFront()
    end
end

local function addToToolbar(control)
    control:connectSignal(control.focusChangedSignal, toolbarChildFocusChanged, control)
    toolBar:addChild(control)
end

local function removeFromToolbar(control)
    toolBar:removeChild(control)
end

addToToolbar(windowsDropdown)
addToToolbar(mosDropdown)
--topBar:addChild(windowsDropdown)

local programViewport = require(".core.multiProcess.programViewport")(engine:getObjects()["control"], multiProgram, engine.input)
local programWindow = require(".core.multiProcess.programWindow")(engine:getObjects()["windowControl"], programViewport)

local focusedWindowStyle = engine:newStyle()
focusedWindowStyle.backgroundColor = colors.blue
focusedWindowStyle.textColor = colors.white
local unfocusedWindowStyle = engine:newStyle()
unfocusedWindowStyle.backgroundColor = colors.white
unfocusedWindowStyle.textColor = colors.black
local exitButtonClickedStyle = engine:newStyle()
exitButtonClickedStyle.backgroundColor = colors.red
exitButtonClickedStyle.textColor = colors.white

local function launchProgram(name, path, x, y, w, h, ...)
    local window = programWindow:new{}
    windowsContainer:addChild(window)

    local viewport = programViewport:new{}
    window:addViewport(viewport)

    window.x = x
    window.y = y
    window.w = w
    window.h = h
    if w < window.minW then
        window.minW = w
    end
    if h < window.minH then
        window.minH = h
    end    window.style = unfocusedWindowStyle
    window.focusedStyle = focusedWindowStyle
    window.unfocusedStyle = unfocusedWindowStyle
    window.exitButton.clickedStyle = exitButtonClickedStyle
    window.oldW = w --Fixes bug so that the window doesn't resize to default size
    window.oldH = h
    window.text = name

    local extraEnv = {}

    extraEnv.__mos = mos
    extraEnv.__window = window

    viewport:launchProgram(engine.screenBuffer, path, extraEnv, ...)

    addWindow(window)

    return window
end

function mosDropdown:optionPressed(i)
    local text = mosDropdown:getOptionText(i)
    if text == "Test" then
        launchProgram("Shell", "test", 2, 2, 200, 19)
    elseif text == "Shell" then
        launchProgram("Shell", "rom/programs/advanced/multishell.lua", 2, 2, 20, 10)
    elseif text == "Exit" then
        multiProgram.exit()
    elseif text == "File Explorer" then
        --launchProgram("WO", "/os/programs/test.lua", 1, 1, 20, 20)
        
        launchProgram("File Explorer", "/os/programs/fileExplorer.lua", 7, 2, 35, 15,
            function(path, name, ...) -- This function is called when the user has chosen a file
                if engine.input.isKey(keys.leftCtrl) then -- Lctrl
                    launchProgram("Edit '" .. name .. "'", "/rom/programs/edit.lua", 1, 1, 24, 12, path)
                else
                    for k, v in pairs(mos.profile.fileExecptions) do
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
        launchProgram("Settings", "/os/programs/settings.lua", 20, 5, 30, 13, mos)
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
    --callbackFunction(true)
end

local clock_timer_id = os.startTimer(mos.profile.backgroundUpdateTime)
local root = engine.root

engine.input.addResizeEventListener(clock)
engine.input.addRawEventListener(root)

function clock:resizeEvent()
    --windowsDropdown.x = term.getSize() - 2
    self.x = term.getSize() - 5
end

clock:resizeEvent()

function clock:update()
    term.redirect(engine.parentTerm)
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
        elseif data[2] == keys.f4 then
            if currentWindow ~= nil then
                currentWindow:setFullscreen(currentWindow.fullscreen == false)
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

mos.engine = engine
mos.root = engine.root
mos.addWindow = addWindow
mos.launchProgram = launchProgram
mos.background = background
mos.bindTool = bindTool
mos.addToToolbar = addToToolbar
mos.removeFromToolbar = removeFromToolbar

multiProgram.launchProcess(engine.screenBuffer, engine.start, nil, 1, 1, term.getSize())
local err = multiProgram.start()

if err == nil or err == "Terminated" then
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 1)
    term.setCursorBlink(true)
    term.clear()
    print("MOS Terminated...")
else
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 1)
    term.setCursorBlink(true)
    term.clear()
    print("Something Went Wrong :(")
    print(err)
end
