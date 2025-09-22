---@param mos MOS
return function (mos)
local engine = mos.engine

---@class QuickSearch : LineEdit
local qs = engine.LineEdit:new()
qs.h = 1
qs.expandW = true
qs.visible = false
qs.focusStyle = mos.styles.style
qs.trueTextChanged = function (o)
    engine.LineEdit.trueTextChanged(o)
    qs:refreshList()
end

function qs:open()
    self.trueText = ""
    self:grabFocus()
    self:refreshList()
    self.list.shortcutSelection = self.list
end

function qs:close()
    --self:releaseFocus()
    self:grabFocus()
    self:releaseFocus()
    self.visible = false
end


function qs:next()
    if self.visible == false then
        self:open()
    else
        self.list:next()
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

    if fs.exists("/.mosdata/shortcuts") == false then
        return
    end

    local shortcuts = {}
    for path, fav in pairs(mos.profile.favorites) do
        table.insert(shortcuts, { name = fav.name, path = path })
    end

    for _, file in ipairs(fs.list("/.mosdata/shortcuts")) do
        table.insert(shortcuts, { name = file, path = fs.combine("/.mosdata/shortcuts", file) })
    end

    list:next()
    list:clearList()

    for i = 1, #shortcuts do
        if shortcuts[i].name:find(qs.trueText) ~= nil then --and fs.isDir(files[i]) == false then
            local option = list:addToList(shortcuts[i].name:sub(1, #shortcuts[i].name - 4))
            option.pressed = function (o)
                local file = fs.open(shortcuts[i].path, "r")
                local path = file.readAll()
                file.close()
                self:close()
                mos.openProgram(o.text, path, false)
            end
        end
        --button.expandW = true
    end
end

return qs
end
