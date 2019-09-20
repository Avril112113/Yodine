local re = require "relabel"
local yolol = require "yolol"
local vm = require "yololVM"
local deviceValidation = require "devices._deviceValidation"

local function errorLevelToNumber(level)
	if type(level) == "number" then
		return level
	end
	if level == "warn" then
		return 2
	end
	return 1
end
local function errorLevelColor(level)
	level = errorLevelToNumber(level)
	if level == 2 then
		return 1, 0.9, 0, 1
	else
		return 0.7, 0, 0, 1
	end
end

local ChipWait = {
	name="ChipWait",
	default=0,
	desc="Controls script execution. Negative values mean execution is paused, zero means script is being executed, and positive values mean execution will continue after the amount of line runs have passed that are equal to the value.",
	---@type Device_Button
	parent=nil,
	---@type number
	value=nil
}
---@param newValue string|number
---@return string|number
function ChipWait:changed(newValue)
	if type(newValue) == "number" then
		return newValue
	end
	return self.default
end

---@class Device_Chip
local chip = {
	name="Chip",
	desc="TODO",
	fields={
		chipWait=ChipWait
	},

	-- Drawing
	lineWidth=(GetFont():getHeight()+4)*40,
	lineHeight=GetFont():getHeight()+4,
	rightPanelWidth=BackgroundCellSize*6,

	-- Editor
	---@type string[]
	lines=nil,
	---@type number
	line=1,
	---@type number
	column=0,

	-- Other
	vmStepTimePass=0,
	vmStepInterval=0.2
}

--- for love.graphics.scale and :getSize() as :getSize() is for map/world space
function chip:getScale()
	return (BackgroundCellSize*6)/self.lineWidth
end
---@param n number
function chip:effectLine(n)
	self.line = (self.line+n)%#self.lines
	if self.line == 0 then self.line = #self.lines end
	if self.line == 1+#self.lines then self.line = 1 end
	self:checkColumn(false)
end
function chip:checkColumn(moveLine)
	if moveLine == nil then moveLine = true end
	if self.column < 0 then
		if moveLine then
			self:effectLine(-1)
		end
		self.column = #self.lines[self.line]
	elseif self.column > #self.lines[self.line] then
		if moveLine then
			self:effectLine(1)
			self.column = 0
		else
			self.column = #self.lines[self.line]
		end
	end
end
---@param ln number|nil
function chip:codeChanged(ln)
	if ln == nil then
		for i=1,#self.lines do
			self:codeChanged(i)
		end
	elseif self.lines[ln] == nil then
		error("schip:codeChanged() on invalid line " .. tostring(ln))
	else
		self.vm.lines[ln] = yolol.parseLine(self.lines[ln])
	end
end

function chip:init()
	self.vm = vm.new(self)
	self.lines = {}
	for i=1,20 do
		table.insert(self.lines, "")
	end
	self:codeChanged()
