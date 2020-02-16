local json = require "json"
local loveframes = require "loveframes"
local devices = require "devices"
local Map = require "Map"
local saves_system = require "saves_system"


-- Patch terrible text colors
-- when its a dark skin the text is hard to see due to its color
local textColor = {0.9, 0.9, 0.9, 1}
local color = function(s, a) return {loveframes.Color(s, a)} end
for i, v in pairs(loveframes.skins) do
	if i:sub(1, 4) == "Dark" then
		v.controls.color_fore0  = color "e5e5e5"
	end
end

-- TODO: customize this
loveframes.SetActiveSkin("Dark green")


local menus = {}


do
	local DeviceInfo = {
		deviceNamePadding=5,
		deviceFieldsPadding=5,
		deviceNameFont=love.graphics.newFont(24),
		deviceDescFont=love.graphics.newFont(14)
	}
	menus.DeviceInfo = DeviceInfo
	local base = loveframes.Create("panel")
	DeviceInfo.base = base

	local DeviceName = loveframes.Create("text", base)
	DeviceInfo.DeviceName = DeviceName

	local DeviceFields = loveframes.Create("grid", base)

	function DeviceInfo.setDevice(device)
		DeviceInfo.device = device

		for i, obj in pairs(DeviceFields.children) do
			obj:Remove()
			DeviceFields.children[i] = nil
		end

		if device == nil then
			DeviceName:SetText {
				{font=DeviceInfo.deviceNameFont, color=textColor}, "No Device Selected",
				"\n",
				{font=DeviceInfo.deviceDescFont, color=textColor}, "No Device Description."
			}
			DeviceFields:SetRows(0)
		else
			DeviceName:SetText {
				{font=DeviceInfo.deviceNameFont, color=textColor}, device.name or "<NO_DEVICE_NAME>",
				"\n",
				{font=DeviceInfo.deviceDescFont, color=textColor}, device.desc or "No Device Description."
			}
			local orderedFields = {}
			for fieldName, field in pairs(device.fields) do
				table.insert(orderedFields, {fieldName, field})
			end
			table.sort(orderedFields, function(a, b)
				if a[1].order == nil and b[1].order == nil and a[1].name ~= nil and b[1].name ~= nil then
					return a[1].name < b[1].name
				end
				return (a[1].order or -1) < (b[1].order or -1)
			end)
			DeviceFields:SetRows(#orderedFields)
			local function OnValueEditFocusGained(self)
				if self:GetText():sub(1, 1) == "\"" then
					self.indicatornum = self.indicatornum - 1
				end
			end
			for row, fieldData in ipairs(orderedFields) do
				local fieldName, field = unpack(fieldData)

				local FieldNameEdit = loveframes.Create("textinput")
				FieldNameEdit:SetSize(DeviceFields:GetCellWidth(), DeviceFields:GetCellHeight())
				FieldNameEdit:SetText(field.name)
				local newName
				local function setNewName()
					if newName ~= nil then
						field.name = newName
						newName = nil
					end
					FieldNameEdit:SetText(field.name)
				end
				function FieldNameEdit:OnEnter()
					setNewName()
				end
				function FieldNameEdit:Update(dt)
					if FieldNameEdit:GetFocus() then
						newName = FieldNameEdit:GetText()
					else
						setNewName()
					end
				end
				FieldNameEdit.OnFocusLost = function() setNewName() end
				DeviceFields:AddItem(FieldNameEdit, row, 1)

				local FieldValueEdit = loveframes.Create("textinput")
				FieldValueEdit:SetSize(DeviceFields:GetCellWidth(), DeviceFields:GetCellHeight())
				FieldValueEdit:SetText(type(field.value) == "string" and "\"" .. field.value .. "\"" or tostring(field.value))
				local newValue
				local function setNewValue()
					if newValue ~= nil then
						if tonumber(newValue) ~= nil then
							LoadedMap:changeField(device, field.name, tonumber(newValue))
						elseif newValue == "" then
							LoadedMap:changeField(device, field.name, field.default)
						else
							LoadedMap:changeField(device, field.name, newValue:gsub("^\"", ""):gsub("\"$", ""))
						end
						newValue = nil
					end
					FieldValueEdit:SetText(type(field.value) == "string" and "\"" .. field.value .. "\"" or tostring(field.value))
				end
				function FieldValueEdit:OnEnter()
					setNewValue()
				end
				function FieldValueEdit:Update(dt)
					if FieldValueEdit:GetFocus() then
						local text = FieldValueEdit:GetText()
						newValue = text
					else
						setNewValue()
					end
				end
				FieldValueEdit.OnFocusGained = OnValueEditFocusGained
				FieldValueEdit.OnFocusLost = function() setNewValue() end
				DeviceFields:AddItem(FieldValueEdit, row, 2)
			end
		end

		DeviceFields:SetPos(DeviceInfo.deviceFieldsPadding, DeviceInfo.deviceFieldsPadding+DeviceName.height)
	end
	DeviceInfo.setDevice(nil)

	function DeviceInfo.update()
		base:SetSize(280, love.graphics.getHeight())
		base:SetPos(0, 0)

		DeviceName:SetSize(base.width-DeviceInfo.deviceNamePadding*2, DeviceInfo.deviceNameFont:getHeight())
		DeviceName:SetPos(DeviceInfo.deviceNamePadding, DeviceInfo.deviceNamePadding)

		DeviceFields:SetSize(base.width-DeviceInfo.deviceFieldsPadding*2, base.height-DeviceFields.y-DeviceInfo.deviceFieldsPadding*2)
		DeviceFields:SetPos(DeviceInfo.deviceFieldsPadding, DeviceInfo.deviceFieldsPadding+DeviceName.height)
		DeviceFields:SetColumns(2)
		DeviceFields:SetCellWidth(DeviceFields.width/2.15)
	end
end

do
	local DevicesList = {
		deviceNameFont=love.graphics.newFont(24),
		deviceDescFont=love.graphics.newFont(12)
	}
	menus.DevicesList = DevicesList
	local base = loveframes.Create("list")
	DevicesList.base = base
	base:SetPadding(0)
	base:SetSpacing(3)

	local orderedDevices = {}
	for _, device in pairs(devices) do
		table.insert(orderedDevices, device)
	end
	table.sort(orderedDevices, function(a, b)
		return (a.name or "") < (b.name or "")
	end)

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
		-- SetPos is fine as long as base:SetSize uses a constant width in DevicesList.update()
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

		base:AddItem(panel)
	end

	function DevicesList.update()
		base:SetSize(280, love.graphics.getHeight())
		base:SetPos(love.graphics.getWidth()-base.width, 0)
	end
end

do
	local OpenSavesMenu = {}
	menus.OpenSavesMenu = OpenSavesMenu
	local base = loveframes.Create("button")
	OpenSavesMenu.base = base

	base:SetSize(74, 70)
	base:SetText("")
	base:SetImage(GetImage("imgs/save and load.png"))

	function base:OnClick()
		menus.SavesMenu.base:SetVisible(not menus.SavesMenu.base.visible)
	end

	function OpenSavesMenu.update()
		base:SetPos((love.graphics.getWidth() - base.width) / 2, 5)
	end
end

do
	local SavesMenu = {}
	menus.SavesMenu = SavesMenu
	local base = loveframes.Create("frame")
	SavesMenu.base = base

	local padding = 2

	-- base:SetVisible(false)
	base:SetName("Save and Load")
	base:SetResizable(false)
	base:SetDraggable(false)

	function base:OnClose()
		base:SetVisible(false)
		return false
	end

	local SaveNameEdit = loveframes.Create("textinput", base)
	SaveNameEdit:SetText("save")

	function SaveNameEdit:Update()
		local pattern = "[/\\*?<>:|]"
		if self:GetText():find(pattern) then
			self:SetText(self:GetText():gsub(pattern, ""))
		end
	end

	local SaveButton = loveframes.Create("button", base)
	SaveButton:SetText("Save")

	function SaveButton:OnClick()
		saves_system.save(LoadedMap, SaveNameEdit:GetText())
		LoadedMap.hasModification = false
		SavesMenu.refreshSavesList()
	end

	local SavesList = loveframes.Create("list", base)
	local LoadSaveButton = loveframes.Create("button", base)
	LoadSaveButton:SetText("Load Selected Save")

	local selectedSave

	function LoadSaveButton:OnClick()
		if selectedSave ~= nil then
			local loadedMap = saves_system.load(selectedSave)
			if loadedMap ~= nil then
				LoadedMap = loadedMap
				ClearSelectedDevices()
				base:SetVisible(false)
			else
				SavesMenu.refreshSavesList()
			end
		end
	end

	function SavesMenu.refreshSavesList()
		SavesList:Clear()
		for _, save in ipairs(saves_system.fetch_save_list()) do
			local button = loveframes.Create("button")
			button:SetText(save.name)
			button.groupIndex = 1
			function button:OnClick()
				selectedSave = save
				SaveNameEdit:SetText(save.name)
			end
			SavesList:AddItem(button)
		end
	end
	SavesMenu.refreshSavesList()

	local ShowInFileBrowser = loveframes.Create("button", base)
	ShowInFileBrowser:SetText("Show In File Browser")
	function ShowInFileBrowser:OnClick()
		local path = "file://"..love.filesystem.getSaveDirectory()
		if selectedSave ~= nil then
			path = path .. "/" .. selectedSave.dir
		end
		love.system.openURL(path)
	end

	function SavesMenu.update()
		local width = 350
		local base_frame_height = 25

		SaveNameEdit:SetSize(width-padding-50, 25)
		SaveNameEdit:SetPos(padding, padding + base_frame_height)
		SaveButton:SetSize(50-padding, SaveNameEdit.height)
		SaveButton:SetPos(padding + SaveNameEdit.staticx + SaveNameEdit.width, padding + base_frame_height)

		SavesList:SetSize(width-padding, 400)
		SavesList:SetPos(padding, padding + SaveNameEdit.staticy + SaveNameEdit.height)

		LoadSaveButton:SetSize(width/2-padding, 28)
		LoadSaveButton:SetPos(padding, padding + SavesList.staticy + SavesList.height)
		ShowInFileBrowser:SetSize(width/2-padding, 28)
		ShowInFileBrowser:SetPos(padding + width/2, padding + SavesList.staticy + SavesList.height)

		base:SetSize(ShowInFileBrowser.staticx + ShowInFileBrowser.width + padding, ShowInFileBrowser.staticy + ShowInFileBrowser.height + padding)
		base:SetPos((love.graphics.getWidth() - width) / 2, (love.graphics.getHeight() - base.height) / 2)
	end
end

-- do
-- 	local SavesOverrideConfirm = {}
-- 	menus.SavesOverrideConfirm = SavesOverrideConfirm
-- 	local base = loveframes.Create("frame")
-- 	SavesOverrideConfirm.base = base

-- 	base:SetVisible(false)
-- 	base:SetName("Save Confirmation")
-- 	base:SetSize(280, 100)

-- 	local Text = loveframes.Create("text", base)
-- 	Text:SetText {
-- 		{font=SavesOverrideConfirm.font, color=textColor}, "Are you sure you want to override the save?"
-- 	}

-- 	local CancelButton = loveframes.Create("button", base)
-- 	CancelButton:SetText("Cancel")
-- 	CancelButton:SetSize()

-- 	local ConfirmButton = loveframes.Create("button", base)
-- 	ConfirmButton:SetText("Confirm")

-- 	function SavesOverrideConfirm.update()
-- 		base:SetPos((love.graphics.getWidth() - base.width) / 2, (love.graphics.getHeight() - base.height) / 2)

-- 		CancelButton:SetSize(80, 20)
-- 		CancelButton:SetPos(5, base.height-CancelButton.height-5)

-- 		ConfirmButton:SetSize(CancelButton.width, CancelButton.height)
-- 		ConfirmButton:SetPos(base.width-ConfirmButton.width-5, base.height-ConfirmButton.height-5)

-- 		Text:SetSize(base.width, base.height - CancelButton.height)
-- 		Text:SetPos(5, 28)
-- 	end
-- end


return menus
