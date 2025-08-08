local engine = require(".core.engine")
local mos = __mos

local args = {...}

local paint = {}
paint.canvas = nil
paint.saveFile = ""
paint.colorL = colors.red
paint.colorR = colors.orange
paint.edited = false

local sprite = nil

local colourLookup = {}
for n = 1, 16 do
    colourLookup[string.byte("0123456789abcdef", n, n)] = 2 ^ (n - 1)
end

paint.charToColor = function (char)
    return colourLookup[char]
end

paint.colorToChar = function (color)
    if type(color) == "number" then
        local value = math.floor(math.log(color) / math.log(2)) + 1
        if value >= 1 and value <= 16 then
            return string.sub("0123456789abcdef", value, value)
        end
    end
    return " "
end

paint.createCanvas = function (w, h)
    local canvas = {}
    for i = 1, h do
        canvas[i] = {}
        for j = 1, w do
            canvas[i][j] = -1
        end
    end

    return canvas
end

paint.fillCanvas = function (canvas, color)
    for i = 1, #canvas do
        for j = 1, #canvas[i] do
            canvas[i][j] = color
        end
    end
end

paint.clearCanvas = function (canvas)
    paint.fillCanvas(canvas, -1)
end

paint.resizeCanvas = function (canvas, x, y, w, h)
    local _w, _h = paint.getCanvasSize(canvas)

    -- Trim
    if h < _h then
        for i = h, _h - 1 do
            table.remove(canvas, #canvas)
        end
    end

    if y > 1 then
        for i = 1, y - 1 do
            table.remove(canvas, 1)
        end
    end

    _w, _h = paint.getCanvasSize(canvas)
    if w < _w then
        for i = 1, _h do
            for j = w, _w - 1 do
                table.remove(canvas[i], #canvas[i])
            end
        end
    end

    if x > 1 then
        for i = 1, _h do
            for j = 1, x - 1 do
                table.remove(canvas[i], 1)
            end
        end
    end

    -- Expand
    _w, _h = paint.getCanvasSize(canvas)

    -- TODO Add expand left and up

    if h - y + 1 > _h then
        for i = _h + 1, h - y + 1 do
            local line = {}
            for j = 1, _w do
                line[j] = -1
            end
            table.insert(canvas, #canvas + 1, line)
        end
    end

    _w, _h = paint.getCanvasSize(canvas)
    if w - x + 1 > _w then
        for i = 1, _h do
            for j = _w + 1, w - x + 1 do
                canvas[i][j] = -1
            end
        end
    end
end

paint.trimCanvas = function (canvas)
    local w, h = paint.getCanvasSize(canvas)
    local l, r, u, d = w, 1, -1, -1
    local uLocked = true
    local dLocked = true
    for i = 1, h do
        local count = 0
        for j = 1, w do
            if canvas[i][j] > -1 then
                l = math.min(l, j)
                r = math.max(r, j)
                count = count + 1
            end
        end
        if count == 0 then
            uLocked = false
            if dLocked == false and d == -1 then
                d = i - 1
            end
        else
            dLocked = false
            if uLocked == false and u == -1 then
                u = i
            end
        end
    end

    if d == -1 then -- TODO Fix check
        d = w
    end

    if u == -1 then
        u = 1
    end


    paint.resizeCanvas(canvas, l, u, r, d)
end

paint.getCanvasSize = function (canvas)
    local w, h = 0, #canvas
    for i = 1, h do
        w = math.max(w, #canvas[i])
    end

    return w, h
end

paint.saveCanvas = function (canvas, file)
    local f, err = fs.open(file, "w")
    if not f then
        return false, err
    end

    canvas = canvas or paint.canvas

    local w, h = paint.getCanvasSize(canvas)
    for i = 1, h do
        local line = ""
        for j = 1, w do
            line = line .. paint.colorToChar(canvas[i][j])
        end
        f.writeLine(line)
    end

    f.close()
    return true
end

paint.setCanvasPixel = function (canvas, x, y, color)
    canvas[y][x] = color
end

paint.fitSprite = function ()
    sprite.w, sprite.h = paint.getCanvasSize(paint.canvas)
end

paint.centerSprite = function ()
    local w, h = engine.root.w, engine.root.h
    sprite.x, sprite.y = math.floor((w - sprite.w) / 2.0), math.floor((h - sprite.h) / 2.0)
end

paint.newImage = function (w, h)
    paint.saveFile = ""
    paint.canvas = paint.createCanvas(w, h)
    paint.fitSprite()
    paint.centerSprite()
    sprite:redraw()
end

paint.openImage = function (file)
    paint.saveFile = file
    paint.canvas = paintutils.loadImage(file) -- FIXME if image isn't stored as a square it will result in canvas not being a square
    paint.fitSprite()
    paint.centerSprite()
    sprite:redraw()
    __window.text = "Paint " .. fs.getName(file)
end

paint.saveImage = function (file)
    paint.saveFile = file
    paint.saveCanvas(paint.canvas, file)
    __window.text = "Paint " .. fs.getName(file)
end

paint.setEdited = function (edited)
    edited = edited or true
    if paint.edited == false and edited then
        paint.edited = true
        __window.text = __window.text .. "*"
        __window:redraw()
    end

    if paint.edited == true and edited == false then
        paint.edited = false
        __window.text = __window.text:sub(1, #__window.text - 1)
        __window:redraw()
    end
end

-- Ui [
sprite = engine.root:addControl()

engine.input.addRawEventListener(sprite)

local function fillArea(char, x, y, w, h)
    for i = 1, h do
        for j = 1, w do
            term.setCursorPos(x + j, y + i)
            term.write(char)
        end
    end
end

function sprite:render()
    if paint.canvas ~= nil then
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.gray)
        local w, h = term.getSize()
        fillArea('\146', 0, 0, w, h)

        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.lightGray)
        w, h = paint.getCanvasSize(paint.canvas)
        fillArea('\127', self.x, self.y, w, h)

        paintutils.drawImage(paint.canvas, self.x + 1, self.y + 1)
    end
end

function sprite:setPixel(x, y, button)
    paint.setEdited()

    local color = paint.colorR
    if button == 1 then
        color = paint.colorL
    end

    paint.setCanvasPixel(paint.canvas, x, y, color)
    if color == -1 then
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.lightGray)
        term.setCursorPos(x + self.globalX, y + self.globalY)
        term.write('\127')
    else
        paintutils.drawPixel(x + self.globalX, y + self.globalY, color)
    end
end

function sprite:click(x, y, button)
    sprite:setPixel(x, y, button)
end

function sprite:drag(relativeX, relativeY, x, y, button)
    if x < 1 or y < 1 or x > self.w or y > self.h then return end
    sprite:setPixel(x, y, button)
end

function sprite:rawEvent(data)
    local event = data[1]
    if event == "key" then
        local key = data[2]
        if key == keys.d or key == keys.right then
            self.x = self.x - 1
        elseif key == keys.a or key == keys.left then
            self.x = self.x + 1
        elseif key == keys.w or key == keys.up then
            self.y = self.y + 1
        elseif key == keys.s or key == keys.down then
            self.y = self.y - 1
        end

        if key == keys.f then
            paint.centerSprite()
        end
    end
end

local palette = engine.root:addControl()
palette.rendering = false

palette.w = 2
palette.anchorW = palette.anchor.RIGHT
palette.expandH = true

local colorL = palette:addControl()
local colorR = palette:addControl()
colorL.text = ""
colorR.text = ""
colorL.y = 16
colorR.y = 16
colorL.x = 0
colorR.x = 1
colorL.w = 1
colorR.w = 1
colorL.h = 1
colorR.h = 1
colorL.style = engine.newStyle()
colorR.style = engine.newStyle()
colorL.style.backgroundColor = paint.colorL
colorR.style.backgroundColor = paint.colorR

for i = 1, 16 do
    local c = palette:addControl()
    c.w = 2
    c.h = 1
    c.y = i - 1
    c.text = ""
    c.style = engine.newStyle()
    if i == 16 then
        c.style.backgroundColor = colors.gray
        c.style.textColor = colors.lightGray
        c.text = "\127\127"
        c.colorIndex = -1
    else
        c.style.backgroundColor = 2 ^ i
        c.colorIndex = c.style.backgroundColor
    end
    c.click = function (_, x, y, button)
        if button == 1 then
            paint.colorL = c.colorIndex
            colorL.style = c.style
        else
            paint.colorR = c.colorIndex
            colorR.style = c.style
        end
        c:redraw()
    end
end

local windowStyle = engine.newStyle()
windowStyle.backgroundColor = colors.white

local editStyle = engine.newStyle()
editStyle.backgroundColor = colors.gray
editStyle.textColor = colors.white

local editFocusStyle = editStyle:new()
editFocusStyle.backgroundColor = colors.black

local function createEditField(fieldName, text, parent)
    text = text or ""

    local h = engine.getObject("hContainer"):new{}
    h.h = 1
    h.expandW = true
    local label = h:addControl()
    label.text = fieldName
    label.h = 1
    label.fitToText = true
    h.sortOnTransformChanged = true

    local edit = h:addLineEdit()
    edit.inheritStyle = false
    edit.h = 1
    edit.expandW = true
    edit.trueText = text
    edit.normalStyle = editStyle
    edit.focusStyle = editFocusStyle
    edit.style = editStyle

    parent:addChild(h)

    return edit
end

local function createDialogue()
    local wi = engine.root:addWindowControl()
    wi.style = windowStyle
    wi.x = 1
    wi.y = 1
    return wi
end

local function createResizeDialogue(fn)
    local _w, _h = paint.getCanvasSize(paint.canvas)

    local wi = createDialogue()
    wi.text = "Resize"
    wi.vContainer = wi:addVContainer()
    wi.vContainer.expandW = true
    wi.vContainer.expandH = true
    wi.vContainer.y = 1
    wi.wEdit = createEditField("W: ", tostring(_w), wi.vContainer)
    wi.hEdit = createEditField("H: ", tostring(_h), wi.vContainer)
    wi.ok = wi:addButton()
    wi.ok.text = "Ok"
    wi.ok.h = 1
    wi.ok.expandW = true
    wi.ok.centerText = true
    wi.ok.anchorH = wi.anchor.DOWN
    wi.ok.pressed = function ()
        local w = tonumber(wi.wEdit.trueText) or _w
        local h = tonumber(wi.hEdit.trueText) or _h
        fn(w, h)
        wi:queueFree()
    end
    wi:_expandChildren()

    wi.wEdit:grabFocus()
end

-- ]

if mos then
    local fileDropdown = mos.engine.getObject("dropdown"):new{}
    fileDropdown.text = "File"
    fileDropdown:addToList("New  Image")
    fileDropdown:addToList("Open Image")
    fileDropdown:addToList("----------", false)
    fileDropdown:addToList("Save")
    fileDropdown:addToList("Save As...")
    fileDropdown:addToList("----------", false)
    fileDropdown:addToList("Close")

    function fileDropdown:optionPressed(i)
        local text = fileDropdown:getOptionText(i)
        local fileExplorer = nil
        if text == "New  Image" then
            paint.newImage(16, 10)
        elseif text == "Open Image" then
            fileExplorer = mos.openProgram("Open File", "/os/programs/fileExplorer.lua", false, function (name, path)
                paint.openImage(path)
                fileExplorer:close()
                __window:grabFocus()
                paint.setEdited(false)
            end)
            return
        elseif text == "Save" then
            if paint.saveFile == "" then
                fileDropdown:optionPressed(i + 1)
                return
            else
                paint.saveImage(paint.saveFile)
                paint.setEdited(false)
            end
        elseif text == "Save As..." then
            fileExplorer = mos.openProgram("Save File", "/os/programs/fileExplorer.lua", false, function (name, path)
                local suffix = ".nfp"
                if path:sub(-#suffix) ~= suffix then
                    path = path .. suffix
                end
                paint.saveImage(path)
                fileExplorer:close()
                __window:grabFocus()
                paint.setEdited(false)
            end, "", true)
            return
        elseif text == "Close" then
            __window:close()
            return
        end

        __window:grabFocus()
    end

    local imageDropdown = mos.engine.getObject("dropdown"):new{}
    imageDropdown.text = "Image"
    imageDropdown:addToList("Resize")
    imageDropdown:addToList("Trim")
    imageDropdown:addToList("------", false)
    imageDropdown:addToList("Fill")
    imageDropdown:addToList("Clear")

    function imageDropdown:optionPressed(i)
        local text = imageDropdown:getOptionText(i)
        if text == "Resize" then
            createResizeDialogue(function (w, h)
                paint.resizeCanvas(paint.canvas, 1, 1, w, h)
                paint.fitSprite()
                paint.centerSprite()
                paint.setEdited()
            end)
        elseif text == "Trim" then
            paint.trimCanvas(paint.canvas)
            paint.fitSprite()
            sprite:redraw()
            paint.setEdited()
        elseif text == "Fill" then
            paint.fillCanvas(paint.canvas, paint.colorL)
            sprite:redraw()
            paint.setEdited()
        elseif text == "Clear" then
            paint.clearCanvas(paint.canvas)
            sprite:redraw()
            paint.setEdited()
        end

        __window:grabFocus()
    end

    mos.bindTool(__window, function (focus)
        if focus then
            mos.addToToolbar(fileDropdown)
            mos.addToToolbar(imageDropdown)
        else
            mos.removeFromToolbar(fileDropdown)
            mos.removeFromToolbar(imageDropdown)
        end
    end)
end

local startFile = args[1]
if startFile ~= nil and type(startFile) == "string" then
    paint.openImage(startFile)
end

if paint.canvas == nil then
    paint.newImage(16, 10)
end

engine.start()
