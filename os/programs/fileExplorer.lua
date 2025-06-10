local engine = require(".core.engine")
local utils = require(".core.utils")
local currentPath = ""
local paths = {}

local args = {...}
local callbackFunction = args[1]

local main = engine.root:addControl()
local inputReader = {}

engine.input.addScrollListener(inputReader)
engine.input.addResizeEventListener(inputReader)



function main:ready()
    engine:getVCointainer().ready(main)
    a.b = 2

end

--tools
local toolsStyle = engine:newStyle() 
toolsStyle.backgroundColor = colors.white

local tools = main:addHContainer()
tools.rendering = true
tools.h = 1
tools.w = 51
tools.text = "  res:/"
tools.style = toolsStyle

local backButton = tools:addButton()
backButton.w = 1
backButton.h = 1
backButton.text = '<'
backButton.normalStyle = toolsStyle

function backButton:pressed()
    if (#paths <= 0) then return end
    table.remove(paths, #paths)
    openCurrentFolder()
end

--files
local vContainer = main:addVContainer()
vContainer:toBack()
vContainer.rendering = true
vContainer.background = true
vContainer.visible = true
vContainer.style.backgroundColor = colors.black

vContainer.x = 0
vContainer.y = 0
vContainer.w = 51
vContainer.h = 99

function inputReader:scroll(dir, x, y)
    local newY = vContainer.y - dir
    local w, h = term.getSize()
    term.setTextColour(colors.white)
    if newY > 1 then
        --vContainer.y = 1
        --return
    elseif newY < h - #vContainer.children then
        --vContainer.y = h - #vContainer.children
        --return
    end
    vContainer.y = newY
    --print(#vContainer.children .. " : " .. vContainer.y .. " : " .. vContainer.h .. " : " .. h)
    --print(h - #vContainer.children)
end


function inputReader:resizeEvent()
    local w, h = term.getSize()
    main.h = h + 2
    vContainer.h = 99
end


local style = engine:newStyle()
style.backgroundColor = colors.black
style.textColor = colors.white

local clickedStyle = engine:newStyle()
clickedStyle.backgroundColor = colors.gray
clickedStyle.textColor = colors.white

local fileButton = engine.getObject("button"):new{}
fileButton.h = 1
fileButton.w = 52
fileButton.normalStyle = style
fileButton.clickedStyle = clickedStyle

function fileButton:doublePressed()
    callbackFunction(currentPath .. self.text, self.text)--Left CTRL
end

local dirStyle = style:new{}
dirStyle.textColor = colors.green

local dirButton = fileButton:new{}
dirButton.normalStyle = dirStyle

local function openFolder(path)
    vContainer.y = 1
    tools.text = "  res:/" .. path
    --term.clear()
    for i = 1, #vContainer.children do
        vContainer.children[1]:remove()
    end
    vContainer.children = {}
    local names = fs.list(path, "r")
    local files = {}
    local dirs = {}
    for i = 1, #names do
        if fs.isDir(path .. names[i]) then
            table.insert(dirs, names[i])
        else
            table.insert(files, names[i])
        end
    end

    for i = 1, #dirs do
        local b = dirButton:new{}
        b.text = dirs[i]
        vContainer:addChild(b)
        b.style = dirStyle
    end

    for i = 1, #files do
        local b = fileButton:new{}
        b.text = files[i]
        vContainer:addChild(b)
        b.style = style
    end
end

function openCurrentFolder()
    currentPath = ""
    for i = 1, #paths do
        currentPath = currentPath .. paths[i] .. "/"
    end
    openFolder(currentPath)
end

function dirButton:doublePressed()
    table.insert(paths, self.text)
    openCurrentFolder(currentPath)
end

openFolder("")
engine:start()
