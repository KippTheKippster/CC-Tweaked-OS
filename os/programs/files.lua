local corePath = ".mos.core"
if _G.__Global then
    corePath =_G.__Global.coreDotPath
end

---@type Engine
local engine = require(corePath .. ".engine")
---@type MOS
local mos = __mos
---@type ProgramWindow
local mosWindow = __window

local args = {...}

local fe = {}
fe.currentPath = ""
fe.mountPaths = {
    "top",
    "bottom",
    "front",
    "back",
    "right",
    "left",
}
fe.mountedDisks = {}
fe.selection = {}
---@enum PasteMode
fe.PasteMode = {
    COPY = 1,
    CUT = 2,
}

---@type PasteMode
fe.pasteMode = fe.PasteMode.COPY
fe.clipboard = {}

---comment
---@param path string
---@param modifier FileOpenModifier
fe.openFileCallback = function (path, modifier, ...)
    if mos then
        if modifier == mos.FileOpenModifier.EDIT then
            mos.editProgram(path)
        elseif modifier == mos.FileOpenModifier.ARGS then
            mos.openProgramWithArgs(path)
        else
            mos.openProgram(path, ...)
        end
    end
end

if type(args[1]) == "function" then
    fe.openFileCallback = args[1]
end

local settings = args[2] or {}
local dirColor = colors.blue

if mos then
    mos.applyTheme(engine)
    dirColor = mos.profile.dirColor or mos.theme.fileColors.dirText
end

local fileStyle = engine.normalStyle
local dirStyle = engine.newStyle()
dirStyle.textColor = dirColor
local dirSelectStyle = engine.newStyle(engine.focusStyle)
dirSelectStyle.textColor = dirColor

engine.background = true

local main = engine.root:addVContainer()
main.expandW = true
main.expandH = true

local top = main:addHContainer()
top.expandW = true
top.h = 1
top.topLevel = true

local backButton = top:addButton()
backButton.text = "<"
backButton.h = 1
backButton.dragSelectable = true

local topSpacer = top:addControl()
topSpacer.text = ""

local pathContainer = top:addHContainer()
pathContainer.expandW = true
pathContainer.h = 1
pathContainer.rendering = true

local searchbar = main:addLineEdit()
searchbar.topLevel = true
searchbar.expandW = true
searchbar.visible = false

searchbar.textChanged = function (self)
    engine.LineEdit.textChanged(self)
    if self.text == "" then
        self.visible = false
        self:releaseFocus()
    else
        self.visible = true
    end
    main:queueSort()
    fe.filter(self.text)
end

local scrollContainer = main:addScrollContainer()
scrollContainer.marginR = 1
scrollContainer.expandW = true
scrollContainer.expandH = true

local fileContainer = scrollContainer:addVContainer()
fileContainer.expandW = true
fileContainer.expandH = true


---@class SaveContainer : HContainer
local SaveContainer = engine.HContainer:newClass()
SaveContainer.expandW = true
---@type LineEdit
SaveContainer.saveEdit = nil
---@type Button
SaveContainer.saveButton = nil

---@type SaveContainer
local saveContainer = nil

if settings.saveMode then
    saveContainer = SaveContainer:new()
    saveContainer.expandW = true

    saveContainer.saveEdit = saveContainer:addLineEdit()
    saveContainer.saveEdit.expandW = true
    saveContainer.saveEdit.text = args[3]

    saveContainer.saveButton = saveContainer:addButton()
    saveContainer.saveButton.text = "Save"
    saveContainer.saveButton.pressed = function ()
        fe.openFile(fe.nameToPath(saveContainer.saveEdit.text), mos.getFileOpenModifierInput())
    end

    main:addChild(saveContainer)
end


---@return boolean, string
function fe.pPopupError(f, ...)
    local ok, err = pcall(f, ...)
    if ok == false then
        for i = 1, 3 do
            local idx = err:find(":")
            if idx ~= nil then
                err = err:sub(idx + 1)
            end
        end
        err = err:sub(2)
        mos.popupError(err)
    end
    return ok, err
