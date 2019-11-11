package.path = "libs/?.lua;libs/?/init.lua;" .. package.path
package.cpath = "libs/?.dll;" .. package.cpath

-- require "test"
-- require "test_rpc"
require "utils"  -- provides a set of global functions

-- Constant's and defining locals
BackgroundCellSize = 20
DefaultFont = GetFont()
Consola = love.graphics.newFont("fonts/Consola.ttf")

local background

local loveframes = require "loveframes"
local camera = require "camera"

-- local yolol = require "yolol"
local menus = require "menus"
-- local devices = require "devices"
local Map = require "Map"


LoadedMap = Map.new()

-- Variables
CenterDrawObject = nil  -- used if a map object has a :drawGUI(), there are other functions for input ect
SelectedDevices = setmetatable({}, {
	__newindex=function(self, index, value)
		rawset(self, index, value)
		if index == 1 then
			menus.DeviceInfo.setDevice(value)
		end
	end
})
local dragSelectionPosition
local isMovingSelection = false


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
function GetCenterDrawObjectPositionData()
	if CenterDrawObject ~= nil and CenterDrawObject.getSizeGUI ~= nil then
		local ww, wh = love.graphics.getWidth(), love.graphics.getHeight()
		local cdo_w, cdo_h = CenterDrawObject:getSizeGUI()
		local cdo_x, cdo_y = (ww/2)-(cdo_w/2), (wh/2)-(cdo_h/2)
		return cdo_x, cdo_y, cdo_w, cdo_h
	end
end

local function genBackgroundImage()
	local imgData = love.image.newImageData(love.graphics.getWidth()+BackgroundCellSize, love.graphics.getHeight()+BackgroundCellSize)
	local mapCells = function(x, y, r, g, b, a)
		if (x+1)%BackgroundCellSize <= 1 or (y+1)%BackgroundCellSize <= 1 then
			return 0, 0, 0, 1
		else
			return 0.7, 0.7, 0.7, 1
		end
	end
	imgData:mapPixel(mapCells)
	background = love.graphics.newImage(imgData)
end


function love.load()
	love.window.maximize()

	camera.x = -love.graphics.getWidth()/2
	camera.y = -love.graphics.getHeight()/2

	-- copy help file from game directory to save directory
	love.filesystem.write("/Help.txt", love.filesystem.read("/data/Help.txt"))

	love.keyboard.setKeyRepeat(true)
end

function love.draw()
	local ww, wh = love.graphics.getWidth(), love.graphics.getHeight()

	love.graphics.setColor(1, 1, 1, 1)

	if background == nil then
		genBackgroundImage()
	end
	love.graphics.draw(background, -camera.x%BackgroundCellSize-BackgroundCellSize, -camera.y%BackgroundCellSize-BackgroundCellSize)

	camera:set()
		love.graphics.setColor(0, 0, 0, 0.5)
		love.graphics.print("0,0", -GetFont():getWidth("0,0")/2, -GetFont():getHeight()+2)

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

		love.graphics.setColor(1, 0.5, 0, 0.8)
		love.graphics.setLineWidth(3)
		love.graphics.setLineStyle("smooth")
		for _, device in ipairs(SelectedDevices) do
			love.graphics.rectangle("line", device.x, device.y, device:getSize())
		end

		love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
		love.graphics.setLineWidth(3)
		love.graphics.setLineStyle("smooth")
		if dragSelectionPosition ~= nil then
			local x, y = dragSelectionPosition[1], dragSelectionPosition[2]
			local mwx, mwy = camera:mousePosition()
			love.graphics.rectangle("line", x, y, mwx-x, mwy-y)
		end
	camera:unset()

	if CenterDrawObject ~= nil and CenterDrawObject.drawGUI ~= nil and CenterDrawObject.getSizeGUI ~= nil then
		love.graphics.push()
			local cdo_w, cdo_h = CenterDrawObject:getSizeGUI()
			love.graphics.translate((ww/2)-(cdo_w/2), (wh/2)-(cdo_h/2))
			CenterDrawObject:drawGUI()
		love.graphics.pop()
	end

	loveframes.draw()

	local draggingDevice = menus.DevicesList.draggingDevice
	if draggingDevice ~= nil then
		love.graphics.push()
		love.graphics.translate(love.mouse.getPosition())
		draggingDevice:draw()
		love.graphics.pop()
	end
end

function love.update(dt)
	loveframes.update(dt)
	if loveframes.collisioncount <= 0 then
		camera:dragPosition(2)
	end

	for _, v in pairs(LoadedMap.objects) do
		if v.update then
			v:update(dt)
		end
	end

	local draggingDevice = menus.DevicesList.draggingDevice
	if draggingDevice ~= nil then
		if not love.mouse.isDown(1) then
			local x, y = camera:mousePosition()
			LoadedMap:createObject(x, y, draggingDevice)
			menus.DevicesList.draggingDevice = nil
		end
	end
