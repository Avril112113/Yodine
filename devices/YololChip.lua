local devices = require "devices"
local menus = require "menus"
local SaveSystem = require "SaveSystem"
local yolol = require "yolol"
local yololVM = require "yololVM"


---@class YololChip
local YololChip = setmetatable({
	name="YololChip",
	desc="The YOLOL chip can interact with any connected device networks when placed inside a chip slot.\nThis interaction is done with a specific script.",
	category=devices.categories.starbase_chips,
	---@type string[]
	lines=nil,
	maxLineLength=70,
	lineCount=20,
	font=love.graphics.setNewFont(24),
	---@type string
	fileName=nil,
	---@type VM
	vm=nil,
	lastStep=0,
	stepInveral=0.2
}, devices.ChipMeta)

YololChip:newField {
	name="ChipWait",
	desc="Controls script execution. Negative values mean execution is paused, zero means script is being executed, and positive values mean execution will continue after the amount of line runs have passed that are equal to the value.	",
	default=0,
	validateValue=devices.validateValue_number
}

function YololChip:init()
	self.lines = {}
	for i=1,self.lineCount do
		self.lines[i] = ""
	end
	self.vm = yololVM.new(self)
	local changes = {}
	for i, text in ipairs(self.lines) do
		table.insert(changes, {
			line=i,
			text=text
		})
	end
	self:linesChanged(unpack(changes))
end
function YololChip:update(dt)
	local chipWait = self:getFieldValue("ChipWait", false)

	self.lastStep = self.lastStep + dt
	if self.lastStep > self.stepInveral then
		self.lastStep = self.lastStep - self.stepInveral
		if chipWait < 0 then
		elseif chipWait > 0 then
			self:setFieldValue("ChipWait", chipWait - 1)
		else
			self.vm:step()
		end
		menus.YololChipEditor:vmUpdate()
	end
end
function YololChip:draw()
	local width, height = self:getSize()
	love.graphics.setColor(0.24, 0, 0.17, 1)
	love.graphics.rectangle("fill", 0, 0, width, height)
	love.graphics.setLineWidth(3)
	love.graphics.setColor(0, 0.17, 0.17, 1)
	love.graphics.rectangle("line", 1, 1, width-2, height-2)
	love.graphics.setColor(0.7, 0.7, 0.7, 1)
	love.graphics.setFont(self.font)
	love.graphics.printf("Yolol Chip TODO", 0, 0, width, "center")
end
function YololChip:getSize()
	return 80, 120
end

function YololChip:openGUI()
	menus.YololChipEditor:OpenChip(self)
end

function YololChip:linesChanged(...)
	for _, change in ipairs({...}) do
		self.lines[change.line] = change.text
		self.vm.lines[change.line] = yolol.parseLine(change.text)
	end
end

function YololChip:save(data)
	local fileName = self.fileName or self.network.name .. "_chip_" .. #self.network.objects .. ".yolol"
	self.fileName = fileName
	local filePath = SaveSystem.loadedSave.save.dir .. "/" .. fileName
	data.script = fileName
	love.filesystem.write(filePath, table.concat(self.lines, "\n"))
end

function YololChip:load(data)
	self.fileName = data.script
	if self.fileName ~= nil then
		local filePath = SaveSystem.loadedSave.save.dir .. "/" .. self.fileName
		local code = love.filesystem.read(filePath)
		local i = 1
		local changes = {}
		for text in (code .. "\n"):gmatch("(.-)\n") do
			self.lines[i] = text
			table.insert(changes, {
				line=i,
				text=text
			})
			i = i + 1
		end
		self:linesChanged(unpack(changes))
	end
end

function YololChip:isPaused()
	return self:getFieldValue("ChipWait", false) ~= 0
end


devices:register(YololChip)