end

---@class FileButton : Button
local FileButton = engine.Button:newClass()
FileButton.selected = false
FileButton.selectStyle = engine.focusStyle
FileButton.path = ""
function FileButton:down()
    engine.Button.down(self)
    fe.selectFileButton(self, engine.input.isKey(keys.leftCtrl) == false)
end

function FileButton:refreshStyle()
    if self.isClicked then
        self.style = self.clickStyle
    elseif self.selected then
        self.style = self.selectStyle
    else
        self.style = self.normalStyle
    end
end

---comment
---@param b FileButton
---@param clearSelection boolean
function fe.selectFileButton(b, clearSelection)
    if clearSelection then
        fe.clearSelection()
    end

    if saveContainer and saveContainer.saveEdit then
        saveContainer.saveEdit.text = b.text
    end

    fe.addToSelection(b)
    b:refreshStyle()
end

---comment
---@param b FileButton
function fe.addToSelection(b)
    b.selected = true
    table.insert(fe.selection, b)
end

---comment
---@param b FileButton
function fe.removeFromSelection(b)
    b.selected = false
    table.remove(fe.selection, engine.utils.find(fe.selection, b))
end

function fe.clearSelection()
    for i, b in ipairs(fe.selection) do
        if b:isValid() == true then
            b.selected = false
            b:refreshStyle()
        end
    end

    fe.selection = {}
end

---comment
---@param name string
---@return FileButton
function fe.newFileButton(name)
    ---@type FileButton
    local fileButton = FileButton:new()
    fileButton.__name = name
    local path = fe.nameToPath(name)
    if fs.isDir(path) then
        fileButton.normalStyle = dirStyle
        fileButton.selectStyle = dirSelectStyle
    else
        fileButton.normalStyle = fileStyle
    end
    fileButton.style = fileButton.normalStyle
    fileButton.h = 1
    fileButton.expandW = true
    fileButton.dragSelectable = true
    fileButton.text = name
    fileButton.path = path
    return fileButton
end

---comment
---@param name string
---@return FileButton
function fe.addFileButton(name)
    local fileButton = fe.newFileButton(name)
    fileContainer:addChild(fileButton)
    if fs.isDir(fileButton.path) then
        fileButton.doublePressed = function (o)
            fe.openDir(o.path)
        end
    else
        fileButton.doublePressed = function (o)
            fe.openFile(o.path, mos.getFileOpenModifierInput())
        end
    end

    return fileButton
end


---comment
---@param text string
---@param callback function
---@return LineEdit
function fe.newFileEdit(text, callback)
    local edit = engine.LineEdit:new()
    edit.expandW = true
    edit:grabFocus()
    edit.text = text
    edit.textSubmitted = function()
        callback(edit)
    end
    return edit
end

---comment
---@param callback function
---@return LineEdit
function fe.addFileEdit(callback)
    local edit = fe.newFileEdit("", callback)
    fileContainer:addChild(edit)
    fe.clearSelection()
    mosWindow:grabFocus()
    return edit
end

---Combines the current path and the filename
---@param name string
---@return string
function fe.nameToPath(name)
    return fs.combine(fe.currentPath, name)
end

function fe.formatName(name)
    local path = fe.nameToPath(name)
    return fs.getName(path)
end

