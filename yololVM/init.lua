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
---@param name string
function vm:getVariableFromName(name)
	if name:sub(1, 1) == ":" then
		LoadedMap:getField(self.chip, name:sub(2, #name))
	else
		return self.variables[name] or 0
	end
end

local function execCode_errHandler(err)
	if type(err) == "string" and err:sub(#err-18, #err) == "STOP_LINE_EXECUTION" then
		return false
	else
		print("CRITIAL VM ERROR:")
		print(debug.traceback(err))
		return true
	end
end
function vm:execCode(code)
	for _, v in ipairs(code) do
		-- i think empty lines cause empty string to be in line.code ???
		if type(v) ~= "string" then
			local ok, result = xpcall(function()
				self:executeStatement(v)
			end, execCode_errHandler)
			if not ok then
				if result == "not enough memory" then
					self:pushError({
						msg="Ran out of Memory"
					})
				-- known case where running out of memory can mess stuff up
				elseif result == execCode_errHandler then
					self:pushError({
						msg="Might have ran out of Memory"
					})
				else
					self:pushError({
						msg="CRITIAL VM ERROR"
					})
				end
				break
			end
		end
	end
end

--- Runs all code in the next line
function vm:step()
	---@type YAST_Line
	local line = self.lines[self.line]
	self.errors[self.line] = {}

	if #line.metadata.errors == 0 then  -- if no syntax errors
		self:execCode(line.code)
	end
	self.line = (self.line % #self.lines) + 1
end

function vm:evalExpr(ast)
	if ast.type == "expression::number" then
		return tonumber(ast.num)
	elseif ast.type == "expression::string" then
		return ast.str
	elseif ast.type == "expression::identifier" then
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
	elseif ast.type == "expression::binary_op" then
		local operator = ast.operator:lower()
		local leftValue = self:evalExpr(ast.lhs)
		local rightValue = self:evalExpr(ast.rhs)
		if operator == "^" then
			return leftValue ^ rightValue
		elseif operator == "*" then
			return leftValue * rightValue
		elseif operator == "/" then
			if rightValue == 0 then
				self:pushError({
					level="error",
					msg="Attempted division by zero."
				})
				self:haltLine()
			end
			return leftValue / rightValue
		elseif operator == "%" then
			if rightValue == 0 then
				self:pushError({
					level="error",
					msg="Attempted modulo by zero."
				})
				self:haltLine()
			end
			return leftValue % rightValue
		elseif operator == "+" then
			if type(leftValue) == "string" or type(leftValue) == "string" then
				return tostring(leftValue) .. tostring(leftValue)
			else
				return leftValue + leftValue
			end
		elseif operator == "-" then
			return leftValue - rightValue
		elseif operator == "==" then
			if leftValue == rightValue then
				return 1
			else
				return 0
			end
		elseif operator == "!=" then
			if leftValue ~= rightValue then
				return 1
			else
				return 0
			end
		elseif operator == ">" then
			if leftValue > rightValue then
				return 1
			else
				return 0
			end
		elseif operator == ">=" then
			if leftValue >= rightValue then
				return 1
			else
				return 0
			end
		elseif operator == "<" then
			if leftValue > rightValue then
				return 1
			else
				return 0
			end
		elseif operator == "<=" then
			if leftValue <= rightValue then
				return 1
			else
				return 0
			end
		elseif operator == "and" then
			if leftValue == 1 and rightValue == 1 then
				return 1
			else
				return 0
			end
		elseif operator == "or" then
			if leftValue == 1 or rightValue == 1 then
				return 1
			else
				return 0
			end
		else
			errorVM("invalid operator " .. ast.operator .. " for binary math handling in eval.")
		end
	elseif ast.type == "expression::unary_op" then
		local operator = ast.operator:lower()
		local value = self:evalExpr(ast.operand)
		if operator == "not" then
			if value == 0 then
				return 1
			else
				return 0
			end
		elseif operator == "abs" then
			return math.abs(value)
		elseif operator == "cos" then
			return math.cos(value)
		elseif operator == "sin" then
			return math.sin(value)
		elseif operator == "tan" then
			return math.tan(value)
		elseif operator == "acos" then
			return math.acos(value)
		elseif operator == "asin" then
			return math.asin(value)
		elseif operator == "atan" then
			return math.atan(value)
		elseif operator == "sqrt" then
			return math.sqrt(value)
		elseif operator == "-" then
			local value = self:evalExpr(ast.operand)
			return -value
		elseif operator == "++" or operator == "--" then
			local identifier
			if ast.operand ~= nil and ast.operand.type == "identifier" then
				identifier = ast.operand.name
			end
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
			if ast.prpo == "pre" then
				return newValue
			else
				return value
			end
		else
			errorVM("invalid keyword " .. ast.operator .. " for keyword handling in eval, expected a valid keyword")
		end
	else
		errorVM("invalid type " .. ast.type .. " for an eval, expected a valid expresstion type")
	end
end

---@param ast table @ YAST_Expression
function vm:executeStatement(ast)
	if ast.type == "statement::assignment" then
		self:st_assign(ast)
	elseif ast.type == "statement::goto" then
		self:st_goto(ast)
	elseif ast.type == "statement::if" then
		self:_if(ast)
	elseif ast.type == "expression::unary_op" and ast.prpo ~= nil then
		self:evalExpr(ast)
	else
		errorVM("unknown ast type for statement " .. ast.type)
	end
end

function vm:st_assign(ast)
	local name = ast.identifier.name
	local value = self:evalExpr(ast.value)
	if ast.operator ~= "=" then
		local oldValue = self:getVariableFromName(name)
		if ast.operator == "+=" then
			if type(oldValue) == "string" or type(value) == "string" then
				value = tostring(oldValue) .. tostring(value)
			else
				value = oldValue + value
			end
		elseif ast.operator == "-=" then
			value = oldValue - value
		elseif ast.operator == "*=" then
			value = oldValue * value
		elseif ast.operator == "/=" then
			if value == 0 then
				self:pushError({
					level="error",
					msg="Attempted division by zero."
				})
				self:haltLine()
			end
			value = oldValue / value
		elseif ast.operator == "%=" then
			if value == 0 then
				self:pushError({
					level="error",
					msg="Attempted modulo by zero."
				})
				self:haltLine()
			end
			value = oldValue % value
		else
			errorVM("assign operator " .. tostring(ast.operator) .. " is not supported yet.")
		end
	end
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
