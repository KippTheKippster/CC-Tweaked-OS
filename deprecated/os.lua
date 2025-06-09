engine = require(".core.engine")
utils = require(".core.utils")
objects = engine.getObjects()

style = objects["style"]:new{}
style.backgroundColor = colors.black
style.textColor = colors.white

clickedStyle = style:new{}
clickedStyle.backgroundColor = colors.gray

engine.root = objects["control"]:new{}
engine.root.style = style
engine.root.visible = false
engine.root:add()

window = objects["control"]:new{}
window.draggable = true

propertyControl = objects["control"]:new{}
propertyControl.w = 16
propertyControl.h = 0
propertyControl.background = false
propertyControl.mouseIgnore = true

fileControl = objects["hContainer"]:new{}
fileControl.visible = true
fileControl.w = 52
fileControl.h = 0
fileControl.text = ""
fileControl.mouseIgnore = false
fileControl.background = true
fileControl.nameControl = nil
fileControl.typeControl = nil

function fileControl:ready()
    local name = propertyControl:new{}
    name:add()
    self:addChild(name)
    self.nameControl = name
    name.w = 24

    local type = propertyControl:new{}
    type:add()
    self:addChild(type)
    self.typeControl = type
end

function fileControl:up()
    self.style = style
end

function fileControl:click()
    self.style = clickedStyle
end

scroll = objects["scrollContainer"]:new{}
scroll:add()
scroll.background = false
engine.root:addChild(scroll)

fileExplorer = objects["vContainer"]:new{}
fileExplorer.visible = true
fileExplorer.background = true
fileExplorer.style = objects["clickedStyle"]:new{}
local w, h = term.getSize()
fileExplorer.w = w
fileExplorer.h = h + 64
fileExplorer.style = style
fileExplorer:add()
scroll:addChild(fileExplorer)

function fileExplorer:openFolder(path)
    local files = fs.list(path, "r")
    for i = 1, #files do
        local f = fileControl:new{}
        f:add()
        self:addChild(f)

        f.nameControl.text = files[i]
    end
end

fileExplorer:openFolder("")

w = window:new{}
w.text = "Window"
engine.root:addChild(w)
w.style = clickedStyle
w:add()

b = objects["control"]:new{}
b:add()
w:addChild(b)
b.style = objects["style"]:new{}
b.h = b.h - 1
b.x = 0 

close = objects["button"]:new{}
close.text = "x"
close.h = 0
close.w = 0
close:add()
w:addChild(close)
close.x = 13
close.y = 0
close.normalStyle = clickedStyle


--TODO FIX!!
--fileExplorer.x = 0
--fileExplorer.x = 1

engine.start()

