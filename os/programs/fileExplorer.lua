local engine = require(".core.engine")
local utils = require(".core.utils")
local currentPath = ""
local paths = {}

local args = {...}
local callbackFunction = args[1]
local startPath = args[2]
local mos = __mos
local fileExplorer = {}
local selectedFiles = {}
local copiedFiles = {}

local function popupError(err, ...)
    mos.createPopup("Error", err, ...)
end

local function pPopupError(f, ...)
    local ok, err = pcall(f, ...)
    if ok == false then
        for i = 1, 3 do
            local idx = err:find(":")
            err = err:sub(idx + 1)
        end
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

--local main = engine.root:addControl()
--main.expandW = true
--main.expandH = true
local inputReader = {}

local diskNames = {
    "top",
    "bottom",
    "front",
    "back",
    "right",
    "left"
}


--engine.input.addScrollListener(inputReader)
engine.input.addResizeEventListener(inputReader)
engine.input.addCharListener(inputReader)
engine.input.addKeyListener(inputReader)
engine.input.addRawEventListener(inputReader)

--background
--[[
local background = engine.root:addControl()
background.text = ""
background.expandW = true
background.expandH = true
]]--

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
local startSelectedFiles = {}
local currentLineEdit = nil

function fileButton:click()
    button.click(self)
    if engine.input.isKey(keys.leftCtrl) == false then
        for k, v in ipairs(selectedFiles) do
            v.style = v.normalStyle
            v.selected = false
            --selectedFiles[k] = nil
        end

        selectedFiles = {}
    end

    if self.selected == false then
        table.insert(selectedFiles, self)
        self.selected = true
    end
    --if selection ~= nil and selection ~= self then
    --    selection.style = selection.normalStyle
    --    selection = nil
    --end
    selection = self
end

function fileButton:up()
    if self.selected == true then
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
    --local w, h = term.getSize()
    local h = engine.root.h
    local offset = 0
    if center == true then
        offset = h / 2
    end

    --error(control.globalY .. " : " .. tostring(vContainer.globalY) .. " : " .. tostring(h))

    if control.globalY <= 0 then
        --error(control.globalY .. " : " .. tostring(vContainer.globalY) .. " : " .. tostring(h))

        vContainer.globalY = vContainer.globalY - control.globalY + 1 - offset--h - control.globalY--  - offset
    elseif control.globalY >= h then
        vContainer.globalY = -control.globalY + h - offset
    end
end

local function isControlOnScreen(c)
    local w, h = term.getSize()
    if c.globalY <= 0 or c.globalY >= h then
        return false
    end
    return true
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
    selection = nil
    selectedFiles = {}

    if fs.exists(path) == false then
        currentPath = ""
        openFolder("")
        return
    end

    vContainer.y = 1
    tools.text = "  /" .. path
    for i = 1, #vContainer.children do
        vContainer:removeChild(vContainer.children[1])
    end
    --for i = 1, #vContainer.children do
    --    vContainer.children[1]:remove()
    --end
    vContainer.children = {}

    local names = fs.list(path, "r")
    local files = {}
    local dirs = {}
    for i = 1, #names do
        if filter == "" or names[i]:find(filter) ~= nil then
            --local drive = fs.getDrive(path .. names[i])
            --if utils.find(driveNames, drive) ~= nil then
            --    local diskName = disk.getLabel(drive) or disk.getMountPath(drive)
            --    table.insert(dirs, "[" .. diskName .. "]")
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

        if utils.find(startSelectedFiles, dirs[i]) ~= nil then--b.text == startSelectionFile then
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

        if mos.isFileFavorite(path .. files[i]) then
            fileExplorer.addHeart(b, path .. files[i])
        end

        if utils.find(startSelectedFiles, files[i]) ~= nil then-- b.text == startSelectionFile then
            b:click()
            b:up()
            scrollToControl(b, true)
        end
    end

    inputReader:scroll(0)
    startSelectionFile = ""
    startSelectedFiles = {}
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
    local h = engine.root.h
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

local function createEditFile(startText, f, parent, scroll)
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
        currentLineEdit:remove()
        currentLineEdit = nil
        local ok = f(o)
        if ok then
            startSelectionFile = o.text
            startSelectedFiles = { o.text }
            openCurrentFolder()
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
                if fs.isReadOnly(currentPath .. edit.text) then return false end
                if fs.exists(currentPath .. edit.text) then return false end
                fs.copy(disk.getMountPath(name), currentPath .. edit.text)
                return true
            end)
        elseif text == "Install Here" then
            if fs.isReadOnly(currentPath) then
                os.createPopup("Warning", "Folder is read only!")
                return
            end
            --fs.makeDir(currentPath .. o.text)
            
            local mountPath = disk.getMountPath(name)
            local names = fs.list(mountPath, "r")
            for i = 1, #names do
                local path = mountPath .. "/" .. names[i]
                local dest = currentPath .. names[i]
                if path == dest then
                    break
                end

                if fs.exists(dest) then
                    fs.delete(dest)
                end
                fs.copy(path, dest)
            end

            openCurrentFolder()
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
        --addDisk(data[2])
        --openCurrentFolder()
    elseif event == "disk_eject" then
        clearDisks()
        --removeDisk(data[2])
        --openCurrentFolder()
    elseif event == "mos_favorite_remove" then
        openCurrentFolder()
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

