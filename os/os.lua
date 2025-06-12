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

mos.loadProfile()
if mos.profile == nil then
    mos.profile = {}
    mos.profile.backgroundPath = "os/textures/backgrounds/melvin.nfp"
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

--Main
local main = engine.root:addVContainer()
main.expandW = true
main.y = 0

function main:update()
    if engine.input.isKey(keys.leftCtrl) and engine.input.isKey(keys.tab) then
        local a = b.c
    end
end

--Top Bar
local topBar = main:addHContainer()
topBar.rendering = true
topBar.background = true
topBar.expandW = true
topBar.h = 1

local dropdown = engine.root:addDropdown()
dropdown.text = "MOS"
dropdown.w = 3
--dropdown:addToList("New")
dropdown:addToList("File Explorer")
dropdown:addToList("Settings")
dropdown:addToList("Shell")
dropdown:addToList("Exit")
--dropdown:addToList("-Open Windows-", false)

local windowsDropdown = engine.root:addDropdown()
windowsDropdown.text = "Windows"
windowsDropdown.w = 7
windowsDropdown.x = 4

--dropdown:addToList("Exit")
local windows = {}

local function addWindow(w)
    local count = 1
    for key, _ in pairs(windows) do
        count = count + 1
    end
    local text = count .. "." .. w.text
    windows[text] = w
    w.closed = function(o)
        windowsDropdown:removeFromList(text)
        windows[text] = nil
    end
    windowsDropdown:addToList(text)
    w:grabFocus()
    windowsDropdown:toFront()
end

local function launchProgram(path, x, y, w, h, ...)
    local parentTerm = engine.screenBuffer
    local parent = engine.root
    local w = multiWindow.launchProgram(parentTerm, parent, path, 2, 2, 20, 10, ...)
    addWindow(w)
    return w
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
        local w = launchProgram("rom/programs/advanced/multishell.lua", 2, 2, 20, 10)
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
        local fileExplorer = launchProgram("/os/programs/fileExplorer.lua", 1, 1, 40, 15,
            function(path, name) -- This function is called when the user has chosen a file
                if engine.input.isKey(keys.leftCtrl) then -- Lctrl
                    local w = launchProgram("/rom/programs/edit.lua", 0, 0, 30, 18, path)
                    w.text = "Edit '" .. name .. "'" 
                else
                    local w = launchProgram(path, 2, 2, 20, 10)
                    w.text = name
                end
            end
        )
        fileExplorer.text = "File Explorer"
    elseif text == "Settings" then
        local w = launchProgram("/os/programs/settings.lua", 1, 1, 40, 15, mos)
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

local clock = engine.root:addControl() -- TODO add to topbar instead
clock.x = termW - 5

clock.h = 1

engine.input.addResizeEventListener(clock)

function clock:resizeEvent() 
    self.x = term.getSize() - 5
end


function clock:update()
    self.text = textutils.formatTime(os.time('local'), true)
    --self:redraw()
end

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

multiWindow.start(term.current(), engine.start, engine)