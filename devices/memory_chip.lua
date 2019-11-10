-- For testing, not in the game its self
local deviceValidation = require "devices._deviceValidation"

local ChipField = {
	name="ChipField",
	default=0,
	desc="No Desc",
	sort=999,
	---@type Device_Button
	parent=nil,
	---@type number
	value=nil
}
function ChipField._copy(n)
	local tbl = DeepCopy(ChipField)
	tbl.name = tbl.name .. tostring(n)
	tbl.sory = n
	return tbl
end

---@class Device_MemoryChip
local MemoryChip = {
	name="Memory Chip",
	desc="Stores 10 device fields",
	fields={
		ChipField1=ChipField._copy(1),
		ChipField2=ChipField._copy(2),
		ChipField3=ChipField._copy(3),
		ChipField4=ChipField._copy(4),
		ChipField5=ChipField._copy(5),
		ChipField6=ChipField._copy(6),
		ChipField7=ChipField._copy(7),
		ChipField8=ChipField._copy(8),
		ChipField9=ChipField._copy(9),
		ChipField10=ChipField._copy(10),
	}
}

function MemoryChip:draw()
	-- everything is already transformed, just draw as 0, 0 was top-left
	local width, height = self:getSize()
	love.graphics.setColor(0, 0.24, 0.17, 1)
	love.graphics.rectangle("fill", 0, 0, width, height)
	love.graphics.setLineWidth(3)
	love.graphics.setColor(0, 0.17, 0.17, 1)
	love.graphics.rectangle("line", 1, 1, width-2, height-2)
	love.graphics.setColor(0.7, 0.7, 0.7, 1)
	love.graphics.printf("Mem Chip 10 Fields", 0, 0, width, "center")
end
function MemoryChip:getSize()
	return BackgroundCellSize*2, BackgroundCellSize*3
end
function MemoryChip:getWireDrawOffset()
	local width, height = self:getSize()
	return width/2, height/2
end

deviceValidation.validateDevice(MemoryChip)
return MemoryChip
