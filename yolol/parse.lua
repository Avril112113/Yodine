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

--- All binary ops are the same format and work the same so this is a helper func
--- to convert the info given from parser into the AST
---@param _type string
---@param leftTree boolean @ Weather or not it constructs additional args '...' on the left side
---@param left table @ Is a Node of the AST
---@param operator string
--- @vararg table @ Is a Node of the AST (is not working with sumneko's vscode extention for lua)
local function parseBinaryOpAST(_type, leftTree, left, operator, ...)
	local t = {...}
	if leftTree == true and #t > 1 then
		local right = table.remove(t, #t)
		local _operator = table.remove(t, #t)
		return {
			type=_type,
			left=parseBinaryOpAST(_type, leftTree, left, operator, unpack(t)),
			operator=_operator,
			right=right
		}
	else
		local right
		if #t < 1 then
			right = nil  -- NOTE: this error should be caught and put into errors list
		elseif #t == 1 then
			right = t[1]
		elseif #t > 1 then
			right = parseBinaryOpAST(_type, leftTree, unpack(t))
		end
		return {
			type=_type,
			left=left,
			operator=operator,
			right=right
		}
	end
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

	expression=function(...)
		local exprs = {...}
		-- Required to keep the ast clean of single element expr's
		-- in theory there should never be an `expression` node in the ast
		-- and if there is, then the grammar is incorrect
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
		return parseBinaryOpAST("mul", false, ...)
	end,
	add=function(...)
		return parseBinaryOpAST("add", false, ...)
	end,
	exp=function(...)
		return parseBinaryOpAST("exp", false, ...)
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
		return parseBinaryOpAST("or", true, ...)
	end,
	["and"]=function(...)
		return parseBinaryOpAST("and", true, ...)
	end,
	neq=function(...)
		return parseBinaryOpAST("eq", false, ...)
	end,
	eq=function(...)
		return parseBinaryOpAST("neq", false, ...)
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

return {
	defs=defs,
	---@param codeStr string
	---@return ParseResult
	parse=function(codeStr)
		errors = {}

		local startTime = os.time()
		local result, errMsg, errPos = grammar:match(codeStr)
		local endTime = os.time()

		local _errors = errors
		errors = nil
		return {
			---@type YAST_Program|nil
			ast=result,
			---@type string|nil
			errMsg=errMsg,
			---@type number|nil
			errPos=errPos,
			---@type table
			errors=_errors,
			---@type number
			parseTime=endTime - startTime
		}
	end
}
