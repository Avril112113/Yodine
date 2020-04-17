local devices = {
	registered={},
	registered_save_name={},
	categories={
		starbase={
			displayname="Star Base Devices",
			order=1
		},
		starbase_chips={
			displayname="Star Base Chips",
			order=2
		},
		unoffical={
			displayname="Un-Official Devices",
			order=3
		},
		unoffical_chips={
			displayname="Un-Official Chips",
			order=4
		},
		uncatagorized={
			displayname="Uncategorized",
			order=9999
		},
	}
}

---@class Device
local DeviceMeta = {
	---@type number
	x=nil,
	---@type number
	y=nil,
	---@type Network
	network=nil,

	category=devices.categories.uncatagorized
}
DeviceMeta.__index = DeviceMeta
devices.DeviceMeta = DeviceMeta

---@param x number
---@param y number
function DeviceMeta:create(x, y)
	assert(self ~= nil, "should be a call using `:`")
	local meta = DeviceMeta
	local isChip = x == devices.ChipMeta and y == devices.ChipMeta
	if isChip then
		meta = x
		x = nil
		y = nil
	else
		assert(type(x) == "number", "x is not a number")
		assert(type(y) == "number", "y is not a number")
	end
	local Device = self  -- `Button:create(x, y)`
	---@type Device
	local self = setmetatable({
		Device=Device,
		x=x,
		y=y
	}, {
		__index=function(iself, key)
			local value = rawget(iself, key)
			if value ~= nil then return value end
			return Device[key]
		end,
		__metatable=meta
	})
	self._fields = {}
	for _, DeviceField in pairs(Device.DeviceFields) do
		self._fields[DeviceField.name] = DeviceField.name
	end
	self:init()
	return self
end

function DeviceMeta:destroy()
	self:cleanup()
	if self.network ~= nil then
		self.network:removeObject(self)
	end
	-- Invalidate the object in-case of left over references we WANT it to error so we can fix
	for k, v in pairs(self) do
		self[k] = nil
	end
end

function DeviceMeta:deserialize(network, save)
	local x, y = save.extensions.x, save.extensions.y
	local invalidPosWarning = false
	if type(x) ~= "number" and type(self) == DeviceMeta then x = 0 invalidPosWarning = true end
	if type(y) ~= "number" and type(self) == DeviceMeta then y = 0 invalidPosWarning = true end
	if invalidPosWarning then
		print("WARNING: save.yaml contained invalid device position")
	end
	local self = self:create(x, y)
	self:changeNetwork(network)
	-- fieldDeviceName's are mixed in with other data in the save
	for _, DeviceField in pairs(self.DeviceFields) do
		local deviceFieldName = DeviceField.name
		local fieldName = save[deviceFieldName]
		if fieldName ~= nil then
			self:setFieldName(deviceFieldName, fieldName)
		end
	end
	if self.load ~= nil then
		self:load(save)
	end
	return self
end

function DeviceMeta:serialize()
	local data = setmetatable({
		extensions={
			x=self.x,
			y=self.y
		}
	}, {__yaml_order={extensions=1}})
	for deviceFieldName, fieldName in pairs(self._fields) do
		data[deviceFieldName] = fieldName
	end
	if self.save ~= nil then
		self:save(data)
	end
	return data
end

local POINT_RADIUS = 30
function DeviceMeta:getBounds(x, y)
	x, y = x or self.x, y or self.y
	local w, h = self:getSize()
	local points = {}
	table.insert(points, {x+w+POINT_RADIUS, y-POINT_RADIUS})
	table.insert(points, {x-POINT_RADIUS,   y-POINT_RADIUS})
	table.insert(points, {x-POINT_RADIUS,   y+h+POINT_RADIUS})
	table.insert(points, {x+w+POINT_RADIUS, y+h+POINT_RADIUS})
	return points
end

function DeviceMeta:changeNetwork(network)
	local oldNetwork = self.network
	if oldNetwork ~= nil then
		oldNetwork:removeObject(self)
	end
	network:addObject(self)
	self.network = network
	-- self:setFieldDefaults()
	for fieldDeviceName, fieldName in pairs(self._fields) do
		local value = network.fields[fieldName]
		if value == nil then
			network.fields[fieldName] = oldNetwork and oldNetwork.fields[fieldName] or self.DeviceFields[fieldDeviceName].default
		end
	end
	if oldNetwork ~= nil then
		oldNetwork:generateHull()
	end
	self:networkChanged(oldNetwork, network)
end

function DeviceMeta:GetSaveName()
	return self.save_name or self.name:lower():gsub(" ", "_")
end

function DeviceMeta:setFieldDefaults()
	if self.network ~= nil then
		for fieldDeviceName, fieldName in pairs(self._fields) do
			fieldName = fieldName
			for netFieldName, _ in pairs(self.network.fields._fields) do
				netFieldName = netFieldName
				if netFieldName == fieldName then
					goto continue
				end
			end
			self.network:setField(fieldName, self:getFieldInfo(fieldDeviceName).default)
			::continue::
		end
	end
