local function errorVM(msg, ...)
	error("CRITAL VM ERROR: " .. tostring(msg), 2, ...)
end


local vm = {
	---@type YAST_Program
	ast=nil,
	---@type number
	line=nil
}
vm.__index = vm

---@param ast YAST_Program
---@param chip Device_Chip
function vm.new(ast, chip)
	local self = setmetatable({
		chip=chip,
		ast=ast,
		errors={},

		variables={},
		line=0
	}, vm)
	return self
end

function vm:pushError(errTbl)
	table.insert(self.errors[self.line], errTbl)
end

--- Runs all code in the next line
function vm:step()
	self.line = (self.line % #self.ast.lines) + 1
	---@type YAST_Line
	local line = self.ast.lines[self.line]
	self.errors[self.line] = {}

	for _, v in ipairs(line.code) do
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
					--pos=ast.pos,
					msg="Found multiple different values for the name data field '" .. name .. "'"
				})
				error("STOP_LINE_EXECUTION")
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
					msg="Attempted division by zero."
				})
				error("STOP_LINE_EXECUTION")
			end
			return leftValue / rightValue
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
	else
		errorVM("invalid type " .. ast.type .. " for an eval, expected a valid expresstion type")
	end
end

---@param ast table @ YAST_Expression
function vm:executeStatement(ast)
	if ast.type == "assign" then
		self:st_assign(ast)
	elseif ast.type == "comment" then
	else
		errorVM("unknown ast node type " .. ast.type)
	end
end

function vm:st_assign(ast)
	if ast.operator ~= "=" then errorVM("assign operator " .. tostring(ast.operator) .. " is not supported yet.") end
	local name = ast.identifier.name
	local value = self:evalExpr(ast.value)
	if name:sub(1, 1) == ":" then
		LoadedMap:changeField(self.chip, name:sub(2, #name), value)
	else
		self.variables[name] = value
	end
end


return vm
