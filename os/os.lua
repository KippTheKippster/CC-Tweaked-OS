print("MOS is Starting...")

---@class MOS
local mos = {}
function mos.getVersion ()
    return "1.0.0"
end

mos.latestMosOption = ""

local runningProgram = shell.getRunningProgram()
local mosPath =  "/" .. fs.getDir(fs.getDir(runningProgram))
local mosDotPath = "." .. mosPath:gsub("/", ".")
local corePath = mosPath .. "/core"
_G.corePath = corePath
local coreDotPath = mosDotPath .. ".core"
local osPath = mosPath .. "/os"
local osDotPath = mosDotPath .. ".os"

---comment
---@param name string
---@return string
local function toMosPath(name)
    return fs.combine(mosPath, name)
end

---@param name string
---@return string
local function toOsPath(name)
    return fs.combine(osPath, name)
end

---@param name string
---@return string
local function toCorePath(name)
    return fs.combine(corePath, name)
end

---@type Engine
local engine = require(coreDotPath .. ".engine")

__Global.mosDotPath = mosDotPath

---@type MultiProgram
local multiProgram = require(coreDotPath .. ".multiProcess.multiProgram")

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
    backgroundIcon = toOsPath("/textures/backgrounds/tux.nfp"),
    backgroundUpdateTime = 0.1,
    fileExecptions = {
        [".nfp"] = {
            program = toOsPath("/programs/paint.lua"),
            fullscreen = false
        },
        [".txt"] = { program = "/rom/programs/edit.lua" }
    },
    theme = "",
    backgroundColor = nil,
    favorites = {

    },
    showDotFiles = true,
    showRomFiles = true,
    showMosFiles = true,
}

local function validateTable(tbl, default)
    for k, v in pairs(default) do
        if tbl[k] == nil then
            tbl[k] = v
        end
    end
end

---comment
---@param file string|nil
function mos.loadProfile(file)
    file = file or "/.mosdata/profiles/profile.sav"
    local profile = engine.utils.loadTable(file)
    mos.profile = profile or {}
    validateTable(mos.profile, defaultProfile)
    if profile == nil then
        mos.saveProfile()
    end
end

---comment
---@param file string|nil
function mos.saveProfile(file)
    file = file or "/.mosdata/profiles/profile.sav"
    engine.utils.saveTable(mos.profile, file)
end

---comment
---@param file string
---@param profile Profile|nil
---@return boolean
function mos.isFileFavorite(file, profile)
    profile = profile or mos.profile
    return profile.favorites[file] ~= nil
end

---comment
---@param file string
---@param settings table|nil
---@param profile Profile|nil
function mos.addFileFavorite(file, settings, profile)
    profile = profile or mos.profile
    if profile.favorites[file] ~= nil then return end
    settings = settings or { name = fs.getName(file) }
    profile.favorites[file] = settings
end

---comment
---@param file string
---@param profile Profile|nil
function mos.removeFileFavorite(file, profile)
    profile = profile or mos.profile
    profile.favorites[file] = nil
end

---comment
---@param file string
function mos.loadTheme(file)
    local theme = engine.utils.loadTable(file)
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
local programViewport = require(coreDotPath .. ".multiProcess.programViewport")(engine.Control, multiProgram, engine.input)
local programWindow = require(coreDotPath .. ".multiProcess.programWindow")(engine.WindowControl, engine.input)

local style = engine.getDefaultStyle()
local clickStyle = engine.getDefaultClickedStyle()
local optionNormalStyle = style:new()
local optionClickStyle = clickStyle:new()
local windowStyle = engine.newStyle()
windowStyle.shadowOffsetU = 0
---@type Style
local normalWindowStyle = windowStyle:new()
---@type Style
local focusWindowStyle = windowStyle:new()
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
        for i = 0, 15 do
            local color = 2 ^ i
            if palette[color] ~= nil then
                redirect.setPaletteColor(color, palette[color])
            else
                redirect.setPaletteColor(color, term.nativePaletteColor(color))
            end
        end
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
    style.shadowOffsetU = 1
    
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

    normalWindowStyle.shadowOffsetU = 0
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
engine.utils.saveTable(defaultTheme, toOsPath("/themes/defaultTheme.thm"))

