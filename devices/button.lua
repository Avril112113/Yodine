local devices = require "devices"


---@class ButtonDevice
local ButtonDevice = setmetatable({
	name="Button",
	desc="TODO",
	category=devices.categories.starbase,
	font=love.graphics.newFont("fonts/Inconsolata-Regular.ttf", 14)
}, devices.DeviceMeta)

ButtonDevice:newField {
	name="ButtonState",
	desc="The current state of the button based on the fields ButtonOnStateValue and ButtonOffStateValue.",
	default=0
}
ButtonDevice:newField {
	name="ButtonOnStateValue",
	desc="The value of ButtonState when the button is pressed.",
	default=1
}
ButtonDevice:newField {
	name="ButtonOffStateValue",
	desc="The value of ButtonState when the button is not pressed.",
	default=0
}
ButtonDevice:newField {
	name="ButtonStyle",
	desc="TODO",
	default=0,
	validateValue=devices.genValidateValue_range(0, 2)
}

function ButtonDevice:draw()
	local btnImg
	if self:isPressed() then
		btnImg = GetImage("imgs/button_on.png")
	else
		btnImg = GetImage("imgs/button.png")
	end
	local width, height = self:getSize()
	love.graphics.draw(btnImg, 0, 0, 0, GetScale(btnImg:getWidth(), btnImg:getHeight(), width, height))
	love.graphics.setFont(self.font)
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.printf(self:getFieldName("ButtonState"), 1, height/2 - self.font:getHeight() + 1, width, "center")
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(self:getFieldName("ButtonState"), 0, height/2 - self.font:getHeight() + 1, width, "center")
end
function ButtonDevice:getSize()
	return 80, 80
end
---@param x number
---@param y number
---@param button ButtonDevice
function ButtonDevice:clicked(x, y, button)
	if self:isPressed() then
		self:setFieldValue("ButtonState", self:getFieldValue("ButtonOffStateValue"))
	else
		self:setFieldValue("ButtonState", self:getFieldValue("ButtonOnStateValue"))
	end
end

function ButtonDevice:isPressed()
	return self:getFieldValue("ButtonState") == self:getFieldValue("ButtonOnStateValue")
end

devices:register(ButtonDevice)
