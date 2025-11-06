return function(engine, collision)

local targetTerm = term.current()

local inputConsumed = false
local mouse = {}
mouse.current = nil
mouse.cursorControl = nil
mouse.clickTime = os.clock()
mouse.doublePressed = false
mouse.dragX = 0
mouse.dragY = 0

local function isValid(o)
    if o == nil then
        return false
    elseif o.isValid == nil or o:isValid() == true then
        return true
    else
        return false
    end
end

local function isControlInPoint(c, x, y)
    return collision.inArea(
        x, y, math.floor(c.globalX) + 1, math.floor(c.globalY) + 1, math.floor(c.w) - 1, math.floor(c.h) - 1
        )
end

local function getBranchInPoint(root, x, y)
    if root.visible == false then
        return nil
    end

    for i = 1, #root.children do
        local child = root.children[#root.children - i + 1]
        local branchInPoint = getBranchInPoint(child, x, y)
        if branchInPoint then
            return branchInPoint
        end
    end

    if isControlInPoint(root, x, y) and root.mouseIgnore == false then
        return root
    end

    return nil
end

---Returns a list with all the root top level controls
---@param parent Control
---@param list table
---@return table
local function getTopLevelControls(parent, list)
    for i, child in ipairs(parent.children) do
        if child.topLevel then
            table.insert(list, child)
        else
            getTopLevelControls(child, list)
        end
    end

    return list
end

---Returns the deepest control in branch that overlaps point (x, y)
---@param x number
---@param y number
---@return Control|nil
function mouse.getControlInPoint(x, y)
    local topControls = getTopLevelControls(engine.root, {})
    for _, control in ipairs(topControls) do
        local branch = getBranchInPoint(control, x, y)
        if branch then
            return branch
        end
    end

    return getBranchInPoint(engine.root, x, y)
end

---Returns the focus owner of control c 
---@param c Control
---@return Control|nil
function mouse.getFocusOwner(c)
    if c == nil then
        return nil
    elseif c:isValid() == false then
        return nil
    elseif c.propogateFocusUp == false then
        return c
    else
        return mouse.getFocusOwner(c.parent)
    end
end

local focusChangedListeners = {}

local function addFocusChangedListener(o)
    table.insert(focusChangedListeners, o)
end

local function focusChangedEvent(o)
    for i = 1, #focusChangedListeners do
        if type(focusChangedListeners[i]) == "table" then
            focusChangedListeners[i]:focusChangedEvent(o)
        elseif type(focusChangedListeners[i]) == "function" then
            focusChangedListeners[i](o)
        end
    end
end

function mouse.changeFocus(o)
    local owner = mouse.getFocusOwner(o)
    local currentOwner = mouse.getFocusOwner(mouse.current)

    if owner == currentOwner then
        mouse.current = o
        return
    end

    if currentOwner ~= nil then
        currentOwner.focus = false
    end

    if owner ~= nil then
        owner.focus = true
    end

    if currentOwner ~= nil then
        currentOwner:focusChanged()
        currentOwner:emitSignal(currentOwner.focusChangedSignal)
    end

    if owner ~= nil then
        focusChangedEvent(owner)
        owner:focusChanged()
        owner:emitSignal(owner.focusChangedSignal)
    end

    mouse.current = o
end

function mouse.inTerm(x, y)
    local w, h = targetTerm.getSize()
    return collision.inArea(x, y, 1, 1, w, h)
end

function mouse.click(button, x, y)
    mouse.dragX = x
    mouse.dragY = y
    local c = mouse.getControlInPoint(x, y)
    if mouse.current ~= c then -- If user clicks on a new control (or nothing)
        mouse.clickTime = os.clock()
        mouse.changeFocus(c)
    elseif c ~= nil then -- If user clicks on the same control
		local time = os.clock()
		local delta = time - mouse.clickTime
		mouse.clickTime = time
		if delta < 0.33 then
			c:doublePressed(delta)
		end
	end

    if c == nil then
       return
    end

    c:click(x - c.globalX, y - c.globalY, button)
end

local function grabControlFocus(c)
    mouse.changeFocus(c)
end

local function releaseControlFocus(c)
    mouse.changeFocus(nil)
end

local function setCursorControl(c)
    mouse.cursorControl = c
end

local function getCursorControl()
    if isValid(mouse.cursorControl) then
        return mouse.cursorControl
    else
        return nil
    end
end

function mouse.up(button, x, y)
    if isValid(mouse.current) == false then return end
    mouse.current:up(x, y, button)
    mouse.current:pressed(x, y, button)
end

function mouse.drag(button, x, y) 
    if isValid(mouse.current) == false then return end
    local relativeX = x - mouse.dragX
    local relativeY = y - mouse.dragY
    local c = mouse.getControlInPoint(x, y)
    if c ~= nil and c ~= mouse.current and c.dragSelectable == true and mouse.current.dragSelectable == true then
        mouse.current:up()
        mouse.changeFocus(c)
        c:click(x - c.globalX, y - c.globalY, button)
    end
    mouse.dragX = x
    mouse.dragY = y
    mouse.current:drag(relativeX, relativeY, x - mouse.current.globalX, y - mouse.current.globalY, button)
end

function mouse.scroll(dir, x, y)
    local function scrollControl(c)
        if isControlInPoint(c, x, y) == true then
            c:scroll(dir)
        end

        for i = 1, #c.children do
            scrollControl(c.children[i])
        end
    end

    scrollControl(engine.root)
end

local function getFocus()
    return mouse.getFocusOwner(mouse.current)
end

local keys = {}
local keyListeners = {}
local charListeners = {}
local scrollListeners = {}
local mouseEventListeners = {}

local function sendEvent(listeners, fun, ...)
    for i = 1, #listeners do
        if inputConsumed == true then -- This doesn't seem to work
            return
        end

        if isValid(listeners[i]) == true then
            if type(listeners[i]) == "table" then
                listeners[i][fun](listeners[i], ...)
            elseif type(listeners[i]) == "function" then
                listeners[i](...)
            end
        end
    end
end

local function isKey(key)
    return keys[key] == true
end

local function key(k)
    keys[k] = true
    sendEvent(keyListeners, "key", k)
end

local function keyUp(key)
    keys[key] = false
end

local function addKeyListener(o)
    table.insert(keyListeners, o)
end

local function char(c)
    sendEvent(charListeners, "char", c)
end

local function addCharListener(o)
    table.insert(charListeners, o)
end

local function mouseClick(button, x, y)
    if mouse.inTerm(x, y) == false then return end
    mouse.click(button, x, y)
end

local function mouseScroll(dir, x, y) -- NOTE: This is bad, TODO remake how objects recieve input
    if mouse.inTerm(x, y) == false then return end
    mouse.scroll(dir, x, y)
    for i = 1, #scrollListeners do
        scrollListeners[i].scroll(scrollListeners[i], dir, x, y)
    end
end

local function addScrollListener(o)
    table.insert(scrollListeners, o)
end

local function mouseUp(button, x, y)
    if mouse.inTerm(x, y) == false then return end
    mouse.up(button, x, y)
end

local function mouseDrag(button, x, y)
    if mouse.inTerm(x, y) == false then
        if mouse.current then
            mouse.current:up()
        end
    else
        mouse.drag(button, x, y)
    end
end

local function mouseEvent(event, data)
    for i = 1, #mouseEventListeners do
        mouseEventListeners[i]:mouseEvent(event, data)
    end
end

local function addMouseEventListener(o)
    table.insert(mouseEventListeners, o)
end

local resizeEventListeners = {}

local function addResizeEventListener(o)
    table.insert(resizeEventListeners, o)
end

local function resizeEvent()
    for i = 1, #resizeEventListeners do 
        if type(resizeEventListeners[i]) == "table" then
            resizeEventListeners[i]:resizeEvent()
        elseif type(resizeEventListeners[i]) == "function" then
            resizeEventListeners[i]()
        end
    end
end

local rawEventListeners = {}

local function addRawEventListener(o)
    table.insert(rawEventListeners, o)
end

local function removeRawEventListener(o)
    table.remove(rawEventListeners, engine.utils.find(rawEventListeners, o))
end

local function rawEvent(data)
    for _, listener in ipairs(rawEventListeners) do
        if isValid(listener) then
        if type(listener) == "table" then
            listener:rawEvent(data)
        elseif type(listener) == "function" then
            listener(data)
        end
    end
    end
end

local function consumeInput()
    inputConsumed = true
end

local function isInputConsumed()
    return inputConsumed
end

---comment
---@return string|nil
local function processInput()
    local data = table.pack(os.pullEventRaw())
    local event = data[1]

    if isValid(mouse.current) == false then
        mouse.current = nil
    end

    if isValid(mouse.cursorControl) == false then
        mouse.cursorControl = nil
    end

    if event == 'key' then
        key(data[2])
    elseif event == 'key_up' then
        keyUp(data[2])
    elseif event == 'char' then
        char(data[2])
    elseif event == 'mouse_click' then
        mouseClick(
            data[2],
            data[3],
            data[4]
        )
    elseif event == 'mouse_up' then
        mouseUp(
            data[2],
            data[3],
            data[4]
        )
    elseif event == "mouse_drag" then
        mouseDrag(
            data[2],
            data[3],
            data[4]
        )
    elseif event == "mouse_scroll" then
        mouseScroll(
            data[2],
            data[3],
            data[4]
        )
    elseif event == "term_resize" then
        resizeEvent()
    end

    rawEvent(data)

    if event then -- HACK, an empty event should never be sent (problem from multiProgram.launchProgram)
        if string.find(event, "mouse") ~= nil then
            mouseEvent(event, data)
        end
    end

    inputConsumed = false

    return event
end

local function setTargetTerm(t)
   targetTerm = t 
end

---@class Input
local Input = {
    isKey = isKey,
    addKeyListener = addKeyListener,
    addCharListener = addCharListener,
    processInput = processInput,
    addScrollListener = addScrollListener,
    addMouseEventListener = addMouseEventListener,
    addResizeEventListener = addResizeEventListener,
    addRawEventListener = addRawEventListener,
    removeRawEventListener = removeRawEventListener,
    grabControlFocus = grabControlFocus,
    releaseControlFocus = releaseControlFocus,
    getFocus = getFocus,
    addFocusChangedListener = addFocusChangedListener,
    setCursorControl = setCursorControl,
    getCursorControl = getCursorControl,
    consumeInput = consumeInput,
    isInputConsumed = isInputConsumed,
    setTargetTerm = setTargetTerm
}

return Input
end