local function getTitle(c)
    local title = c.text
    if title:sub(-4) == ".lua" then
        title = title:sub(1, -5)
    end
    return title
end


function fileButton:doublePressed()
    callbackFunction(currentPath .. self.text, getTitle(self), engine.input.isKey(keys.leftCtrl))--Left CTRL
end

function dirButton:doublePressed()
    filter = ""
    table.insert(paths, self.text)
    openCurrentFolder()
end

if type(startPath) == "string" then
    --local e = e.e
    --currentPath = startPath
    currentPath = startPath
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

local function isPathValid(path, createPopup)
    createPopup = createPopup or true
    if fs.exists(path) == false then return false end
    if fs.isReadOnly(path) == true then 
        mos.createPopup("Warning", "Folder is read only!")
        return false 
    end
    return true
end

local function removeSelectedFiles()
    if #selectedFiles == 0 then return end
    for k, v in ipairs(selectedFiles) do
        local file = currentPath .. v.text
        local ok = pPopupError(fs.delete, file)
        if ok then
            v:remove()
        end
    end

end

local function renameCurrentSelection()
    if selection == nil then return end
    local target = selection
    local name = target.text
    local edit = createEditFile(name, function (o)
        local file = currentPath .. name
        local dest = currentPath .. o.text
        local ok = pPopupError(fs.move, file, dest)
        if ok == false then return end
        --if name == o.text then return false end
        --if isPathValid(file) == false then return false end
        --fs.move(file, dest)
        target.text = o.text
        --startSelectionFile = edit.text
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
    for k, v in ipairs(selectedFiles) do
        table.insert(copiedFiles, currentPath .. v.text)
    end
end

fileExplorer.pasteCopiedFiles = function()
    for k, file in ipairs(copiedFiles) do
        local dest = currentPath .. fs.getName(file)
        --if fs.exists(file) == false then goto continue end
        --if isPathValid(dest) == false then goto continue end -- FIXME add checking
        --if fs.exists(dest) == true then goto continue end
        local ok, err = pcall(fs.copy, file, dest)
        if ok then
            table.insert(startSelectedFiles, fs.getName(file))
        end
    end
    openCurrentFolder()
end

function fileDropdown:optionPressed(i)
    if currentLineEdit ~= nil then
        currentLineEdit:releaseFocus()
    end

    local text = fileDropdown:getOptionText(i)
    if text == "New File" then
        createEditFile("", function (o)
            --[[
            if fs.isReadOnly(currentPath .. o.text) then 
                mos.createPopup("Warning", "Folder is read only!")
                return false
            end
            if fs.exists(currentPath .. o.text) then                 
                mos.createPopup("Warning", "File already exists!")
                return false
            end
            ]]--
            local ok = pPopupError(fs.open, currentPath .. o.text, "w")
            if ok then
                startSelectedFiles = {o.text}
            end
            return true
        end, nil, true)
    elseif text == "New Dir" then
        createEditFile("", function (o)
            --[[
            if fs.isReadOnly(currentPath .. o.text) then 
                mos.createPopup("Warning", "Folder is read only!")
                return false
            end
            if fs.exists(currentPath .. o.text) then                 
                mos.createPopup("Warning", "Dir already exists!")
                return false
            end
            ]]--
            local ok = pPopupError(fs.makeDir, currentPath .. o.text)
            if ok then
                startSelectedFiles = {o.text}
            end
            --startSelectionFile = o.text
            return true
        end, nil, true)
    elseif text == "Open" then
        if selection == nil then return end
        local isDir = fs.isDir(currentPath .. selection.text)
        selection:doublePressed()
        if isDir == false then
            return
        end
    elseif text == "Open w/ args" then
        if selection == nil then return end
        if fs.isDir(currentPath .. selection.text) then return end
        mos.launchProgram("Write Args", "/os/programs/writeArgs.lua", 3, 3, 24, 2, function (...)
            if selection == nil then return end
            if isPathValid(currentPath .. selection.text) == false then return end
            callbackFunction(currentPath .. selection.text, getTitle(self), false, ...)
        end)
        return
    elseif text == "Edit" then
        if selection == nil then return end
        local isDir = fs.isDir(currentPath .. selection.text)
        if isDir == false then
            callbackFunction(currentPath .. selection.text, getTitle(self), true)
            return
        end
    elseif text == "Close" then
        __window:close()
    end

    __window:grabFocus()
end

function editDropdown:optionPressed(i)
    if currentLineEdit ~= nil then
        currentLineEdit:releaseFocus()
    end

    local text = editDropdown:getOptionText(i)
    if text == "Copy" then
        fileExplorer.copySelectedFiles()
    elseif text == "Paste" then
        fileExplorer.pasteCopiedFiles()
    elseif text == "Favorite" then
        if selection == nil then return end
        if fs.isDir(currentPath .. selection.text) then return end
        if mos.isFileFavorite(currentPath .. selection.text) then
            for k, v in ipairs(selectedFiles) do
                fileExplorer.removeFavorite(v, currentPath .. v.text)
            end
        else
            for k, v in ipairs(selectedFiles) do
                fileExplorer.addFavorite(v, currentPath .. v.text)
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
