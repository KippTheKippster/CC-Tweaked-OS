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
qs.trueTextChanged = function (o)
    engine.LineEdit.trueTextChanged(o)
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

    local pathSelection = ""
    if list.shortcutSelection then
        pathSelection = list.shortcutSelection.text
    end

    list:clearList()

    for i = 1, #shortcuts do
        if shortcuts[i].name:lower():find(qs.trueText:lower()) ~= nil then --and fs.isDir(files[i]) == false then
            local option = list:addToList(shortcuts[i].name:sub(1, #shortcuts[i].name - 4))
            option.pressed = function (o)
                if shortcuts[i].path then
                    local file = fs.open(shortcuts[i].path, "r")
                    local path = file.readAll()
                    file.close()
                    self:close()
                    mos.openProgram(o.text, path, false)
                else
                    self:close()
                    mos.openProgram(o.text, shortcuts[i].file, false)
                end
            end

            if option.text == pathSelection then
                list.shortcutSelection = option
                option:click()
            end
        end
        --button.expandW = true
    end

    if list.shortcutSelection == nil then
        list.shortcutSelection = list
        list:next()
    end
end

return qs
end
