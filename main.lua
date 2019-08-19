--[[TMP]] -- require "test"
require "utils"  -- provides a set of global functions

--[ =[
-- Constant's and defining locals
BackgroundCellSize = 20
local background
DefaultFont = GetFont()
Consola = love.graphics.newFont("Consola.ttf")

local helpers = require "yolol.tests.helpers"

local camera = require "camera"
local devices = require "devices.init"
local Map = require "Map"


LoadedMap = Map.new()
-- Testing stuff
local testButton = LoadedMap:createObject(0, -100, devices.button)
local testLED = LoadedMap:createObject(100, -100, devices.led)
---@type Device_Chip
local testChip = LoadedMap:createObject(-100, 0, devices.chip)
LoadedMap:connect(testButton, testLED)
LoadedMap:connect(testButton, testChip)

local lines = testChip.lines
lines[1] = "if 1 then a=1 else a=2 end"
--[[
lines[1] = "x1 = 1 y1 = ++x1"
lines[2] = "x2 = 1 y2 = x2++"
--]]
--[[
lines[1] = ":LEDState = 0.5 * 2"
lines[3] = ":LEDState = 0 / 1"
lines[5] = ":LEDState = 1 ^ 1"
lines[9] = ":LEDState = 0"
lines[10] = ":LEDState = 0 / 0"
lines[12] = "goto 1"
--]]
testChip:codeChanged()

-- Variables
local connectionTarget
CenterDrawObject = nil  -- used if a map object has a :drawGUI(), there are other functions for input ect


function SetCenterDrawObject(obj)
	if obj == nil then
		CenterDrawObject = nil
	else
		if obj.drawGUI == nil then
			error("Attempt to set center draw object but does not have :drawGUI()")
		end
		if obj.getSizeGUI == nil then
			error("Attempt to set center draw object but does not have :getSizeGUI()")
		end
		CenterDrawObject = obj
	end
end

local function genBackgroundImage()
	local imgData = love.image.newImageData(love.graphics.getWidth()+BackgroundCellSize, love.graphics.getHeight()+BackgroundCellSize)
	local mapCells = function(x, y, r, g, b, a)
		if (x+1)%BackgroundCellSize <= 1 or (y+1)%BackgroundCellSize <= 1 then
			return 0, 0, 0, 1
		else
			return 0.8, 0.8, 0.8, 1
		end
	end
	imgData:mapPixel(mapCells)
	background = love.graphics.newImage(imgData)
end


function love.load()
	love.window.maximize()

	camera.x = -love.graphics.getWidth()/2
	camera.y = -love.graphics.getHeight()/2

	love.filesystem.write("/Help.txt", love.filesystem.read("/data/_Help.txt"))
end

function love.draw()
	local ww, wh = love.graphics.getWidth(), love.graphics.getHeight()

	love.graphics.setColor(1, 1, 1, 1)

	if background == nil then
		genBackgroundImage()
	end
	love.graphics.draw(background, -camera.x%BackgroundCellSize-BackgroundCellSize, -camera.y%BackgroundCellSize-BackgroundCellSize)

	camera:set()
		love.graphics.setColor(0, 0, 0, 0.7)
		love.graphics.print("0,0", -GetFont():getWidth("0,0")/2, -GetFont():getHeight()+2)
		love.graphics.setColor(1, 0, 0, 1)
		love.graphics.circle("line", 0, 0, 50)

		love.graphics.setColor(0.3, 0.3, 0.3, 1)
		love.graphics.setLineWidth(3)
		for _, v in pairs(LoadedMap.objects) do
			for _, other in pairs(v.connections) do
				local vOffX, vOffY = 0, 0
				local otherOffX, otherOffY = 0, 0
				if v.getWireDrawOffset then vOffX, vOffY = v:getWireDrawOffset() end
				if other.getWireDrawOffset then otherOffX, otherOffY = other:getWireDrawOffset() end
				love.graphics.line(v.x+vOffX, v.y+vOffY, other.x+otherOffX, other.y+otherOffY)
			end
		end

		for _, v in pairs(LoadedMap.objects) do
			love.graphics.push()
				love.graphics.translate(v.x, v.y)
				if v.draw == nil then
					love.graphics.setColor(0, 0, 0, 1)
					love.graphics.print(v.name .. " Has no :draw()")
				else
					love.graphics.setColor(1, 1, 1, 1)
					v:draw()
				end
			love.graphics.pop()
		end
	camera:unset()

	if CenterDrawObject ~= nil and CenterDrawObject.drawGUI ~= nil and CenterDrawObject.getSizeGUI ~= nil then
		love.graphics.push()
			local cdo_w, cdo_h = CenterDrawObject:getSizeGUI()
			love.graphics.translate((ww/2)-(cdo_w/2), (wh/2)-(cdo_h/2))
			CenterDrawObject:drawGUI()
		love.graphics.pop()
	end

	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.print(love.timer.getFPS(), 1, 1)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print(love.timer.getFPS())
end

function love.update(dt)
	-- TODO: fix able to use RMB while hovered over a CenterDrawObject (or other potential GUI)
	camera:dragPosition(2)

	for _, v in pairs(LoadedMap.objects) do
		if v.update then
			v:update(dt)
		end
	end
end

function love.mousereleased(x, y, button)
	local ww, wh = love.graphics.getWidth(), love.graphics.getHeight()
	local worldX, worldY = camera:cameraPosition(x, y)
	local has_cdo = false
	local cdo_x, cdo_y, cdo_w, cdo_h = GetCenterDrawObjectPositionData()
	local cdo_mx, cdo_my
	if cdo_x ~= nil then
		has_cdo = true
		cdo_mx, cdo_my = x-cdo_x, y-cdo_y
	end
	if button == 3 then
		local obj = LoadedMap:getObjectAt(worldX, worldY)
		if connectionTarget ~= nil and obj ~= nil then
			if LoadedMap:isConnected(obj, connectionTarget) then
				LoadedMap:disconnect(obj, connectionTarget)
			else
				LoadedMap:connect(obj, connectionTarget)
			end
			connectionTarget = nil
		else
			connectionTarget = obj
		end
	elseif has_cdo and IsInside(cdo_x, cdo_y, cdo_x+cdo_w, cdo_y+cdo_h, x, y) then
		CenterDrawObject:clickedGUI(cdo_mx, cdo_my, button)
	elseif button == 1 then
		local obj = LoadedMap:getObjectAt(worldX, worldY)
		if obj then
			if obj.clicked then
				obj:clicked(obj.x-worldX, obj.y-worldY, button)
				return
			end
		end
	end
end

function love.keypressed(key)
	if CenterDrawObject ~= nil and key == "escape" then
		SetCenterDrawObject()
	elseif CenterDrawObject == nil and key == "space" then
		for i, v in pairs(testChip.vm.variables) do
			print(i, helpers.strValueFromType(v))
		end
	elseif CenterDrawObject ~= nil and CenterDrawObject.keypressedGUI then
		CenterDrawObject:keypressedGUI(key)
	end
end

function love.textinput(text)
	if CenterDrawObject ~= nil and CenterDrawObject.textinputGUI then
		CenterDrawObject:textinputGUI(text)
	end
end

function love.resize()
	genBackgroundImage()
end
--]=]
