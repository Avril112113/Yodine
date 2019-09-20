local deviceValidation = require "devices._deviceValidation"

local ButtonState = {
	name="ButtonState",
	default=0,
	desc="The name of the field of which value the button modifies.",
	---@type Device_Button
	parent=nil,
	---@type number
	value=nil
}
---@param newValue string|number
---@return string|number
function ButtonState:changed(newValue)
	if newValue == 0 or newValue == 1 then
		return newValue
	end
	return self.default
end

local ButtonOnStateValue = {
	name="ButtonOnStateValue",
	default=0,
	desc="Controls the value when pressed.",
	---@type Device_Button
	parent=nil,
	---@type number
	value=nil
}
ButtonOnStateValue.changed = deviceValidation.changed_anyNumber

local ButtonOffStateValue = {
	name="ButtonOnStateValue",
	default=1,
	desc="Controls the value when pressed.",
	---@type Device_Button
	parent=nil,
	---@type number
	value=nil
}
ButtonOffStateValue.changed = deviceValidation.changed_anyNumber

local ButtonStyle = {
	name="ButtonStyle",
	default=0,
	desc="Controls the interaction style of the button.\n\n0: Hold down and release\n1: Basic Toggle (simple click to toggle)\n2: 4-state switch (like a click pen)",
	---@type Device_Button
	parent=nil,
	---@type number
	value=nil
}
---@param newValue string|number
---@return string|number
function ButtonStyle:changed(newValue)
	if newValue == 0 or newValue == 1 or newValue == 2 then
		return newValue
	end
	return self.default
end

---@class Device_Button
local button = {
	name="Button",
	desc="TODO",
	fields={
		buttonState=ButtonState,
		ButtonOnStateValue=ButtonOnStateValue,
		ButtonOffStateValue=ButtonOffStateValue,
		ButtonStyle=ButtonStyle
	}
}

function button:draw()
	-- everything is already transformed, just draw as 0, 0 was top-left
	local btnImg
	if self.fields.buttonState.value == 0 then
		btnImg = GetImage("imgs/button.png")
	else
		btnImg = GetImage("imgs/button_on.png")
	end
	local width, height = self:getSize()
	love.graphics.draw(btnImg, 0, 0, 0, GetScale(btnImg:getWidth(), btnImg:getHeight(), width, height))
end
function button:getSize()
	return BackgroundCellSize*4, BackgroundCellSize*4
end
function button:getWireDrawOffset()
	local width, height = self:getSize()
	return width/2, height/2
end
function button:clicked(x, y, button)
	-- x, y is relitive to the position of the object and is never greater than :getSize()
	self.fields.buttonState.value = self.fields.buttonState.value == 1 and 0 or 1
end

deviceValidation.validateDevice(button)
return button
