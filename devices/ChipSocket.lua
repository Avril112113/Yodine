local devices = require "devices"
local menus = require "menus"

require "devices.MemoryChip"


---@class ChipSocketDevice
local ChipSocketDevice = setmetatable({
	name="ChipSocket",
	desc="YOLOL chip socket is a base device, which relays power and connection to a data network for the YOLOL chip.\nOther option for mounting YOLOL chips is the Modular device rack.",
	---@type Device
	chip=nil,
	category=devices.categories.starbase
}, devices.DeviceMeta)

ChipSocketDevice:newField {
	name="CurrentState",
	desc="TODO desc",
	default=1
}

ChipSocketDevice:newField {
	name="OnState",
	desc="TODO desc",
	default=1
}

ChipSocketDevice:newField {
	name="OffState",
	desc="TODO desc",
	default=0
}

ChipSocketDevice:newField {
	name="ButtonStyle",
	desc="TODO desc",
	default=0
}

function ChipSocketDevice:init()
end

function ChipSocketDevice:cleanup()
	if self.chip then
		self.chip:destroy()
	end
end

function ChipSocketDevice:draw()
	local ChipSocketImg = GetImage("imgs/chip_socket.png")
	local width, height = self:getSize()
	love.graphics.draw(ChipSocketImg, 0, 0, 0, GetScale(ChipSocketImg:getWidth(), ChipSocketImg:getHeight(), width, height))
end
function ChipSocketDevice:getSize()
	return 120, 80
end

function ChipSocketDevice:openGUI()
	menus.ChipSocketGUI:openGUI(self)
end

function ChipSocketDevice:networkChanged(oldNetwork, newNetwork)
	if self.chip ~= nil then
		self.chip:changeNetwork(newNetwork)
	end
end

function ChipSocketDevice:SetNewChipDevice(device)
	assert(getmetatable(device) == devices.ChipMeta)
	if self.chip ~= nil then
		self.chip:destroy()
	end
	local obj = device:create()
	self.chip = obj
	obj:changeNetwork(self.network)
	menus.ChipSocketGUI:update(true)
	ClearSelectedDevices()
	AddSelectedDevice(obj)
	return obj
end

function ChipSocketDevice:save(data)
	if self.chip ~= nil then
		data.chip = setmetatable(self.chip:serialize(), {
			__yaml_tag="!" .. self.chip:GetSaveName()
		})
	end
end
function ChipSocketDevice:load(save)
	if save.chip then
		self.chip = save.chip._tagged_device:deserialize(self.network, save.chip)
	end
end

devices:register(ChipSocketDevice)
