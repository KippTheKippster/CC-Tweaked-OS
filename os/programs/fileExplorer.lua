local engine = require(".core.engine")
local utils = require(".core.utils")
local currentPath = ""
local paths = {}

local args = {...}
local callbackFunction = args[1]
local startPath = args[2]
local saveMode = args[3]
local mos = __mos
local fileExplorer = {}
local selectedFileButtons = {}
local copiedFiles = {}

local popupStyle = engine.newStyle()
popupStyle.backgroundColor = colors.white
popupStyle.textColor = colors.black

local function popupError(err)
    err = " " .. err .. " "

    local w, h = engine.root.w, engine.root.h
    local window = engine.root:addWindowControl()
    window.text = "Error"
    window.style = popupStyle
    window.w = math.min(24, #err)
    window.h = 2
    window.x = math.floor((w - window.w) / 2)
    window.y = math.floor((h - window.h) / 2)
    window:refreshMinSize()

    local message = window:addControl()
    message.y = 1
    message.expandW = true
    message.expandH = true

    message.text = err
    message.centerText = true
end

local function pPopupError(f, ...)
    local ok, err = pcall(f, ...)
    if ok == false then
        for i = 1, 3 do
            local idx = err:find(":")
            if idx ~= nil then
                err = err:sub(idx + 1)
            end
        end

        err = err:sub(2)

        popupError(err)
    end
    return ok, err
end

__window.engine = engine

if mos == nil then
    printError("File Explorer must be opened with MOS!")
    return
end

local filter = ""

local inputReader = {}

local diskNames = {
    "top",
    "bottom",
    "front",
    "back",
    "right",
    "left"
}


engine.input.addResizeEventListener(inputReader)
engine.input.addCharListener(inputReader)
engine.input.addKeyListener(inputReader)
engine.input.addRawEventListener(inputReader)

--tools
local toolsStyle = engine:newStyle() 
toolsStyle.backgroundColor = colors.white

local tools = engine.root:addControl()
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

local copyButton = tools:addButton()
copyButton.text = '\169'
copyButton.w = #copyButton.text
copyButton.h = 1
copyButton.normalStyle = toolsStyle
copyButton.anchorW = copyButton.anchor.RIGHT

local marginU = 1
local marginD = 0

--files
local vContainer = engine.root:addVContainer()
vContainer:toBack()
vContainer.visible = true
vContainer.style.backgroundColor = colors.black
vContainer.style = engine.newStyle()
vContainer.style.backgroundColor = colors.red
vContainer.x = 0
vContainer.y = 0
vContainer.expandW = true
vContainer.expandH = true

local saveEdit = nil
local currentLineEdit = nil

if saveMode == true then
    local saveContainer = engine.root:addHContainer()
    saveContainer.style = toolsStyle
    saveContainer.h = 1
    saveContainer.expandW = true
    saveContainer.anchorH = saveContainer.anchor.DOWN

    saveContainer.label = saveContainer:addControl()
    saveContainer.label.h = 1
    saveContainer.label.fitToText = true
    saveContainer.label.text = "Name: "

    saveContainer.edit = saveContainer:addLineEdit()
    saveContainer.edit.x = saveContainer.label.w
    saveContainer.edit.h = 1
    saveContainer.edit.expandW = true

    saveContainer.ok = saveContainer:addButton()
    saveContainer.ok.fitToText = true
    saveContainer.ok.h = 1
    saveContainer.ok.text = "Save"
    saveContainer.ok.normalStyle = toolsStyle
    saveContainer.ok.pressed = function (o)
        callbackFunction("", fs.combine(currentPath, saveContainer.edit.text), false)
    end

    saveEdit = saveContainer.edit

    function saveEdit:focusChanged()
        engine.getObject("lineEdit").focusChanged(self)
        if self.focus then
           currentLineEdit = self 
        else
            if currentLineEdit == self then
                currentLineEdit = nil
            end
        end
    end

    saveEdit:grabFocus()

    saveContainer.sortOnTransformChanged = true
    saveContainer:sort()

    marginD = 1
end

local style = engine:newStyle()
style.backgroundColor = colors.black
style.textColor = colors.white

local clickedStyle = engine:newStyle()
clickedStyle.backgroundColor = colors.lightGray
clickedStyle.textColor = colors.white

local selectedStyle = engine:newStyle()
selectedStyle.backgroundColor = colors.gray
selectedStyle.textColor = colors.white

local fileButton = engine.getObject("button"):new{}
fileButton.h = 1
fileButton.w = 1
fileButton.expandW = true
fileButton.selected = false
fileButton.normalStyle = style
fileButton.clickedStyle = clickedStyle
fileButton.selectedStyle = selectedStyle

local selection = nil
local startSelectedFiles = {}

function fileButton:click()
    engine.getObject("button").click(self)
    if engine.input.isKey(keys.leftCtrl) == false then
        for k, v in ipairs(selectedFileButtons) do
            v.style = v.normalStyle
            v.selected = false
        end

        selectedFileButtons = {}
    end

    if self.selected == false then
        table.insert(selectedFileButtons, self)
        self.selected = true
    end

    selection = self
end

function fileButton:up()
    if self.selected == true then
        self.style = self.selectedStyle
    end
end

function fileButton:pressed()
    if saveEdit ~= nil then
        saveEdit.trueText = self.text
    end
end

local dirStyle = style:new{}
dirStyle.textColor = colors.green

local dirSelectedStyle = selectedStyle:new()
dirSelectedStyle.textColor = colors.lime

local dirButton = fileButton:new{}
dirButton.normalStyle = dirStyle
dirButton.selectedStyle = dirSelectedStyle

local function getPath(c)
    if c == nil or c:isValid() == false then -- NOTE Somewhere selection is freed but not set to nil
        return ""
    else
        return fs.combine(currentPath, c.text)
    end
end


local function getTitle(c)
    local title = c.text
    if title:sub(-4) == ".lua" then
        title = title:sub(1, -5)
    end
    return title
end


local function scrollToBottom()
    vContainer.y = -#vContainer.children - marginD
end

local function scrollToTop()
    vContainer.y = marginU
end

local function scrollToControl(control, center)
    local h = engine.root.h
    local offset = 0
    if center == true then
        offset = h / 2
    end

    if control.globalY <= 0 then
        vContainer.globalY = vContainer.globalY - control.globalY + marginU - offset--h - control.globalY--  - offset
    elseif control.globalY >= h then
        vContainer.globalY = -control.globalY + h - offset - marginD
    end
end

fileExplorer.addHeart = function (o, file)
    local heart = o:addButton()
    heart.text = "\3"
    heart.w = #heart.text
    heart.h = 1
    heart.normalStyle = style
    heart.anchorW = heart.anchor.RIGHT
    heart.pressed = function ()
        fileExplorer.removeFavorite(o, file)
    end

    o.heart = heart
end

fileExplorer.removeHeart = function (o)
    o:removeChild(o.heart)
    o.heart = nil
end

fileExplorer.addFavorite = function (o, file)
    if mos.isFileFavorite(file) == true then return end

    fileExplorer.addHeart(o, file)
    mos.addFileFavorite(file)
    mos.refreshMosDropdown()
end

fileExplorer.removeFavorite = function (o, file)
    if mos.isFileFavorite(file) == false then return end

    fileExplorer.removeHeart(o)
    mos.removeFileFavorite(file)
    mos.refreshMosDropdown()
end

local function openFolder(path)
    path = fs.combine(path)
    currentPath = path
    selection = nil
    selectedFileButtons = {}

    if fs.exists(path) == false then
        currentPath = ""
        openFolder("")
        return
    end

    vContainer.y = 1
    tools.text = "  /" .. path
    for i = 1, #vContainer.children do
        vContainer.children[i]:queueFree()
    end

    vContainer.children = {}

    local names = fs.list(path, "r")
    local files = {}
    local dirs = {}
    local selectedButtons = {}
    for i, name in ipairs(names) do
        if filter == "" or name:find(filter) ~= nil then
            if fs.isDir(fs.combine(path, name)) then
                table.insert(dirs, name)
            else
                table.insert(files, name)
            end

            if utils.find(startSelectedFiles, name) ~= nil then
                selectedButtons[name] = true
            end
        end
    end

    for i, name in ipairs(dirs) do
        local button = dirButton:new{}
        button.text = name
        vContainer:addChild(button)
        button.style = dirStyle

        if selectedButtons[name] == true then
            button:click()
            button:up()
        end
    end

    for i, name in ipairs(files) do
        local button = fileButton:new{}
        button.text = name
        vContainer:addChild(button)
        button.style = style

        local file = fs.combine(path, name)
        if mos.isFileFavorite(file) then
            fileExplorer.addHeart(button, file)
        end

        if selectedButtons[name] == true then
            button:click()
            button:up()
        end
    end

    if #startSelectedFiles > 0 then -- TODO FIXME1
        --local last = startSelectedFiles[#startSelectedFiles - 1]
        --scrollToControl(last)
    end

    inputReader:scroll(0)
    startSelectedFiles = {}
end

local function refreshFiles()
    openFolder(currentPath)
end

function backButton:pressed()
    openFolder(fs.getDir(currentPath))
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
    refreshFiles()
end

function inputReader:scroll(dir)
    local newY = vContainer.y - dir
    local h = engine.root.h - marginD
    --local w, h = term.getSize()
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
    inputReader:scroll(0)
end

function inputReader:char(char)
    if currentLineEdit == nil then
        searchEdit:grabFocus()
    end
end

local function createEditFile(startText, fn, parent, scroll)
    parent = parent or vContainer
    local edit = parent:addLineEdit()
    edit.trueText = startText
    if scroll == true then
        scrollToControl(edit)
    end
    __window:grabFocus()
    edit:grabFocus()
    edit.expandW = true
    currentLineEdit = edit
    edit.textSubmitted = function (o)
        local ok = fn(o)
        currentLineEdit.parent:removeChild(currentLineEdit)
        currentLineEdit:remove()
        currentLineEdit = nil
        if ok then
            startSelectedFiles = { o.text }
            refreshFiles()
        end
    end
    return edit
end

local presentDisks = {}

local function removeDisk(name)
    if presentDisks[name] == nil then return end

    local dropdown = presentDisks[name]
    presentDisks[name] = nil

    mos.removeFromToolbar(dropdown)
end

local function ejectDisk(name)
    disk.eject(name)
    removeDisk(name)
end

local function createAudioDropdown(name)
    local dropdown = mos.engine.getObject("dropdown"):new{}
    dropdown.text = disk.getAudioTitle(name) or disk.getMountPath(name) --  or --"D-" .. name --tostring(disk.getID(name))
    dropdown.text = "[" .. dropdown.text .. "]"
    dropdown.w = #dropdown.text
    dropdown:addToList("Play Audio")
    dropdown:addToList("Stop Audio")
    dropdown:addToList("Eject")

    dropdown.optionPressed = function (o, i)
        local text = o:getOptionText(i)
        if text == "Play Audio" then
            disk.playAudio(name)
        elseif text == "Stop Audio" then
            disk.stopAudio(name)
        elseif text == "Eject" then
            ejectDisk(name)
        end
    end

    return dropdown
end

local function createDiskDropdown(name)
    local dropdown = mos.engine.getObject("dropdown"):new{}
    dropdown.text = disk.getMountPath(name) -- disk.getLabel(name) or --"D-" .. name --tostring(disk.getID(name))
    dropdown.text = "[" .. dropdown.text .. "]"
    dropdown.w = #dropdown.text
    dropdown:addToList("Install To Folder")
    dropdown:addToList("Install Here")
    dropdown:addToList("Eject")

    dropdown.optionPressed = function (o, idx)
        local text = o:getOptionText(idx)
        if text == "Install To Folder" then
            createEditFile("", function (edit)
                local dest = getPath(edit)
                if fs.isReadOnly(dest) then return false end
                if fs.exists(dest) then return false end
                pPopupError(fs.copy, disk.getMountPath(name), dest)
                return true
            end)
        elseif text == "Install Here" then
            if fs.isReadOnly(currentPath) then
                mos.createPopup("Warning", "Folder is read only!")
                return
            end
            
            local mountPath = disk.getMountPath(name)
            local names = fs.list(mountPath, "r")
            for i = 1, #names do
                local path = fs.combine(mountPath, names[i])
                local dest = fs.combine(currentPath, names[i])
                if path == dest then
                    break
                end

                if fs.exists(dest) then
                    pPopupError(fs.delete, dest)
                end
                pPopupError(fs.copy, path, dest)
            end

            refreshFiles()
        elseif text == "Eject" then
            ejectDisk(name)
        end

        __window:grabFocus()
    end

    return dropdown
end

local function addDisk(name)
    if presentDisks[name] ~= nil then return end

    local dropdown = nil
    if disk.hasAudio(name) then
        dropdown = createAudioDropdown(name)
    elseif disk.hasData(name) then
        dropdown = createDiskDropdown(name)
    else
        return
    end

    presentDisks[name] = dropdown--disk.getLabel(name) or "disk"

    mos.addToToolbar(dropdown)
end

local function scanDisks()
    for i = 1, #diskNames do
        if disk.isPresent(diskNames[i]) == true then
            addDisk(diskNames[i])
        end
    end
end

local function clearDisks()
    for k, _ in pairs(presentDisks) do
        removeDisk(k)
    end
end

function inputReader:rawEvent(data)
    local event = data[1]
    if event == "disk" then
        scanDisks()
    elseif event == "disk_eject" then
        clearDisks()
    elseif event == "mos_favorite_remove" then
        refreshFiles()
    elseif event == "paste" then
        fileExplorer.pasteCopiedFiles()
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
    callbackFunction(getTitle(self), getPath(self), engine.input.isKey(keys.leftCtrl))
end

function dirButton:doublePressed()
    filter = ""
    openFolder(fs.combine(currentPath, self.text))
end

if type(startPath) == "string" then
    openFolder(startPath)
else
    openFolder("")
end

local fileDropdown = mos.engine.getObject("dropdown"):new{}
local editDropdown = mos.engine.getObject("dropdown"):new{}

local function windowFocusChanged(focus)
    if focus then
        mos.addToToolbar(fileDropdown)
        mos.addToToolbar(editDropdown)
        scanDisks()
    else
        mos.removeFromToolbar(fileDropdown)
        mos.removeFromToolbar(editDropdown)
        clearDisks()
    end
end

mos.bindTool(__window, windowFocusChanged)

local function removeSelectedFiles()
    if #selectedFileButtons == 0 then return end
    for k, v in ipairs(selectedFileButtons) do
        local file = getPath(v)
        local ok = pPopupError(fs.delete, file)
        if ok then
            v:remove()
        end
    end
    selectedFileButtons = {}
    selection = nil
end

local function renameCurrentSelection()
    if selection == nil then return end
    local target = selection
    local name = target.text
    createEditFile(name, function (o)
        local file = fs.combine(currentPath, name)
        local dest = fs.combine(currentPath, o.text)
        local ok = pPopupError(fs.move, file, dest)
        if ok == false then return end
        target.text = o.text
        target:click()
        target:up()
        if mos.isFileFavorite(file) then
            mos.removeFileFavorite(file)
            mos.addFileFavorite(dest)
            mos.refreshMosDropdown()
        end

        return false
    end, target, true)
end

fileExplorer.copySelectedFiles = function()
    copiedFiles = {}
    for _, v in ipairs(selectedFileButtons) do
        table.insert(copiedFiles, getPath(v))
    end
end

fileExplorer.pasteCopiedFiles = function()
    for _, file in ipairs(copiedFiles) do
        local dest = fs.combine(currentPath, fs.getName(file))
        local ok, err = pcall(fs.copy, file, dest)
        if ok then
            table.insert(startSelectedFiles, fs.getName(file))
        end
    end
    refreshFiles()
end

function fileDropdown:optionPressed(i)
    if currentLineEdit ~= nil then
        currentLineEdit:releaseFocus()
    end

    local text = fileDropdown:getOptionText(i)
    local selectedPath = getPath(selection)
    __Global.log(selectedPath)
    if text == "New File" then
        createEditFile("", function (o)
            local file = getPath(o)
            if fs.isReadOnly(file) then 
                popupError("Dir is read-only")
                return false
            end

            if fs.exists(file) == true then
                popupError("File exists" .. file)
                return false
            end

            local ok = pPopupError(fs.open, file, "w")
            if ok then
                startSelectedFiles = {o.text}
            end
            return true
        end, nil, true)
        __window:grabFocus()
    elseif text == "New Dir" then
        createEditFile("", function (o)
            local file = getPath(o)
            if fs.isReadOnly(file) then
                popupError("Dir is read-only")
                return false
            end

            if fs.exists(file) then
                popupError("Dir exists")
                return false
            end

            local ok = pPopupError(fs.makeDir, file)
            if ok then
                startSelectedFiles = {o.text}
            end
            return true
        end, nil, true)
        __window:grabFocus()
    elseif text == "Open" then
        if selection == nil then return end
        local isDir = fs.isDir(selectedPath)
        selection:doublePressed()
        if isDir == true then
            __window:grabFocus()
        end
    elseif text == "Open w/ args" then
        if selection == nil then return end
        if fs.isDir(selectedPath) then return end
        mos.launchProgram("Write Args", "/os/programs/writeArgs.lua", 3, 3, 24, 2, function (...)
            if selection == nil then return end
            if fs.exists(selectedPath) == false then return end
            callbackFunction(getTitle(self), selectedPath, false, ...)
        end)
    elseif text == "Edit" then
        if selection == nil then return end
        local isDir = fs.isDir(selectedPath)
        if isDir == false then
            callbackFunction(getTitle(self), selectedPath, true)
        end
    elseif text == "Close" then
        __window:close()
    end
end

function editDropdown:optionPressed(i)
    if currentLineEdit ~= nil then
        currentLineEdit:releaseFocus()
    end

    local text = editDropdown:getOptionText(i)
    local selectedPath = getPath(selection)

    if text == "Copy" then
        fileExplorer.copySelectedFiles()
    elseif text == "Paste" then
        fileExplorer.pasteCopiedFiles()
    elseif text == "Favorite" then
        if selection == nil then return end
        if fs.isDir(selectedPath) then return end
        if mos.isFileFavorite(selectedPath) then
            for k, v in ipairs(selectedFileButtons) do
                fileExplorer.removeFavorite(v, getPath(v))
            end
        else
            for k, v in ipairs(selectedFileButtons) do
                fileExplorer.addFavorite(v, getPath(v))
            end
        end
    elseif text == "Delete" then
        removeSelectedFiles()
    elseif text == "Rename" then
        renameCurrentSelection()
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
        removeSelectedFiles()
    elseif key == keys.r and engine.input.isKey(keys.leftCtrl) then
        renameCurrentSelection()
    elseif key == keys.c and engine.input.isKey(keys.leftCtrl) then
        fileExplorer.copySelectedFiles()
    elseif key == keys.v and engine.input.isKey(keys.leftCtrl) then -- Note this doesn't work since ctrl+v is consumed as a paste event and the key event is not sent 
        error("A")
    end
end

fileDropdown.text = "File"
fileDropdown:addToList("New File")
fileDropdown:addToList("New Dir")
fileDropdown:addToList("------------", false)
fileDropdown:addToList("Open")
fileDropdown:addToList("Open w/ args")
fileDropdown:addToList("------------", false)
fileDropdown:addToList("Edit")
fileDropdown:addToList("------------", false)
fileDropdown:addToList("Close")

editDropdown.text = "Edit"
editDropdown:addToList("Copy")
editDropdown:addToList("Paste")
editDropdown:addToList("--------", false)
editDropdown:addToList("Rename")
editDropdown:addToList("Favorite")
editDropdown:addToList("--------", false)
editDropdown:addToList("Delete")

engine:start()
