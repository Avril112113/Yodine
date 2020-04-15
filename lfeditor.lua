local loveframes = require "loveframes"


---@class Diagnostic
local Diagnostic = {
	---@type string
	msg=nil,
	---@type number
	line=nil,
	---@type number
	start=nil,
	---@type number
	finish=nil,
	---@type string|nil
	type=nil
}


---@class lfeditor
local editor = loveframes.NewObject("editor", "lfeditor_editor", true)
editor.errorColors = {
	info={0, 0.58, 1},
	warn={1, 1, 0},
	error={1, 0, 0}
}


function editor:initialize()
	self.type = "editor"
	self.internal = false
	self.children = {}
	self.internals = {}

	self.width = 360
	self.height = 240
	self.font = love.graphics.getFont()
	self.maxLineLength = 70
	--- This editor will be limited to the amount of lines in self.lines, the editor user can not add/remove lines
	self.lines = {}
	self.readOnly = false
	--- The colors for each line (loops back to start)
	self.lineColors = {{1, 1, 1, 0}}
	self.textColor = {1, 1, 1, 1}
	---@type Diagnostic[]
	self.diagnostics = {}

	self.cursory = 1
	self.cursorx = 1

	self:SetDrawFunc()

	self:update(0)
end

function editor:update(dt)
	local parent = self.parent
	local base = loveframes.base
	local font = self.font

	-- move to parent if there is a parent
	if parent ~= nil and parent ~= base then
		local parentx = parent.x
		local parenty = parent.y
		local staticx = self.staticx
		local staticy = self.staticy
		self.x = parentx + staticx
		self.y = parenty + staticy
	end

	self.lineHeight = font:getHeight()
	self.lineWidth = self.maxLineLength * font:getWidth("A")

	self.lineNumbersWidth = font:getWidth("AA") + 4

	self.width = self.lineWidth + self.lineNumbersWidth
	self.height = self.lineHeight * #self.lines
end

