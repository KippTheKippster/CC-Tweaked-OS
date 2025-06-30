local engine = require(".core.engine")
local utils = require(".core.utils")
local currentPath = ""
local paths = {}

local args = {...}
local callbackFunction = args[1]
local mos = __mos

if mos == nil then
    printError("File Explorer must be opened with MOS!")
    return
end

local filter = ""

--local main = engine.root:addControl()
--main.expandW = true
--main.expandH = true
local inputReader = {}

--engine.input.addScrollListener(inputReader)
engine.input.addResizeEventListener(inputReader)
engine.input.addCharListener(inputReader)
engine.input.addKeyListener(inputReader)

--background
local background = engine.root:addControl()
background.text = ""
background.expandW = true
background.expandH = true

--tools
local toolsStyle = engine:newStyle() 
toolsStyle.backgroundColor = colors.white

local tools = engine.root:addHContainer()
tools.rendering = true
tools.h = 1
tools.w = 1
tools.expandW = true
tools.text = "  /"
tools.style = toolsStyle
tools.separation = 1

local backButton = tools:addButton()
backButton.w = 1
backButton.h = 1
backButton.text = '<'
backButton.normalStyle = toolsStyle



--files
local vContainer = engine.root:addVContainer()
vContainer:toBack()
vContainer.visible = true
vContainer.style.backgroundColor = colors.black

vContainer.x = 0
vContainer.y = 0
vContainer.w = 1
vContainer.h = 1
--vContainer.w = 51
--vContainer.h = 99
vContainer.expandW = true
vContainer.expandH = true

background:toBack()

local style = engine:newStyle()
style.backgroundColor = colors.black
style.textColor = colors.white

local clickedStyle = engine:newStyle()
clickedStyle.backgroundColor = colors.lightGray
clickedStyle.textColor = colors.white

local selectedStyle = engine:newStyle()
selectedStyle.backgroundColor = colors.gray
selectedStyle.textColor = colors.white

local button = engine.getObject("button")

local fileButton = button:new{}
fileButton.h = 1
--fileButton.w = 52
fileButton.w = 1
fileButton.expandW = true
fileButton.selected = false
fileButton.normalStyle = style
fileButton.clickedStyle = clickedStyle
fileButton.selectedStyle = selectedStyle

local selection = nil
local startSelectionFile = ""
local currentLineEdit = nil

function fileButton:click()
    button.click(self)
    if selection ~= nil and selection ~= self then
        selection.style = selection.normalStyle
        selection = nil
    end
    selection = self
end

function fileButton:up()
    if selection == self then
        self.style = self.selectedStyle
    end
end

local dirStyle = style:new{}
dirStyle.textColor = colors.green

local dirSelectedStyle = selectedStyle:new()
dirSelectedStyle.textColor = colors.lime

local dirButton = fileButton:new{}
dirButton.normalStyle = dirStyle
dirButton.selectedStyle = dirSelectedStyle

local function scrollToBottom()
    vContainer.y = -#vContainer.children
end

local function scrollToTop()
    vContainer.y = 1
end

local function scrollToControl(control, center)
    local w, h = term.getSize()
    local offset = 0
    if center == true then
        offset = h / 2
    end

    if control.globalY <= 0 then
        vContainer.y = -control.y + 1 + offset
    elseif control.globalY >= h then
        vContainer.y = -control.y + h - 1 + offset
    end
end

local function isControlOnScreen(c)
    local w, h = term.getSize()
    if c.globalY <= 0 or c.globalY >= h then
        return false
    end
    return true
end

local function openFolder(path)
    selection = nil

    if fs.exists(path) == false then
        currentPath = ""
        openFolder("")
        return
    end

    vContainer.y = 1
    tools.text = "  /" .. path
    for i = 1, #vContainer.children do
        vContainer.children[1]:remove()
    end
    vContainer.children = {}

    local names = fs.list(path, "r")
    local files = {}
    local dirs = {}
    for i = 1, #names do
        if filter == "" or names[i]:find(filter) ~= nil then
            if fs.isDir(path .. names[i]) then
                table.insert(dirs, names[i])
            else
                table.insert(files, names[i])
            end
        end
    end

    local w, h = term.getSize()

    for i = 1, #dirs do
        local b = dirButton:new{}
        b.text = dirs[i]
        vContainer:addChild(b)
        b.style = dirStyle
        if b.text == startSelectionFile then
            b:click()
            b:up()
            scrollToControl(b, true)
        end
    end

    for i = 1, #files do
        local b = fileButton:new{}
        b.text = files[i]
        vContainer:addChild(b)
        b.style = style
        if b.text == startSelectionFile then
            b:click()
            b:up()
            scrollToControl(b, true)
        end
    end

    inputReader:scroll(0, 0, 0)
    startSelectionFile = ""
end

local function openCurrentFolder()
    currentPath = ""
    for i = 1, #paths do
        currentPath = currentPath .. paths[i] .. "/"
    end
    openFolder(currentPath)
end

