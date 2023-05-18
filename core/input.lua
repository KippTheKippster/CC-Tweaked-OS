mouse = {}
mouse.current = nil
mouse.clickTime = os.clock()
mouse.doublePressed = false
mouse.dragX = 0
mouse.dragY = 0

function mouse.getControl(x, y)
    for i = 1, #controls do
        local c = controls[#controls - i + 1] --Go in inverse order so the collision of the mouse matches with visuals (the button on top gets pressed)
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
end

function mouse.click(button, x, y)
    mouse.dragX = x
    mouse.dragY = y
    local c = mouse.getControl(x, y)
    if mouse.current ~= c then
        mouse.clickTime = os.clock()

        if mouse.current ~= nil then
            mouse.current:up()
            mouse.current.focus = false
            mouse.current:focusChanged()
        end
        mouse.current = c 
        if mouse.current ~= nil then
            mouse.current.focus = true
            mouse.current:focusChanged()
        end
    elseif c ~= nil then
		local time = os.clock()
		local delta = time - mouse.clickTime
		if delta < 0.4 then
			c:doublePressed(delta)
		end
		mouse.clickTime = time
	end
    
    if c == nil then
       return 
    end
    
    c:click()
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
    mouse.dragX = x
    mouse.dragY = y
    mouse.current:drag(relativeX, relativeY)
end

keys = {}
keyListeners = {}
charListeners = {}
scrollListeners = {}

function isKey(key)
    if keys[key] == true then
        return true
    end
    
    return false
end

function key(key)
    keys[key] = true
    for i = 1, #keyListeners do
        keyListeners[i]:key(key)
    end
end

function keyUp(key)
    keys[key] = false
end

function addKeyListener(o)
    table.insert(keyListeners, o)
end

function char(char)
    for i = 1, #charListeners do 
        charListeners[i]:char(char)
    end
end

function addCharListener(o)
    table.insert(charListeners, o)
end

function mouseClick(button, x, y)
    mouse.click(button, x, y)
end

function mouseScroll(dir, x, y)
    for i = 1, #scrollListeners do 
        scrollListeners[i]:scroll(dir, x, y)
    end
end

function addScrollListener(o)
    table.insert(scrollListeners, o)
end

function mouseUp(button, x, y)
    mouse.up(button, x, y)
end

function mouseDrag(button, x, y)
    mouse.drag(button, x, y)
end 

function processInput()
    while true do 
        local data = {os.pullEvent()}
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
        end
    end
end

return {
    isKey = isKey,
    addKeyListener = addKeyListener,
    addCharListener = addCharListener,
    processInput = processInput,
    addScrollListener = addScrollListener
}
