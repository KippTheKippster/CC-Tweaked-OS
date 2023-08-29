local path = ".core."

utils = require(path .. "utils")

local w, h = term.getSize()

grid = {}
for i = 1, w do
    grid[i] = {}
    for j = 1, h do
        grid[i][j] = 1
    end
end

function inTerm(x, y)
    if x == nil or y == nil then
        --error("X OR Y == NIL")
        return false
    end
    if x < 1 or x > w or y < 1 or y > h then
        return false
    end
    return true
end

function drawPixel(x, y, color)
    local x = math.floor(x + 0.5)
    local y = math.floor(y + 0.5)
    if not inTerm(x, y) then
        --error("Atempting to draw outside canvas!", 3)
        return
    end
    --print("x: " .. x .. " y: " .. y .. " w: " .. w .. " h: " .. h)
    grid[x][y] = color
    paintutils.drawPixel(x, y, color)
end

function drawScreen()
    for i = 1, w do
        for j = 1, h do
            paintutils.drawPixel(i, j, getPixel(i, j))
        end
    end
end

function getPixel(x, y)
    local x = math.floor(x + 0.5)
    local y = math.floor(y + 0.5)
    if not inTerm(x, y) then 
        return 1
    end
    return grid[x][y]
end

function drawXLine(x, y, length, color)
    dir = utils.getDir(length)
    for i = 1, math.abs(length) do
        drawPixel(x + i * dir - dir, y, color)
    end
end

function drawYLine(x, y, length, color) 
    dir = utils.getDir(length)
    for i = 1, math.abs(length) do 
        drawPixel(x, y + i * dir - dir, color)
    end
end

function drawBox(startX, startY, endX, endY, color)
    local deltaX = endX - startX
    local deltaY = endY - startY
    local dirX = utils.getDir(deltaX)
    local dirY = utils.getDir(deltaY)
    --Top
    drawXLine(startX, startY, deltaX + dirX, color)
    --Left
    drawYLine(startX, startY, deltaY + dirY, color)
    --Bottom
    drawXLine(endX, endY, -(deltaX + dirX), color)
    --Right
    drawYLine(endX, endY, -(deltaY + dirY), color)
end

function drawFilledBox(startX, startY, endX, endY, color)
    local deltaX = endX - startX
    local deltaY = endY - startY 
    local dirX = utils.getDir(deltaX)
    local dirY = utils.getDir(deltaY)
    for i = 1, math.abs(deltaX) + 1 do
        for j = 1, math.abs(deltaY) + 1 do
            drawPixel(
                i * dirX + startX - dirX, 
                j * dirY + startY - dirY, 
                color)
        end
    end
end

local i = 0

function resize()
    i = i + 1
    w, h = term.getSize()
    if #grid == w then
        --print("same!")
    elseif w > #grid then
        --print("Expand!")
        for i = #grid, w do
            grid[i] = {}
            for j = 1, h do
                grid[i][j] = 1
            end
        end
    else
        --print("Reduce!")
        for i = w, #grid do
            table.remove(grid, i)
        end
    end


    if #grid[1] == h then
    elseif h > #grid[1] then --Will auto add new slots if needed (maybe?)
    else
        for i = 1, w do
            for j = h, #grid[i] do
                table.remove(grid[i], j)
            end
        end
    end
end

return {
    drawPixel = drawPixel,
    drawXLine = drawXLine,
    drawYLine = drawYLine,
    drawBox = drawBox,
    drawFilledBox = drawFilledBox,
    getPixel = getPixel,
    drawScreen = drawScreen,
    resize = resize
}
