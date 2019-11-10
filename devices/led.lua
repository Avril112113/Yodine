-- For testing, not in the game its self
local deviceValidation = require "devices._deviceValidation"

local LEDState = {
	name="LEDState",
	default=0,
	desc="Its either on or off, its a light...",
	---@type Device_LED
	parent=nil,
	---@type number
	value=nil
}
---@param newValue string|number
---@return string|number
function LEDState:changed(newValue)
	if newValue == 0 or newValue == 1 then
		return newValue
	end
	return self.default
end

---@class Device_LED
local LED = {
	name="LED",
	desc="TODO",
	fields={
		LEDState=LEDState
	}
}

function LED:draw()
	-- everything is already transformed, just draw as 0, 0 was top-left
	local LEDImg = GetImage("imgs/led.png")
	if self.fields.LEDState.value ~= nil and self.fields.LEDState.value == 0 then
		love.graphics.setColor(0.5, 0, 0, 1)
	else
		love.graphics.setColor(1, 0, 0, 1)
	end
	local width, height = self:getSize()
	love.graphics.draw(LEDImg, 0, 0, 0, GetScale(LEDImg:getWidth(), LEDImg:getHeight(), width, height))
end
function LED:getSize()
	return BackgroundCellSize*2, BackgroundCellSize*2
end
function LED:getWireDrawOffset()
	local width, height = self:getSize()
	return width/2, height
end

deviceValidation.validateDevice(LED)
return LED
