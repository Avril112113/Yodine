local function errorVM(msg, ...)
	error("CRITAL VM ERROR: " .. tostring(msg), 2, ...)
end


---@class VM_ErrMsg
local VM_ErrMsg = {
	---@type nil|number
	pos=nil,
	---@type nil|string
	level=nil,
	---@type nil|string
	msg=nil
}


local vm = {
	---@type Device_Chip
	chip=nil,
	---@type YAST_Program
	ast=nil,
	---@type table<number,VM_ErrMsg>
	errors=nil,

	---@type table<string,string|number>
	variables=nil,
	---@type number
	line=nil
}
vm.__index = vm

---@param chip Device_Chip
---@param initialLines string[]|nil
function vm.new(chip, initialLines)
	local self = setmetatable({
		chip=chip,
		lines=initialLines or {},
		errors={},

		variables={},
		line=1
	}, vm)
	return self
end

---@param errTbl VM_ErrMsg
function vm:pushError(errTbl)
	table.insert(self.errors[self.line], errTbl)
end

function vm:haltLine()
	error("STOP_LINE_EXECUTION")
end

---@param name string
---@param value string|number
function vm:setVariableFromName(name, value)
	if name:sub(1, 1) == ":" then
		LoadedMap:changeField(self.chip, name:sub(2, #name), value)
	else
		self.variables[name] = value
	end
end

function vm:execCode(code)
	for _, v in ipairs(code) do
		-- i think empty lines cause empty string to be in line.code ???
		if type(v) ~= "string" then
			local ok, result = pcall(function() self:executeStatement(v) end)
			if not ok and result:sub(#result-18, #result) == "STOP_LINE_EXECUTION" then
				break
			elseif not ok then
				error(result)  -- when i wish we could handle errors like in python
			end
		end
	end
end

--- Runs all code in the next line
function vm:step()
	self.line = (self.line % #self.lines) + 1
	---@type YAST_Line
	local line = self.lines[self.line]
	self.errors[self.line] = {}

	if #line.errors == 0 then  -- if no syntax errors
		self:execCode(line.code)
	end
end

function vm:evalExpr(ast)
	if ast.type == "number" then
		return tonumber(ast.num)
	elseif ast.type == "string" then
		return ast.str
	elseif ast.type == "identifier" then
		local name = ast.name
		local external = false
		if name:sub(1, 1) == ":" then
			external = true
			name = name:sub(2, #name)
		end
		local value
		if external then
			value = LoadedMap:getField(self.chip, name)
		else
			local v, multipleDifferentValues = self.variables[name]
			value = v
			if multipleDifferentValues then
				self:pushError({
					level="error",
					msg="Found multiple different values for the name data field '" .. name .. "'"
				})
				self:haltLine()
			end
		end
		if value == nil then
			value = 0  -- default if undefined
		end
		return value
	-- General binary math handling
	elseif ast.type == "exp" or ast.type == "mul" or ast.type == "add" then
		local leftValue = self:evalExpr(ast.left)
		local rightValue = self:evalExpr(ast.right)
		if ast.operator == "^" then
			return leftValue ^ rightValue
		elseif ast.operator == "*" then
			return leftValue * rightValue
		elseif ast.operator == "/" then
			if rightValue == 0 then
				self:pushError({
					level="error",
					msg="Attempted division by zero."
				})
				self:haltLine()
			end
			return leftValue / rightValue
		elseif ast.operator == "%" then
			if rightValue == 0 then
				self:pushError({
					level="error",
					msg="Attempted modulo by zero."
				})
				self:haltLine()
			end
			return leftValue % rightValue
		elseif ast.operator == "+" then
			return leftValue + rightValue
		elseif ast.operator == "-" then
			return leftValue - rightValue
		else
			errorVM("invalid operator " .. ast.operator .. " from " .. ast.type .. " type for binary math handling in eval.")
		end
	elseif ast.type == "keyword" then
		local keyword = ast.operator:lower()
		local value = self:evalExpr(ast.operand)
		if keyword == "not" then
			if value == 0 then
				return 1
			else
				return 0
			end
		elseif keyword == "abs" then
			return math.abs(value)
		elseif keyword == "cos" then
			return math.cos(value)
		elseif keyword == "sin" then
			return math.sin(value)
		elseif keyword == "tan" then
			return math.tan(value)
		elseif keyword == "acos" then
			return math.acos(value)
		elseif keyword == "asin" then
			return math.asin(value)
		elseif keyword == "atan" then
			return math.atan(value)
		elseif keyword == "sqrt" then
			return math.sqrt(value)
		else
			errorVM("invalid keyword " .. ast.operator .. " for keyword handling in eval, expected a valid keyword")
		end
	elseif ast.type == "pre_add" or ast.type == "post_add" then
		local identifier
		if ast.operand ~= nil and ast.operand.type == "identifier" then
			identifier = ast.operand.name
		end
		local value = self:evalExpr(ast.operand)
		local newValue
		if ast.operator == "++" then
			newValue = value + 1
		elseif ast.operator == "--" then
			newValue = value - 1
		else
			errorVM("invalid operator " .. ast.operator .. " for unary_add handling in eval, expected a valid operator")
		end
		if identifier ~= nil then
			self:setVariableFromName(identifier, newValue)
		end
		if ast.type == "pre_add" then
			return newValue
		else
			return value
		end
	else
		errorVM("invalid type " .. ast.type .. " for an eval, expected a valid expresstion type")
	end
end

---@param ast table @ YAST_Expression
function vm:executeStatement(ast)
	if ast.type == "assign" then
		self:st_assign(ast)
	elseif ast.type == "goto" then
		self:st_goto(ast)
	elseif ast.type == "if" then
		self:_if(ast)
	elseif ast.type == "comment" then
	elseif ast.type == "expression" then
		if ast.expression == nil or (ast.expression.type ~= "pre_add" and ast.expression.type ~= "post_add") then
			self:pushError({
				level="warn",
				msg="used expression"
			})
		else
			self:evalExpr(ast.expression)
		end
	else
		errorVM("unknown ast node type " .. ast.type)
	end
end

function vm:st_assign(ast)
	if ast.operator ~= "=" then errorVM("assign operator " .. tostring(ast.operator) .. " is not supported yet.") end
	local name = ast.identifier.name
	local value = self:evalExpr(ast.value)
	self:setVariableFromName(name, value)
end

function vm:st_goto(ast)
	local ln = self:evalExpr(ast.expression)
	if type(ln) ~= "number" then
		self:pushError({
			level="error",
			msg="attempt to goto a invalid line, it was not a number."
		})
		self:haltLine()
	else
		if ln <= 0 then
			ln = 1
		elseif ln > 20 then
			ln = 20
		end
		self.line = ln-1
	end
end

function vm:_if(ast)
	local value = self:evalExpr(ast.condition)
	if value == 0 then
		if ast.else_body ~= nil then
			self:execCode(ast.else_body)
		end
	else
		self:execCode(ast.body)
	end
end


return vm
