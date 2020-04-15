local loveframes = require "loveframes"
local menus = require "menus"


local textColor = {0.9, 0.9, 0.9, 1}


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

---@param device Device
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
		for deviceFieldName, fieldName in pairs(device:getFields()) do
			table.insert(orderedFields, {deviceFieldName=deviceFieldName, fieldName=fieldName, deviceField=device:getFieldInfo(deviceFieldName)})
		end
		table.sort(orderedFields, function(a, b)
			if a.deviceField.order == nil and b.deviceField.order == nil then
				return a.deviceFieldName < b.deviceFieldName
			end
			return (a.deviceField.order or -2) < (b.deviceField.order or -1)
		end)
		DeviceFields:SetRows(#orderedFields)
		local function OnValueEditFocusGained(self)
			if self:GetText():sub(1, 1) == "\"" then
				self.indicatornum = self.indicatornum - 1
			end
		end
		for row, data in ipairs(orderedFields) do
			local fieldDeviceName = data.deviceFieldName
			local fieldInfo = data.deviceField
			local fieldName = data.fieldName
			local fieldValue = device:getFieldValue(fieldDeviceName)
			local FieldNameEdit = loveframes.Create("textinput")
			FieldNameEdit:SetSize(DeviceFields:GetCellWidth(), DeviceFields:GetCellHeight())
			FieldNameEdit:SetText(fieldName)
			local newName
			local function setNewName()
				if newName ~= nil then
					device:setFieldName(fieldDeviceName, newName)
					newName = nil
				end
				fieldName = device:getFieldName(fieldDeviceName)
				FieldNameEdit:SetText(fieldName)
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
			FieldValueEdit:SetText(type(fieldValue) == "string" and "\"" .. fieldValue .. "\"" or tostring(fieldValue))
			local newValue
			local function setNewValue()
				if newValue ~= nil then
					if tonumber(newValue) ~= nil then
						device:setFieldValue(fieldDeviceName, tonumber(newValue))
					elseif newValue == "" then
						device:setFieldValue(fieldDeviceName, fieldInfo.default)
					else
						device:setFieldValue(fieldDeviceName, newValue:gsub("^\"", ""):gsub("\"$", ""))
					end
					newValue = nil
				end
				fieldValue = device:getFieldValue(fieldDeviceName)
				FieldValueEdit:SetText(type(fieldValue) == "string" and "\"" .. fieldValue .. "\"" or tostring(fieldValue))
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

function DeviceInfo:update()
	base:SetSize(280, love.graphics.getHeight())
	base:SetPos(0, 0)

	DeviceName:SetSize(base.width-self.deviceNamePadding*2, self.deviceNameFont:getHeight())
	DeviceName:SetPos(self.deviceNamePadding, self.deviceNamePadding)

	DeviceFields:SetSize(base.width-self.deviceFieldsPadding*2, base.height-DeviceFields.y-self.deviceFieldsPadding*2)
	DeviceFields:SetPos(self.deviceFieldsPadding, self.deviceFieldsPadding+DeviceName.height)
	DeviceFields:SetColumns(2)
	DeviceFields:SetCellWidth(DeviceFields.width/2.15)
end