function editor:draw()
	love.graphics.push()
	love.graphics.translate(self.x, self.y)
	local lineCount = #self.lines
	local lineColors = self.lineColors

	local prevFont = love.graphics.getFont()
	love.graphics.setFont(self.font)
	love.graphics.setColor(0.35, 0.35, 0.35, 1)
	love.graphics.rectangle("fill", 0, 0, self.lineNumbersWidth, lineCount*self.lineHeight)
	love.graphics.setColor(0.9, 0.9, 0.9, 1)
	for i=1,lineCount do
		love.graphics.printf(tostring(i), 0, (i-1)*self.lineHeight, self.lineNumbersWidth, "center")
	end

	for i=1,lineCount do
		local color = lineColors[(i-1) % #lineColors + 1]
		love.graphics.setColor(unpack(color))
		love.graphics.rectangle("fill", self.lineNumbersWidth, (i-1)*self.lineHeight, self.lineWidth, self.lineHeight)
	end
	-- Font already set above
	-- local prevFont = love.graphics.getFont()
	-- love.graphics.setFont(self.font)
	love.graphics.setColor(unpack(self.textColor))
	for _, diagnostic in pairs(self.diagnostics) do
		local alpha = 0.25
		local errorType = diagnostic.type or "error"
		local errorColor = {unpack(self.errorColors[errorType] or self.errorColors["error"] or {1, 0, 1})}
		table.insert(errorColor, alpha)
		love.graphics.setColor(unpack(errorColor))
		local textBefore = self.lines[diagnostic.line]:sub(0, diagnostic.start-1)
		local text = self.lines[diagnostic.line]:sub(diagnostic.start, diagnostic.finish-1)
		local diagX = self.font:getWidth(textBefore)
		local diagWidth = self.font:getWidth(text)
		if diagWidth <= 0 then
			diagWidth = self.font:getWidth("A")
		end
		love.graphics.rectangle("fill", self.lineNumbersWidth + diagX, (diagnostic.line-1)*self.lineHeight, diagWidth, self.font:getHeight())
	end
	love.graphics.setColor(1, 1, 1, 1)
	for i=1,lineCount do
		love.graphics.print(self.lines[i], self.lineNumbersWidth, (i-1)*self.lineHeight)
	end
	if not self.readOnly then
		love.graphics.rectangle("fill", self.lineNumbersWidth + self.font:getWidth(self.lines[self.cursory]:sub(0, self.cursorx-1)), (self.cursory-1)*self.lineHeight + 2, 2, self.lineHeight - 4)
	end
	local hoveredDiagnostics = {}
	local diagnosticsX, diagnosticsY
	for _, diagnostic in pairs(self.diagnostics) do
		local textBefore = self.lines[diagnostic.line]:sub(0, diagnostic.start-1)
		local text = self.lines[diagnostic.line]:sub(diagnostic.start, diagnostic.finish-1)
		local diagX = self.font:getWidth(textBefore)
		local diagWidth = self.font:getWidth(text)
		if diagWidth <= 0 then
			diagWidth = self.font:getWidth("A")
		end
		local x, y = self.lineNumbersWidth + diagX, (diagnostic.line-1)*self.lineHeight
		local w, h = diagWidth, self.font:getHeight()
		if IsInside(self.x + x, self.y + y, self.x + x + w, self.y + y + h, love.mouse.getX(), love.mouse.getY()) then
			if diagnosticsX == nil then
				diagnosticsX, diagnosticsY = x, y + h + 2
			end
			table.insert(hoveredDiagnostics, diagnostic)
		end
	end

	for _, diagnostic in pairs(hoveredDiagnostics) do
		local msg = diagnostic.msg
		love.graphics.setColor(0.4, 0.4, 0.5, 0.85)
		local width = self.font:getWidth(msg)+4
		local xOff = 0
		if diagnosticsX + width > self.width then
			xOff = (diagnosticsX + width) - self.width
		end
		love.graphics.rectangle("fill", diagnosticsX-xOff, diagnosticsY, width, self.font:getHeight()+4)
		love.graphics.setColor(1, 1, 1, 1)

		love.graphics.print(msg, diagnosticsX+2-xOff, diagnosticsY+2)
		diagnosticsY = diagnosticsY + self.font:getHeight()
	end

	love.graphics.setFont(prevFont)
	love.graphics.pop()
end

function editor:validateCursorY()
	self.cursory = ((self.cursory-1) % #self.lines)+1
end
function editor:validateCursor(dontWrapCursor)
	self:validateCursorY()
	local lineLength = #self.lines[self.cursory] + 1
	if self.cursorx > lineLength then
		if dontWrapCursor ~= true then
			self.cursory = self.cursory + 1
			self:validateCursorY()
			self.cursorx = 1
		else
			self.cursorx = #self.lines[self.cursory] + 1
		end
	elseif self.cursorx < 1 then
		if dontWrapCursor ~= true then
			self.cursory = self.cursory - 1
			self:validateCursorY()
			self.cursorx = #self.lines[self.cursory] + 1
		else
			self.cursorx = 1
		end
	end
end

function editor:mousepressed(x, y, button)
	x, y = x - self.x, y - self.y
	if x < 0 or y < 0 or x > self.width or y > self.height or not self.visible or  loveframes.state ~= self.state or self.readOnly then
		return
	end

	local charSize = self.font:getWidth("A")
	local line = math.floor(y / self.lineHeight) + 1
	local columnPixels = x-self.lineNumbersWidth+(charSize/2)
	if columnPixels < 0 then
		return
	end
	local column = math.floor(columnPixels / charSize) + 1
	self.cursory, self.cursorx = line, column
	self:validateCursor(true)
end

function editor:keypressed(key, isrepeat)
	if not self.visible or loveframes.state ~= self.state or self.readOnly then
		return
	end

	if key == "left" then
		self.cursorx = self.cursorx - 1
		self:validateCursor()
	elseif key == "right" then
		self.cursorx = self.cursorx + 1
		self:validateCursor()
	elseif key == "up" then
		local oldCursorY = self.cursory
		self.cursory = self.cursory - 1
		self:validateCursor(true)
		if love.keyboard.isDown("lalt") then
			-- TODO Maybe: might want to move diagnostics along with the line
			local curLine = self.lines[oldCursorY]
			self.lines[oldCursorY] = self.lines[self.cursory]
			self.lines[self.cursory] = curLine
			self:linesChanged({line=oldCursorY, text=curLine}, {line=self.cursory, text=self.lines[self.cursory]})
		end
	elseif key == "down" then
		local oldCursorY = self.cursory
		self.cursory = self.cursory + 1
		self:validateCursor(true)
		if love.keyboard.isDown("lalt") then
			-- TODO Maybe: might want to move diagnostics along with the line
			local curLine = self.lines[oldCursorY]
			self.lines[oldCursorY] = self.lines[self.cursory]
			self.lines[self.cursory] = curLine
			self:linesChanged({line=oldCursorY, text=curLine}, {line=self.cursory, text=self.lines[self.cursory]})
		end
	elseif key == "backspace" then
		local line = self.lines[self.cursory]
		if #line > 0 then
			local newLine = line:sub(0, self.cursorx-2) .. line:sub(self.cursorx)
			self.lines[self.cursory] = newLine
			self.cursorx = self.cursorx - 1
			self:validateCursor(true)
			self:linesChanged({line=self.cursory, text=newLine})
		end
	elseif key == "delete" then
		local line = self.lines[self.cursory]
		if #line > 0 then
			local newLine = line:sub(0, self.cursorx-1) .. line:sub(self.cursorx+1)
			self.lines[self.cursory] = newLine
			self:validateCursor(true)
			self:linesChanged({line=self.cursory, text=newLine})
		end
	end
end

function editor:textinput(char)
	if not self.visible or loveframes.state ~= self.state or self.readOnly then
		return
	end

	-- TODO: find out why this and other events like keypressed gets called 2 times

	local line = self.lines[self.cursory]
	if #line + #char > self.maxLineLength then
		-- Do nothing
	else
		local newLine = line:sub(0, self.cursorx-1) .. char .. line:sub(self.cursorx)
		self.lines[self.cursory] = newLine
		self.cursorx = self.cursorx + 1
		self:validateCursor(true)
		self:linesChanged({line=self.cursory, text=newLine})
	end
end

-- Events

---@class lfeditor_LineChange
local LineChange = {
	---@type number
	line=nil,
	---@type string
	text=nil
}
---@vararg lfeditor_LineChange[]
function editor:linesChanged(...)
end
