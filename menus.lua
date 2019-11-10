local loveframes = require "loveframes"
require "loveframes_ext"


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
				{font=DeviceInfo.deviceNameFont}, "No Device Selected",
				"\n",
				{font=DeviceInfo.deviceDescFont}, "No Device Description."
			}
			DeviceFields:SetRows(0)
		else
			DeviceName:SetText {
				{font=DeviceInfo.deviceNameFont}, device.name or "<NO_DEVICE_NAME>",
				"\n",
				{font=DeviceInfo.deviceDescFont}, device.desc or "No Device Description."
			}
			local orderedFields = {}
			for fieldName, field in pairs(device.fields) do
				table.insert(orderedFields, {fieldName, field})
			end
			table.sort(orderedFields, function(a, b) return (a[1].order or -1) < (b[1].order or -1) end)
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
				function FieldNameEdit:OnEnter()
					if newName ~= nil then
						if newName ~= nil then
							field.name = newName
							newName = nil
						end
						FieldNameEdit:SetText(field.name)
					end
				end
				function FieldNameEdit:Update(dt)
					if FieldNameEdit:GetFocus() then
						newName = FieldNameEdit:GetText()
					else
						if newName ~= nil then
							field.name = newName
							newName = nil
						end
						FieldNameEdit:SetText(field.name)
					end
				end
				DeviceFields:AddItem(FieldNameEdit, row, 1)

				local FieldValueEdit = loveframes.Create("textinput")
				FieldValueEdit:SetSize(DeviceFields:GetCellWidth(), DeviceFields:GetCellHeight())
				FieldValueEdit:SetText(type(field.value) == "string" and "\"" .. field.value .. "\"" or tostring(field.value))
				local newValue
				function FieldValueEdit:OnEnter()
					if newValue ~= nil then
						if newValue:sub(1, 1) == "\"" then
							field.value = newValue:gsub("^\"", ""):gsub("\"$", "")
						else
							field.value = tonumber(newValue)
						end
						newValue = nil
						FieldValueEdit:SetText(type(field.value) == "string" and "\"" .. field.value .. "\"" or tostring(field.value))
					end
				end
				function FieldValueEdit:Update(dt)
					if FieldValueEdit:GetFocus() then
						local text = FieldValueEdit:GetText()
						newValue = text
					else
						if newValue ~= nil then
							if tonumber(newValue) ~= nil then
								field.value = tonumber(newValue)
							elseif newValue == "" then
								field.value = field.default
							else
								field.value = newValue:gsub("^\"", ""):gsub("\"$", "")
							end
							newValue = nil
						end
						FieldValueEdit:SetText(type(field.value) == "string" and "\"" .. field.value .. "\"" or tostring(field.value))
					end
				end
				FieldValueEdit.OnFocusGained = OnValueEditFocusGained
				DeviceFields:AddItem(FieldValueEdit, row, 2)
			end
		end

		DeviceFields:SetPos(DeviceInfo.deviceFieldsPadding, DeviceInfo.deviceFieldsPadding+DeviceName.height)
	end
	DeviceInfo.setDevice(nil)

	function DeviceInfo.update()
		base:SetPos(0, 0)
		base:SetSize(280, love.graphics.getHeight())

		DeviceName:SetPos(DeviceInfo.deviceNamePadding, DeviceInfo.deviceNamePadding)
		DeviceName:SetSize(base.width-DeviceInfo.deviceNamePadding*2, DeviceInfo.deviceNameFont:getHeight())

		DeviceFields:SetPos(DeviceInfo.deviceFieldsPadding, DeviceInfo.deviceFieldsPadding+DeviceName.height)
		DeviceFields:SetSize(base.width-DeviceInfo.deviceFieldsPadding*2, base.height-DeviceFields.y-DeviceInfo.deviceFieldsPadding*2)
		DeviceFields:SetColumns(2)
		DeviceFields:SetCellWidth(DeviceFields.width/2.15)
	end
end


return menus
