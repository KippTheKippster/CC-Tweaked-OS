term.clear()
paintutils.drawPixel(2,3, colors.red)
oldDrawPixel = paintutils.drawPixel
paintutils.drawPixel = function(x, y, color)
    oldDrawPixel(x, y, color)
    write(
end
--paintutils.drawPixel()
