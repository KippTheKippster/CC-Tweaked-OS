while true do 
    local data = table.pack(os.pullEvent())
    print(table.unpack(data))
end
