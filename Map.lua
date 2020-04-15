local Network = require "Network"

---@class Relay
local Relay = {
	---@type Network
	src=nil,
	---@type Network
	dst=nil
}

---@class Map
local Map = {}
Map.__index = Map

---@return Map
function Map.new()
	local self = setmetatable({
		---@type table<string, Network>
		networks={},
		---@type Relay[]
		relays={}  -- Not used yet
	}, Map)
	return self
end

function Map.deserialize(save)
	local self = Map.new()
	for _, networkSave in pairs(save.networks) do
		self.networks[networkSave.name] = Network.deserialize(self, networkSave)
	end
	for _, relay in ipairs(save.relays) do
		self.relays[#self.relays+1] = {
			src=relay.src,
			dst=relay.dst
		}
	end
	return self
end

---@return string
function Map:serialize()
	local networks = {}
	for _, network in pairs(self.networks) do
		networks[#networks+1] = network:serialize()
	end
	local relays = {}
	for _, relay in pairs(self.relays) do
		relays[#relays+1] = relay
	end
	return setmetatable({
		networks=setmetatable(networks, {__yaml_mapping=false}),
		relays=setmetatable(relays, {__yaml_mapping=false})
	}, {__yaml_order={networks=1}})
end

function Map:update(dt)
	for _, network in pairs(self.networks) do
		network:update(dt)
	end
end

function Map:removeNetwork(network)
	self.networks[network.name] = nil
end

function Map:addNetwork(network)
	if self.networks[network.name] ~= nil then
		error("Attempt to override existing network with name " .. network.name)
	end
	self.networks[network.name] = network
end

---@param x number
---@param y number
---@return Device|nil
function Map:getObjectAt(x, y)
	for _, network in pairs(self.networks) do
		if network:withinBounds(x, y) then
			local obj = network:getObjectAt(x, y)
			if obj ~= nil then
				return obj
			end
		end
	end
end

---@param x number
---@param y number
---@return Network|nil
function Map:getNetworkAt(x, y)
	for _, network in pairs(self.networks) do
		if network:withinBounds(x, y) then
			return network
		end
	end
end

---@param x number
---@param y number
---@return Network|nil
function Map:getNetworksAt(x, y)
	local networks = {}
	for _, network in pairs(self.networks) do
		if network:withinBounds(x, y) then
			table.insert(networks, network)
		end
	end
	return networks
end

return Map
