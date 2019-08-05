local unpack = table.unpack or unpack


local m = require "lpeglabel"
local re = require "relabel"

local errors
local inputFilePath = "test.yolol"


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
local function printAST(ast, indent, depth, fieldName)
	indent = indent or "\t"
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
			end
		elseif i ~= "type" then
			print(string.rep(indent, depth+1) .. strValueFromType(i) .. " = " .. strValueFromType(v))
		end
	end
end
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
		return calc(ast.left) + calc(ast.right)
	elseif op == "-" then
		return calc(ast.left) - calc(ast.right)
	elseif op == "*" then
		return calc(ast.left) * calc(ast.right)
	elseif op == "/" then
		return calc(ast.left) / calc(ast.right)
	elseif op == "^" then
		return calc(ast.left) ^ calc(ast.right)
	elseif op == "and" then
		if calc(ast.left) ~= 0 and calc(ast.right) ~= 0 then
			return 1
		end
		return 0
	elseif op == "or" then
		if calc(ast.left) ~= 0 or calc(ast.right) ~= 0 then
			return 1
		end
		return 0
	elseif op == "==" then
		if calc(ast.left) == calc(ast.right) then
			return 1
		end
		return 0
	elseif op == "!=" then
		if calc(ast.left) ~= calc(ast.right) then
			return 1
		end
		return 0
	elseif op == "<=" then
		if calc(ast.left) <= calc(ast.right) then
			return 1
		end
		return 0
	elseif op == ">=" then
		if calc(ast.left) >= calc(ast.right) then
			return 1
		end
		return 0
	elseif op == "<" then
		if calc(ast.left) < calc(ast.right) then
			return 1
		end
		return 0
	elseif op == ">" then
		if calc(ast.left) > calc(ast.right) then
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
local function pusherror(err)
	table.insert(errors, err)
end
local function parseBinaryOpAST(_type, left, operator, ...)
	local t = {...}
	local right
	if #t < 1 then
		right = nil  -- NOTE: this error should be caught and put into errors list
	elseif #t == 1 then
		right = t[1]
	elseif #t > 1 then
		right = parseBinaryOpAST(_type, unpack(t))
	end
	return {
		type=_type,
		left=left,
		operator=operator,
		right=right
	}
end


local defs = {
	-- Errors
	fail="An uncaught error has occured.",
	TEST="Test Error Msg.",

	-- Other
	esc_t="\t",

	-- AST Building
	Test=function(...)
		print("Test:")
		for _, v in ipairs({...}) do
			if type(v) == "string" then
				v = v:gsub("\r", "\\r"):gsub("\n", "\\n"):gsub("\t", "\\t")
			elseif type(v) == "table" and v.type ~= nil then
				printAST(v)
			end
			print(tostring(v))
		end
	end,

	program=function(...)
		return {
			type="program",
			lines={...}
		}
	end,
	line=function(...)
		return {
			type="line",
			code={...}
		}
	end,

	["goto"]=function(...)
		return {
			type="goto",
			...  -- TODO
		}
	end,
	["if"]=function(...)
		return {
			type="if",
			...  -- TODO
		}
	end,
	if_body=function(cond, ...)
		return {
			type="if_body",
			cond=cond,
			...
		}
	end,
	else_body=function(...)
		return {
			type="else_body",
			...  -- TODO
		}
	end,
	assign=function(identifier, operator, value)
		return {
			type="assign",
			identifier=identifier,
			operator=operator,
			value=value
		}
	end,

	expression=function(...)
		local exprs = {...}
		-- Required to keep the ast clean of single element expr's
		-- also values might be just there `Value` not an expr containing there `Value`
		if #exprs == 1 then
			return exprs[1]
		end
		pusherror {
			pos=0,
			msg="AST Error: Got multiple children in a single expression."
		}
		return {
			type="expression",
			...  -- For debugging
		}
	end,
	mul=function(...)
		return parseBinaryOpAST("mul", ...)
	end,
	add=function(...)
		return parseBinaryOpAST("add", ...)
	end,
	exp=function(...)
		return parseBinaryOpAST("exp", ...)
	end,
	keyword=function(operator, operand)
		return {
			type="keyword",
			operator=operator,
			operand=operand
		}
	end,
	neg=function(operator, operand)
		return {
			type="neg",
			operator=operator,
			operand=operand
		}
	end,
	["or"]=function(...)
		return parseBinaryOpAST("or", ...)
	end,
	["and"]=function(...)
		return parseBinaryOpAST("and", ...)
	end,
	neq=function(...)
		return parseBinaryOpAST("eq", ...)
	end,
	eq=function(...)
		return parseBinaryOpAST("neq", ...)
	end,

	string=function(str)
		return {
			type="string",
			str=str
		}
	end,
	number=function(num)
		return {
			type="number",
			num=num
		}
	end,
	identifier=function(name)
		return {
			type="identifier",
			name=name
		}
	end,

	comment=function(start, value, finish)
		return {
			type="comment",
			start=start,
			finish=finish,
			value=value
		}
	end,

	MISS_CURLY=function(pos)
		pusherror {
			pos=pos,
			msg="Syntax Error: Missing closing curly bracket."
		}
	end,
	MISS_EXPR=function(pos)
		pusherror {
			pos=pos,
			msg="Syntax Error: Missing required expression."
		}
	end,
	MISS_THEN=function(pos)
		pusherror {
			pos=pos,
			msg="Syntax Error: Missing `hen' keyword."
		}
	end,
	INVALID_DIGIT=function(pos)
		pusherror {
			pos=pos,
			msg="Syntax Error: Invalid digit."
		}
	end,
	MISS_END=function(pos)
		pusherror {
			pos=pos,
			msg="Syntax Error: Missing 'end' keyword."
		}
	end,
	SYNTAX_ERROR=function(pos, remaining, finish)
		pusherror {
			pos=pos,
			remaing=remaining,
			msg="Syntax Error: un-parsed input remaining '" .. remaining:gsub("\r", "\\r"):gsub("\n", "\\n"):gsub("\t", "\\t") .. "'"
		}
	end,
}


local grammarF = io.open("grammar.relabel")
local grammarStr = grammarF:read("*a")
grammarF:close()
local start = os.time()
local g = re.compile(grammarStr, defs)
local _end = os.time()
print("Took " .. tostring(_end - start) .. "s odd to compile grammar.")


local inputF = io.open(inputFilePath)
local input = inputF:read("*a") .. "\n"
inputF:close()
errors = {}
local start = os.time()
local r, e, pos = g:match(input)
local _end = os.time()
print("Took " .. tostring(_end - start) .. "s odd to parse.")
if r == nil then
	local ln, col = re.calcline(input, pos)
	print("Failed at " .. tostring(ln) .. ":" .. tostring(col) .. " with")
	print(defs[e])
end
print()
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
if r ~= nil then
	print()
	print("Parsed data.")
	print("AST")
	printAST(r, "   |")
	print()
	print("Checking and calculating any expression's that are on there own.")
	for i, line in pairs(r.lines) do
		if line.code ~= nil and #line.code == 1 then
			local v = line.code[1]
			if type(v) == "table" and v.operator ~= nil and v.type ~= "assign" then
				local ok, calcResult = pcall(calc, v)
				if not ok then
					calcResult = calcResult:gsub(".*:%d+:", ""):gsub("^ *", "")
				end
				print("Calc ln " .. strValueFromType(i) .. ":", tostring(calcResult))
			end
		end
	end
else
	print("No parsed data.")
end
