print("MOS is Starting...")

---@class MOS
local mos = {}
function mos.getVersion ()
    return "1.0.0"
end

local src = debug.getinfo(1, "S").short_src
local corePath = ".core"

local engine = require(corePath .. ".engine")
local utils = require(corePath .. ".utils")
local multiProgram = require(corePath .. ".multiProcess.multiProgram")

local termW, termH = term.getSize()

local windows = {}
local customTools = {}
local currentWindow = nil

--MOS
--Profile
---@class Theme
local defaultTheme = {
    backgroundColor = colors.yellow,
    shadow = true,
    shadowColor = colors.gray,
    toolbarColors = {
        text = colors.black,
        background = colors.white,
        clickText = colors.black,
        clickBackground = colors.lightBlue
    },
    windowColors = {
        text = colors.gray,
        background = colors.white,
        focusText = colors.white,
        focusBackground = colors.blue,
        clickBackground = colors.white,
        clickText = colors.black,
    },
    palette = {}
}

---@class Profile
local defaultProfile = {
    backgroundIcon = "os/textures/backgrounds/tux.nfp",
    backgroundPath = "os/textures/backgrounds/melvin.nfp",
    backgroundUpdateTime = 0.1,
    fileExecptions = {
        [".nfp"] = {
            program = "/os/programs//paint.lua",
            fullscreen = true
        },
        [".txt"] = { program = "/rom/programs/edit.lua" }
    },
    theme = "",
    backgroundColor = nil,
    favorites = {

    },
}

local function validateTable(tbl, default)
    for k, v in pairs(default) do
        if tbl[k] == nil then
            tbl[k] = v
        end
    end
end

function mos.loadProfile(file)
    file = file or ".mosdata/profile.sav"
    local profile = utils.loadTable(file)
    mos.profile = profile or {}
    validateTable(mos.profile, defaultProfile)
    if profile == nil then
        mos.saveProfile()
    end
end

function mos.saveProfile(file)
    file = file or ".mosdata/profile.sav"
    utils.saveTable(mos.profile, file)
end

function mos.isFileFavorite(file, profile)
    profile = profile or mos.profile
    return profile.favorites[file] ~= nil
end

function mos.addFileFavorite(file, settings, profile)
    profile = profile or mos.profile
    if profile.favorites[file] ~= nil then return end
    settings = settings or { name = fs.getName(file) }
    profile.favorites[file] = settings
end

function mos.removeFileFavorite(file, profile)
    profile = profile or mos.profile
    profile.favorites[file] = nil
end

function mos.loadTheme(file)
    local theme = utils.loadTable(file)
    if theme == nil then
       mos.theme = defaultTheme
    else
        mos.theme = theme
        mos.profile.theme = file
        validateTable(theme, defaultTheme)
    end

    mos.refreshTheme()
end


local dropdown = engine.Dropdown
local programViewport = require(".core.multiProcess.programViewport")(engine.Control, multiProgram, engine.input)
local programWindow = require(".core.multiProcess.programWindow")(engine.WindowControl, engine.input)

local style = engine.getDefaultStyle()
local clickStyle = engine.getDefaultClickedStyle()
local optionNormalStyle = style:new{}
local optionClickStyle = clickStyle:new{}
local windowStyle = engine.newStyle()
---@type Style
local normalWindowStyle = windowStyle:new{}
---@type Style
local focusWindowStyle = windowStyle:new{}
local clickWindowStyle = engine.newStyle()
local exitButtonClickStyle = engine.newStyle()

---@class MosStyles
mos.styles = {
    style = style,
    clickStyle = clickStyle,
    optionNormalStyle = optionNormalStyle,
    optionClickStyle = optionClickStyle,
    windowStyle = windowStyle,
    normalWindowStyle = normalWindowStyle,
    focusWindowStyle = focusWindowStyle,
    clickWindowStyle = clickWindowStyle,
    exitButtonClickStyle = exitButtonClickStyle
}

