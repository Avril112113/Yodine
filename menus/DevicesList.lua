local loveframes = require "loveframes"
local menus = require "menus"
local devices = require "devices"


local textColor = {0.9, 0.9, 0.9, 1}


local DevicesList = {
	deviceNameFont=love.graphics.newFont(24),
	deviceDescFont=love.graphics.newFont(12)
}
menus.DevicesList = DevicesList
local base = loveframes.Create("list")
DevicesList.base = base
base:SetPadding(0)
base:SetSpacing(3)

local orderedCategories = {}
-- TODO: fix this, its exponentially slow (device count)
for _, category in pairs(devices.categories) do
	local orderedDevices = {}
	for _, device in pairs(devices.registered) do
		if device.category == category then
			table.insert(orderedDevices, device)
		end
	end
	table.sort(orderedDevices, function(a, b)
		return (a.name or "") < (b.name or "")
	end)
	table.insert(orderedCategories, {category=category, devices=orderedDevices})
end
table.sort(orderedCategories, function(a, b)
	return (a.category.order or math.huge) < (b.category.order or math.huge)
end)

for _, data in ipairs(orderedCategories) do
	local category = data.category
	local orderedDevices = data.devices

	local collapsible = loveframes.Create("collapsiblecategory")
	collapsible:SetText(category.displayname)

	local categoryDevicesList = loveframes.Create("list")
	collapsible:SetObject(categoryDevicesList)

	for _, device in ipairs(orderedDevices) do
		local panel = loveframes.Create("panel")

		local padding = 2
		local targetWidth = 80
		local dw, dh = device:getSize()
		local aspect = targetWidth/dw
		local panelHeight = dh*aspect + (padding*2)
		local panelWidth = base.width + padding
		local leftOfPreviewWidth = panelWidth - targetWidth - (padding*2) - 26

		local DeviceName = loveframes.Create("text", panel)
		DeviceName:SetSize(leftOfPreviewWidth, -1)
		DeviceName:SetPos(padding, padding)
		DeviceName:SetText {{font=DevicesList.deviceNameFont, color=textColor}, device.name or "<NO_DEVICE_NAME>"}

		local DescText = loveframes.Create("text", panel)
		DescText:SetSize(leftOfPreviewWidth, -1)
		-- SetPos is fine as long as base:SetSize uses a constant width in DevicesList:update()
		DescText:SetPos(padding, padding + DeviceName.y + DeviceName.height)
		DescText:SetText {{font=DevicesList.deviceDescFont, color=textColor}, device.desc or "No Device Description."}
		local descTextBottom = padding + DeviceName.y + DeviceName.height + DescText.y + DescText.height + (padding*2)
		if descTextBottom > panelHeight then
			panelHeight = descTextBottom
		end
		panel:SetSize(panelWidth, panelHeight)
		function panel:DrawOver()
			local tx, ty = self.x + self.width - targetWidth - padding, self.y + padding
			love.graphics.push()
			love.graphics.translate(tx, ty)
			love.graphics.scale(aspect, aspect)
			device:draw()
			love.graphics.pop()
		end

		local panel_mousepressed = panel.mousepressed
		local function anyChildIsHoverObject(obj)
			if obj.children == nil then return false end
			for _, child in pairs(obj.children) do
				if child == loveframes.hoverobject then return true end
			end
			return false
		end
		function panel:mousepressed(x, y, button)
			panel_mousepressed(self, x, y, button)

			if self == loveframes.hoverobject or anyChildIsHoverObject(self) then
				DevicesList.draggingDevice = device
			end
		end

		categoryDevicesList:AddItem(panel)
	end

	categoryDevicesList:SetHeight(categoryDevicesList.itemheight)
	collapsible:SetOpen(true)  -- must be here and not before the above line, otherwise it will not calculate heights propperly
	base:AddItem(collapsible)
end

function DevicesList:update()
	base:SetSize(280, love.graphics.getHeight())
	base:SetPos(love.graphics.getWidth()-base.width, 0)
end
