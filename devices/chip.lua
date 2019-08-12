local deviceValidation = require "devices._deviceValidation"

---@class Device_Chip
local chip = {
	name="Chip",
	desc="TODO",
	fields={},

	-- Drawing
	lineWidth=(GetFont():getHeight()+4)*40,
	lineHeight=GetFont():getHeight()+4,

	-- Editor
	---@type string[]
	lines=nil,
	---@type number
	line=1,
	---@type number
	column=0
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

function chip:init()
	self.lines = {}
	for i=1,20 do
		table.insert(self.lines, "// Testing stuff...")
	end
end
function chip:draw(opened)
	if opened ~= true then
		love.graphics.scale(self:getScale())
	end
	love.graphics.setFont(Consola)
	for ln=1,#self.lines do
		local lnStr = tostring(ln)
		lnStr = string.rep(" ", 2-#lnStr) .. lnStr
		if ln%2 == 0 then
			love.graphics.setColor(0, 0, 0.6)
		else
			love.graphics.setColor(0, 0, 0.4)
		end
		love.graphics.rectangle("fill", 0, self.lineHeight*(ln-1), self.lineWidth, self.lineHeight)
		love.graphics.setColor(0, 0, 0.4)
		love.graphics.rectangle("fill", 0, self.lineHeight*(ln-1), 24, self.lineHeight)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.print(lnStr, 2, self.lineHeight*(ln-1)+2)
		love.graphics.print(self.lines[ln], 26, self.lineHeight*(ln-1)+2)

		if ln == self.line and AtTimeInterval(1, 0.5) then
			local charStr = self.lines[ln]:sub(self.column, self.column)
			if #charStr <= 0 then charStr = " " end
			local colStr = self.lines[ln]:sub(1, self.column)
			love.graphics.rectangle("fill", 26+GetFont():getWidth(colStr), self.lineHeight*(ln-1)+2+(self.lineHeight/3), GetFont():getWidth(charStr), self.lineHeight/4)
		end
	end
	love.graphics.setFont(DefaultFont)
end
function chip:getSize()
	local scale = self:getScale()
	return self.lineWidth*scale, (self.lineHeight*#self.lines)*scale
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
	return self.lineWidth, self.lineHeight*#self.lines
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
	elseif key == "delete" then
		local lineStr = self.lines[self.line]
		local rightStr = lineStr:sub(self.column+1, #lineStr)
		if #rightStr > 0 then
			self.lines[self.line] = lineStr:sub(1, self.column) .. rightStr:sub(2, #rightStr)
			self:checkColumn(false)
		end
	end
end
function chip:textinputGUI(text)
	self.lines[self.line] = self.lines[self.line]:sub(1, self.column) .. text .. self.lines[self.line]:sub(self.column+1, #self.lines[self.line])
	self.column = self.column + #text
end

deviceValidation.validateDevice(chip)
return chip
