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

-- https://gist.github.com/GigsD4X/8513963
function HSVToRGB( hue, saturation, value )
	-- Returns the RGB equivalent of the given HSV-defined color
	-- (adapted from some code found around the web)

	-- If it's achromatic, just return the value
	if saturation == 0 then
		return value, value, value;
	end;

	-- Get the hue sector
	local hue_sector = math.floor( hue / 60 );
	local hue_sector_offset = ( hue / 60 ) - hue_sector;

	local p = value * ( 1 - saturation );
	local q = value * ( 1 - saturation * hue_sector_offset );
	local t = value * ( 1 - saturation * ( 1 - hue_sector_offset ) );

	if hue_sector == 0 then
		return value, t, p;
	elseif hue_sector == 1 then
		return q, value, p;
	elseif hue_sector == 2 then
		return p, value, t;
	elseif hue_sector == 3 then
		return p, q, value;
	elseif hue_sector == 4 then
		return t, p, value;
	else
		return value, p, q;
	end;
end;