---comment
---@param path string
function fe.openDir(path)
    if not fs.exists(path) then
        error("Attemting to open non existent dir '" .. path .. "'")
    end

    fe.currentPath = path
    fe.clearSelection()

    fileContainer:clearAndFreeChildren()
    pathContainer:clearAndFreeChildren()
    scrollContainer:setScroll(0)

    searchbar.text = ""

    local bRoot = pathContainer:addButton()
    bRoot.text = "/"
    bRoot.dragSelectable = true
    bRoot.pressed = function ()
        fe.openDir("")
    end

    local split = engine.utils.split(path, "/")
    local bPath = ""
    for i, v in ipairs(split) do
        bPath = fs.combine(bPath, v)

        local b = pathContainer:addButton()
        b.dragSelectable = true
        b.text = v .. "/"
        local ok = bPath
        b.pressed = function ()
            fe.openDir(ok)
        end
    end


    local dirNames = {}
    local fileNames = {}
    for _, file in ipairs(fs.list(path)) do
        local filePath = fe.nameToPath(file)
        if fs.isDir(filePath) then
            table.insert(dirNames, file)
        else
            table.insert(fileNames, file)
        end
    end

    for _, dirName in ipairs(dirNames) do
        local b = fe.addFileButton(dirName)
    end

    for _, fileName in ipairs(fileNames) do
        local b = fe.addFileButton(fileName)
    end

    fileContainer:_expandChildren()
    scrollContainer:_expandChildren()
    main:_expandChildren()
end

---comment
---@param filter string
function fe.filter(filter)
    for _, v in ipairs(fileContainer.children) do
        if filter == "" or v.path:find(filter, 1, true) ~= nil then
            v.visible = true
        else
            v.visible = false
        end
    end
    fileContainer:queueSort()
end

---comment
---@param path string
---@param openModifier FileOpenModifier
function fe.openFile(path, openModifier, ...)
    fe.openFileCallback(path, openModifier, ...)
end

function fe.refresh()
    fe.openDir(fe.currentPath)
end

---comment
---@param name string
function fe.makeFile(name)
    if name == nil or name == "" then return end
    name = fe.formatName(name)
    if fe.pPopupError(fs.open, fe.nameToPath(name), "w") then
        fe.addFileButton(name)
    end
end

---comment
---@param name string
function fe.makeDir(name)
    if name == nil or name == "" then return end
    name = fe.formatName(name)
    if fe.pPopupError(fs.makeDir, fe.nameToPath(name)) then
        fe.addFileButton(name)
    end
end

---comment
---@param b FileButton
function fe.favorite(b)
    if mos.isFileFavorite(b.path) then
        mos.removeFileFavorite(b.path)
    else
        mos.addFileFavorite(b.path)
    end
    mos.refreshMosDropdown()
end

function fe.favoriteSelection()
    for i, v in ipairs(fe.selection) do
        fe.favorite(v)
    end
    mos.refreshMosDropdown()
end

---comment
---@param b FileButton
function fe.delete(b)
    if fe.pPopupError(fs.delete, b.path) then
        -- TODO Remove from selection
        b:queueFree()
    end
end

function fe.deleteSelection()
    for i, v in ipairs(fe.selection) do
        fe.delete(v)
    end

    fe.clearSelection()
end

function fe.clearClipboard()
    fe.clipboard = {}
end

function fe.copySelectionToClipboard()
    fe.clearClipboard()
    for i, v in ipairs(fe.selection) do
        table.insert(fe.clipboard, v.path)
    end
end

---comment
---@param pasteMode PasteMode
function fe.pasteClipboard(pasteMode)
    local fn = fs.copy
    if pasteMode == fe.PasteMode.CUT then
        fn = fs.cut
    end

    for i, v in ipairs(fe.clipboard) do
        fe.pPopupError(fn, v, fe.nameToPath(fs.getName(v)))
    end

    fe.clearClipboard()
    fe.refresh()
end

---comment
---@param b FileButton
---@param name string
function fe.rename(b, name)
    name = fe.formatName(name)
    if b.text == name then
        return
    end

    local path = fe.nameToPath(name)
    if fe.pPopupError(fs.move, b.path, path) then
        b.text = name
        b.path = path
    end
    --fe.refresh()
end

