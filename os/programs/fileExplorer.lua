local corePath = __Global.coreDotPath

---@type Engine
local engine = require(corePath .. ".engine")--corePath .. ".engine")
---@type Utils
local utils = require(corePath .. ".utils")

local currentPath = ""

local args = {...}
local callbackFunction = args[1]
local startPath = args[2]
local saveMode = args[3]
local mos = __mos
local fileExplorer = {}
local selectedFileButtons = {}
local copiedFiles = {}
local readOnlyFiles = {
    ["mos"] = true,
}

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

local backButton = tools:addButton()
backButton.w = 1
backButton.h = 1
backButton.text = '<'
backButton.normalStyle = toolsStyle

local copyButton = tools:addButton()
copyButton.text = string.char(169)
copyButton.w = #copyButton.text
copyButton.h = 1
copyButton.normalStyle = toolsStyle
copyButton.anchorW = copyButton.Anchor.RIGHT

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
    saveContainer.anchorH = saveContainer.Anchor.DOWN

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
        engine.LineEdit.focusChanged(self)
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

local heartOffStyle = style:new()
heartOffStyle.textColor = colors.gray

local clickedStyle = engine:newStyle()
clickedStyle.backgroundColor = colors.lightGray
clickedStyle.textColor = colors.white

local selectedStyle = engine:newStyle()
selectedStyle.backgroundColor = colors.gray
selectedStyle.textColor = colors.white

---@class FileButton : Button
local FileButton = engine.Button:new{}
FileButton.h = 1
FileButton.w = 1
FileButton.expandW = true
FileButton.selected = false
FileButton.normalStyle = style
FileButton.clickedStyle = clickedStyle
FileButton.selectedStyle = selectedStyle
FileButton.dragSelectable = true
FileButton.path = ""

local selection = nil
local startSelectedFiles = {}

function FileButton:click()
    engine.Button.click(self)
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

function FileButton:up()
    if self.selected == true then
        self.style = self.selectedStyle
    end
end

function FileButton:pressed()
    if saveEdit ~= nil then
        saveEdit.trueText = self.text
    end
end

local dirStyle = style:new{}
dirStyle.textColor = colors.green

local dirSelectedStyle = selectedStyle:new()
dirSelectedStyle.textColor = colors.lime

local dirButton = FileButton:new{}
dirButton.normalStyle = dirStyle
dirButton.selectedStyle = dirSelectedStyle

local function getPath(c)
    if c == nil or c:isValid() == false then -- NOTE Somewhere selection is freed but not set to nil
        return ""
    else
        return c.path
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
        vContainer.globalY = vContainer.globalY - control.globalY + marginU - offset
    elseif control.globalY >= h then
        vContainer.globalY = -control.globalY + h - offset - marginD
    end

    vContainer:redraw()
end

---comment
---@param o Control
---@param file string
fileExplorer.addHeart = function (o, file)
    local heart = o:addButton()
    heart.text = string.char(3)
    heart.w = #heart.text
    heart.h = 1
    heart.normalStyle = style
    heart.clickedStyle = clickedStyle
    heart.anchorW = heart.Anchor.RIGHT
    heart.dragSelectable = true
    heart.inheritStyle = false
    heart.pressed = function ()
        if mos.isFileFavorite(file) then
            fileExplorer.removeFavorite(o, file)
        else
            fileExplorer.addFavorite(o, file)
        end
    end

    o.heart = heart
end

fileExplorer.removeHeart = function (o)
    o:removeChild(o.heart)
    o.heart = nil
end

---comment
---@param heart Button
---@param active boolean
fileExplorer.setHeartActive = function (heart, active)
    if active then
        heart.text = string.char(3)
        heart.normalStyle = style
    else
        heart.text = string.char(3)
        heart.normalStyle = heartOffStyle
    end
end

---comment
---@param o Control
---@param file string
fileExplorer.addFavorite = function (o, file)
    if mos.isFileFavorite(file) == true then return end

    fileExplorer.setHeartActive(o.heart, true)
    mos.addFileFavorite(file)
    mos.refreshMosDropdown()
end

