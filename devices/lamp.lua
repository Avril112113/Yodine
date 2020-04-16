local devices = require "devices"


---@class LampDevice
local LampDevice = setmetatable({
	name="Lamp",
	desc="Lamps are light emitting devices that have programmable fields, such as state, color and brightness.",
	category=devices.categories.starbase
}, devices.DeviceMeta)

LampDevice:newField {
	name="LampOn",
	desc="TODO desc",
	default=0,
	validateValue=devices.validateValue_number
}
LampDevice:newField {
	name="LampLumens",
	desc="How bright the lamp is in lumens. 600 is a reasonable value for average lights.",
	default=600,
	validateValue=devices.validateValue_number
}
LampDevice:newField {
	name="LampColorHue",
	desc="The HSV color hue value.\nRange: 0 - 360",
	default=0,
	validateValue=devices.genValidateValue_range(0, 360)
}
LampDevice:newField {
	name="LampColorSaturation",
	desc="The HSV saturation value.\nRange: 0 - 1",
	default=1,
	validateValue=devices.genValidateValue_range(0, 1)
}
LampDevice:newField {
	name="LampColorValue",
	desc="The HSV color value.\nRange: 0 - 1",
	default=1,
	validateValue=devices.genValidateValue_range(0, 1)
}
LampDevice:newField {
	name="LampRange",
	desc="The HSV range value.\nRange: 0 - 1",
	default=1,
	validateValue=devices.genValidateValue_range(0, 1)
}

function LampDevice:draw()
	local LampImg = GetImage("imgs/lamp.png")
	local LampLightImg = GetImage("imgs/lamp_light.png")
	local width, height = self:getSize()
	love.graphics.draw(LampImg, 0, 0, 0, GetScale(LampImg:getWidth(), LampImg:getHeight(), width, height))
	if self:getFieldValue("LampOn", false) ~= 0 then
		local r, g, b = HSVToRGB(self:getFieldValue("LampColorHue", false), self:getFieldValue("LampColorSaturation", false),  self:getFieldValue("LampColorValue", false))
		love.graphics.setColor(r, g, b, 1)
	else
		love.graphics.setColor(0.1, 0.1, 0.1, 1)
	end
	love.graphics.draw(LampLightImg, 0, 0, 0, GetScale(LampImg:getWidth(), LampImg:getHeight(), width, height))
end
function LampDevice:getSize()
	return 40, 20
end

devices:register(LampDevice)
