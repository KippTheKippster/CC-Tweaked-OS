return function(engine, collision)

local mouse = {}
mouse.current = nil
mouse.clickTime = os.clock()
mouse.doublePressed = false
mouse.dragX = 0
mouse.dragY = 0

local i1 = 0

local function controlInArea(c, x, y) 
    i1 = i1 + 1
    if collision.inArea(
        x, y, c.globalX + 1, c.globalY + 1, c.w - 1, c.h - 1
        ) 
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
        if #children[index].children > 0 then
            local inArea = childrenInArea(children[index].children, x, y)
            if inArea ~= nil then
                return inArea
            end
        end
        local inArea = controlInArea(children[index], x, y)
        if inArea ~= nil then
            return inArea
        end
    end

    return nil
end

function mouse.getControl(x, y)
    local inArea = childrenInArea(engine.root.children, x, y)
    return inArea
    --[[
    for i = 1, #controls do
        local c = controls[#controls - i + 1] --Go in inverse order so the collision of the mouse matches with visuals (the button on top gets pressed)
        print(main)
        if collision.inArea(
            x, y, c.globalX + 1, c.globalY + 1, c.w - 1, c.h - 1
            ) 
			and c.mouseIgnore == false
            and c.visible == true
        then
            return c 
        end
    end
    
    return nil
    ]]--
end

function mouse.getFocusOwner(o)
    if o == nil or o.propogateFocusUp == false then
        return o
    else
        return mouse.getFocusOwner(o.parent)
    end
end

function mouse.changeFocus(o)
    if o == mouse.current then
        return
    end

    local owner = mouse.getFocusOwner(o)

    if mouse.current ~= nil then
        local currentOwner = mouse.getFocusOwner(mouse.current)
        currentOwner.focus = false
        currentOwner:focusChanged()
    end

    mouse.current = o

    if owner ~= nil then
        owner.focus = true
        owner:focusChanged()
    end
end

function mouse.click(button, x, y)
    mouse.dragX = x
    mouse.dragY = y
    local c = mouse.getControl(x, y)
    if mouse.current ~= c then -- If user clicks on a new control
        mouse.clickTime = os.clock()
        if mouse.current ~= nil then
            mouse.current:up()
            --mouse.current.focus = false
            --mouse.current:focusChanged()
        end
        mouse.changeFocus(c)
        --mouse.current = c 
        --if mouse.current ~= nil then
        --    mouse.current.focus = true
        --    mouse.current:focusChanged()
        --end
    elseif c ~= nil then -- If user clicks on the same control
		local time = os.clock()
		local delta = time - mouse.clickTime
		mouse.clickTime = time
		if delta < 0.4 then
			c:doublePressed(delta)
		end
	end

    if c == nil then
       return 
    end

    c:click()
end

local function grabControlFocus(c) 
    mouse.changeFocus(c)
    --if c == mouse.current then return end

    --local prev = mouse.current
    --if prev ~= nil then
    --    prev.focus = false
    --end
    --mouse.current = c
    --c.focus = true
    --c:focusChanged()
    --if prev ~= nil then
    --    prev:focusChanged()
   -- end
end 

function mouse.up(button, x, y)
    if mouse.current == nil then return end
    mouse.current:up()
    mouse.current:pressed()
end

function mouse.drag(button, x, y) 
    if mouse.current == nil then return end
    local relativeX = x - mouse.dragX
    local relativeY = y - mouse.dragY
    local c = mouse.getControl(x, y)
    if c ~= nil and c ~= mouse.current and c.dragSelectable == true then
        if mouse.current.dragSelectable == false then
            mouse.current:up()
        end
        mouse.current.focus = false
        mouse.current:focusChanged()
        c.focus = true
        c:focusChanged()
        c:click()
        mouse.current = c
    end
    mouse.dragX = x
    mouse.dragY = y
    mouse.current:drag(relativeX, relativeY)
end

function mouse.scroll(dir, x, y)
    if mouse.current == nil then return end
    mouse.current:scroll(dir)
end

local keys = {}
local keyListeners = {}
local charListeners = {}
local scrollListeners = {}
local mouseEventListeners = {}

local function isKey(key)
    return keys[key] == true
end

local function key(key)
    keys[key] = true
    for i = 1, #keyListeners do
        keyListeners[i]:key(key)
    end
end

local function keyUp(key)
    keys[key] = false
end

local function addKeyListener(o)
    table.insert(keyListeners, o)
end

local function char(char)
    for i = 1, #charListeners do 
        charListeners[i]:char(char)
    end
end

local function addCharListener(o)
    table.insert(charListeners, o)
end

local function mouseClick(button, x, y)
    mouse.click(button, x, y)
end

local function mouseScroll(dir, x, y)
    mouse.scroll(dir)
    for i = 1, #scrollListeners do
        scrollListeners[i].scroll(scrollListeners[i], dir, x, y)
    end
end

local function addScrollListener(o)
    table.insert(scrollListeners, o)
end

local function mouseUp(button, x, y)
    mouse.up(button, x, y)
end

local function mouseDrag(button, x, y)
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

local function processInput()
    local data = {os.pullEventRaw()}
    local event = data[1]

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

    if string.find(event, "mouse") ~= nil then
        mouseEvent(event, data)
    end
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
    grabControlFocus = grabControlFocus
}
end