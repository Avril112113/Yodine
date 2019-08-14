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

GetFont = love.graphics.getFont

function GetCenterDrawObjectPositionData()
	if CenterDrawObject ~= nil and CenterDrawObject.getSizeGUI ~= nil then
		local ww, wh = love.graphics.getWidth(), love.graphics.getHeight()
		local cdo_w, cdo_h = CenterDrawObject:getSizeGUI()
		local cdo_x, cdo_y = (ww/2)-(cdo_w/2), (wh/2)-(cdo_h/2)
		return cdo_x, cdo_y, cdo_w, cdo_h
	end
end