function backButton:pressed()
    if (#paths <= 0) then 
        filter = ""
        openCurrentFolder()
    else
        table.remove(paths, #paths)
        openCurrentFolder()
    end
end

local searchEdit = tools:addLineEdit()
searchEdit.inheritStyle = false
searchEdit.expandW = true
searchEdit.visible = false
local editStyle = engine.newStyle()
editStyle.backgroundColor = colors.white
editStyle.textColor = colors.black
searchEdit.focusStyle = editStyle

function searchEdit:focusChanged()
    --engine.getObject("lineEdit").focusChanged(self)
    if self.focus == true then
        self:grabCursorControl()
        self.trueText = ""
    else
        --self.trueText = ""
        self:releaseCursorControl()
    end
    self.visible = self.focus
end

function searchEdit:trueTextChanged()
    if self.visible == false then return end

	engine.getObject("lineEdit").trueTextChanged(self)
    if self.text == "" then
        self:releaseFocus()
    end
    filter = self.text
    openCurrentFolder()
end

function inputReader:scroll(dir)
    local newY = vContainer.y - dir
    local w, h = term.getSize()
    term.setTextColour(colors.white)
    if #vContainer.children - h < 0 then
        vContainer.y = 1
        return
    end

    if newY > 1 then
        vContainer.y = 1
        return
    elseif newY < h - #vContainer.children then
        vContainer.y = h - #vContainer.children
        return
    end
    vContainer.y = newY
end

local root = engine.root

function root:scroll(dir)
    inputReader:scroll(dir)
end

function inputReader:resizeEvent()
    inputReader:scroll(0, 0, 0)
end

function inputReader:char(char)
    if currentLineEdit == nil then
        searchEdit:grabFocus()
    end
end

local function traverse(dir)
    if selection == nil then
        if dir > 0 then
            selection = vContainer.children[1]
            scrollToTop()
        else
            selection = vContainer.children[#vContainer.children]
            scrollToBottom()
        end
        dir = 0
    end

    local i = utils.find(vContainer.children, selection)
    if i == nil then
        return
    end

    local next = vContainer.children[i + dir]
    if next ~= nil then
        next:click()
        next:up()
        scrollToControl(next)
    end
end


function fileButton:doublePressed()
    callbackFunction(currentPath .. self.text, self.text)--Left CTRL
end

function dirButton:doublePressed()
    filter = ""
    table.insert(paths, self.text)
    openCurrentFolder(currentPath)
end


openFolder("")

local toolDropdown = mos.engine.getObject("dropdown"):new{}

local function windowFocusChanged(focus)
    if focus then
        mos.addToToolbar(toolDropdown)
    else
        mos.removeFromToolbar(toolDropdown)
    end
end

mos.bindTool(__window, windowFocusChanged)

local function isPathValid(path)
    if fs.exists(path) == false then return false end
    if fs.isReadOnly(path) == true then return false end
    return true
end

local function removeCurrentSelection()
    if selection == nil then return end
    if isPathValid(currentPath .. selection.text) == false then return end
    fs.delete(currentPath .. selection.text)
    selection:remove()
end

function toolDropdown:optionPressed(i)
    if currentLineEdit ~= nil then
        currentLineEdit:releaseFocus()
    end

    local text = toolDropdown:getOptionText(i)
    if text == "Open w/ args" then
        if selection == nil then return end
        if fs.isDir(currentPath .. selection.text) then return end 
        writeArgs = mos.launchProgram("Write Args", "/os/programs/writeArgs.lua", 3, 3, 24, 2, function (...)
            if selection == nil then return end
            if isPathValid(currentPath .. selection.text) == false then return end
            callbackFunction(currentPath .. selection.text, selection.text, ...)
        end)
        return
    elseif text == "New File" then
        local edit = vContainer:addLineEdit()
        scrollToBottom()
        __window:grabFocus()
        edit:grabFocus()
        --edit:toBack()
        edit.expandW = true
        currentLineEdit = edit
        edit.textSubmitted = function (o)
            currentLineEdit:remove()
            currentLineEdit = nil
            local f,err = io.open(currentPath .. o.text, "w")
            if err then print(err) return end
            f:close()
            startSelectionFile = o.text
            openCurrentFolder() 
        end
    elseif text == "New Dir" then
        local edit = vContainer:addLineEdit()
        scrollToBottom()
        __window:grabFocus()
        edit:grabFocus()
        --edit:toBack()
        edit.expandW = true
        currentLineEdit = edit
        edit.textSubmitted = function (o)
            currentLineEdit:remove()
            currentLineEdit = nil
            if fs.isReadOnly(currentPath .. o.text) then return end
            fs.makeDir(currentPath .. o.text)
            startSelectionFile = o.text
            openCurrentFolder() 
        end
    elseif text == "Remove" then
        removeCurrentSelection()
    elseif text == "Rename" then
        if selection == nil then return end
        local target = selection
        local name = target.text
        local edit = target:addLineEdit()
        currentLineEdit = edit
        --edit.text = name
        edit.trueText = name
        edit.globalX = target.globalX
        edit.globalY = target.globalY
        edit.expandW = true
        edit:grabFocus()
        edit.textSubmitted = function (o)
            currentLineEdit:remove()
            currentLineEdit = nil
            if name == edit.text then return end
            if isPathValid(currentPath .. name) == false then return end
            fs.move(currentPath .. name, currentPath .. edit.text)
            target.text = edit.text
            --startSelectionFile = edit.text
            target:click()
            target:up()
            --o:remove()
            edit = nil
            --openCurrentFolder()
        end
    elseif text == "Close" then
        __window:close()
        return
    end

    __window:grabFocus()
end


function inputReader:key(key)
    if key == keys.up then
        traverse(-1)
    elseif key == keys.down then
        traverse(1)
    elseif key == keys.enter then
        if selection ~= nil and currentLineEdit == nil then
            selection:doublePressed()
        end
    elseif key == keys.delete then
        removeCurrentSelection()
    end
end

toolDropdown.text = "File"
toolDropdown.w = 4
toolDropdown:addToList("Open w/ args")
toolDropdown:addToList("New File")
toolDropdown:addToList("New Dir")
toolDropdown:addToList("Rename")
toolDropdown:addToList("Remove")
toolDropdown:addToList("Close")

engine:start()
