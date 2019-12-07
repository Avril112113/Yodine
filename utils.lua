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

function table.serialize(_tbl)
	local str = {}
	local function serialize(tbl)
		str[#str+1] = "{"
		local firstElem = true
		for i, v in pairs(tbl) do
			if firstElem then
				firstElem = false
			else
				str[#str+1] = ","
			end
			str[#str+1] = "["
			if type(i) == "table" then
				serialize(i)
			elseif type(i) == "string" then
				str[#str+1] = "\"" .. i:gsub("\"", "\\\"") .. "\""
			else
				str[#str+1] = tostring(i)
			end
			str[#str+1] = "]"
			str[#str+1] = "="
			if type(v) == "table" then
				serialize(v)
			elseif type(v) == "string" then
				str[#str+1] = "\"" .. v:gsub("\"", "\\\"") .. "\""
			else
				str[#str+1] = tostring(v)
			end
		end
		str[#str+1] = "}"
	end
	serialize(_tbl)
	return table.concat(str)
end

function jsonify_auto(tbl)
	local new = {}
	for i, v in pairs(tbl) do
		if type(v) == "table" then
			if v.jsonify then
				new[i] = v:jsonify()
			else
				new[i] = jsonify_auto(v)
			end
		elseif type(v) == "function" then
			-- we cant jsonify a function
		else
			new[i] = v
		end
	end
	return new
end
