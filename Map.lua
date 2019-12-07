local devices = require "devices"
local devicesNameLookup = {}
for _, device in pairs(devices) do
	devicesNameLookup[device.name] = device
end


---@class MapObject
local MapObject = {
	-- NOTE: a device is just an 'extension' of this (Technically its the other way round in code)
	---@type number
	x=nil,
	---@type number
	y=nil,
	---@type table<MapObject,MapObject>
	connections=nil
}
MapObject.__index = MapObject
function MapObject.new(x, y, device)
	local self = setmetatable(DeepCopy(device), MapObject)
	self.x = x
	self.y = y
	self.connections = {}
	self._device = device  -- just incase we need the original reference for comparison for example

	for i, v in pairs(self.fields) do
		v.value = v.default
		v.parent = self
	end
	return self
end
function MapObject.newFromSave(device, save)
	local self = setmetatable(DeepCopy(device), MapObject)
	self.x = save.x or error("Missing field x on object save")
	self.y = save.y or error("Missing field y on object save")
	self.connections = save.connections or {}
	self._device = device  -- just incase we need the original reference for comparison for example

	for i, v in pairs(self.fields) do
		v.value = v.default
		v.parent = self
	end
	if save.fields ~= nil then
		for i, v in pairs(save.fields) do
			local field = self.fields[i]
			field.name = v.name or field.name
			field.value = v.value
		end
	end
	return self
end

---@class Map
local Map = {
	---@type MapObject[]
	objects=nil,
	hasModification=false
}
Map.__index = Map
---@return Map
function Map.new(save)
	local objects = {}
	if save ~= nil then
		if save.objects ~= nil then
			for i, v in ipairs(save.objects) do
				local device = devicesNameLookup[v.name]
				if device == nil then
					error("Failed to find device with name " .. tostring(v.name))
				end
				objects[i] = MapObject.newFromSave(device, v)
			end
		end
		-- make obj.connections references to objects instead of numbers again
		-- also run obj.loadFromSave if exists
		for objI, obj in pairs(objects) do
			for i, connectionObjIndex in pairs(obj.connections) do
				obj.connections[i] = objects[connectionObjIndex]
			end
			if obj.loadFromSave ~= nil then
				obj:loadFromSave(save.objects[objI])
			end
		end
	end
	local self = setmetatable({
		objects=objects,
		hasModification=false
	}, Map)
	return self
end

function Map:jsonify()
	return {
		objects=jsonify_auto(self.objects)
	}
end

---@param x number
---@param y number
---@param device Device
function Map:createObject(x, y, device)
	local obj = MapObject.new(x, y, device)
	if obj.init then
		obj:init()
	end
	table.insert(self.objects, obj)
	self.hasModification = true
	return obj
end

---@param obj MapObject
function Map:removeObject(obj)
	for i, v in pairs(self.objects) do
		if v == obj then
			table.remove(self.objects, i)
			return true
		end
	end
	self.hasModification = true
	return false
end

---@param x number
---@param y number
function Map:getObjectAt(x, y)
	for i, v in pairs(self.objects) do
		if v.getSize ~= nil then
			local width, height = v:getSize()
			if IsInside(v.x, v.y, v.x+width, v.y+height, x, y) then
				return v
			end
		end
	end
end

---@param objA MapObject
---@param objB MapObject
function Map:connect(objA, objB)
	objA.connections[objB] = objB
	objB.connections[objA] = objA
end

---@param objA MapObject
---@param objB MapObject
function Map:disconnect(objA, objB)
	objA.connections[objB] = nil
	objB.connections[objA] = nil
end

---@param objA MapObject
---@param objB MapObject
function Map:isConnected(objA, objB)
	return objA.connections[objB] ~= nil or objB.connections[objA] ~= nil
end

---@param origin MapObject
---@param fieldName string
---@param newValue string|number
function Map:changeField(origin, fieldName, newValue)
	assert(origin ~= nil)
	assert(fieldName ~= nil)
	assert(newValue ~= nil)
	local processed = {}
	local toProcess = {origin}
	while #toProcess > 0 do
		local obj = table.remove(toProcess)
		processed[obj] = obj
		for _, v in pairs(obj.fields) do
			if v.name:lower() == fieldName:lower() then
				v.value = v.changed and v:changed(newValue) or newValue
			end
		end
		for _, v in pairs(obj.connections) do
			if processed[v] == nil then
				table.insert(toProcess, v)
			end
		end
	end
end

---@param origin MapObject
---@param fieldName string
function Map:getField(origin, fieldName)
	assert(origin ~= nil)
	assert(fieldName ~= nil)
	local values = {}
	local processed = {}
	local toProcess = {origin}
	while #toProcess > 0 do
		local obj = table.remove(toProcess)
		processed[obj] = obj
		for _, v in pairs(obj.fields) do
			if v.name:lower() == fieldName:lower() then
				table.insert(values, v.value)
			end
		end
		for _, v in pairs(obj.connections) do
			if processed[v] == nil then
				table.insert(toProcess, v)
			end
		end
	end
	if #values <= 0 then
		return nil  -- undefined handled by caller
	else
		local value = values[1]
		for i, v in pairs(values) do
			if v ~= value then
				return nil, true
			end
		end
		return value
	end
end

return Map