---comment
---@param b FileButton
function fe.addRenameFileEdit(b)
    fe.selectFileButton(b, true)
    local edit = fe.newFileEdit(b.text, function (o)
        fe.rename(b, o.text)
        o:queueFree()
    end)
    edit.inheritStyle = false
    b:addChild(edit)
end

---comment
---@return FileButton|nil
function fe.getFocusFileButton()
    if #fe.selection == 0 then
        return nil
    else
        return fe.selection[#fe.selection]
    end
end


local function newAudioDropdown(name)
    ---@type Dropdown
    local dropdown = mos.engine.Dropdown:new()
    dropdown.text = disk.getAudioTitle(name) or disk.getMountPath(name)
    dropdown.text = "[" .. dropdown.text .. "]"
    dropdown.w = #dropdown.text
    dropdown:addToList("Play Audio")
    dropdown:addToList("Stop Audio")
    dropdown:addToList("----------", false)
    dropdown:addToList("Info")
    dropdown:addToList("----------", false)
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
            fe.ejectDisk(name)
        end
    end

    return dropdown
end

local function newDiskDropdown(name)
    ---@type Dropdown
    local dropdown = mos.engine.Dropdown:new()
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

---comment
---@param mountPath string
function fe.mountDisk(mountPath)
    
end

---comment
---@param mountPath string
function fe.unmountDisk(mountPath)
    
end

---comment
---@param mountPath string
function fe.ejectDisk(mountPath)
    fe.unmountDisk(mountPath)
    disk.eject(mountPath)
end


function fe.scanMounts()
    for i, path in ipairs(fe.mountPaths) do
        if disk.isPresent(path) then
            fe.mountDisk(path)
        end
    end
end

function fe.clearMounts()
    for path, _ in pairs(fe.mountedDisks) do
        fe.unmountDisk(path)
    end
end

function fe.backDir()
    if fe.currentPath == "" then
        fe.openDir("")
    else
        fe.openDir(fs.getDir(fe.currentPath))
    end
end

function backButton:pressed()
    fe.backDir()
end

if mos and mosWindow then
    local fileDropdown = mos.engine.Dropdown:new()
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

    function fileDropdown:optionPressed(i)
        local focusFileButton = fe.getFocusFileButton()
        local focusPath = nil
        if focusFileButton then
            focusPath = focusFileButton.path
        end

        local text = fileDropdown:getOptionText(i)
        if     text == "New File" then
            fe.addFileEdit(function (edit)
                edit:queueFree()
                fe.makeFile(edit.text)
            end)
        elseif text == "New Dir" then
            fe.addFileEdit(function (edit)
                edit:queueFree()
                fe.makeDir(edit.text)
            end)
        elseif text == "Open" then
            if focusPath then
                if fs.isDir(focusPath) then
                    fe.openDir(focusPath)
                else
                    fe.openFile(focusPath, mos.FileOpenModifier.NONE)
                end
            end
        elseif text == "Open w/ args" then
            if focusPath and fs.isDir(focusPath) == false then
                fe.openFile(focusPath, mos.FileOpenModifier.ARGS)
            end
        elseif text == "Edit" then
            if focusPath then
                if fs.isDir(focusPath) == false then
                    fe.openFile(focusPath, mos.FileOpenModifier.EDIT)
                end
            end
        elseif text == "Close" then
            if __window then
                __window:close()
            end
        end
    end

    local editDropdown = mos.engine.Dropdown:new()
    editDropdown.text = "Edit"
    editDropdown:addToList("Cut")
    editDropdown:addToList("Copy")
    editDropdown:addToList("Paste")
    editDropdown:addToList("--------", false)
    editDropdown:addToList("Rename")
    editDropdown:addToList("Favorite")
    editDropdown:addToList("--------", false)
    editDropdown:addToList("Delete")

    function editDropdown:optionPressed(i)
        local focusFileButton = fe.getFocusFileButton()
        if not focusFileButton then
            return
        end
        local focusPath = focusFileButton.path
        local text = editDropdown:getOptionText(i)
        if     text == "Cut" then
            fe.pasteMode = fe.PasteMode.CUT
            fe.copySelectionToClipboard()
        elseif text == "Copy" then
            fe.pasteMode = fe.PasteMode.COPY
            fe.copySelectionToClipboard()
        elseif text == "Paste" then
            fe.pasteClipboard(fe.pasteMode)
        elseif text == "Rename" then
            fe.addRenameFileEdit(focusFileButton)
            __window:grabFocus()
        elseif text == "Favorite" then
            fe.favoriteSelection()
        elseif text == "Delete" then
            fe.deleteSelection()
        end
    end

    mos.bindTool(mosWindow, function (focus)
        if focus then
            mos.addToToolbar(fileDropdown)
            mos.addToToolbar(editDropdown)
        else
            mos.removeFromToolbar(fileDropdown)
            mos.removeFromToolbar(editDropdown)
        end
    end)
end

function main:input(data)
    local event = data[1]
    if engine.input.isEventConsumed(event) then
        --return
    end

    if     event == "paste" then
        fe.pasteClipboard(fe.pasteMode)
    elseif event == "disk" then
        fe.scanDisks()
    elseif event == "disk_eject" then
        fe.clearDisks()
    elseif event == "mos_favorite_remove" then
        fe.refresh()
    elseif event == "mos_refresh_files" then
        fe.refresh()
    elseif event == "char" then
        local focus = engine.input.getFocus() -- This should be replaced with inputConsumed
        if focus == nil or focus.__type ~= "LineEdit" then
            searchbar:grabFocus()
            searchbar:input(data)
        end
    elseif event == "key" then
        if engine.input.isKey(keys.leftCtrl) then
            if     data[2] == keys.x then
                fe.pasteMode = fe.PasteMode.CUT
                fe.copySelectionToClipboard()
            elseif data[2] == keys.c then
                fe.pasteMode = fe.PasteMode.COPY
                fe.copySelectionToClipboard()
            end
        elseif data[2] == keys.delete then
            fe.deleteSelection()
        end

        if data[2] == keys.down then
            if #fileContainer.children == 0 then
                return
            end

            local focus = fe.getFocusFileButton()
            if focus == nil then
                fe.selectFileButton(fileContainer:getChild(1), true)
            else
                local start = engine.utils.find(fileContainer.children, focus) + 1
                for i = start, #fileContainer.children do
                    local c = fileContainer:getChild(i)
                    if c.visible then
                        fe.selectFileButton(c, true)
                        return
                    end
                end
                fe.clearSelection()
            end
        elseif data[2] == keys.up then
            if #fileContainer.children == 0 then
                return
            end

            local focus = fe.getFocusFileButton()
            if focus == nil then
                fe.selectFileButton(fileContainer:getChild(#fileContainer.children), true)
            else
                local start = engine.utils.find(fileContainer.children, focus)
                for i = 1, start - 1 do
                    local index = start - i
                    local c = fileContainer:getChild(index)
                    if c.visible then
                        fe.selectFileButton(c, true)
                        return
                    end
                end
                fe.clearSelection()
            end
        elseif data[2] == keys.enter then
            local focus = fe.getFocusFileButton()
            if focus then
                if fs.isDir(focus.path) then
                    fe.openDir(focus.path)
                else
                    fe.openFile(focus.path, mos.getFileOpenModifierInput())
                end
            end
        elseif data[2] == keys.right then
            local focus = fe.getFocusFileButton()
            if focus then
                if fs.isDir(focus.path) then
                    fe.openDir(focus.path)
                end
            end
        elseif data[2] == keys.left then
            fe.backDir()
        end
    end
end

engine.input.addRawEventListener(rawEvent)

if settings.dir then
    fe.currentPath = settings.dir
end

fe.openDir(fe.currentPath)

engine:start()

-- Ideas
-- When opening a folder just add more files to the container instead of replacing them