--Objects
--Background
local backgroundIcon = engine.root:addIcon()
backgroundIcon.text = ""
backgroundIcon.texture = paintutils.loadImage(mos.profile.backgroundIcon)
backgroundIcon.anchorW = backgroundIcon.Anchor.CENTER
backgroundIcon.anchorH = backgroundIcon.Anchor.CENTER


local focusContainer = engine.root:addControl()
focusContainer.expandW = true
focusContainer.mouseIgnore = true
focusContainer.rendering = false

local windowContainer = focusContainer:addControl()
windowContainer.mouseIgnore = true
windowContainer.rendering = false

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
local windowDropdown = dropdown:new()
addToToolbar(windowDropdown)
windowDropdown.text = "="

---@type Dropdown
local mosDropdown = dropdown:new()
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
            local option = mosDropdown:addToList(v.name .. " ")
            option.pressed = function (o)
                if fs.isDir(k) then
                    mos.openDir(k)
                elseif engine.input.isKey(keys.leftCtrl) then
                    mos.editProgram(k)
                elseif engine.input.isKey(keys.leftAlt) then
                    mos.openProgramWithArgs(k)
                else
                    mos.openProgram(k)
                end
            end
            local x = option:addButton()
            x.text = string.char(3)
            x.w = #x.text
            x.h = 1
            x.anchorW = x.Anchor.RIGHT
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

    --mosDropdown:addToList("Reboot")
    mosDropdown:addToList("Exit")
end

mos.refreshMosDropdown()

local clock = topBar:addControl()
clock.w = #"00:00"
clock.h = 1
clock.anchorW = clock.Anchor.RIGHT

local function isFullscreen()
    return mos.fullscreenWindow ~= nil
end

local function setFullscreenMode(fullscreen)
    backgroundIcon.visible = fullscreen == false
    if fullscreen == true then
        topBar:toFront()
        topBar.style = focusWindowStyle
    else
        windowContainer:toFront()
        topBar.style = style
    end

    for _, child in ipairs(toolBar.children) do
        if child.normalStyle then
            child.normalStyle = topBar.style
        end
    end
end


---comment
---@param w ProgramWindow
local function windowFullscreenChanged(w)
    if w.fullscreen == false then
        if w == mos.fullscreenWindow then
            mos.fullscreenWindow = nil
        end
    else
        mos.fullscreenWindow = w
    end

    setFullscreenMode(isFullscreen())
end

