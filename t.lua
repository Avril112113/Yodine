local yolol = require "parser"


local r = yolol([[
1/3
]])

for i, v in pairs(r[1]) do
    print(i, v)
end
