-- Contains data validators and some functions to simplfy things

-- Typing
---@class Field
local Field = {
	---@type string
	name=nil,
	---@type string|nil
	desc=nil,
	---@type string|number
	default=nil,
	---@type fun(newValue:string|number):string|number @ Or nil
	changed=nil
}
---@class Device
local Device = {
	---@type string
	name=nil,
	---@type string|nil
	desc=nil,
	---@type table<string,Field>
	fields=nil
}


local function validateField(field, otherFieldname, deviceName)
	local otherFieldname = otherFieldname or "<NO_NAME>"
	local deviceName = deviceName or "<NO_NAME>"
	if type(field.name) ~= "string" then
		error("field " .. otherFieldname .. " of " .. deviceName .. " is missing a 'name' field of the type string.")
	elseif type(field.desc) ~= "string" then
		print("field " .. field.name .. " of " .. deviceName .. " is missing a 'desc' field of the type string.")
	elseif type(field.default) ~= "string" and type(field.default) ~= "number" then
		error("field " .. field.name .. " of " .. deviceName .. " is missing a 'default' field of the type string or number.")
	end
end

local function validateDevice(device)
	if type(device.name) ~= "string" then
		error("<NO_NAME> is missing a 'name' field of the type string.")
	elseif type(device.desc) ~= "string" then
		print(device.name .. " is missing a 'desc' field of the type string.")
	elseif type(device.fields) ~= "table" then
		error(device.name .. " is missing a 'fields' field of the type table.")
	end
	for i,v in pairs(device.fields) do
		validateField(v, i, device.name)
	end
end

return {
	validateDevice=validateDevice,
	validateField=validateField,

	-- used for simplification
	changed_anyNumber=function(self, newValue)
		if type(newValue) ~= "number" then
			error(self.name .. " expected a number but got " .. type(newValue) .. " instead.")
		end
		return newValue
	end,
	changed_anyString=function(self, newValue)
		if type(newValue) ~= "string" then
			error(self.name .. " expected a string but got " .. type(newValue) .. " instead.")
		end
		return newValue
	end
}
