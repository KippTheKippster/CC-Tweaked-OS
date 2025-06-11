local i = 1
while true do 
    i = i + 1
    term.setBackgroundColor(i)
    if i > 15 then
        i = 1
    end
    term.clear()
    sleep(0.1)
end