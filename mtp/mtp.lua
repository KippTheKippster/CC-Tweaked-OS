peripheral.find("modem", rednet.open)
write("Host? ")
local host = read()
local remoteId = rednet.lookup("mtp", host)
local currentPath = ""

while true do
    write(remoteId .. "/" .. currentPath .. ">")
    local input = read()    
    local path = currentPath .. "/" .. input
    
    rednet.send(remoteId, { cmd = "get", path = path }, "mtp")
    
    while true do
        local id, ans = rednet.receive("mtp")
    
        if id == remoteId then         
            if ans["ans"] == "dir" then
                for i = 1,#ans["content"] do
                    print(ans["content"][i])
                end
                currentPath = ans["path"]
                
            elseif ans["ans"] == "file" then
                local file = fs.open("/downloads/" .. host .. "/" .. ans["path"], "w")
                file.write(ans["content"])
                file.close()
                print("SAVED TO DOWNLOADS")                    
            elseif ans["ans"] == "no_file" then
                print("NO SUCH FILE OR DIRECTORY")
            end
            break
        end
    end
end
