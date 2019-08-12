--[[
Camera Stuff With Custom Functions To Make Life Easyer.
This Was Made A Different File For The Sake Of Easyer Use Of This Stuff :D
--]]

local camera = {}
camera.x = 0
camera.y = 0
camera.scaleX = 1
camera.scaleY = 1
camera.rotation = 0
camera.boundryMinX = 0
camera.boundryMinY = 0
camera.boundryMaxX = 0
camera.boundryMaxY = 0
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
function camera:move(dx, dy)
  self.x = self.x + (dx or 0)
  self.y = self.y + (dy or 0)
end
function camera:rotate(dr)
  self.rotation = self.rotation + dr
end
function camera:scale(sx, sy)
  sx = sx or 1
  self.scaleX = self.scaleX * sx
  self.scaleY = self.scaleY * (sy or sx)
end
function camera:setPosition(x, y)
  self.x = x or self.x
  self.y = y or self.y
end
function camera:setScale(sx, sy)
  self.scaleX = sx or self.scaleX
  self.scaleY = sy or self.scaleY
end
function camera:mousePosition()
  return love.mouse.getX() * self.scaleX + self.x, love.mouse.getY() * self.scaleY + self.y
end

--Custom--
function camera:mousePositionC()-- DEPERCATED use cameraPositionCenterScreen or cameraPosition
    return (love.mouse.getX() / scaleX) * self.scaleX + self.x, (love.mouse.getY() / scaleY) * self.scaleY + self.y
end

function camera:dragPosition() --love.update(dt)
	if love.mouse.isDown(2) then
		local mx,my = self:mousePosition()
		if mouse2Down == false then
			startPosX = mx
			startPosY = my
			mouse2Down = true
		else
			tcprx = startPosX - love.mouse.getX() * self.scaleX
			tcpry = startPosY - love.mouse.getY() * self.scaleY
			self.x = tcprx
			self.y = tcpry
		end
	else
		mouse2Down = false
	end
end

function camera:mouseWheelZoom(y,px,py) --love.wheelmoved( x, y )
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

function camera:setBoundry(minx,miny,maxx,maxy)
	self.boundryMinX = minx or 0
	self.boundryMinY = miny or 0
	self.boundryMaxX = maxx or 0
	self.boundryMaxY = maxy or 0
end

function camera:cameraPositionCenterScreen()
    return self.x + love.graphics.getWidth()/2 * self.scaleX, self.y + love.graphics.getHeight()/2 * self.scaleY
end

function camera:cameraSpace(x, y)
    return x * self.scaleX, y * self.scaleY
end

function camera:cameraPosition(x,y)
    return self.x + x * self.scaleX, self.y + y * self.scaleY
end

function camera:cameraPositionX(x)
    return self.x + x * self.scaleX
end

function camera:cameraPositionY(y)
    return self.y + y * self.scaleY
end

function camera:checkBoundry() --love.update(dt) --Better than the old one by ALOT (also updated dragPosition because of this)!
	if self.boundryMinX == 0 and self.boundryMinY == 0 and self.boundryMaxX == 0 and self.boundryMaxY == 0 then
		--Do Nothing
	else
		cx, cy = camera:cameraPosition(0, 0)
		cxm, cym = camera:cameraPosition(love.graphics.getWidth(), love.graphics.getHeight())
		if cx > self.boundryMinX and cxm < self.boundryMaxX and cy > self.boundryMinY and cym < self.boundryMaxY then
			--Do Nothing
		else
			if self.boundryMinX > cx then
				self.x = camera.boundryMinX
			end
			if self.boundryMaxX < cxm then
				self.x = camera.boundryMaxX-(love.graphics.getWidth()*camera.scaleX)
			end
			if self.boundryMinY > cy then
				self.y = camera.boundryMinY
			end
			if self.boundryMaxY < cym then
				self.y = camera.boundryMaxY-(love.graphics.getHeight()*camera.scaleY)
			end
			startPosX, startPosY = self:mousePosition()
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

function camera:followObject(objInWorld,paddingX,paddingY) --love.update(dt) OR love.draw() --Must Be Object Body Able To Use [OBJ]:getX() and [OBJ]:getY() EG "objects.player.body"
	paddingX = paddingX or 0
	paddingY = paddingY or 0
	self.x = objInWorld:getX() - (love.graphics.getWidth() / 2) + paddingX
	self.y = objInWorld:getY() - (love.graphics.getHeight() / 2) + paddingY
end

return camera
