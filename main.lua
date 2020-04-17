if love.filesystem.isFused() then
	love.filesystem.mount(love.filesystem.getSourceBaseDirectory(), "", true)
end
love.filesystem.setRequirePath("libs/?.lua;libs/?/init.lua;" .. love.filesystem.getRequirePath())
love.filesystem.setCRequirePath("libs/??;libs/l??;" .. love.filesystem.getCRequirePath())
package.path = ""
package.cpath = ""

math.randomseed(os.time())

require "utils"  -- provides a set of global functions

-- require "test"


-- Constant's and defining locals
BackgroundCellSize = 20
DoubleClickTime = 0.2
DefaultFont = GetFont()

local background

local loveframes = require "loveframes"
local camera = require "camera"

-- local yolol = require "yolol"
local menus = require "menus"
local devices = require "devices"
local SaveSystem = require "SaveSystem"
local Network = require "Network"

SaveSystem.loadTempSave()

-- Variables
SelectedDevices = {}
local dragSelectionPosition
local isMovingSelection = false
local hasMovedSelection = false

function AddSelectedDevice(device)
	if device == nil then return end
	SelectedDevices[device] = device
	menus.DeviceInfo.setDevice(device)
end
function RemoveSelectedDevice(device)
	SelectedDevices[device] = nil
	if menus.DeviceInfo.device == device then
		menus.DeviceInfo.setDevice(nil)
	end
end
function ClearSelectedDevices()
	SelectedDevices = {}
	menus.DeviceInfo.setDevice(nil)
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
		for _, network in pairs(SaveSystem.loadedSave.map.networks) do
			local polygon = {}
			for _, v in ipairs(network.hull) do
				table.insert(polygon, v[1])
				table.insert(polygon, v[2])
			end
			local r, g, b = unpack(network.color)
			love.graphics.setColor(r, g, b, 0.5)
			love.graphics.polygon("fill", polygon)
			love.graphics.setColor(1-r, 1-g, 1-b, 0.75)
			love.graphics.polygon("line", polygon)
		end

		love.graphics.setColor(0, 0, 0, 0.5)
		local posText = math.floor(camera.x+love.graphics.getWidth()/2)..","..math.floor(camera.y+love.graphics.getHeight()/2)
		love.graphics.setNewFont(12)
		love.graphics.print(posText, camera.x+(love.graphics.getWidth()/2)-GetFont():getWidth(posText), camera.y+(love.graphics.getHeight()/2))

		for _, network in pairs(SaveSystem.loadedSave.map.networks) do
			for _, v in pairs(network.objects) do
				if getmetatable(v.Device) == devices.DeviceMeta then
					love.graphics.push()
						love.graphics.translate(v.x, v.y)
						love.graphics.setColor(1, 1, 1, 1)
						v:draw()
					love.graphics.pop()
				end
			end
		end

		love.graphics.setLineWidth(3)
		love.graphics.setLineStyle("smooth")

		love.graphics.setColor(1, 0.5, 0, 0.8)
		for _, device in pairs(SelectedDevices) do
			if getmetatable(device.Device) == devices.DeviceMeta then
				love.graphics.rectangle("line", device.x, device.y, device:getSize())
			end
		end

		love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
		if dragSelectionPosition ~= nil then
			local x, y = dragSelectionPosition[1], dragSelectionPosition[2]
			local mwx, mwy = camera:mousePosition()
			love.graphics.rectangle("line", x, y, mwx-x, mwy-y)
		end
	camera:unset()

	loveframes.draw()

	local draggingDevice = menus.DevicesList.draggingDevice
	if draggingDevice ~= nil then
		love.graphics.push()
		local w, h = draggingDevice:getSize()
		local mx, my = love.mouse.getPosition()
		love.graphics.translate(mx-(w/2), my-(h/2))
		draggingDevice:draw()
		love.graphics.pop()
	end
end

local lastSave = os.clock()
function love.update(dt)
	if SaveSystem.loadedSave.save.name == "%TMP%" and os.clock() - lastSave > 10 then
		lastSave = os.clock()
		SaveSystem.save(SaveSystem.loadedSave.save.name, false)
	end

	loveframes.update(dt)
	if loveframes.collisioncount <= 0 then
		camera:dragPosition(2)
	end

	SaveSystem.loadedSave.map:update(dt)

	local draggingDevice = menus.DevicesList.draggingDevice
	if draggingDevice ~= nil then
		if not love.mouse.isDown(1) then
			local mx, my = love.mouse.getPosition()
			local hoveredMenu
			-- TODO: might want to move this to a function
			for _, menu in pairs(menus) do
				if menu.base.visible ~= false then
					local x, y = menu.base.x, menu.base.y
					local xw, yh = x + menu.base.width, y + menu.base.height
					if IsInside(x, y, xw, yh, mx, my) then
						if hoveredMenu == nil then
							hoveredMenu = menu
						else
							local otherOrder = hoveredMenu.base.draworder
							local newOrder = menu.base.draworder
							if (otherOrder == nil and newOrder ~= nil) or (otherOrder ~= nil and newOrder ~= nil and otherOrder < newOrder) then
								hoveredMenu = menu
							end
						end
					end
				end
			end

			if hoveredMenu ~= nil then
				if hoveredMenu.deviceDropped then
					hoveredMenu:deviceDropped(draggingDevice)
				end
			elseif loveframes.collisioncount <= 0 and getmetatable(draggingDevice) == devices.DeviceMeta then
				local cmx, cmy = camera:mousePosition()
				local w, h = draggingDevice:getSize()
				local dx, dy = cmx-(w/2), cmy-(h/2)
				local network = SaveSystem.loadedSave.map:getNetworkAt(dx, dy)
				for _, point in pairs(draggingDevice:getBounds(dx, dy)) do
					for _, _network in pairs(SaveSystem.loadedSave.map:getNetworksAt(point[1], point[2])) do
						network = _network
						break
					end
				end
				if network == nil then
					network = Network.new(SaveSystem.loadedSave.map)
					SaveSystem.loadedSave.map:addNetwork(network)
				end
				local obj = draggingDevice:create(dx, dy)
				obj:changeNetwork(network)
			end
			menus.DevicesList.draggingDevice = nil
		end
	end