---comment
---@param o Control
---@param file string
fileExplorer.removeFavorite = function (o, file)
    if mos.isFileFavorite(file) == false then return end

    fileExplorer.setHeartActive(o.heart, false)
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

    local fileFilter = fs.getName(filter)
    if fileFilter == "root" and filter ~= "root" or filter:sub(#filter) == "/" then
        fileFilter = ""
    end

    local dirFilter = fs.getDir(filter .. "a")
    if filter == "" then
        dirFilter = ""
    end

    if filter:sub(1, 1) == "/" then
        dirFilter = ""
    end

    if dirFilter ~= "" then
        path = fs.combine(path, dirFilter)
    end
    local names = fs.list(path, "r")
    local files = {}
    local dirs = {}
    local selectedButtons = {}
    for i, name in ipairs(names) do
        if fileFilter == "" or name:find(fileFilter) ~= nil then
            if
                (mos.profile.showDotFiles or name:sub(0, 1) ~= ".") and not 
                (mos.profile.showMosFiles == false and fs.combine(path, name) == "mos") and not
                (mos.profile.showRomFiles == false and fs.combine(path, name) == "rom") then
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
    end

    for i, name in ipairs(dirs) do
        local button = dirButton:new{}
        local buttonPath = fs.combine(path, name)
        local drive = fs.getDrive(buttonPath)
        local label = disk.getLabel(drive)
        if label ~= nil and fs.isDriveRoot(buttonPath) then
            name = name .. " [" .. label .. "]"
        end
        name = name

        button.text = name
        button.path = buttonPath
        vContainer:addChild(button)
        button.style = dirStyle

        if selectedButtons[name] == true then
            button:click()
            button:up()
        end
    end

    for i, name in ipairs(files) do
        local buttonPath = fs.combine(path, name)

        local button = FileButton:new{}
        button.text = name
        button.path = buttonPath
        vContainer:addChild(button)
        button.style = style
        local sizeLabel = button:addControl()
        sizeLabel.fitToText = true
        sizeLabel.h = 1
        sizeLabel.anchorW = sizeLabel.Anchor.RIGHT
        sizeLabel.text = math.ceil(fs.getSize(buttonPath) / 1000) .. "KB  "
        button:_expandChildren()


        fileExplorer.addHeart(button, buttonPath)
        fileExplorer.setHeartActive(button.heart, mos.isFileFavorite(buttonPath))

        if selectedButtons[name] == true then
            button:click()
            button:up()
        end
    end

    if #startSelectedFiles > 0 then -- TODO FIXME
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

---@type LineEdit
local searchEdit = tools:addLineEdit()
searchEdit.inheritStyle = false
searchEdit.expandW = true
searchEdit.visible = false

local editStyle = engine.newStyle()
editStyle.backgroundColor = colors.white
editStyle.textColor = colors.black
searchEdit.focusStyle = editStyle

function searchEdit:focusChanged()
    if self.focus == true then
        self:grabCursorControl()
        self.trueText = ""
    else
        self:releaseCursorControl()
    end
    self.visible = self.focus
end

function searchEdit:trueTextChanged()
    if self.visible == false then return end

	engine.LineEdit.trueTextChanged(self)
    if self.text == "" then
        self:releaseFocus()
    end

    filter = self.text

    local dir = fs.getDir(self.trueText .. "a")
    if dir == "root" then
        dir = ""
    end
    if self.text:sub(1, 1) == "/" and currentPath ~= dir then
        openFolder(dir)
    else
        refreshFiles()
    end
end

function inputReader:scroll(dir)
    local newY = vContainer.y - dir
    local h = engine.root.h - marginD
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
    vContainer:redraw()
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
        local ok = fn(o, fs.combine(currentPath, o.text))
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
    local dropdown = mos.engine.Dropdown:new{}
    dropdown.text = disk.getAudioTitle(name) or disk.getMountPath(name)
    dropdown.text = "[" .. dropdown.text .. "]"
    dropdown.w = #dropdown.text
    dropdown:addToList("Play Audio")
    dropdown:addToList("Stop Audio")
    dropdown:addToList("----------")
    dropdown:addToList("Info")
    dropdown:addToList("----------")
    dropdown:addToList("Eject")

    dropdown.optionPressed = function (o, i)
        local text = o:getOptionText(i)
        if text == "Play Audio" then
            disk.playAudio(name)
        elseif text == "Stop Audio" then
            disk.stopAudio(name)
        elseif text == "Info" then
            mos.launchProgram("Disk Info", "/os/programs/diskInfo.lua", 3, 3, 20, 6, name)
        elseif text == "Eject" then
            ejectDisk(name)
        end
    end

    return dropdown
end

local function createDiskDropdown(name)
    ---@type Dropdown
    local dropdown = mos.engine.Dropdown:new{}
    dropdown.text = disk.getMountPath(name)
    dropdown.text = "[" .. dropdown.text .. "]"
    dropdown.w = #dropdown.text
    dropdown:addToList("Install Folder")
    dropdown:addToList("Install Here")
    dropdown:addToList("--------------", false)
    dropdown:addToList("Set Label")
    dropdown:addToList("Info")
    dropdown:addToList("--------------", false)
    dropdown:addToList("Eject")

    dropdown.optionPressed = function (o, idx)
        local text = o:getOptionText(idx)
        if text == "Install Folder" then
            createEditFile("", function (edit)
                local dest = fs.combine(currentPath, edit.text)
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
        elseif text == "Set Label" then
            mos.launchProgram("Set Label", "/os/programs/writeArgs.lua", 3, 3, 24, 2, function (label)
                disk.setLabel(name, label)
                refreshFiles()
            end, disk.getLabel(name), false)
            return
        elseif text == "Info" then
            mos.launchProgram("Disk Info", "/os/programs/diskInfo.lua", 3, 3, 20, 9, name)
            return
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

    presentDisks[name] = dropdown

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
        if __window:inFocus() then
            scanDisks()
        end
    elseif event == "disk_eject" then
        if __window:inFocus() then
            clearDisks()
        end
    elseif event == "mos_favorite_remove" then
        refreshFiles()
    elseif event == "mos_refresh_files" then
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

function FileButton:doublePressed()
    callbackFunction(getTitle(self), getPath(self), engine.input.isKey(keys.leftCtrl))
end

function dirButton:doublePressed()
    filter = ""
    openFolder(getPath(self))
end

if type(startPath) == "string" then
    openFolder(startPath)
else
    openFolder("")
end

---@type Dropdown
local fileDropdown = mos.engine.Dropdown:new{}
---@type Dropdown
local editDropdown = mos.engine.Dropdown:new{}
---@type Dropdown
local pastebinDropdown = mos.engine.Dropdown:new{}

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

local function deleteSelectedFiles()
    if #selectedFileButtons == 0 then return end
    local buttons = selectedFileButtons
    for k, v in ipairs(buttons) do
        v.selected = false
        v:click()
        v:up()
        if readOnlyFiles[getPath(v)] == nil then
            local file = getPath(v)
            local ok = pPopupError(fs.delete, file)
            if ok then
                v:remove()
            end
        else
            popupError("Access denied")
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
        local file = getPath(target)
        local dest = fs.combine(currentPath, o.text)
        local ok = pPopupError(fs.move, file, dest)
        if ok == false then return end
        target.text = o.text
        target.path = fs.combine(currentPath, o.text)
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
        local ok, err = pPopupError(fs.copy, file, dest)
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
    if text == "New File" then
        createEditFile("", function (o, path)
            if fs.isReadOnly(path) then
                popupError("Dir is read-only")
                return false
            end

            if fs.getName(path) == "" or fs.getName(path) == "root" then
                return false
            end

            if fs.exists(path) == true then
                popupError("File exists" .. path)
                return false
            end

            local ok = pPopupError(fs.open, path, "w")
            if ok then
                startSelectedFiles = {o.text}
            end
            return true
        end, nil, true)
        __window:grabFocus()
    elseif text == "New Dir" then
        createEditFile("", function (o, path)
            if fs.isReadOnly(path) then
                popupError("Dir is read-only")
                return false
            end

            if fs.exists(path) then
                popupError("Dir exists")
                return false
            end

            local ok = pPopupError(fs.makeDir, path)
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
            callbackFunction(getTitle(selection), selectedPath, false, ...)
        end)
    elseif text == "Edit" then
        if selection == nil then return end
        local isDir = fs.isDir(selectedPath)
        if isDir == false then
            callbackFunction(getTitle(selection), selectedPath, true)
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
        deleteSelectedFiles()
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
        deleteSelectedFiles()
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
