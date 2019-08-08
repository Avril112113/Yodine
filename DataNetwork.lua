---@class DataNetwork
local DataNetwork = {
	---@type Device[]
	devices=nil
}
DataNetwork.__index = DataNetwork
---@return DataNetwork
function DataNetwork.new()
	local self = setmetatable({
		devices={}
	}, DataNetwork)
	return self
end

return DataNetwork
