
local collision = {}
function collision.inArea(x, y, x1, y1, w, h)
    if (
        x <= x1 + w and
        x >= x1 and
        y <= y1 + h and
        y >= y1
    ) then
        return true
    else
        return false
    end
end

function collision.overlappingArea(x, y, w, h, x1, y1, w1, h1)
    if (
        x <= x1 + w1 and
        x + w >= x1 and 
        y <= y1 + h1 and
        y + h >= y1
    ) then
        return true
    else
        return false
    end
end

return collision
