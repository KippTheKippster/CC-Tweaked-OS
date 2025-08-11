return function(engine, collision)

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

local function isControlInArea(c, x, y)
    return collision.inArea(
        x, y, math.floor(c.globalX) + 1, math.floor(c.globalY) + 1, math.floor(c.w) - 1, math.floor(c.h) - 1
        )
end

local function controlInArea(c, x, y)
    if isControlInArea(c, x, y)
        and c.mouseIgnore == false
        and c.visible == true
    then
        return c
    end

    return nil
end

local function childrenInArea(children, x, y)
    for i = 1, #children do
        local index = #children - i + 1
        if children[index].visible == true and #children[index].children > 0 then
            local inArea = childrenInArea(children[index].children, x, y)
            if inArea ~= nil then
                return inArea
            end
        end
        local inArea = controlInArea(children[index], x, y)
        if inArea ~= nil and inArea.visible == true then
            return inArea
        end
    end

    return nil
end

function mouse.getControl(x, y)
    return childrenInArea(engine.root.children, x, y)
end

function mouse.getFocusOwner(o)
    if o == nil then
        return nil
    elseif o:isValid() == false then
        return nil
    elseif o.propogateFocusUp == false then
        return o
    else
        return mouse.getFocusOwner(o.parent)
    end
end

function mouse.propogateInput(o, method, ...)
    method(o, ...)
    if o.propogateInputUp == true then
        mouse.propogateInput(o.parent)
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
    local w, h = term.getSize()
    return collision.inArea(x, y, 1, 1, w, h)
end

function mouse.click(button, x, y)
    mouse.dragX = x
    mouse.dragY = y
    local c = mouse.getControl(x, y)
    if mouse.current ~= c then -- If user clicks on a new control (or nothing)
        mouse.clickTime = os.clock()
        if mouse.current ~= nil then
            --mouse.current:up()
        end
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
    local c = mouse.getControl(x, y)
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
    --if mouse.current == nil then return end
    local function scrollControl(c, dir, x, y)
        if isControlInArea(c, x, y) == true then
            c:scroll(dir)
        end

        for i = 1, #c.children do
            scrollControl(c.children[i], dir, x, y)
        end
    end

    scrollControl(engine.root, dir, x, y)
    --mouse.current:scroll(dir)
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

        if isValid(listeners[i]) == false then
            --table.remove(listeners, i) -- I have no idea if this is safe
        else
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
    --for i = 1, #keyListeners do
    --    keyListeners[i]:key(k)
    --end
end

local function keyUp(key)
    keys[key] = false
end

local function addKeyListener(o)
    table.insert(keyListeners, o)
end

local function char(c)
    sendEvent(charListeners, "char", c)
    --for i = 1, #charListeners do 
    --    charListeners[i]:char(char)
    --end
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
    if mouse.inTerm(x, y) == false then return end 
    mouse.drag(button, x, y)
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

local function rawEvent(data)
    for i = 1, #rawEventListeners do 
        if type(rawEventListeners[i]) == "table" then
            rawEventListeners[i]:rawEvent(data)
        elseif type(rawEventListeners[i]) == "function" then
            rawEventListeners[i](data)
        end
    end
end

local function consumeInput()
    inputConsumed = true
end

local function isInputConsumed()
    return inputConsumed
end

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
    elseif event == "terminate" then
        --term.clear()
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

return {
    isKey = isKey,
    addKeyListener = addKeyListener,
    addCharListener = addCharListener,
    processInput = processInput,
    addScrollListener = addScrollListener,
    addMouseEventListener = addMouseEventListener,
    addResizeEventListener = addResizeEventListener,
    addRawEventListener = addRawEventListener,
    grabControlFocus = grabControlFocus,
    releaseControlFocus = releaseControlFocus,
    getFocus = getFocus,
    addFocusChangedListener = addFocusChangedListener,
    setCursorControl = setCursorControl,
    getCursorControl = getCursorControl,
    consumeInput = consumeInput,
    isInputConsumed = isInputConsumed
}
end