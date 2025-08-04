-- Handles coroutines of multiple programs

local utils = require(".core.utils")

local tProcesses = {}
local endQueue = {}

local function resumeProcess(p, data)
    term.redirect(p.window)
    local status = table.pack(coroutine.resume(p.co, table.unpack(data)))
    term.redirect(p.parentTerm)
    return table.unpack(status)
end

local function launchProcess(parentTerm, process, resume, x, y, w, h, ...)
    local p = {}
    local args = table.pack(...)
    p.window = window.create(parentTerm, x, y, w, h, true)
    p.parentTerm = parentTerm
    p.co = coroutine.create(function()
        term.redirect(p.window)
        process(p, table.unpack(args))
        term.redirect(parentTerm)
    end)
    p.resume = resume or function (data)
        return resumeProcess(p, data)
    end
    table.insert(tProcesses, p)
    return p
end

local function createMultishellWrapper(env, ...)
    local args = table.pack(...)
    _G.__wrapper = {
        env = env,
        args = args
    }

    shell.run("rom/programs/advanced/multishell.lua")
end

local function launchProgram(parentTerm, programPath, extraEnv, resume, x, y, w, h, ...)
    local env = { shell = shell, multishell = multishell }
    env.require, env.package = dofile("rom/modules/main/cc/require.lua").make(env, "")

    extraEnv = extraEnv or {}
    for k, v in pairs(extraEnv) do
        env[k] = v
    end

    local p = launchProcess(parentTerm, function(p, ...)
        createMultishellWrapper(env, programPath, ...)
        --os.run(env, programPath, ...)
    end, resume, x, y, w, h, ...)

    coroutine.resume(p.co, "")
    coroutine.resume(p.co, "paste", "core/multiProcess/multishellWrapper.lua")
    coroutine.resume(p.co, "key", keys.enter)

    return p
end

local function endProcess(p)
    --coroutine.close(p.co)
    
    --local i = utils.find(tProcesses, p.co)
    --table.remove(tProcesses, i)
    table.insert(endQueue, p)
end

local running = true

local function exit()
    running = false
end

local function start()
    term.clear()
    running = true
    while running and #tProcesses > 0 do
        local data = table.pack(os.pullEventRaw())
        for k, v in ipairs(tProcesses) do
            --if coroutine.status(v.co) ~= "dead" then
            local ok, err = v.resume(data)
            if ok == false then
                term.setCursorPos(1, 1)
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.red)
                printError("MP: ", err)
                endProcess(v)
                exit()
                return err
            end
            --end 
        end

        for _, p in ipairs(endQueue) do
            local i = utils.find(tProcesses, p)
            if i == nil then
                error("Trying to remove non existent process!")
            end
            p.window.setVisible(false)
            debug.sethook(p.co, function() error("killed") end, "l")
            p.resume({"kill"})
            table.remove(tProcesses, i)
        end

        endQueue = {}
    end
    return nil
end

return {
    launchProgram = launchProgram,
    launchProcess = launchProcess,
    resumeProcess = resumeProcess,
    endProcess = endProcess,
    start = start,
    exit = exit
}