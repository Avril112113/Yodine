-- basically just to load all devices in this folder
return {
	chip=require "devices.chip",
	button=require "devices.button",
	led=require "devices.led",
	memory_chip=require "devices.memory_chip"
}