---comment
---@param w WindowControl
---@param b Button
local function windowClosed(w, b)
    w.fullscreen = false
    windowFullscreenChanged(w) -- This is a bit of a hack, but it doesn't seem like the fullscreen signal is called right after?
    if isFullscreen() == false then
        setFullscreenMode(false)
    end
    windowDropdown:removeFromList(b)
    if customTools[w] ~= nil then
        customTools[w](false)
    end

    table.remove(windows, engine.utils.find(windows, w))

    w.visible = false
    for i = 0, #windowContainer.children - 1 do
        local nextW = windowContainer.children[#windowContainer.children - i]
        if nextW.visible == true then
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

---comment
---@param window ProgramWindow
local function windowFocusChanged(window)
    multiProgram.resumeProcess(window.programViewport.program, { "mos_window_focus", window.focus })
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
    if not isFullscreen() then
        windowContainer:toFront()
    end
    window:queueDraw()
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
    x.anchorW = x.Anchor.RIGHT
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

    w:queueDraw()
end

---Creates a new window running the program of path, unless you want to specify the position of the window use 'openProgram' instead
---@param name string
---@param path string
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param ... any
---@return ProgramWindow
local function launchProgram(name, path, x, y, w, h, ...)
    local window = programWindow:new()
    windowContainer:addChild(window)

    local viewport = programViewport:new()
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
    --viewport:unhandledEvent({}) -- Forces program to start

    addWindow(window)

    return window
end

mos.windowStartX = 1
mos.windowStartY = 2

local function nextWindowTransform()
    local screenW, screenH = mos.root.w, mos.root.h
    local x, y, w, h = mos.windowStartX, mos.windowStartY, math.floor(screenW * 0.66), math.floor(screenH * 0.75)
    mos.windowStartX = mos.windowStartX + 1
    mos.windowStartY = mos.windowStartY + 1
    if x + w > screenW - 2 then
        mos.windowStartX = 1
    end

    if y + h > screenH - 2 then
        mos.windowStartY = 2
    end
    return x, y, w, h
end

---Opens a new window running the program expected for the file type (i.e. paint for nfp files, for lua files it will run as expected)
---@param path string
---@param ... any
---@return ProgramWindow
local function openProgram(path, ...)
    local x, y, w, h = nextWindowTransform()
    local file = fs.getName(path)
    for k, v in pairs(mos.profile.fileExecptions) do
        local suffix = k
        if file:sub(-#suffix) == suffix then
            local program = v.program or path
            if v.fullscreen then
                x, y = 0, 0
                w, h = engine.root.w, engine.root.h
            end

            local wi = launchProgram(file, program, x, y, w, h, path, ...)
            if v.fullscreen then
                wi:setFullscreen(true)
            end
            return wi
        end
    end

    return launchProgram(file, path, x, y, w, h, ...)
end

---@param path string
---@return WindowControl
function mos.editProgram(path)
    local x, y, w, h = nextWindowTransform()
    return launchProgram("Edit '" .. fs.getName(path) .. "'", "/rom/programs/edit.lua", x, y, w, h, path)
end

---comment
---@param path string
---@return WindowControl
function mos.openProgramWithArgs(path)
    return mos.launchProgram("Args '" .. fs.getName(path) .. "'", toOsPath("programs/writeArgs.lua"), 3, 3, 24, 2, function (data)
        mos.openProgram(path, table.unpack(data))
    end, path)
end

---comment
---@param path string
---@param callback function|nil
---@return ProgramWindow
function mos.openDir(path, callback)
    local w = mos.openProgram(toOsPath("/programs/files.lua"), callback, { dir =  path })
    w.text = "File Explorer"
    return w
end

---comment
---@param title string
---@param callback function
---@param saveMode boolean|nil
---@param dir string|nil
---@return ProgramWindow
function mos.openFileDialogue(title, callback, saveMode, dir)
    local w = mos.openProgram(toOsPath("programs/files.lua"), callback, { saveMode = saveMode, dir = dir })
    w.text = title
    return w
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
end

function mosDropdown:optionPressed(i)
    local text = mosDropdown:getOptionText(i)
    mos.latestMosOption = text
    if text == "Shell" then
        openProgram("/rom/programs/advanced/multishell.lua").text = "Shell"
    elseif text == "Exit" then
        multiProgram.exit()
    elseif text == "Reboot" then
        multiProgram.exit()
        shell.run(osPath .. "/os.lua")
    elseif text == "File Explorer" then
        mos.openDir("")
    elseif text == "Settings" then
        openProgram(toOsPath("/programs/settings.lua")).text = "Settings"
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
                if engine.utils.contains(windows, engine.input.getFocus()) then
                    engine.input.getFocus():close()
                end
            end
        elseif data[2] == keys.f4 then
            if currentWindow ~= nil then
                currentWindow:setFullscreen(currentWindow.fullscreen == false)
            end
        elseif data[2] == keys.s then
            if engine.input.isKey(keys.leftAlt) then
                if mos.quickSearch:isOpen() then
                    mos.quickSearch:close()
                else
                    mos.quickSearch:open()
                end
            end
            --mos.quickSearch:next()
        elseif data[2] == keys.enter then
            mos.quickSearch:select()
        elseif data[2] == keys.up then
            mos.quickSearch:previous()
        elseif data[2] == keys.down then
            mos.quickSearch:next()
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
    elseif event == "mouse_up" then
        if mos.quickSearch:isOpen() then
            mos.quickSearch:close()
        end
    end
end

clock:update()

mos.engine = engine
mos.root = engine.root
mos.addWindow = addWindow
mos.launchProgram = launchProgram
mos.openProgram = openProgram
mos.backgroundIcon = backgroundIcon
mos.bindTool = bindTool
mos.addToToolbar = addToToolbar
mos.removeFromToolbar = removeFromToolbar
mos.toMosPath = toMosPath
mos.toOsPath = toOsPath
mos.toCorePath = toCorePath
---@type ProgramWindow|nil
mos.fullscreenWindow = nil
mos.quickSearch = require(osDotPath .. ".programs.quickSearch")(mos)
engine.root:addChild(mos.quickSearch)
mos.quickSearch.y = 1

__Global.log("Launching MOS")
multiProgram.launchProcess(engine.screenBuffer, engine.start, nil, 1, 1, term.getSize())
local err = multiProgram.start()
__Global.log("MOS Terminated")
engine.stop()

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

if mos.latestMosOption == "Reboot" then
    shell.run(mosPath .. "/mos.lua")
end
