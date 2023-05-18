local path = ".core."

local tProcesses = {}
local focusIndex = 1
local parentTerm = term.current()
local collision = require(path .. "collision")

function launchProgram(path, x, y, w, h, ...)
    local env = { shell = shell, multishell = multishell }
    env.require, env.package = dofile("rom/modules/main/cc/require.lua").make(env, "")
    local args = table.pack(...)
    return launchProcess(function()
        os.run(env, path, table.unpack(args, 1, args.n))
    end, x, y, w, h)
end

function launchProcess(fun, x, y, w, h, ...)
    local p = {}
    local args = table.pack(...)
    p.co = coroutine.create(function(args)
        fun(table.unpack(args, 1, args.n))
    end)
    p.window = window.create(parentTerm, x, y, w, h, true)
    tProcesses[#tProcesses + 1] = p
    setFocus(#tProcesses)
    return p
end

function resumeProcess(p, event, ...)
    --local p = tProcesses[i]
    term.redirect(p.window)
    local ok, result = coroutine.resume(p.co, event, ...)
    --print(tostring(ok) .. " : " .. event .. " : " .. tostring(result) .. " : " .. tostring(coroutine.status(p.co) .. " : " .. tostring(coroutine.running ())))
    p.window.redraw() 
end

function resumeProcesses(event, ...)
    for i = 1, #tProcesses do
        resumeProcess(tProcesses[i], event, ...)
    end
end

function clearProcess(i, force)
    local force = force or false
    local p = tProcesses[i]
    if coroutine.status(p.co) == "dead" or force == true then
        table.remove(tProcesses, i)
        if nCurrentProcess == nil then
            if i > 1 then
                setFocus(i - 1)
            elseif #tProcesses > 0 then
                setFocus(1)
            end
        end
    end
end

function clearProcesses(force)
    local force = force or false
    for i = 1, #tProcesses do
        clearProcess(i, force)
    end

    if (#tProcesses == 0 and force == false) then
        exit()
    end
end

function getWindow(x, y)
    for i = 1, #tProcesses do
        local p = tProcesses[#tProcesses - i + 1]
        local window = p.window
        local x1, y1 = window.getPosition()
        local w, h = window.getSize()
        if window.isVisible() and collision.inArea(x, y, x1, y1, w, h) then
            return p
        end
    end

    return nil
end 

function setFocus(n)
    focusIndex = n
end

local running = true
function start()
    term.clear()
    while running do 
        term.redirect(parentTerm)
        local data = table.pack(os.pullEvent())
        local event = data[1]

        if event == "mouse_click" or event == "mouse_drag" or event == "mouse_drag" or event == "mouse_up"then
            local button, x, y = data[2], data[3], data[4]
            local p = getWindow(x, y)
            if p ~= nil then
                local offsetX, offsetY =  p.window.getPosition()
                resumeProcess(p, event, button, x - offsetX + 1, y - offsetY + 1)
            end
        else --if event == "timer" then
            resumeProcesses(event, table.unpack(data, 2, #data))
        end

        clearProcesses()
    end
    --parentTerm.clear()
    --term.setCursorPos(1, 1)
    --print("Done...")
end

function exit()
    clearProcesses(true)
    running = false
end

--launchProgram("os/os.lua", 3, 3, 51, 20)
--launchProgram("rom/tProcesses/fun/advanced/paint.lua", 3, 3, 51 - 51 / 2, 20 - 20 / 2, "multiPaint")
--launchProgram("rom/tProcesses/shell.lua", 3, 3, 51 - 51 / 2, 20 - 20 / 2)
--launchProgram("test2.lua", 1, 1, 15, 18)
--term.clear()
--start()

return {
    launchProgram = launchProgram, 
    launchProcess = launchProcess, 
    start = start,
    setFocus = setFocus
}