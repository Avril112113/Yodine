local lpl = require "lpeglabel"
local re = require "relabel"

local grammarPath = "yolol/grammar.relabel"
local grammarFile = io.open(grammarPath, "r")
local grammarStr = grammarFile:read("*a")
grammarFile:close()

local errors

--- Used to add an error to the errors list
--- this is a function for syntatic sugar
--- pusherror {pos=number, msg=string}
---@param err table @ Is format of an error {pos=number, msg=string}
local function pusherror(err)
	table.insert(errors, err)
end


local operatorData = {
	-- ["OPERATOR"]={Precedence, RightAssoc, TypeName}
	["^"]={7, true, "exp"},
	["*"]={6, false, "mul"},
	["/"]={6, false, "mul"},
	["%"]={6, false, "mul"},
	["+"]={5, false, "add"},
	["-"]={5, false, "add"},
	["<"]={4, false, "neq"},
	[">"]={4, false, "neq"},
	["<="]={4, false, "neq"},
	[">="]={4, false, "neq"},
	["!="]={3, false, "eq"},
	["=="]={3, false, "eq"},
	["or"]={2, false, "or"},
	["and"]={1, true, "and"},
}
--- NOTE: only handles binary operators
---@param data any @ YAST_Base
---@param min_precedence number
local function climbPrecedence(data, min_precedence)
	local lhs = table.remove(data, 1)
	while #data > 0 do
		local lahead = data[1]
		if type(lahead) ~= "string" then break end

		local op = lahead:lower()
		local opData = operatorData[op]
		if opData == nil then
			error("Invalid op, bad operator, was '" .. op .. "' but expected an operator in opPrecedence")
		end
		if #opData ~= 3 then
			error("Invalid opData, opData for '" .. op .. "' does not contain 3 values")
		end

		if opData[1] < min_precedence then
			break
		end

		lahead = table.remove(data, 1)

		local nextPrecedence = opData[1]
		if not opData[2] then
			nextPrecedence = nextPrecedence + 1
		end
		lhs = {
			type=opData[3],
			lhs=lhs,
			operator=op,
			rhs=climbPrecedence(data, nextPrecedence)
		}
	end
	return lhs
end

---@class YDEFS
local defs = {
	-- Errors (is raised with `^` in grammar, no result will be returned when matching)
	fail="An uncaught error has occured.",
	TEST="Test Error Msg.",

	-- Errors (handled so we can continue parsing)
	MISS_CURLY=function(pos)
		pusherror {
			type="MISS_CURLY",
			pos=pos,
			msg="Syntax Error: Missing closing curly bracket."
		}
	end,
	MISS_EXPR=function(pos)
		pusherror {
			type="MISS_EXPR",
			pos=pos,
			msg="Syntax Error: Missing required expression."
		}
	end,
	MISS_THEN=function(pos)
		pusherror {
			type="MISS_THEN",
			pos=pos,
			msg="Syntax Error: Missing `hen' keyword."
		}
	end,
	INVALID_DIGIT=function(pos)
		pusherror {
			type="INVALID_DIGIT",
			pos=pos,
			msg="Syntax Error: Invalid digit."
		}
	end,
	MISS_END=function(pos)
		pusherror {
			type="MISS_END",
			pos=pos,
			msg="Syntax Error: Missing 'end' keyword."
		}
	end,
	SYNTAX_ERROR=function(pos, remaining, finish)
		pusherror {
			type="SYNTAX_ERROR",
			pos=pos,
			remaing=remaining,
			msg="Syntax Error: un-parsed input remaining '" .. remaining:gsub("\r", "\\r"):gsub("\n", "\\n"):gsub("\t", "\\t") .. "'"
		}
	end,

	-- Other
	esc_t="\t",

	-- AST Building
	line=function(...)
		return {
			type="line",
			code={...}
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
	["goto"]=function(expression)
		return {
			type="goto",
			expression=expression
		}
	end,
	["if"]=function(ifBody, elseBody)
		local elseBody_body
		if elseBody ~= nil then elseBody_body = elseBody.body end
		return {
			type="if",
			condition=ifBody.condition,
			body=ifBody.body,
			else_body=elseBody_body
		}
	end,
	if_body=function(condition, ...)
		-- gets used only by `if`, not in the resulting AST
		return {
			type="if_body",
			condition=condition,
			body={...}
		}
	end,
	else_body=function(...)
		-- gets used only by `if`, not in the resulting AST
		return {
			type="else_body",
			body={...}
		}
	end,
	expression_stmt=function(expression)
		return {
			type="expression",
			expression=expression
		}
	end,

	expression=function(...)
		local exprs = {...}
		-- Required to keep the ast clean of single element expr's
		-- in theory there should never be an `expression` node in the ast
		-- and if there is, then the grammar is incorrect (unless its origin is expression_stmt)
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
	fact=function(value, operator, ...)
		local result = {
			type="fact",
			operator=operator,
			operand=value
		}
		for i, v in pairs({...}) do
			result = {
				type="fact",
				operator=v,
				operand=result
			}
		end
		return result
	end,
	pre_add=function(operator, operand)
		return {
			type="pre_add",
			operator=operator,
			operand=operand
		}
	end,
	post_add=function(operand, operator)
		return {
			type="post_add",
			operator=operator,
			operand=operand
		}
	end,
	binary=function(...)
		return climbPrecedence({...}, 1)
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
}
local grammar = re.compile(grammarStr, defs)

---@param lineCode string
---@return YAST_Line,table
local function parseLine(lineCode)
	errors = {}

	local startTime = os.time()
	local line, errMsg, errPos = grammar:match(lineCode)
	local endTime = os.time()
	if line == nil then line = {type="line"} end
	line.parseTime = endTime - startTime
	line.errMsg = errMsg
	line.errPos = errPos
	line.errors = errors

	errors = nil
	return line
end

---@param codeStr string
---@return ParseResult
local function parse(codeStr)
	local lines = {}
	local program = {
		type="program",
		lines=lines
	}

	local startTime = os.time()
	for lineStr in codeStr:gmatch("([^\n]*)\n?") do
		table.insert(lines, parseLine(lineStr))
	end
	local endTime = os.time()

	return {
		---@type YAST_Program|nil
		ast=program,
		---@type number
		totalParseTime=endTime - startTime
	}
end

return {
	defs=defs,
	parse=parse,
	parseLine=parseLine
}
