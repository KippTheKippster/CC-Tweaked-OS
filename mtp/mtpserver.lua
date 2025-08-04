peripheral.find("modem", rednet.open)

local arg = {...}

local host = arg[1]
rednet.host("mtp", host)
print("Lyssnar...")

while true do
    local id, msg = rednet.receive("mtp")
    print(textutils.serialise(msg))
    print(id .. " " .. msg["cmd"])
                    
    if msg["cmd"] == "get" then
        local path = "/" .. shell.resolve("/mtp/" .. msg["path"])
        
        if path:sub(0, 4) ~= "/mtp" or not fs.exists(path) then 
            rednet.send(id, { ans = "no_file", path = path:sub(6) }, "mtp")
        
        elseif fs.isDir(path) then    
            rednet.send(id, { ans = "dir", path = path:sub(6), content = fs.list(path) }, "mtp")
        
        else
            local file = fs.open(path, "r")
            local textContent = file.readAll()
            
            rednet.send(id, { ans = "file", path = path:sub(6), content = textContent }, "mtp")
        end
    end
end
