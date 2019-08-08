local deviceValidation = require "devices._deviceValidation"

---@class Device_Chip
local chip = {
	name="Chip",
	desc="TODO",
	fields={}
}

deviceValidation.validateDevice(chip)
return chip