end

local lastclick = 0
function love.mousepressed(x, y, button)
	loveframes.mousepressed(x, y, button)
	if loveframes.collisioncount > 0 then return end

	local worldX, worldY = camera:cameraPosition(x, y)
	local obj = SaveSystem.loadedSave.map:getObjectAt(worldX, worldY)
	if os.clock() < lastclick + DoubleClickTime and obj and obj.openGUI then
		lastclick = os.clock() + DoubleClickTime
		obj:openGUI()
	else
		lastclick = os.clock()
		if button == 1 then
			if obj == nil then
				if not love.keyboard.isDown("lctrl") then
					ClearSelectedDevices()
				end
				dragSelectionPosition = {worldX, worldY}
			elseif obj ~= nil then
				AddSelectedDevice(obj)

				obj:clicked(obj.x-worldX, obj.y-worldY, button)
				hasMovedSelection = false
				isMovingSelection = true
			end
		end
	end
end
function love.mousereleased(x, y, button)
	loveframes.mousereleased(x, y, button)

	if button == 1 then
		if isMovingSelection then
			isMovingSelection = false

			if not hasMovedSelection and not love.keyboard.isDown("lctrl") then
				local worldX, worldY = camera:cameraPosition(x, y)
				local obj = SaveSystem.loadedSave.map:getObjectAt(worldX, worldY)
				ClearSelectedDevices()
				AddSelectedDevice(obj)
			end
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
			for _, network in pairs(SaveSystem.loadedSave.map.networks) do
				for _, obj in pairs(network.objects) do
					if getmetatable(obj.Device) == devices.DeviceMeta then
						local objW, objH = obj:getSize()
						if obj.x > x1-objW and obj.y > y1-objH and obj.x+objW < x2+objW and obj.y+objH < y2+objH then
							AddSelectedDevice(obj)
						end
					end
				end
			end
		end
	end
end

function love.mousemoved(x, y, dx, dy)
	if isMovingSelection then
		hasMovedSelection = true
		local hullGenedNetworks = {}
		for _, v in pairs(SelectedDevices) do
			if getmetatable(v) == devices.DeviceMeta then
				v.x = v.x + dx
				v.y = v.y + dy
				---@type table<Network, Network>
				local networks = {}
				for _, point in pairs(v:getBounds()) do
					for _, network in pairs(SaveSystem.loadedSave.map:getNetworksAt(point[1], point[2])) do
						networks[network] = network
					end
				end
				networks[v.network] = nil
				for _, network in pairs(networks) do
					v:changeNetwork(network)
					break
				end
				if hullGenedNetworks[v.network] == nil then
					v.network:generateHull()
					hullGenedNetworks[v.network] = v.network
				end
			end
		end
	end
end

function love.wheelmoved(x, y)
	loveframes.wheelmoved(x, y)
end

function love.keypressed(key, isrepeat)
	loveframes.keypressed(key, isrepeat)

	if loveframes.collisioncount <= 0 and key == "delete" then
		local isEmpty = true; for _, _ in pairs(SelectedDevices) do isEmpty = false break end
		if isEmpty then
			local obj = SaveSystem.loadedSave.map:getObjectAt(camera:mousePosition())
			if obj ~= nil then
				obj:destroy()
			end
		else
			for _, obj in pairs(SelectedDevices) do
				RemoveSelectedDevice(obj)
				obj:destroy()
			end
			ClearSelectedDevices()
		end
	elseif loveframes.collisioncount <= 0 and key == "c" then
		local isEmpty = true; for _, _ in pairs(SelectedDevices) do isEmpty = false break end
		if isEmpty then
			local obj = SaveSystem.loadedSave.map:getObjectAt(camera:mousePosition())
			if obj ~= nil then
				AddSelectedDevice(obj)
			end
		end
		local network = Network.new(SaveSystem.loadedSave.map)
		SaveSystem.loadedSave.map:addNetwork(network)
		for _, obj in pairs(SelectedDevices) do
			obj:changeNetwork(network)
		end
	elseif key == "f12" then
		loveframes.config.DEBUG = not loveframes.config.DEBUG
	end
end
function love.keyreleased(key)
	loveframes.keyreleased(key)
end

function love.textinput(text)
	loveframes.textinput(text)
end

function love.resize()
	genBackgroundImage()

	for _, menu in pairs(menus) do
		if menu.update then
			menu:update()
		end
	end
end

function love.quit()
	SaveSystem.save(SaveSystem.loadedSave.save.name, SaveSystem.loadedSave.save.name ~= "%TMP%")
end
