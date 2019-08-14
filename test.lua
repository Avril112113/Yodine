-- used to test yolol parser when developing stuff for it

local re = require "relabel"
local yolol = require "yolol.init"
local helpers = require "yolol.tests.helpers"

local input = [[1 and 2 and 3
]]
local result = yolol.parse(input)

print("Took " .. tostring(result.parseTime) .. "s odd to parse.")

if result.errPos ~= nil then
	local ln, col = re.calcline(input, result.errPos)
	print("Failed at " .. tostring(ln) .. ":" .. tostring(col) .. " with")
	print(yolol.defs[result.errMsg])
end
print()
if #result.errors > 0 then
	print(tostring(#result.errors) .. " errors reported.")
	for i, v in ipairs(result.errors) do
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
	helpers.printAST(result.ast, "   |")
	print()
	print("Checking and calculating any expression's that are on there own.")
	for i, line in pairs(result.ast.lines) do
		if line.code ~= nil and #line.code == 1 then
			local v = line.code[1]
			if type(v) == "table" and v.operator ~= nil and v.type ~= "assign" then
				local ok, calcResult = pcall(helpers.calc, v)
				if not ok then
					calcResult = calcResult:gsub(".*:%d+:", ""):gsub("^ *", "")
				end
				print("Calc ln " .. helpers.strValueFromType(i) .. ":", tostring(calcResult))
			end
		end
	end
	-- print(); print(helpers.serializeTable(result.ast))
else
	print("No parsed data.")
end