--[[
Based on http://nova-fusion.com/2011/04/19/cameras-in-love2d-part-1-the-basics/
with a bunch of extra features previously used

Version: 1.0.1
--]]

local camera = {}
camera.x = 0
camera.y = 0
camera.scaleX = 1
camera.scaleY = 1
camera.startPosX = nil
camera.startPosY = nil
camera.dragMouseDown = nil
camera.rotation = 0  -- not well supported
camera.boundaryMinX = 0
camera.boundaryMinY = 0
camera.boundaryMaxX = 0
camera.boundaryMaxY = 0
camera.scaleLimitHigh = 1
camera.scaleLimitLow = 5
camera.canScaleDown = true
camera.canScaleUp = true
camera.zoomSpeed = 1.1

function camera:set()
	love.graphics.push()
	love.graphics.rotate(-self.rotation)
	love.graphics.scale(1 / self.scaleX, 1 / self.scaleY)
	love.graphics.translate(-self.x, -self.y)
end
function camera:unset()
	love.graphics.pop()
end
--- move the camera relitive to its current position
---@param dx number
---@param dy number
function camera:move(dx, dy)
	self.x = self.x + (dx or 0)
	self.y = self.y + (dy or 0)
end
---@param dr number
function camera:rotate(dr)
	self.rotation = self.rotation + dr
end
---@param sx number
---@param sy number
function camera:scale(sx, sy)
	sx = sx or 1
	self.scaleX = self.scaleX * sx
	self.scaleY = self.scaleY * (sy or sx)
end
---@param x number
---@param y number
function camera:setPosition(x, y)
	self.x = x or self.x
	self.y = y or self.y
	self:checkBoundary()
end
---@param sx number
---@param sy number
function camera:setScale(sx, sy)
	self.scaleX = sx or self.scaleX
	self.scaleY = sy or self.scaleY
end
function camera:mousePosition()
	return love.mouse.getX() * self.scaleX + self.x, love.mouse.getY() * self.scaleY + self.y
end

function camera:cameraPositionCenterScreen()
		return self.x + love.graphics.getWidth()/2 * self.scaleX, self.y + love.graphics.getHeight()/2 * self.scaleY
end

---@param x number
---@param y number
function camera:cameraSpace(x, y)
	return x * self.scaleX, y * self.scaleY
end

---@param x number
---@param y number
function camera:cameraPosition(x, y)
	x = x or 0
	y = y or 0
	return self.x + x * self.scaleX, self.y + y * self.scaleY
end

---@param x number
function camera:cameraPositionX(x)
	return self.x + x * self.scaleX
end

---@param y number
function camera:cameraPositionY(y)
	return self.y + y * self.scaleY
end

function camera:dragPosition(button)  --love.update(dt)
	button = button or 1
	if love.mouse.isDown(button) then
		local mx, my = self:mousePosition()
		if self.dragMouseDown == false then
			self.startPosX = mx
			self.startPosY = my
			self.dragMouseDown = true
		else
			self.x = self.startPosX - love.mouse.getX() * self.scaleX
			self.y = self.startPosY - love.mouse.getY() * self.scaleY
		end
	else
		self.dragMouseDown = false
	end
end

---@param y number @ mouse scroll
---@param px number @ position offset (zoom in/out as this being focus point)
---@param py number @ position offset (zoom in/out as this being focus point)
function camera:mouseWheelZoom(y, px, py)	--love.wheelmoved(x, y)
	if y > 0 and self.canScaleDown == true then
		self.scaleX = self.scaleX * self.zoomSpeed
		self.scaleY = self.scaleY * self.zoomSpeed
		self.x = self.x - (self.scaleX * (px/11))
		self.y = self.y - (self.scaleY * (py/11))
	elseif y < 0 and self.canScaleUp == true then
		self.scaleX = self.scaleX / self.zoomSpeed
		self.scaleY = self.scaleY / self.zoomSpeed
		self.x = self.x + (self.scaleX * (px/10))
		self.y = self.y + (self.scaleY * (py/10))
	end
end

---@param minX number
---@param minY number
---@param maxX number
---@param maxY number
function camera:setBoundary(minX, minY, maxX, maxY)
	self.boundaryMinX = minX or 0
	self.boundaryMinY = minY or 0
	self.boundaryMaxX = maxX or 0
	self.boundaryMaxY = maxY or 0
end

function camera:checkBoundary()	--love.update(dt)
	if self.boundaryMinX == 0 and self.boundaryMinY == 0 and self.boundaryMaxX == 0 and self.boundaryMaxY == 0 then
		--Do Nothing
	else
		local cx, cy = camera:cameraPosition(0, 0)
		local cxm, cym = camera:cameraPosition(love.graphics.getWidth(), love.graphics.getHeight())
		if cx > self.boundaryMinX and cxm < self.boundaryMaxX and cy > self.boundaryMinY and cym < self.boundaryMaxY then
			--Do Nothing
		else
			if self.boundaryMinX > cx then
				self.x = camera.boundaryMinX
			end
			if self.boundaryMaxX < cxm then
				self.x = camera.boundaryMaxX-(love.graphics.getWidth()*camera.scaleX)
			end
			if self.boundaryMinY > cy then
				self.y = camera.boundaryMinY
			end
			if self.boundaryMaxY < cym then
				self.y = camera.boundaryMaxY-(love.graphics.getHeight()*camera.scaleY)
			end
			self.startPosX, self.startPosY = self:mousePosition()
		end
	end
end

function camera:checkSacleLimit() --love.update(dt)
	if self.scaleX <= self.scaleLimitHigh then
		self.scaleX = self.scaleLimitHigh
		self.scaleY = self.scaleLimitHigh
		self.canScaleUp = false
	elseif self.scaleX > self.scaleLimitHigh then
		self.canScaleUp = true
	end
	if self.scaleX >= self.scaleLimitLow then
		self.scaleX = self.scaleLimitLow
		self.scaleY = self.scaleLimitLow
		self.canScaleDown = false
	elseif self.scaleX < self.scaleLimitLow then
		self.canScaleDown = true
	end
end

--- Must Be Able To Use `obj:getX()`, `obj:getY()`
---@param obj any
---@param paddingX number
---@param paddingY number
---@param x nil|number
---@param y nil|number
function camera:followObject(obj, paddingX, paddingY, x, y)	--love.update(dt)
	x = x or love.graphics.getWidth() / 2
	y = y or love.graphics.getHeight() / 2
	love.physics.newWorld()
	paddingX = paddingX or 0
	paddingY = paddingY or 0
	self.x = obj:getX() - x + paddingX
	self.y = obj:getY() - y + paddingY
end

return camera
