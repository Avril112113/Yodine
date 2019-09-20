-- Helpful functions, shorthands ect


GetFont = love.graphics.getFont


local images = {}
function GetImage(path)
	if images[path] ~= nil then
		return images[path]
	else
		local img = love.graphics.newImage(path)
		images[path] = img
		return img
	end
end

function GetScale(x, y, tx, ty)
	return tx/x, ty/y
end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param ix number
---@param iy number
function IsInside(x1, y1, x2, y2, ix, iy)
	return ix > x1 and iy > y1 and ix < x2 and iy < y2
end

---@param s number
---@param sm number
function AtTimeInterval(s, sm)
	return love.timer.getTime() % s < sm
end

function DeepCopy(tbl)
	local newTbl = {}
	if getmetatable(tbl) ~= nil then
		setmetatable(newTbl, getmetatable(tbl))
	end
	for i,v in pairs(tbl) do
		if type(v) == "table" then
			newTbl[i] = DeepCopy(v)
		else
			newTbl[i] = v
		end
	end
	return newTbl
end

function triangle(mode, x, y, w, h)
	love.graphics.polygon(mode, x, y, x+w, y+(h/2), x, y+h)
end
