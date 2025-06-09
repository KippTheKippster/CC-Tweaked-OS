local i = 0
local parentTerm = term.current()
print(term.getSize())
print(parentTerm.getSize())
while true do
    os.pullEvent("term_resize")
    local w, h = term.getSize()
    --print(i .. ": Resize: " .. w .. " : " .. h)
    i = i + 1
end
