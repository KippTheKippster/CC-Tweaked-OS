local multiProgram = require(".core.multiProcess.multiProgram")

local function start()
    local a = b.c
end

multiProgram.launchProcess(term.current(), start, nil, 1, 1, term.getSize())
multiProgram.start()
print("ADSA")