end
function DeviceMeta:newField(tbl)
	if type(tbl.name) ~= "string" then error("device 'name' is invalid") end
	if type(tbl.desc) ~= "string" then error("device 'desc' is invalid") end
	if type(tbl.default) ~= "string" and type(tbl.default) ~= "number" then error("device 'default' is invalid") end
	self.DeviceFields = self.DeviceFields or {}
	self.DeviceFields[tbl.name] = tbl
end
function DeviceMeta:hasFieldWithName(name)
	for _, fieldName in pairs(self._fields) do
		if fieldName == name then
			return true
		end
	end
	return false
end
function DeviceMeta:getFields()
	return self._fields
end
function DeviceMeta:getFieldInfo(fieldDeviceName)
	return self.DeviceFields[fieldDeviceName]
end
function DeviceMeta:getFieldName(fieldDeviceName)
	assert(self.DeviceFields[fieldDeviceName] ~= nil, "Field " .. tostring(fieldDeviceName) .. " does not exist")
	return (self._fields and self._fields[fieldDeviceName]) or self.DeviceFields[fieldDeviceName]
end
function DeviceMeta:setFieldName(fieldDeviceName, newName)
	assert(self._fields ~= nil, "Attempt to set field name on non device instance")
	assert(self.DeviceFields[fieldDeviceName] ~= nil, "Field " .. tostring(fieldDeviceName) .. " does not exist")
	local oldName = self._fields[fieldDeviceName]
	self._fields[fieldDeviceName] = newName
	self.network:changeField(oldName, newName)
end
function DeviceMeta:getFieldValue(fieldDeviceName, getRawValue)
	local value
	local deviceField = self.DeviceFields[fieldDeviceName]
	assert(deviceField ~= nil, "Field " .. tostring(fieldDeviceName) .. " does not exist")
	if self.network == nil then
		value = deviceField.default
	else
		value = self.network:getField(self:getFieldName(fieldDeviceName))
	end
	if getRawValue == false then
		local validator = deviceField.validateValue
		if validator ~= nil then
			value = validator(deviceField, value)
		end
	end
	return value
end
function DeviceMeta:setFieldValue(fieldDeviceName, value)
	assert(self.network ~= nil, "Attempt to set field value on non device instance")
	self.network:setField(self:getFieldName(fieldDeviceName), value)
end

-- DeviceMeta defaults, all overrideable
function DeviceMeta:init()
end
--- In the case where we are drawing a preview of the device and not one where it is in the map, `self` is equal to the registered device and not a device object
function DeviceMeta:draw()
	love.graphics.setColor(1, 0, 1)
	love.graphics.rectangle("fill", 0, 0, self:getSize())
end
function DeviceMeta:update(dt)
end
function DeviceMeta:getSize()
	return 80, 40
end
function DeviceMeta:getWireDrawOffset()
	local width, height = self:getSize()
	return width/2, height/2
end
function DeviceMeta:clicked(x, y, button)
end
function DeviceMeta:cleanup()
end
function DeviceMeta:networkChanged(oldNetwork, newNetwork)
end


function devices:register(device)
	assert(getmetatable(device) == DeviceMeta or getmetatable(device) == devices.ChipMeta, "Attempt to register device " .. (device.name or "<UnknownDeviceName>") .. " without the DeviceMeta")
	device.Device = device
	local save_name = device.save_name or device.name:lower():gsub(" ", "_")
	device.save_name = save_name
	if self.registered[device.name] ~= nil then
		print("WARNING: attempt to over-register device with name " .. device.name .. " (multiple devices with the same name?)")
	end
	if self.registered[device.name] ~= nil then
		print("WARNING: attempt to over-register device with save name " .. save_name .. " (multiple devices with the same save_name?)")
	end
	self.registered[device.name] = device
	self.registered_save_name[save_name] = device
end


---@type Device
local ChipMeta = DeepCopy(DeviceMeta)
ChipMeta.__index = ChipMeta
devices.ChipMeta = ChipMeta

-- very similar to DeviceMeta:create()
function ChipMeta:create()
	return DeviceMeta.create(self, ChipMeta, ChipMeta)
end

function ChipMeta:getBounds()
	return {}
end


-- pre-set value validaters
function devices.validateValue_none(self, value)
	return value
end
function devices.validateValue_number(self, value)
	if type(value) ~= "number" then
		return self.default
	end
	return value
end
--- inclusive
function devices.genValidateValue_range(from, to)
	return function(self, value)
		if type(value) ~= "number" then
			value = 1
		end
		if value < from then
			value = from
		elseif value > to then
			value = to
		end
		return value
	end
end


-- prevent recursive require
package.loaded["devices"] = devices
-- find and load all devices
for _, fileName in pairs(love.filesystem.getDirectoryItems("devices")) do
	local fileNameExcExt = fileName:sub(0, -5)
	if fileName:sub(-4, -1) == ".lua" and fileNameExcExt ~= "init" then
		require("devices." .. fileNameExcExt)
	end
end


return devices
