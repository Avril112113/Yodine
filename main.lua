-- NOTE: menuManager.lua is old, and needs to be rewriten
local menuManager = require "menuManager"
local camera = require "camera"
local yolol = require "yolol"
local helpers = require "yolol.tests.helpers"

local devices = require "devices.init"
local DataNetwork = require "DataNetwork"

local loadedDataNetwork = DataNetwork.new()

local backgroundCellSize = 20
local background = nil

local function genBackgroundImage()
	local imgData = love.image.newImageData(love.graphics.getWidth()+backgroundCellSize, love.graphics.getHeight()+backgroundCellSize)
	local mapCells = function(x, y, r, g, b, a)
		if x%backgroundCellSize == 0 or y%backgroundCellSize == 0 then
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
	local ww, wh = love.graphics.getHeight(), love.graphics.getWidth()

	love.graphics.setColor(1, 1, 1, 1)

	if background == nil then
		genBackgroundImage()
	end
	love.graphics.draw(background, -camera.x%backgroundCellSize-backgroundCellSize, -camera.y%backgroundCellSize-backgroundCellSize)

	camera:set()
		love.graphics.setColor(0, 0, 0, 0.7)
		love.graphics.print("0,0", -love.graphics.getFont():getWidth("0,0")/2, -love.graphics.getFont():getHeight()+2)
		love.graphics.setColor(1, 0, 0, 1)
		love.graphics.circle("line", 0, 0, 50)
	camera:unset()
end

function love.update(dt)
	camera:dragPosition()
end

function love.resize()
	genBackgroundImage()
end
