-- test/init.lua - contains helpers for tests and debugging

--- Converts a value to a more readable string repersentation based on its type
---@param v any
local function strValueFromType(v)
	if type(v) == "string" then
		v = v:gsub("\r", "\\r"):gsub("\n", "\\n"):gsub("\t", "\\t")
		local _, singlePos = string.find(v, "'")
		if singlePos == nil or singlePos <= 0 then
			return "'" .. v .. "'"
		end
		return "\"" .. v .. "\""
	end
	return tostring(v)
end

--- Checks if 2 tables are the same
---@param a table
---@param b table
local function tblEqual(a, b)
	for i, v in pairs(a) do
		if type(v) == "table" and type(b[i]) == "table" then
			if tblEqual(v, b[i]) == false then
				return false
			end
		elseif b[i] ~= v then
			return false
		end
	end
	return true
end

--- Prints the difference's between 2 tables
---@param a table
---@param b table
local function tblPrint(a, b, path)
	path = path or "<INPUT>"
	for i, v in pairs(a) do
		if type(v) == "table" and type(b[i]) == "table" then
			tblPrint(v, b[i], path.."."..strValueFromType(i))
		elseif b[i] ~= v then
			print(path.."."..strValueFromType(i).." should be " .. strValueFromType(v) .. " but is " .. strValueFromType(b[i]))
		end
	end
end

local function isEmptyTable(tbl)
	for i, v in ipairs(tbl) do return false end
	return true
end

--- Very simple, calculates the result of the given AST if its valid
---@param ast table @ Is a Node of the AST
local function calc(ast)
	if ast == nil then
		error("Invalid AST!")
	end
	local op = type(ast.operator) == "string" and ast.operator:lower() or ast.operator
	if ast.type == "number" then
		return tonumber(ast.num)
	elseif ast.type == "identifier" then
		error("Variables are not supported by calc().")
	-- Unary
	elseif op == "-" and ast.type == "neg" then
		return -calc(ast.operand)
	-- Binary
	elseif op == "+" then
		return calc(ast.lhs) + calc(ast.rhs)
	elseif op == "-" then
		return calc(ast.lhs) - calc(ast.rhs)
	elseif op == "*" then
		return calc(ast.lhs) * calc(ast.rhs)
	elseif op == "/" then
		return calc(ast.lhs) / calc(ast.rhs)
	elseif op == "^" then
		return calc(ast.lhs) ^ calc(ast.rhs)
	elseif op == "%" then
		return calc(ast.lhs) % calc(ast.rhs)
	elseif op == "and" then
		if calc(ast.lhs) ~= 0 and calc(ast.rhs) ~= 0 then
			return 1
		end
		return 0
	elseif op == "or" then
		if calc(ast.lhs) ~= 0 or calc(ast.rhs) ~= 0 then
			return 1
		end
		return 0
	elseif op == "==" then
		if calc(ast.lhs) == calc(ast.rhs) then
			return 1
		end
		return 0
	elseif op == "!=" then
		if calc(ast.lhs) ~= calc(ast.rhs) then
			return 1
		end
		return 0
	elseif op == "<=" then
		if calc(ast.lhs) <= calc(ast.rhs) then
			return 1
		end
		return 0
	elseif op == ">=" then
		if calc(ast.lhs) >= calc(ast.rhs) then
			return 1
		end
		return 0
	elseif op == "<" then
		if calc(ast.lhs) < calc(ast.rhs) then
			return 1
		end
		return 0
	elseif op == ">" then
		if calc(ast.lhs) > calc(ast.rhs) then
			return 1
		end
		return 0
	-- Keyword
	elseif op == "abs" then
		local v = calc(ast.operand)
		return v - (v%1)
	elseif op == "sin" then
		return math.cos(calc(ast.operand))
	elseif op == "cos" then
		return math.cos(calc(ast.operand))
	elseif op == "tan" then
		return math.tan(calc(ast.operand))
	elseif op == "asin" then
		return math.acos(calc(ast.operand))
	elseif op == "acos" then
		return math.acos(calc(ast.operand))
	elseif op == "atan" then
		return math.atan(calc(ast.operand))
	else
		if op ~= nil then
			error("Unsupported operator for calc " .. strValueFromType(ast.operator) .. ".")
		else
			error("Unsupported type for calc " .. strValueFromType(ast.type) .. ".")
		end
	end
end

--- Prints the given AST to stdout
---@param ast table @ Is a Node of the AST
---@param indent string
---@param depth number
---@param fieldName string|nil
local function printAST(ast, indent, depth, fieldName)
	indent = indent or "    "
	depth = depth or 0
	print(string.rep(indent, depth) .. (function()
		if fieldName ~= nil then
			return strValueFromType(fieldName) .. " = "
		end
		return ""
	end)() .. ast.type)
	for i, v in pairs(ast) do
		if type(v) == "table" and type(v.type) == "string" then
			printAST(v, indent, depth+1, i)
		elseif type(v) == "table" then
			local hasPrintedStart = false
			for i1, v1 in ipairs(v) do
				if type(v1) == "table" and type(v1.type) == "string" then
					if not hasPrintedStart then
						print(string.rep(indent, depth+1) .. strValueFromType(i) .. " = " .. "[")
					end
					printAST(v1, indent, depth+2)
					hasPrintedStart = true
				end
			end
			if hasPrintedStart then
				print(string.rep(indent, depth+1) .. "]")
			elseif isEmptyTable(v) then
				print(string.rep(indent, depth+1) .. strValueFromType(i) .. " = " .. strValueFromType(v) .. "(Empty Table)")
			else
				print(string.rep(indent, depth+1) .. strValueFromType(i) .. " = " .. strValueFromType(v))
			end
		elseif i ~= "type" then
			print(string.rep(indent, depth+1) .. strValueFromType(i) .. " = " .. strValueFromType(v))
		end
	end
end

local function _serializeValue(s)
	return string.format("%q", s)
end
local function serializeTable(tbl, indent, depth)
	indent =  "    "
	depth = depth or 0
	local out = "{\n"
	local lastI = 0
	for i, v in ipairs(tbl) do
		out = out .. string.rep(indent, depth+1)
		if type(v) == "table" then
			out = out .. serializeTable(v, indent, depth+1) .. ",\n"
		else
			out = out .. _serializeValue(v) .. ",\n"
		end
		lastI = i
	end
	for i, v in pairs(tbl) do
		if type(i) == "number" and i > lastI or type(i) ~= "number" then
			out = out .. string.rep(indent, depth+1)
			if type(i) == "string" then
				out = out .. i .. " = "
			else
				out = out .. "[" .. _serializeValue(i) .. "]" .. " = "
			end
			if type(v) == "table" then
				out = out .. serializeTable(v, indent, depth+1) .. ",\n"
			else
				out = out .. _serializeValue(v) .. ",\n"
			end
		end
	end
	return out:gsub(",\n$", "\n") .. string.rep(indent, depth) .. "}"
end

return {
	strValueFromType=strValueFromType,
	calc=calc,
	printAST=printAST,
	tblEqual=tblEqual,
	tblPrint=tblPrint,
	serializeTable=serializeTable
}
