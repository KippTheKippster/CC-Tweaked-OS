local args = {...}

print(#args)

for i = 1, #args do 
    print(args[i])
end

for k, v in pairs(args) do 
    print(k)
    print(v)
end

print(args)
print("=)")

read()

--while true do
    
--end
