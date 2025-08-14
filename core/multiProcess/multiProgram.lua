-- Handles coroutines of multiple programs

local utils = require(".core.utils")

local mp = {}
local tProcesses = {}
local endQueue = {}

mp.resumeProcess = function (p, data)
    term.redirect(p.window)
    local status = table.pack(coroutine.resume(p.co, table.unpack(data)))
    term.redirect(p.parentTerm)
    return table.unpack(status)
end

mp.launchProcess = function (parentTerm, process, resume, x, y, w, h, ...)
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
        return mp.resumeProcess(p, data)
    end
    p.dead = false
    table.insert(tProcesses, p)
    return p
end

mp.runProgram = function (env, programPath, ...)
    setmetatable(env, { __index = _G })

    if settings.get("bios.strict_globals", false) then
        -- load will attempt to set _ENV on this environment, which
        -- throws an error with this protection enabled. Thus we set it here first.
        env._ENV = env
        getmetatable(env).__newindex = function(_, name)
          error("Attempt to create global " .. tostring(name), 2)
        end
    end

    local fnFile, ok, err = nil, false, nil
    fnFile, err = loadfile(programPath, nil, env)
    if fnFile then
        ok, err = fnFile(...)--pcall(fnFile, ...)
    end

    return ok, err
end

local function createMultishellWrapper(p, env, ...)
    local args = table.pack(...)
    _G.__wrapper = {
        env = env,
        args = args,
        mp = mp,
    }

    mp.runProgram(env, "rom/programs/advanced/multishell.lua")
end



mp.launchProgram = function (parentTerm, programPath, extraEnv, resume, x, y, w, h, ...)
    local env = { shell = shell, multishell = multishell }
    env.require, env.package = dofile("rom/modules/main/cc/require.lua").make(env, "")

    extraEnv = extraEnv or {}
    for k, v in pairs(extraEnv) do
        env[k] = v
    end

    local p = mp.launchProcess(parentTerm, function(p, ...)
        createMultishellWrapper(p, env, programPath, ...) -- TODO Read and fix error messages
        --os.run(env, programPath, ...)
        --mp.runProgram(env, programPath, ...)
    end, resume, x, y, w, h, ...)

    coroutine.resume(p.co, "start")
    coroutine.resume(p.co, "paste", "core/multiProcess/multishellWrapper.lua")
    coroutine.resume(p.co, "key", keys.enter)

    return p
end

mp.endProcess = function (p)
    p.dead = true
    table.insert(endQueue, p)
end

mp.forceError = function (p, err)
    debug.sethook(p.co, function() error(err) end, "l")
    mp.resumeProcess(p, {"force_error"})
end

local running = true

mp.exit = function ()
    running = false
end

mp.start = function ()
    term.clear()
    running = true
    local parentTerm = term.current()
    while running and #tProcesses > 0 do
        local data = table.pack(os.pullEventRaw())
        local n = #tProcesses
        for i = 1, n do
            local p = tProcesses[i]
            if p.dead == false then
                local ok, err = p.resume(data)
                if ok == false then
                    if __Global and type(__Global.log) == "function" then
                        __Global.log("MP Error", err)                    
                    end
                    term.redirect(parentTerm)
                    term.setCursorPos(1, 1)
                    term.setBackgroundColor(colors.black)
                    term.setTextColor(colors.red)
                    printError("MP: ", err)
                    mp.endProcess(p)
                    mp.exit()
                    return err
                end
            end
        end

        for _, p in ipairs(endQueue) do
            local i = utils.find(tProcesses, p)
            if i == nil then
                error("Trying to remove non existent process!", 2)
            end
            p.window.setVisible(false)
            debug.sethook(p.co, function() error("killed") end, "l")
            mp.resumeProcess(p, {"kill"})
            table.remove(tProcesses, i)
        end

        endQueue = {}
    end
    return nil
end

return mp