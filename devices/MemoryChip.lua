local devices = require "devices"


---@class MemoryChip
local MemoryChip = setmetatable({
	name="MemoryChip",
	desc="Stores by default non-functional device fields for data sharing between chips.",
	category=devices.categories.starbase_chips,
	font=love.graphics.setNewFont(24)
}, devices.ChipMeta)

for i=1,10 do
	MemoryChip:newField {
		name="ChipField" .. i,
		desc="",
		default=0
	}
end

function MemoryChip:draw()
	local width, height = self:getSize()
	love.graphics.setColor(0, 0.24, 0.17, 1)
	love.graphics.rectangle("fill", 0, 0, width, height)
	love.graphics.setLineWidth(3)
	love.graphics.setColor(0, 0.17, 0.17, 1)
	love.graphics.rectangle("line", 1, 1, width-2, height-2)
	love.graphics.setColor(0.7, 0.7, 0.7, 1)
	love.graphics.setFont(self.font)
	love.graphics.printf("Mem Chip 10 Fields", 0, 0, width, "center")
end
function MemoryChip:getSize()
	return 80, 120
end

devices:register(MemoryChip)