mos.refreshTheme = function ()
    local palette = mos.theme.palette
    local redirects = { engine.screenBuffer }--{ engine.screenBuffer, engine.parentTerm, term.native() }
    for _, window in ipairs(windows) do
        table.insert(redirects, window.programViewport.program.window)
    end

    for _, redirect in ipairs(redirects) do
        redirect.setVisible(false)
        local line = " "
        for i = 0, 15 do
            local color = 2 ^ i
            if palette[color] ~= nil then
                redirect.setPaletteColor(color, palette[color])
                line = line .. "u"
            else
                redirect.setPaletteColor(color, term.nativePaletteColor(color))
                line = line .. "n"
            end
        end
        __Global.log(tostring(redirect) .. line)
    end

    --Styles
    local theme = mos.theme
    --Background
    engine.backgroundColor = mos.profile.backgroundColor or theme.backgroundColor
    theme.shadowColor = theme.shadowColor or colors.black

    --Toolbar
    local toolbarColors = theme.toolbarColors

    style.textColor = toolbarColors.text
    style.backgroundColor = toolbarColors.background
    style.shadowColor = theme.shadowColor
    clickStyle.shadowColor = theme.shadowColor

    clickStyle.textColor = toolbarColors.clickText
    clickStyle.backgroundColor = toolbarColors.clickBackground

    optionNormalStyle.shadowColor = theme.shadowColor

    optionClickStyle.shadowColor = theme.shadowColor

    dropdown.optionNormalStyle = optionNormalStyle
    dropdown.optionClickedStyle = optionClickStyle
    dropdown.optionShadow = theme.shadow

    --Window
    local windowColors = theme.windowColors

    programWindow.shadow = theme.shadow
    windowStyle.shadowColor = theme.shadowColor

    normalWindowStyle.backgroundColor = windowColors.background
    normalWindowStyle.textColor = windowColors.text

    focusWindowStyle.backgroundColor = windowColors.focusBackground
    focusWindowStyle.textColor = windowColors.focusText

    clickWindowStyle.backgroundColor = windowColors.clickBackground
    clickWindowStyle.textColor = windowColors.clickText

    exitButtonClickStyle.backgroundColor = colors.red
    exitButtonClickStyle.textColor = colors.white
end

---@type Theme
mos.theme = nil
---@type Profile
mos.profile = nil

mos.loadProfile()
mos.loadTheme(mos.profile.theme)
utils.saveTable(defaultTheme, "os/themes/defaultTheme.thm")

--Objects
--Background
local backgroundIcon = engine.root:addIcon()
backgroundIcon.text = ""
backgroundIcon.texture = paintutils.loadImage(mos.profile.backgroundIcon)
backgroundIcon.anchorW = backgroundIcon.anchor.CENTER
backgroundIcon.anchorH = backgroundIcon.anchor.CENTER


local focusContainer = engine.root:addControl()
focusContainer.expandW = true
focusContainer.mouseIgnore = true
focusContainer.rendering = false

local windowContainer = focusContainer:addControl()
windowContainer.mouseIgnore = true
windowContainer.rendering = false
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

---@type Dropdown
local windowDropdown = dropdown:new{}
addToToolbar(windowDropdown)
windowDropdown.text = "="

---@type Dropdown
local mosDropdown = dropdown:new{}
addToToolbar(mosDropdown)
mosDropdown.text = "MOS"

mos.refreshMosDropdown = function ()
    mosDropdown:clearList()
    mosDropdown:addToList("File Explorer")
    mosDropdown:addToList("Settings")
    mosDropdown:addToList("Shell")

    local l = -1
    for k, v in pairs(mos.profile.favorites) do
        l = #k
    end
    if l > -1 then
        mosDropdown:addToList("-------------", false)
        for k, v in pairs(mos.profile.favorites) do
            local option = mosDropdown:addToList(v.name .. "  ")
            option.pressed = function (o)
                mos.openProgram(v.name, k, false)
                --mos.launchProgram(v.name, k, 2, 2, 24, 12)
            end
            local x = option:addButton()
            x.text = string.char(3)
            x.w = #x.text
            x.h = 1
            x.anchorW = x.anchor.RIGHT
            x.dragSelectable = true
            x.propogateFocusUp = true
            x.pressed = function ()
                mos.removeFileFavorite(k)
                mos.refreshMosDropdown()
                os.queueEvent("mos_favorite_remove")
            end
        end
        mosDropdown:addToList("-------------", false)
    end

    mosDropdown:addToList("Exit")
end

mos.refreshMosDropdown()

local clock = topBar:addControl()
clock.w = #"00:00"
clock.h = 1
clock.anchorW = clock.anchor.RIGHT



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
    backgroundIcon.visible = fullscreen == false
    if fullscreen == true then
        topBar:toFront()
    else
        windowContainer:toFront()
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

local function windowClosed(w, b)
    w.fullscreen = false
    if isFullscreen() == false then
        setFullscreenMode(false)
    end
    windowDropdown:removeFromList(b)
    if customTools[w] ~= nil then
        customTools[w](false)
    end

    table.remove(windows, utils.find(windows, w))
    --windows[w] = nil

    for i = 1, #windowContainer.children do
        local nextW = windowContainer.children[i]
        if nextW.visible == true then
            --engine.input.consumeInput()
            nextW.programViewport.skipEvent = true
            nextW:grabFocus()
            break
        end
    end
end

local function windowVisibilityChanged(w)
    if currentWindow == w then
        if customTools[w] ~= nil then
            customTools[w](w.visible)
        end
    end
end

local function windowFocusChanged(window)
    if window.focus == false then
        return
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
        windowContainer:toFront()
    end
    window:redraw()