end
function chip:draw(opened)
	if opened ~= true then
		love.graphics.scale(self:getScale())
	end

	love.graphics.setFont(Consola)
	local consolaCharWidth = GetFont():getWidth(" ")

	for ln=1,#self.lines do
		if ln%2 == 0 then
			love.graphics.setColor(0, 0, 0.6)
		else
			love.graphics.setColor(0, 0, 0.4)
		end
		love.graphics.rectangle("fill", 0, self.lineHeight*(ln-1), self.lineWidth, self.lineHeight)
		love.graphics.setColor(0, 0, 0.4)
		love.graphics.rectangle("fill", 0, self.lineHeight*(ln-1), 24, self.lineHeight)
	end

	-- rectangle for current line
	if self.fields.chipWait.value > 0 then
		love.graphics.setColor(1, 0.49, 0, 0.6)
	elseif self.fields.chipWait.value < 0 then
		love.graphics.setColor(0.75, 0.2, 0, 0.6)
	else
		love.graphics.setColor(0.49, 0.8, 0, 0.6)
	end
	love.graphics.rectangle("fill", 24, self.lineHeight*(self.vm.line-1), self.lineWidth, self.lineHeight)

	for ln=1,#self.lines do
		local lnStr = tostring(ln)
		lnStr = string.rep(" ", 2-#lnStr) .. lnStr

		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.print(lnStr, 2, self.lineHeight*(ln-1)+2)
		love.graphics.print(self.lines[ln], 26, self.lineHeight*(ln-1)+2)
	end

	-- cant really be seen when not opened as centre draw object (unless zoomed in?)
	if opened == true then
		local function drawErrorLine(ln, colStart, colEnd, level)
			colStart = colStart - 1
			love.graphics.setColor(errorLevelColor(level))
			love.graphics.rectangle("fill", 26+consolaCharWidth*colStart, self.lineHeight*(ln-1)+2+(self.lineHeight/1.8), consolaCharWidth*(colEnd-colStart), self.lineHeight/5)
		end
		local function drawHoverPopup(ln, col, msg)
			if col <= 0 then return end
			local x, y = 26+consolaCharWidth*col, self.lineHeight*(ln-1)+2+(self.lineHeight/1.8)
			local w, h = GetFont():getWidth(msg), GetFont():getHeight()
			love.graphics.setColor(0.3, 0.3, 0.3, 1)
			love.graphics.rectangle("fill", x+18, y+self.lineHeight, w*1.2+4, h)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.print(msg, x+20, y+self.lineHeight, 0, 1.2, 1.2)
		end

		for i, line in pairs(self.vm.lines) do
			for _, err in pairs(line.metadata.errors) do
				local pos = err.pos or #self.lines[i]
				drawErrorLine(i, pos, pos, "error")
			end
		end
		for i, errors in pairs(self.vm.errors) do
			for _, err in pairs(errors) do
				local pos = err.pos or #self.lines[i]
				drawErrorLine(i, pos, pos, err.level)
			end
		end
		if AtTimeInterval(1, 0.5) then
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.rectangle("fill", 26+consolaCharWidth*self.column, self.lineHeight*(self.line-1)+2+(self.lineHeight/3), consolaCharWidth, self.lineHeight/4)
		end
		local cdo_x, cdo_y, cdo_w, cdo_h = GetCenterDrawObjectPositionData()
		for i, line in pairs(self.vm.lines) do
			for _, err in pairs(line.metadata.errors) do
				local pos = (err.pos or #self.lines[i]) - 1
				local x, y = 26+consolaCharWidth*pos, self.lineHeight*(i-1)+2
				local w, h = consolaCharWidth*1, GetFont():getHeight()
				if IsInside(x, y, x+w, y+h, love.mouse.getX()-cdo_x, love.mouse.getY()-cdo_y) then
					drawHoverPopup(i, pos, err.msg)
				end
			end
		end
		for i, errors in pairs(self.vm.errors) do
			for _, err in pairs(errors) do
				local pos = (err.pos or #self.lines[i]) - 1
				local x, y = 26+consolaCharWidth*pos, self.lineHeight*(i-1)+2
				local w, h = consolaCharWidth*1, GetFont():getHeight()
				if IsInside(x, y, x+w, y+h, love.mouse.getX()-cdo_x, love.mouse.getY()-cdo_y) then
					drawHoverPopup(i, pos, err.msg)
				end
			end
		end
	end

	love.graphics.setFont(DefaultFont)

	-- Right border
	love.graphics.setColor(0.4, 0.4, 0.7, 1)
	love.graphics.rectangle("fill", self.lineWidth, 0, self.rightPanelWidth, self.lineHeight*#self.lines)
	-- Pause button
	local pauseButtonY = (self.lineHeight*#self.lines)-self.rightPanelWidth
	if self.fields.chipWait.value < 0 then
		love.graphics.setColor(0.59, 0, 0, 1)
		love.graphics.rectangle("fill", self.lineWidth, pauseButtonY, self.rightPanelWidth, self.rightPanelWidth)
		love.graphics.setColor(1, 1, 1, 1)
		local tw = self.rightPanelWidth
		local thw = tw/2
		local tfw = tw/6
		love.graphics.rectangle("fill", self.lineWidth+tfw, pauseButtonY+tfw, tfw, tw-(tfw*2))
		love.graphics.rectangle("fill", self.lineWidth+tw-(tfw*2), pauseButtonY+tfw, tfw, tw-(tfw*2))
	else
		love.graphics.setColor(0, 0.59, 0, 1)
		love.graphics.rectangle("fill", self.lineWidth, pauseButtonY, self.rightPanelWidth, self.rightPanelWidth)
		love.graphics.setColor(1, 1, 1, 1)
		local tw = self.rightPanelWidth
		local thw = tw/2
		local tqw = tw/4
		triangle("fill", self.lineWidth+tqw, pauseButtonY+tqw, tw-thw, tw-thw)
	end

	local errorBorderLevel = 99
	for i, line in pairs(self.vm.lines) do
		for _, err in pairs(line.metadata.errors) do
			local errNum = errorLevelToNumber(err.level)
			if errNum < errorBorderLevel then
				errorBorderLevel = errNum
			end
		end
	end
	for i, errors in pairs(self.vm.errors) do
		for _, err in pairs(errors) do
			local errNum = errorLevelToNumber(err.level)
			if errNum < errorBorderLevel then
				errorBorderLevel = errNum
			end
		end
	end
	if errorBorderLevel < 99 then
		local dw, dh = self:getSizeGUI()
		love.graphics.setColor(errorLevelColor(errorBorderLevel))
		if opened ~= true then
			love.graphics.setLineWidth(15)
		end
		love.graphics.rectangle("line", -1, -1, dw+2, dh+2)
		love.graphics.setLineWidth(3)
	end
end
function chip:getSize()
	local scale = self:getScale()
	local w, h = self:getSizeGUI()
	return w*scale, h*scale
end
function chip:getWireDrawOffset()
	local width, height = self:getSize()
	return width/2, height/2
end
function chip:clicked(x, y, button)
	SetCenterDrawObject(self)
end

function chip:drawGUI()
	return self:draw(true)
end
function chip:getSizeGUI()
	return self.lineWidth+self.rightPanelWidth, self.lineHeight*#self.lines
end
function chip:clickedGUI(x, y, button)
	for ln=1,#self.lines do
		if IsInside(26, self.lineHeight*(ln-1)+2, 26+self.lineWidth, self.lineHeight*(ln-1)+2+self.lineHeight, x, y) then
			self.line = ln
			self.column = math.floor((x-26)/Consola:getWidth(" "))
			self:checkColumn(false)
			return
		end
	end
	local pauseButtonY = (self.lineHeight*#self.lines)-self.rightPanelWidth
	local px, py, pw, ph = self.lineWidth, pauseButtonY, self.rightPanelWidth, self.rightPanelWidth
	if IsInside(px, py, px+pw, py+ph, x, y) then
		if self.fields.chipWait.value < 0 then
			self.fields.chipWait.value = 0
		else
			self.fields.chipWait.value = -1
		end
	end
end
function chip:keypressedGUI(key)
	if key == "up" then
		self:effectLine(-1)
	elseif key == "down" then
		self:effectLine(1)
	elseif key == "left" then
		self.column = self.column - 1
		self:checkColumn()
	elseif key == "right" then
		self.column = self.column + 1
		self:checkColumn()
	elseif key == "backspace" then
		local lineStr = self.lines[self.line]
		local leftStr = lineStr:sub(1, self.column)
		if #leftStr > 0 then
			self.lines[self.line] = leftStr:sub(1, #leftStr-1) .. lineStr:sub(self.column+1, #lineStr)
			self.column = self.column - 1
			self:checkColumn(false)
		end
		self:codeChanged(self.line)
	elseif key == "delete" then
		local lineStr = self.lines[self.line]
		local rightStr = lineStr:sub(self.column+1, #lineStr)
		if #rightStr > 0 then
			self.lines[self.line] = lineStr:sub(1, self.column) .. rightStr:sub(2, #rightStr)
			self:checkColumn(false)
		end
		self:codeChanged(self.line)
	end
end
function chip:textinputGUI(text)
	self.lines[self.line] = self.lines[self.line]:sub(1, self.column) .. text .. self.lines[self.line]:sub(self.column+1, #self.lines[self.line])
	self.column = self.column + #text
	self:codeChanged(self.line)
end

function chip:update(dt)
	self.vmStepTimePass = self.vmStepTimePass + dt

	if self.fields.chipWait.value > 0 then
		if self.vmStepTimePass >= self.vmStepInterval then
			self.vmStepTimePass = self.vmStepTimePass%self.vmStepInterval
			self.fields.chipWait.value = self.fields.chipWait.value - 1
		end
	elseif self.fields.chipWait.value < 0 then
		self.vmStepTimePass = self.vmStepTimePass%self.vmStepInterval
	elseif self.vmStepTimePass >= self.vmStepInterval then
		self.vmStepTimePass = self.vmStepTimePass%self.vmStepInterval
		self.vm:step()
	end
end

deviceValidation.validateDevice(chip)
return chip
