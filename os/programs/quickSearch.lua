---@param mos MOS
return function (mos)
local engine = mos.engine

---@class QuickSearch : LineEdit
local qs = engine.LineEdit:new()
qs.h = 1
qs.expandW = true
qs.visible = false
qs.focusStyle = mos.styles.style

qs.marginL = 2
qs._skip = true

qs.programs = {}

table.insert(qs.programs, { name = "File Explorer", path = "/mos/os/programs/fileExplorer.lua" })
table.insert(qs.programs, { name = "Shell", path = "/rom/programs/advanced/multishell.lua" })
table.insert(qs.programs, { name = "Settings", path = "/mos/os/programs/settings.lua" })
table.insert(qs.programs, { name = "Paint", path = "/mos/os/programs/paint.lua" })
table.insert(qs.programs, { name = "Lua", path = "/rom/programs/lua.lua" })
table.insert(qs.programs, { name = "Time", path = "/rom/programs/time.lua" })

local dirs = { "" }
local index = 1
while index <= #dirs do
    local dir = dirs[index]
    local files = fs.list(dirs[index])
    for i, file in ipairs(files) do
        if fs.isDir(file) then
            if file ~= "rom" and file ~= "mos" and file ~= ".logs" and file ~= ".mosdata" then
                table.insert(dirs, fs.combine(dir, file))
            end
        else
            table.insert(qs.programs, { name = file, path = fs.combine(dir, file) })
        end
    end

    index = index + 1
end


function qs:trueTextChanged ()
    engine.LineEdit.trueTextChanged(self)
    qs:refreshList()
end

function qs:char (char)
    if self._skip == false then
        engine.LineEdit.char(self, char)
    end
    self._skip = false
end

function qs:open()
    self._skip = true
    self.trueText = ""
    self:grabFocus()
    self:refreshList()
    self.list.shortcutSelection = self.list.children[1]
    self.list:next()
end

function qs:close()
    self:grabFocus()
    self:releaseFocus()
    self.visible = false
    self.list:clearList()
end


function qs:next()
    if self:isOpen() then
        self.list:next()
    end
end

function qs:previous()
    if self:isOpen() then
        self.list:previous()
    end
end

function qs:select()
    if self.list.shortcutSelection then
        self.list.shortcutSelection:pressed()
    end
end

function qs:isOpen()
    return self.visible
end

function qs:focusChanged()
    engine.LineEdit.focusChanged(self)
    self.visible = self:inFocus()
end

local list = qs:addDropdown()
list.propogateFocusUp = true
list.rendering = false
list.mouseIgnore = true
qs.list = list

local icon = qs:addControl()
icon.w = 1
icon.h = 1
icon.text = string.char(187)


function qs:refreshList ()
    --[[
    local function getFiles(dir, list)
        local files = fs.list(dir)
        local dirs = {}
        for k, file in ipairs(files) do
            if fs.isDir(fs.combine(dir, file)) then
                table.insert(dirs, file)
            else
                table.insert(list, fs.combine(dir, file))
            end
        end

        for _, newDir in ipairs(dirs) do
            if newDir ~= "rom" and string.sub(newDir, 0, 1) ~= "." then
                getFiles(fs.combine(dir, newDir), list)
            end
        end

        return list
    end

    if fs.exists("/.mosdata/paths") == false then
        return
    end

    local shortcuts = {}
    for path, fav in pairs(mos.profile.favorites) do
        table.insert(shortcuts, { name = fav.name, file = path })
    end

    for _, file in ipairs(fs.list("/.mosdata/paths")) do
        table.insert(shortcuts, { name = file, path = fs.combine("/.mosdata/paths", file) })
    end
    ]]--

    local pathSelection = ""
    if list.shortcutSelection then
        pathSelection = list.shortcutSelection.text
    end

    local count = 0
    list:clearList()
    for i, program in ipairs(qs.programs) do
        if count >= 10 then
            break;
        end

        local continue = true
        __Global.log(program.name:sub(0, 1))
        if mos.profile.showDotFiles == false and program.name:sub(0, 1) == "." then
            continue = false
        end

        if program.name:lower():find(qs.trueText:lower()) == nil then --and fs.isDir(files[i]) == false then
            continue = false
        end

        if continue then
            local option = list:addToList(program.name)--shortcuts[i]:sub(1, #shortcuts[i] - 4))
            option.pressed = function (o)
                self:close()
                mos.openProgram(program.path)
            end

            if option.text == pathSelection then
                list.shortcutSelection = option
                option:click()
            end

            count = count + 1
        end
    end

    if list.shortcutSelection == nil then
        list.shortcutSelection = list
        list:next()
    end
end

return qs
end
