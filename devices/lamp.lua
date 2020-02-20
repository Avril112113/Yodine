-- For testing, not in the game its self
local deviceValidation = require "devices._deviceValidation"

local LampOn = {
	name="LampOn",
	default=0,
	desc="Lamps are light emitting devices that have programmable fields, such as state, color and brightness.\nLamps require a power source to operate.",
	---@type Device_Lamp
	parent=nil,
	---@type number
	value=nil
}
---@param newValue string|number
---@return string|number
function LampOn:changed(newValue)
	if newValue == 0 or newValue == 1 then
		return newValue
	end
	return self.default
end

local LampLumens = {
	name="LampLumens",
	default=600,
	desc="How bright the lamp is in lumens. 600 is a reasonable value for average lights.",
	---@type Device_Lamp
	parent=nil,
	---@type number
	value=nil
}
---@param newValue string|number
---@return string|number
function LampLumens:changed(newValue)
	if type(newValue) == "number" and newValue > 0 and newValue < 2800 then
		return newValue
	end
	return self.default
end

local LampColorHue = {
	name="LampColorHue",
	default=0,
	desc="The HSV color hue value.\nRange: 0 - 360.0",
	---@type Device_Lamp
	parent=nil,
	---@type number
	value=nil
}
function LampColorHue:changed(newValue)
	if type(newValue) ~= "number" or newValue < 0 or newValue > 360 then
		return self.value
	end
	return newValue
end
local LampColorSaturation = {
	name="LampColorSaturation",
	default=1,
	desc="The HSV saturation value.\nRange: 0 - 1",
	---@type Device_Lamp
	parent=nil,
	---@type number
	value=nil
}
LampColorSaturation.changed = deviceValidation.changed_number0to1

local LampColorValue = {
	name="LampColorValue",
	default=1,
	desc="The HSV color value.\nRange: 0 - 1",
	---@type Device_Lamp
	parent=nil,
	---@type number
	value=nil
}
LampColorValue.changed = deviceValidation.changed_number0to1

local LampRange = {
	name="LampRange",
	default=1,
	desc="The HSV range value.\nRange: 0 - 1",
	---@type Device_Lamp
	parent=nil,
	---@type number
	value=nil
}
LampRange.changed = deviceValidation.changed_number0to1

---@class Device_Lamp
local Lamp = {
	name="Lamp",
	desc="TODO",
	fields={
		LampOn=LampOn,
		LampLumens=LampLumens,
		LampColorHue=LampColorHue,
		LampColorSaturation=LampColorSaturation,
		LampColorValue=LampColorValue,
		LampRange=LampRange
	}
}

function Lamp:draw()
	-- everything is already transformed, just draw as 0, 0 was top-left
	local LampImg = GetImage("imgs/lamp.png")
	local LampLightImg = GetImage("imgs/lamp_light.png")
	local width, height = self:getSize()
	love.graphics.draw(LampImg, 0, 0, 0, GetScale(LampImg:getWidth(), LampImg:getHeight(), width, height))
	if self.fields.LampOn.value ~= 1 then
		love.graphics.setColor(0.1, 0.1, 0.1, 1)
	else
		local r, g, b = HSVToRGB(self.fields.LampColorHue.value, self.fields.LampColorSaturation.value, self.fields.LampColorValue.value)
		love.graphics.setColor(r, g, b, 1)
	end
	love.graphics.draw(LampLightImg, 0, 0, 0, GetScale(LampImg:getWidth(), LampImg:getHeight(), width, height))
end
function Lamp:getSize()
	return BackgroundCellSize*2, BackgroundCellSize
end
function Lamp:getWireDrawOffset()
	local width, height = self:getSize()
	return width/2, height/2
end

deviceValidation.validateDevice(Lamp)
return Lamp
