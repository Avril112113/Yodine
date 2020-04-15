local loveframes = require "loveframes"
local menus = require "menus"
local devices = require "devices"
require "devices.YololChip"
require "lfeditor"


local YololChipEditor = {
	---@type YololChip
	yololChip=nil,
	viewOnly=false,
	font=love.graphics.newFont("fonts/Inconsolata-Regular.ttf", 24),
	lineColorPrimary={0.09, 0.13, 0.25, 1},
	lineColorSecondary={0.08, 0.12, 0.2, 1},
	lineColorExecute={0.83, 0.29, 0, 1},
	lineColorPause={0.78, 0, 0, 1},
}
menus.YololChipEditor = YololChipEditor
local base = loveframes.Create("frame")
YololChipEditor.base = base

base:SetName("Yolol Chip Editor")
base:SetResizable(false)
base:SetDraggable(true)
base:SetVisible(false)

---@type lfeditor
local editor = loveframes.Create("editor", base)

function editor:linesChanged(...)
	if YololChipEditor.yololChip ~= nil then
		YololChipEditor.yololChip:linesChanged(...)
	end
end

local rightPanel = loveframes.Create("panel", base)
local pauseButton = loveframes.Create("button", rightPanel)
pauseButton:SetText("")
function pauseButton:DrawOver()
	local img = GetImage("imgs/chip_play.png")
	local chip = YololChipEditor.yololChip
	if chip ~= nil and chip:isPaused() then
		img = GetImage("imgs/chip_pause.png")
	end
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(img, self.x, self.y, GetScale(img:getWidth(), img:getHeight(), 0, self.width, self.height))
end

function pauseButton:OnClick()
	local chip = YololChipEditor.yololChip
	if chip ~= nil then
		if chip:isPaused() then
			chip:setFieldValue("ChipWait", 0)
		else
			chip:setFieldValue("ChipWait", -1)
		end
	end
end


function base:OnClose()
	base:SetVisible(false)
	self.yololChip = nil
	return false
end

function YololChipEditor:update()
	local font = self.font
	local baseYOff = 24
	local lineLength = self.yololChip and self.yololChip.maxLineLength or devices.registered.YololChip.maxLineLength
	local lineCount = self.yololChip and self.yololChip.lineCount or devices.registered.YololChip.lineCount

	local lines = self.yololChip and self.yololChip.lines or nil
	if lines == nil then
		lines = {}
		for i=1, lineCount do
			lines[i] = ""
		end
	end

	editor.font = font
	editor.maxLineLength = lineLength
	editor.lines = lines
	editor.lineColors = {self.lineColorPrimary, self.lineColorSecondary}  -- Temp until vmUpdate()
	-- editor:SetSize(lineLength * font:getWidth("A"), lineCount * font:getHeight())
	editor:update(0)
	editor:SetPos(0, baseYOff)

	rightPanel:SetPos(editor.width+1, baseYOff)
	rightPanel:SetSize(85, editor.height)
	pauseButton:SetSize(rightPanel.width-4, rightPanel.width-4)
	pauseButton:SetPos(2, rightPanel.height-pauseButton.height-2)

	base:SetSize(editor.width + rightPanel.width, editor.height + baseYOff)
	if not base.visible then
		base:SetPos((love.graphics.getWidth()-base.width)/2, (love.graphics.getHeight()-base.height)/2)
	end
end

function YololChipEditor:vmUpdate()
	if self.yololChip == nil or self.yololChip.vm == nil then
		return
	end
	local chip = self.yololChip
	local vm = chip.vm
	local diagnostics = {}
	editor.diagnostics = diagnostics
	for i, line in ipairs(vm.lines) do
		if i == vm.prevLine then
			if chip:isPaused() then
				editor.lineColors[i] = self.lineColorPause
			else
				editor.lineColors[i] = self.lineColorExecute
			end
		elseif i % 2 == 0 then
			editor.lineColors[i] = self.lineColorPrimary
		else
			editor.lineColors[i] = self.lineColorSecondary
		end
		for _, diagnostic in pairs(line.metadata.errors) do
			table.insert(diagnostics, {
				line=i,
				type="error",
				msg=diagnostic.msg,
				start=diagnostic.pos,
				finish=diagnostic.pos+1
			})
		end
	end
	for line, lineErrors in pairs(vm.errors) do
		for _, diagnostic in pairs(lineErrors) do
			table.insert(diagnostics, {
				line=line,
				type=diagnostic.level,
				msg=diagnostic.msg,
				start=1,
				finish=#editor.lines[line]+1
			})
		end
	end
end
