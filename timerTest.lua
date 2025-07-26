local function input()
    while true do
        print(os.pullEventRaw())
    end
end

local function process()
    while true do
        sleep(0.01)
    end
end

parallel.waitForAny(input, process)