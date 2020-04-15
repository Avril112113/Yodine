-- Helpful functions, shorthands ect


GetFont = (love and love.graphics.getFont) or nil


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

--- Does not deep copy metatable, but does set new tables meta the same as the provided table
--- Does not deep copy key values
function DeepCopy(tbl, references)
	references = references or {}
	local newTbl = {}
	references[tbl] = newTbl
	for i, v in pairs(tbl) do
		if type(v) == "table" then
			if references[v] then
				newTbl[i] = references[v]
			else
				newTbl[i] = DeepCopy(v, references)
			end
		else
			newTbl[i] = v
		end
	end
	if getmetatable(tbl) ~= nil then
		setmetatable(newTbl, getmetatable(tbl))
	end
	return newTbl
end

function love.graphics.triangle(mode, x, y, w, h)
	love.graphics.polygon(mode, x, y, x+w, y+(h/2), x, y+h)
end

function table.serialize(_tbl, indent, lineEnd)
	indent = indent or ""
	lineEnd = lineEnd or ""
	local str = {}
	local function serialize(tbl, depth)
		str[#str+1] = "{" .. lineEnd .. indent:rep(depth+1)
		local firstElem = true
		for i, v in pairs(tbl) do
			if firstElem then
				firstElem = false
			else
				str[#str+1] = "," .. lineEnd .. indent:rep(depth+1)
			end
			str[#str+1] = "["
			if type(i) == "table" then
				serialize(i, depth+1)
			elseif type(i) == "string" then
				str[#str+1] = "\"" .. i:gsub("\"", "\\\"") .. "\""
			else
				str[#str+1] = tostring(i)
			end
			str[#str+1] = "]"
			str[#str+1] = "="
			if type(v) == "table" then
				serialize(v, depth+1)
			elseif type(v) == "string" then
				str[#str+1] = "\"" .. v:gsub("\"", "\\\"") .. "\""
			else
				str[#str+1] = tostring(v)
			end
		end
		str[#str+1] = lineEnd .. indent:rep(depth) .. "}"
	end
	serialize(_tbl, 0)
	return table.concat(str)
end

-- function jsonify_auto(tbl)
-- 	local new = {}
-- 	for i, v in pairs(tbl) do
-- 		if type(v) == "table" then
-- 			if v.jsonify then
-- 				new[i] = v:jsonify()
-- 			else
-- 				new[i] = jsonify_auto(v)
-- 			end
-- 		elseif type(v) == "function" then
-- 			-- we cant jsonify a function
-- 		else
-- 			new[i] = v
-- 		end
-- 	end
-- 	return new
-- end

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

-- https://gist.github.com/sixFingers/ee5c1dce72206edc5a42b3246a52ce2e
function MonotoneChain(points)
    local p = #points

    local cross = function(p, q, r)
        return (q[2] - p[2]) * (r[1] - q[1]) - (q[1] - p[1]) * (r[2] - q[2])
    end

    table.sort(points, function(a, b)
        return a[1] == b[1] and a[2] > b[2] or a[1] > b[1]
    end)

    local lower = {}
    for i = 1, p do
        while (#lower >= 2 and cross(lower[#lower - 1], lower[#lower], points[i]) <= 0) do
            table.remove(lower, #lower)
        end

        table.insert(lower, points[i])
    end

    local upper = {}
    for i = p, 1, -1 do
        while (#upper >= 2 and cross(upper[#upper - 1], upper[#upper], points[i]) <= 0) do
            table.remove(upper, #upper)
        end

        table.insert(upper, points[i])
    end

    table.remove(upper, #upper)
    table.remove(lower, #lower)
    for _, point in ipairs(lower) do
        table.insert(upper, point)
    end

    return upper
end

-- https://stackoverflow.com/questions/31730923/check-if-point-lies-in-polygon-lua
function InsidePolygon(polygon, point)
    local oddNodes = false
    local j = #polygon
	for i = 1, #polygon do
        if (polygon[i][2] < point[2] and polygon[j][2] >= point[2] or polygon[j][2] < point[2] and polygon[i][2] >= point[2]) then
            if (polygon[i][1] + (point[2] - polygon[i][2]) / (polygon[j][2] - polygon[i][2]) * (polygon[j][1] - polygon[i][1]) < point[1]) then
                oddNodes = not oddNodes;
            end
        end
        j = i;
    end
    return oddNodes
end
