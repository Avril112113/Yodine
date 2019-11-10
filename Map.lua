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
	end
	return self
end

---@class Map
local Map = {
	---@type MapObject[]
	objects=nil
}
Map.__index = Map
---@return Map
function Map.new()
	local self = setmetatable({
		objects={}
	}, Map)
	return self
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