end

function love.mousepressed(x, y, button)
	loveframes.mousepressed(x, y, button)
	if loveframes.collisioncount > 0 then return end

	local worldX, worldY = camera:cameraPosition(x, y)
	local has_cdo = false
	local cdo_x, cdo_y, cdo_w, cdo_h = GetCenterDrawObjectPositionData()
	local cdo_mx, cdo_my
	if cdo_x ~= nil then
		has_cdo = true
		cdo_mx, cdo_my = x-cdo_x, y-cdo_y
	end
	local obj = LoadedMap:getObjectAt(worldX, worldY)
	if button == 3 then
		if menus.DeviceInfo.device ~= nil and obj ~= nil then
			if LoadedMap:isConnected(obj, menus.DeviceInfo.device) then
				LoadedMap:disconnect(obj, menus.DeviceInfo.device)
			else
				LoadedMap:connect(obj, menus.DeviceInfo.device)
			end
		else
			menus.DeviceInfo.setDevice(obj)
		end
	elseif button == 1 then
		if has_cdo and IsInside(cdo_x, cdo_y, cdo_x+cdo_w, cdo_y+cdo_h, x, y) then
			CenterDrawObject:clickedGUI(cdo_mx, cdo_my, button)
		elseif obj == nil then
			if not love.keyboard.isDown("lctrl") then
				for i, _ in pairs(SelectedDevices) do
					SelectedDevices[i] = nil
				end
			end
			dragSelectionPosition = {worldX, worldY}
		elseif obj ~= nil then
			if love.keyboard.isDown("lctrl") then
				SelectedDevices[#SelectedDevices+1] = obj
			else
				for i, _ in pairs(SelectedDevices) do
					SelectedDevices[i] = nil
				end
				SelectedDevices[1] = obj
			end
			if obj.clicked then
				obj:clicked(obj.x-worldX, obj.y-worldY, button)
			end
			isMovingSelection = true
		end
	end
end
function love.mousereleased(x, y, button)
	loveframes.mousereleased(x, y, button)

	if button == 1 then
		if isMovingSelection then
			isMovingSelection = false
		elseif dragSelectionPosition ~= nil then
			local x1, y1 = dragSelectionPosition[1], dragSelectionPosition[2]
			local x2, y2 = camera:mousePosition()
			if x2 < x1 then
				local t = x2
				x2 = x1
				x1 = t
			end
			if y2 < y1 then
				local t = y2
				y2 = y1
				y1 = t
			end
			dragSelectionPosition = nil
			for _, obj in pairs(LoadedMap.objects) do
				local objW, objH = obj:getSize()
				if obj.x > x1-objW and obj.y > y1-objH and obj.x+objW < x2+objW and obj.y+objH < y2+objH then
					SelectedDevices[#SelectedDevices+1] = obj
				end
			end
		end
	end
end

function love.mousemoved(x, y, dx, dy)
	if isMovingSelection then
		for _, v in ipairs(SelectedDevices) do
			v.x = v.x + dx
			v.y = v.y + dy
		end
	end
end

function love.wheelmoved(x, y)
	loveframes.wheelmoved(x, y)
end

function love.keypressed(key, isrepeat)
	loveframes.keypressed(key, isrepeat)

	if CenterDrawObject ~= nil and key == "escape" then
		SetCenterDrawObject()
	elseif CenterDrawObject ~= nil and CenterDrawObject.keypressedGUI then
		CenterDrawObject:keypressedGUI(key)
	elseif loveframes.collisioncount <= 0 and (key == "delete" or key == "x") then
		if #SelectedDevices <= 0 then
			local obj = LoadedMap:getObjectAt(camera:mousePosition())
			SelectedDevices[1] = obj
		end
		for _, v in ipairs(SelectedDevices) do
			if menus.DeviceInfo.device == v then
				menus.DeviceInfo.setDevice(nil)
			end
			LoadedMap:removeObject(v)
		end
		for i, _ in pairs(SelectedDevices) do
			SelectedDevices[i] = nil
		end
	elseif key == "f12" then
		loveframes.config.DEBUG = not loveframes.config.DEBUG
	end
end
function love.keyreleased(key)
	loveframes.keyreleased(key)
end

function love.textinput(text)
	if CenterDrawObject ~= nil and CenterDrawObject.textinputGUI then
		CenterDrawObject:textinputGUI(text)
	else
		loveframes.textinput(text)
	end
end

function love.resize()
	genBackgroundImage()

	for _, menu in pairs(menus) do
		menu.update()
	end
end
