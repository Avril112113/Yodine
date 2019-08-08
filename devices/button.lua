local deviceValidation = require "devices._deviceValidation"

local ButtonState = {
	name="ButtonState",
	default=0,
	desc="The name of the field of which value the button modifies.",
	---@type Device_Button
	parent=nil
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
	parent=nil
}
ButtonOnStateValue.changed = deviceValidation.changed_anyNumber

local ButtonOffStateValue = {
	name="ButtonOnStateValue",
	default=1,
	desc="Controls the value when pressed.",
	---@type Device_Button
	parent=nil
}
ButtonOffStateValue.changed = deviceValidation.changed_anyNumber

local ButtonStyle = {
	name="ButtonStyle",
	default=0,
	desc="Controls the interaction style of the button.\n\n0: Hold down and release\n1: Basic Toggle (simple click to toggle)\n2: 4-state switch (like a click pen)",
	---@type Device_Button
	parent=nil
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

deviceValidation.validateDevice(button)
return button
