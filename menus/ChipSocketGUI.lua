local loveframes = require "loveframes"
local menus = require "menus"


local ChipSocketGUI = {
	---@type ChipSocketDevice
	chipSocket=nil,
	chipScale=2
}
menus.ChipSocketGUI = ChipSocketGUI
local base = loveframes.Create("frame")
ChipSocketGUI.base = base

base:SetName("ChipSocket")
base:SetResizable(false)
base:SetDraggable(true)
base:SetVisible(false)

local chipPanel = loveframes.Create("panel", base)

function base:OnClose()
	base:SetVisible(false)
	ChipSocketGUI.chipSocket = nil
	return false
end

local lastclick = 0
-- there is no OnClick() for panels :(
function chipPanel:mousereleased(x, y, button)
	if not chipPanel.visible or not chipPanel.hover then
		return
	end

	local chip = ChipSocketGUI.chipSocket and ChipSocketGUI.chipSocket.chip
	if chip then
		ClearSelectedDevices()
		AddSelectedDevice(chip)

		if ChipSocketGUI.chipSocket.chip and ChipSocketGUI.chipSocket.chip.openGUI and os.clock() < lastclick + DoubleClickTime then
			lastclick = os.clock() + DoubleClickTime
			ChipSocketGUI.chipSocket.chip:openGUI()
		else
			lastclick = os.clock()
		end
	end
end

function chipPanel:DrawOver()
	love.graphics.push()
	love.graphics.translate(self.x, self.y)
	if ChipSocketGUI.chipSocket and ChipSocketGUI.chipSocket.chip then
		local cw, ch = ChipSocketGUI.chipSocket.chip:getSize()
		local sx, sy = chipPanel.width / cw, chipPanel.height / ch
		love.graphics.scale(sx, sy)
		ChipSocketGUI.chipSocket.chip:draw()
	else
		local msg
		if ChipSocketGUI.chipSocket == nil then
			love.graphics.setColor(1, 0, 0, 1)
			msg = "WARN: Device not selected in GUI (This is a bug)"
		else
			love.graphics.setColor(1, 1, 1, 1)
			msg = "No chip in this device.\nDrag a chip into this box\nfrom the devices list."
		end
		love.graphics.setNewFont(24)
		love.graphics.printf(msg, 0, 0, chipPanel.width, "center")
	end
	love.graphics.pop()
end

function ChipSocketGUI:update(forceCentre)
	local chip = self.chipSocket and self.chipSocket.chip
	local chipScale = (chip and chip.chipSocketScale) or self.chipScale

	local baseYOff = 24
	local minChipWidth, minChipHeight = 20 * self.chipScale, 20 * self.chipScale
	local chipWidth, chipHeight
	if chip then
		chipWidth, chipHeight = chip:getSize()
	else
		chipWidth = chipWidth or 240
		chipHeight = chipHeight or 80
	end

	local chipPanelWidth, chipPanelHeight = chipWidth * chipScale, chipHeight * chipScale
	if chipPanelWidth < minChipWidth then
		local scale = chipPanelWidth / minChipWidth
		chipPanelWidth, chipPanelHeight = chipPanelWidth * scale, chipPanelHeight * scale
	end
	if chipPanelHeight < minChipHeight then
		local scale = chipPanelHeight / minChipHeight
		chipPanelWidth, chipPanelHeight = chipPanelWidth * scale, chipPanelHeight * scale
	end

	chipPanel:SetSize(chipPanelWidth, chipPanelHeight)
	chipPanel:SetPos(0, baseYOff)

	base:SetSize(chipPanel.width, chipPanel.height + 24)
	if not base.visible or forceCentre == true then
		base:SetPos((love.graphics.getWidth()-base.width)/2, (love.graphics.getHeight()-base.height)/2)
	end
end

function ChipSocketGUI:deviceDropped(device)
	self.chipSocket:SetNewChipDevice(device)
end

function ChipSocketGUI:openGUI(device)
	local oldGuiSocketDevice = self.chipSocket
	self.chipSocket = device
	self:update()
	if oldGuiSocketDevice ~= device then
		self.base:SetVisible(true)
		self.base:MakeTop()
		ClearSelectedDevices()
		AddSelectedDevice(device.chip)
	else
		self.base:OnClose()
	end
end
