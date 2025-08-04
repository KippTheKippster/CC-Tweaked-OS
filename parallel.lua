local function a()
    print("a")
    sleep(1.0)
end

local function b()
    print("b")
    sleep(0.5)
end

local a1, a2, a3 = parallel.waitForAny(a, b)
print(a1, a2, a3)
