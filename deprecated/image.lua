function loadTexture(path)
    local file = fs.open(path,"r")
    local texture = {}
    local i = 1
    while true do  
        local line = file.readLine()
        if line == nil then break end
        --print(#line .. ":" .. line)
        texture[i] = line
        i = i + 1
    end
    return texture   
end

function drawTexture(texture)
    for i = 1, #texture do
    
    end    
end

local texture = loadTexture("test.nfp")
drawTexture(texture)
