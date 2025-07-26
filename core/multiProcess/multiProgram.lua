-- Handles coroutines of multiple programs

local utils = require(".core.utils")

local tProcesses = {}


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

local function createShellEnviroment(parentTerm)
    local function shallowcopy(orig)
        local orig_type = type(orig)
        local copy
        if orig_type == 'table' then
            copy = {}
            for orig_key, orig_value in pairs(orig) do
                copy[orig_key] = orig_value
            end
        else -- number, string, boolean, etc
            copy = orig
        end
        return copy
    end

    local function tokenise(...)
        local sLine = table.concat({ ... }, " ")
        local tWords = {}
        local bQuoted = false
        for match in string.gmatch(sLine .. "\"", "(.-)\"") do
            if bQuoted then
                table.insert(tWords, match)
            else
                for m in string.gmatch(match, "[^ \t]+") do
                    table.insert(tWords, m)
                end
            end
            bQuoted = not bQuoted
        end
        return tWords
    end

    local shellCopy = shallowcopy(shell)
    local ms = require(".os.programs.multishell")(parentTerm)
    shellCopy.openTab = function (...)
        --__mos.launchProgram("HEHE", path, 2, 2, 20, 20)
        local tWords = tokenise(...)
        local sCommand = tWords[1]
        if sCommand then
            local sPath = shell.resolveProgram(sCommand)
            if sPath == "rom/programs/shell.lua" then
                return multishell.launch(env, sPath, table.unpack(tWords, 2))
            elseif sPath ~= nil then
                return multishell.launch(env, "rom/programs/shell.lua", sCommand, table.unpack(tWords, 2))
            else
                printError("No such program")
            end
        end
    end
    local env = { shell = shellCopy, multishell = ms }
    env.require, env.package = dofile("rom/modules/main/cc/require.lua").make(env, "")

    return env
end

--setmetatable(env, {
--__index = function (t, k)
--    --print("get: ", k, t)
--    return _G[k]
--end})
--__newindex = function (t, k, v)
--    --print("set: ", k, v)
--end})

--[[
local fnFile, err = loadfile("core/multiProcess/multishellWrapper.lua", nil, tEnv)
pcall(fnFile)
]]--

--local co = coroutine.create(function ()
--local fnFile, err = loadfile("rom/programs/advanced/multishell.lua", nil, tEnv)
--pcall(fnFile)
-- end)


--coroutine.close(co)

--print(_G.__wrapper.shell.resolve)

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

    coroutine.resume(p.co)
    coroutine.resume(p.co, "paste", "core/multiProcess/multishellWrapper.lua")
    coroutine.resume(p.co, "key", keys.enter)

    return p

    --[[
    local env = { shell = shell, multishell = multishell }
    env.require, env.package = dofile("rom/modules/main/cc/require.lua").make(env, "")
    extraEnv = extraEnv or {}
    for k, v in pairs(extraEnv) do
        env[k] = v
    end

    return launchProcess(parentTerm, function(p, ...)
        os.run(env, programPath, ...)
    end, resume, x, y, w, h, ...)
    ]]--
end

--[[
local co = coroutine.create(function ()
    shell.run("rom/programs/advanced/multishell.lua")
end
)
--while true do
    coroutine.resume(co)
    coroutine.resume(co, "paste", "rom/programs/edit.lua " .. path)
    coroutine.resume(co, "key", keys.enter)
]]--

local function endProcess(p)
    --coroutine.close(p.co)
    --debug.sethook(p.co, function() error("dead") end, "l")
    --p.resume()
    local i = utils.find(tProcesses, p.co)
    table.remove(tProcesses, i)
end

local running = true

local function exit()
    running = false
end

local function start()
    term.clear()
    running = true
    while running do
        local data = table.pack(os.pullEventRaw())
        for k, v in ipairs(tProcesses) do
            --if coroutine.status(v.co) ~= "dead" then
            local ok, err = v.resume(data)
            if ok == false then
                term.setCursorPos(1, 1)
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.red)
                printError("MP: " .. err)
                endProcess(v)
                exit()
                return err
            end
            --end 
        end
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