end

local function addWindow(w)
    local count = 1
    local text = w.text
    for k, v in ipairs(windows) do
        if v.text == w.text then
            count = count + 1
            w.text = text .. "(" .. count.. ")"
        end
    end
    w.text = w.text .. " "
    local b = windowDropdown:addToList(w.text)
    b.window = w
    local x = b:addButton()
    x.text = "x"
    x.w = #x.text
    x.h = 1
    x.anchorW = x.anchor.RIGHT
    x.dragSelectable = true
    x.propogateFocusUp = true
    x.pressed = function ()
        w:close()
    end

    table.insert(windows, w)

    w:connectSignal(w.closedSignal, windowClosed, w, b)
    w:connectSignal(w.fullscreenChangedSignal, windowFullscreenChanged, w)
    w:connectSignal(w.visibilityChangedSignal, windowVisibilityChanged, w)
    w:connectSignal(w.focusChangedSignal, windowFocusChanged, w)
    w:grabFocus()

    w:redraw()
end


--topBar:addChild(windowsDropdown)

local function launchProgram(name, path, x, y, w, h, ...)
    local window = programWindow:new{}
    windowContainer:addChild(window)

    local viewport = programViewport:new{}
    window:addViewport(viewport)

    window.x = x
    window.y = y
    window.w = w
    window.h = h
    window:refreshMinSize()

    window.style = normalWindowStyle
    window.focusedStyle = focusWindowStyle
    window.unfocusedStyle = normalWindowStyle
    window.exitButton.normalStyle = focusWindowStyle
    window.exitButton.clickedStyle = exitButtonClickStyle
    window.clickedStyle = clickWindowStyle
    window.oldW = w --Fixes bug so that the window doesn't resize to default size
    window.oldH = h
    window.text = name

    local extraEnv = {}

    extraEnv.__mos = mos
    extraEnv.__window = window
    extraEnv.__Global = __Global

    viewport:launchProgram(engine.screenBuffer, path, extraEnv, ...)
    viewport:unhandledEvent({}) -- Forces program to start

    addWindow(window)

    return window
end

local function openProgram(name, path, edit, ...)
    if edit == true then -- Lctrl
        return launchProgram("Edit '" .. name .. "'", "/rom/programs/edit.lua", 1, 1, 24, 12, path)
    else
        local x, y, w, h = 1, 1, 24, 12
        for k, v in pairs(mos.profile.fileExecptions) do
            local suffix = k
            if name:sub(-#suffix) == suffix then
                local program = v.program or path
                if v.fullscreen then
                    x, y = 0, 0
                    w, h = engine.root.w, engine.root.h
                end

                local wi = launchProgram(name, program, x, y, w, h, path, ...)
                if v.fullscreen then
                    wi:setFullscreen(true)
                end
                return wi
            end
        end

        return launchProgram(name, path, x, y, w, h, ...)
    end
end

mos.createPopup = function (title, text, x, y, w, h, parent)
    parent = parent or engine.root

    local popup = parent:addWindowControl()
    popup.text = title

    x = x or 16
    y = y or 7
    w = w or 20
    h = h or 2

    popup.x, popup.y, popup.w, popup.h = x, y, w, h
    popup:refreshMinSize()

    local label = popup:addControl()
    label.expandW = true
    label.y = 1
    label.h = 1
    label.text = text
    label.clipText = true

    --addWindow(popup)
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
        launchProgram("File Explorer", "/os/programs/fileExplorer.lua", 7, 2, 35, 15, openProgram)
    elseif text == "Settings" then
        launchProgram("Settings", "/os/programs/settings.lua", 20, 5, 30, 13)
    end
end

function windowDropdown:optionPressed(i)
    local option = windowDropdown:getOption(i)
    for _, window in ipairs(windows) do
        if window == option.window then
            window.visible = true
            window:grabFocus()
            window:toFront()
        end
    end
end

local function bindTool(window, callbackFunction)
    customTools[window] = callbackFunction
end

local clock_timer_id
local root = engine.root

engine.input.addRawEventListener(root)

function clock:update()
    self.text = textutils.formatTime(os.time('local'), true)
    clock_timer_id = os.startTimer(1.0)
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
mos.openProgram = openProgram
mos.background = background
mos.backgroundIcon = backgroundIcon
mos.bindTool = bindTool
mos.addToToolbar = addToToolbar
mos.removeFromToolbar = removeFromToolbar

__Global.log("Launching MOS")
multiProgram.launchProcess(engine.screenBuffer, engine.start, nil, 1, 1, term.getSize())
local err = multiProgram.start()
__Global.log("MOS Terminated")


mos.saveProfile()

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
    --term.setCursorPos(1, 1)
    term.setCursorBlink(true)
    --term.clear()
    print("Something Went Wrong :(")
    print(err)
end
