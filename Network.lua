local devices = require "devices"


---@class Network
local Network = {}
Network.__index = Network

---@param map Map
---@param name string
function Network.new(map, name)
	if name == nil then
		local i = 0
		name = "network_" .. i
		while map.networks[name] ~= nil do
			i = i + 1
			name = "network_" .. i
		end
	end
	local self = setmetatable({
		name=name,
		remark="No Remark.",
		---@type table<string, string|number>
		fields=setmetatable({_fields={}}, {
			__index=function(self, key)
				if key == "_fields" then return rawget(self, key) end
				local fields = rawget(self, "_fields")
				for fieldName, _ in pairs(fields) do
					if fieldName:lower() == key:lower() then
						return fields[fieldName]
					end
				end
				return nil
			end,
			__newindex=function(self, key, value)
				local fields = rawget(self, "_fields")
				for fieldName, _ in pairs(fields) do
					if fieldName:lower() == key:lower() then
						fields[fieldName] = value
						return
					end
				end
				fields[key] = value
			end
		}),
		color={math.random(0, 255)/255, math.random(0, 255)/255, math.random(0, 255)/255},
		---@type Device[]
		objects={},
		---@type Map
		map=map,
		---@type number[]
		hull={}
	}, Network)
	return self
end

function Network:destroy()
	self.map:removeNetwork(self)
	-- Invalidate the object in-case of left over references we WANT it to error so we can fix
	for _, obj in pairs(self.objects) do
		obj:destroy()
	end
	self.objects = nil
	self.hull = nil
	self.map = nil
	self.color = nil
	self.name = nil
	self.remark = nil
	self.fields = nil
end

function Network.deserialize(map, save)
	local self = Network.new(map, save.name)
	self.color = save.extensions.color or self.color
	if save.extensions and save.extensions.fields then
		for fieldName, fieldValue in pairs(save.extensions.fields) do
			self.fields[fieldName] = fieldValue
		end
	end
	for _, deviceSave in pairs(save.devices) do
		deviceSave._tagged_device:deserialize(self, deviceSave)
	end
	return self
end

function Network:serialize()
	local objects = {}
	for _, object in pairs(self.objects) do
		if getmetatable(object) == devices.DeviceMeta then
			table.insert(objects, setmetatable(object:serialize(), {__yaml_tag="!" .. object:GetSaveName()}))
		end
	end
	return setmetatable({
		name=self.name,
		remark=self.remark,
		devices=objects,
		extensions={
			fields=self.fields._fields,
			color=self.color
		}
	}, {__yaml_anchor=self.name})
end

function Network:generateHull()
	local points = {}
	for _, obj in pairs(self.objects) do
		for _, point in pairs(obj:getBounds()) do
			table.insert(points, point)
		end
	end
	self.hull = MonotoneChain(points)
end

function Network:update(dt)
	local drawableObjectCount = 0
	for _, obj in pairs(self.objects) do
		if getmetatable(obj) == devices.DeviceMeta then
			drawableObjectCount = drawableObjectCount + 1
		end
	end
	if drawableObjectCount <= 0 then
		self:destroy()
	else
		for _, obj in pairs(self.objects) do
			obj:update(dt)
		end
	end
end

---@param obj Device
function Network:addObject(obj)
	table.insert(self.objects, obj)
	self:generateHull()
end

---@param obj Device
function Network:removeObject(obj)
	for i, v in pairs(self.objects) do
		if v == obj then
			table.remove(self.objects, i)
			if #self.objects <= 0 then
				self.map:removeNetwork(self)
			else
				self:generateHull()
			end
			return true
		end
	end
	return false
end

---@param x number
---@param y number
---@return Device|nil
function Network:getObjectAt(x, y)
	for _, obj in pairs(self.objects) do
		if getmetatable(obj) == devices.DeviceMeta then
			local ox, oy, ow, oh = obj.x, obj.y, obj:getSize()
			if IsInside(ox, oy, ox+ow, oy+oh, x, y) then
				return obj
			end
		end
	end
end

---@param x number
---@param y number
---@return boolean
function Network:withinBounds(x, y)
	return InsidePolygon(self.hull, {x, y})
end

function Network:getField(name)
	return self.fields[name] or 0
end

function Network:setField(name, value)
	self.fields[name] = value
end

function Network:changeField(oldName, newName)
	if self.fields[newName] == nil then
		self.fields[newName] = self:getField(oldName)
	end
	for _, obj in pairs(self.objects) do
		if obj:hasFieldWithName(oldName) then
			return
		end
	end
	self.fields[oldName] = nil
end

return Network
