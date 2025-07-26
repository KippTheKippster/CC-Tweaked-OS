local ms = require("os.programs.multishell")(term.current())
print(ms)
print(ms.launch)
--[[
local func, err = dofile("rom/programs/advanced/multishell.lua")
if func then
  local ok, add = pcall(func)
  if ok then
    print(add(2,3))
  else
    print("Execution error:", add)
  end
else
  print("Compilation error:", err)
end
]]--