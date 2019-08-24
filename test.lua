-- used to test yolol parser when developing stuff for it

--[[
function debug.relabelDbgFilter(ruleName)
	local bl = {
		Sp=true
	}
	return bl[ruleName] ~= true and #ruleName > 1
end
--]]

local re = require "relabel"
local yolol = require "yolol"

local input = [[
x++ y++
]]
local result = yolol.parse(input)

print("Took " .. tostring(result.parseTime) .. "s odd to parse.")

if result.errPos ~= nil then
	local ln, col = re.calcline(input, result.errPos)
	print("Failed at " .. tostring(ln) .. ":" .. tostring(col) .. " with")
	print(yolol.defs[result.errMsg])
end
print()
local errors = {}
for i, line in ipairs(result.ast.lines) do
	for _, err in ipairs(line.errors) do
		table.insert(errors, err)
	end
end
if #errors > 0 then
	print(tostring(#errors) .. " errors reported.")
	for i, v in ipairs(errors) do
		local ln, col = re.calcline(input, v.pos)
		print(tostring(ln) .. ":" .. tostring(col) .. " " .. v.msg)
	end
else
	print("No errors reported.")
end
print()
if result ~= nil then
	print()
	print("Parsed data.")
	print("AST")
	yolol.helpers.printAST(result.ast, "   |")
	print()
	print("Checking and calculating any statment expression's.")
	for i, line in pairs(result.ast.lines) do
		if line.code ~= nil and #line.code == 1 then
			local v = line.code[1]
			if type(v) == "table" and v.type == "expression" then
				local ok, calcResult = pcall(yolol.helpers.calc, v.expression)
				if not ok then
					calcResult = calcResult:gsub(".*:%d+:", ""):gsub("^ *", "")
				end
				print("Calc ln " .. yolol.helpers.strValueFromType(i) .. ":", tostring(calcResult))
			end
		end
	end
	-- print(); print(yolol.helpers.serializeTable(result.ast))
else
	print("No parsed data.")
end