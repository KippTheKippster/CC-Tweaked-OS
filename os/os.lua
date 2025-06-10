print("mos is starting...")
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
local mos = {}

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
local background = engine.root:addIcon()
background.y = 1
background.x = 0
background.text = ""
function background:update() --TODO, fix it so it textures can be loaded at startup
    if self.texture == nil then
        self.texture = paintutils.loadImage(mos.profile.backgroundPath)
    end
end

--Main
local main = engine.root:addVContainer()
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
topBar.w = termW
topBar.h = 1

local dropdown = engine.root:addDropdown()
dropdown.text = "MOS"
dropdown.w = 10
--dropdown:addToList("New")
dropdown:addToList("File Explorer")
dropdown:addToList("Shell")
dropdown:addToList("Settings")
dropdown:addToList("Exit")
dropdown:addToList("-Open Windows-", false)
--dropdown:addToList("Exit")
local windows = {}

local function addWindow(w)
    --main:addChild(w)
    local count = 1
    for key, _ in pairs(windows) do
        count = count + 1
    end
    local text = count .. ". " .. w.text
    windows[text] = w
    w.closed = function(o)
        dropdown:removeFromList(text)
        windows[text] = nil
    end
    dropdown:addToList(text)
    engine.input.grabControlFocus(w)
    dropdown:toFront()
    --w:grabFocus()
end

function dropdown:click()
    engine.getObject("dropdown").click(self)
    dropdown:toFront()
end

function dropdown:optionPressed(i)
    local parent = engine.root
    local text = dropdown:getOptionText(i)
    if text == "New" then
        local w = engine.root:addWindowControl()
    elseif text == "Shell" then
        local w = multiWindow.launchProgram(parent, "rom/programs/advanced/multishell.lua", 2, 2, 20, 10)
        w.text = "Shell"
        addWindow(w)
    elseif text == "Exit" then
        --engine.stop()
        multiWindow.exit()
        term.clear()
        --shell.run("rom/programs/shell.lua")
        --multiWindow.exit()
    elseif text == "File Explorer" then
        local fileExplorer = multiWindow.launchProgram(parent, "/os/programs/fileExplorer.lua", 1, 1, 40, 15,
        function(path, name) -- This function is called when the user has chosen a file
            if engine.input.isKey(341) then -- Lctrl
                local w = multiWindow.launchProgram(parent, "/rom/programs/edit.lua", 0, 0, 30, 18, path)
                w.text = "Edit '" .. name .. "'" 
                addWindow(w)
            else
                local w = multiWindow.launchProgram(parent, path, 2, 2, 20, 10)
                w.text = name
                addWindow(w)
            end
        end)
        fileExplorer.text = "File Explorer"
        addWindow(fileExplorer)
    elseif text == "Settings" then
        local w = multiWindow.launchProgram(parent, "/os/programs/settings.lua", 1, 1, 40, 15, mos)
        w.text = "Settings"
        addWindow(w)
    else
        for name, window in pairs(windows) do
            if name == text then
                window.visible = true
                window:toFront()
                --window:grabFocus() -- TODO FIX THIS!
            end
        end
    end
end

local clock = engine.root:addControl() -- TODO add to topbar instead
clock.x = termW - 5

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

mos.engine = engine
mos.root = engine.root
mos.addWindow = addWindow
mos.multiWindow = multiWindow
mos.background = background

--multiWindow.launchProcess(engine.start, 1, 1, w, h, engine)
multiWindow.start(engine.start, engine)