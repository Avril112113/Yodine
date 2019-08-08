--zOrder goes by highest number, is on top (number 1 is the highest)
--if useing transparentClick please make shure to return "break" if a component was clicked
--make shure none of the menus have the save zOrder or none of them will be shown (only needed for new())
--Any error made with 'setTag' is a problem with the value being set to the wrong type eg 'boolean' was expecting 'string'
--No menus can have the same name or zOrder!!! if you use the same name you will be overwriting the old one

local menuManager = {}
menuManager.menus = {}

local function isInside(minX,minY,maxX,maxY,inputX,inputY)
	if minX == nil or minY == nil or maxX == nil or maxY == nil or inputX == nil or inputY == nil then
		print("Func 'isInside' Missing Args, Or Passed Args Is 'nil'")
	end
	if inputX >= minX and inputX <= maxX and inputY >= minY and inputY <= maxY then
		return true
	else
		return false
	end
end

local function table_len(t)
	local length = 0
	for i,v in pairs(t) do
		length = length + 1
	end
	return length
end

function menuManager:zOrderInter()
    local tempTable = {}
    for i,v in pairs(menuManager.menus) do
        tempTable[v.zOrder] = v
    end
    return tempTable
end

function menuManager:zOrderInterReverse()
	local tempTable = {}
    for i,v in pairs(menuManager.menus) do
        tempTable[table_len(menuManager.menus) - v.zOrder + 1] = v
    end
    return tempTable
end

function menuManager:canvas(canvasName)
	if type(canvasName) ~= "string" then
		error("Recived 'canvasName' for 'canvas' not a 'String'".."\n"..debug.traceback())
	end
	return menuManager.menus[canvasName]
end

function menuManager:setShown(canvasName, state)
	if type(canvasName) ~= "string" then
		error("Recived 'canvasName' for 'setShown' not a 'String'".."\n"..debug.traceback())
	end
	if type(state) ~= "boolean" then
		error("Recived 'state' for 'setShown' not a 'Boolean'".."\n"..debug.traceback())
	end
	menuManager.menus[canvasName].shown = state
end

function menuManager:setPos(canvasName, x, y)
	print(type(x),type(y))
	if type(canvasName) ~= "string" then
		error("Recived 'canvasName' for 'setPos' not a 'String'".."\n"..debug.traceback())
	end
	if type(x) ~= "number" and type(x) ~= "float" then
		error("Recived 'x' for 'setPos' not a 'number' or 'float'".."\n"..debug.traceback())
	end
	if type(y) ~= "number" and type(x) ~= "float" then
		error("Recived 'y' for 'setPos' not a 'number' or 'float'".."\n"..debug.traceback())
	end
	menuManager.menus[canvasName].x = x
	menuManager.menus[canvasName].y = y
end

function menuManager:setSize(canvasName, sx, sy)
	if type(canvasName) ~= "string" then
		error("Recived 'canvasName' for 'setPos' not a 'String'".."\n"..debug.traceback())
	end
	if type(sx) ~= "number" and type(x) ~= "float" then
		error("Recived 'sx' for 'setPos' not a 'number' or 'float'".."\n"..debug.traceback())
	end
	if type(sy) ~= "number" and type(x) ~= "float" then
		error("Recived 'sy' for 'setPos' not a 'number' or 'float'".."\n"..debug.traceback())
	end
	menuManager.menus[canvasName].sx = sx
	menuManager.menus[canvasName].sy = sy
	for i,v in ipairs(menuManager.menus[canvasName].dragableAreaOriginal) do
		if type(v) == "string" then
			if v == "x" then
				menuManager.menus[canvasName].dragableArea[i] = menuManager.menus[canvasName].sx
			elseif v == "y" then
				menuManager.menus[canvasName].dragableArea[i] = menuManager.menus[canvasName].sy
			end
		end
	end
	menuManager.menus[canvasName].canvas = love.graphics.newCanvas(sx, sy)
end

function menuManager:setTag(canvasName, tagName, value)
	if type(canvasName) ~= "string" then
		error("Recived 'canvasName' for 'setTag' not a 'String'".."\n"..debug.traceback())
	end
	if type(tagName) ~= "string" then
		error("Recived 'tagName' for 'setTag' not a 'String'".."\n"..debug.traceback())
	end
	if value == nil then
		error("Recived 'vlaue' for 'setTag' not 'ANY'".."\n"..debug.traceback())
	end
	menuManager.menus[canvasName][tagName] = value
end

function menuManager:getCursor(canvasName)
	if type(canvasName) ~= "string" and type(canvasName) ~= "table" then
		error("Recived 'canvasName' for 'getCursor' not a 'String' or 'Table'".."\n"..debug.traceback())
	end
	if type(canvasName) == "table" then
		canvasName = canvasName.name
	end
	local x, y = love.mouse.getX() - menuManager.menus[canvasName].x, love.mouse.getY() - menuManager.menus[canvasName].y
	if x < 0 or y < 0 then
		x,y = nil, nil
	elseif x > menuManager.menus[canvasName].sx or y > menuManager.menus[canvasName].sy then
		x,y = nil, nil
	end
	return x,y
end

function menuManager:exists(canvasName)
	if type(canvasName) ~= "string" then
		error("Recived 'canvasName' for 'setTag' not a 'String'".."\n"..debug.traceback())
	end
	if menuManager.menus[canvasName].name ~= nil then
		return true
	else
		return false
	end
end

function menuManager:new(canvasName, menuType, argsTable, drawFunc, clikedFunc)
	if type(canvasName) ~= "string" then
		error("Recived 'canvasName' For 'new' not A 'String'".."\n"..debug.traceback())
	end
	if type(menuType) ~= "string" then
		error("Recived 'menuType' For 'new' not A 'String'".."\n"..debug.traceback())
	end
	--if type(argsTable) ~= "table" then
	--	error("Recived 'argsTable' For 'new' not A 'Table'".."\n"..debug.traceback())
	--end
	if type(drawFunc) ~= "function" then
		error("Recived 'drawFunc' For 'new' not A 'Function'".."\n"..debug.traceback())
	end
	--if type(clikedFunc) ~= "function" then
	--	error("Recived 'clikedFunc' For 'new' not A 'Function'".."\n"..debug.traceback())
	--end
    menuManager.menus[canvasName] = {}
    local menu = menuManager.menus[canvasName]
    if menuType == "sideMenu" then
        menu.type = "sideMenu"
        menu.name = canvasName
        menu.drawFunc = drawFunc
        menu.clikedFunc = clikedFunc
        menu.shown = argsTable["shown"] or true
        menu.x = argsTable["x"] or 0
        menu.y = argsTable["y"] or 0
        menu.sx = argsTable["sx"] or love.graphics.getWidth()
        menu.sy = argsTable["sy"] or love.graphics.getHeight()
        menu.zOrder = argsTable["zOrder"] or table_len(menuManager.menus)
        menu.zOrderOnClick = argsTable["zOrderOnClick"] or false
        menu.transparentClick = argsTable["transparentClick"] or argsTable["transClick"] or false
        menu.dragable = argsTable["dragable"] or false
		menu.dragableAreaOriginal = argsTable["dragableArea"] or {0,0,"x",20}
		menu.dragableArea = {menu.dragableAreaOriginal[1],menu.dragableAreaOriginal[2],menu.dragableAreaOriginal[3],menu.dragableAreaOriginal[4]}
		for i,v in ipairs(menu.dragableArea) do
			if menu.dragable == false then
				menu.dragableArea = {0,0,0,0}
				menu.dragableAreaOriginal = {0,0,0,0}
			else
				if type(v) == "string" then
					if v == "x" then
						menu.dragableArea[i] = menu.sx
					elseif v == "y" then
						menu.dragableArea[i] = menu.sy
					end
				end
			end
		end
		menu.resizable = argsTable["resizable"] or false
		menu.resizableMin = argsTable["resizableSize"] or menu.dragableArea[4]+15 or 30
		menu.resizableSize = argsTable["resizableSize"] or 10
		if menu.resizable == false then
			menu.resizableSize = 0
		end
        menu.canvas = love.graphics.newCanvas(menu.sx, menu.sy)
    else
        error("Invalid type for new menu canvas".."\n"..debug.traceback())
    end
end

function menuManager:mousepressed(x,y,button)
    for i,v in ipairs(menuManager:zOrderInter()) do
		if v.shown == true and v.clikedFunc ~= nil then
	        if v.transparentClick == false and isInside(v.x, v.y, v.x+v.sx, v.y+v.sy, x, y) == true then
				if v.zOrderOnClick == true then
					local lastCount = 2
					for i1,v1 in pairs(menuManager:zOrderInter()) do
						if v1.name == v.name then
							menuManager.menus[v1.name].zOrder = 1
						else
							menuManager.menus[v1.name].zOrder = lastCount
							lastCount = lastCount + 1
						end
					end
				end
	            v.clikedFunc(v,x - v.x,y - v.y,button)
	            break
	        elseif v.transparentClick == true and isInside(v.x, v.y, v.x+v.sx, v.y+v.sy, x, y) == true then
	            if v.clikedFunc(v,x - v.x,y - v.y,button) == "break" then
					if v.zOrderOnClick == true then
						local lastCount = 2
						for i1,v1 in pairs(menuManager:zOrderInter()) do
							if v1.name == v.name then
								menuManager.menus[v1.name].zOrder = 1
							else
								menuManager.menus[v1.name].zOrder = lastCount
								lastCount = lastCount + 1
							end
						end
					end
	                break
	            end
	        end
		end
    end
end

function menuManager:draw()
    for i,v in ipairs(menuManager:zOrderInterReverse()) do
		if v.shown == true then
			love.graphics.push()
		        love.graphics.setCanvas(v.canvas)
		            love.graphics.clear()
		            v.drawFunc(v)
		        love.graphics.setCanvas()
	            love.graphics.translate(v.x, v.y)
	            love.graphics.draw(v.canvas)
	        love.graphics.pop()
		end
    end
end

function menuManager:update(dt)
    for i,v in ipairs(menuManager:zOrderInter()) do
        if v.dragable == true and v.shown == true then
            if love.mouse.isDown(1,2) == true then
                if isInside(v.dragableArea[1]+v.x, v.dragableArea[2]+v.y, v.dragableArea[3]+v.x, v.dragableArea[4]+v.y, love.mouse.getPosition()) == true then
            		if mouseDown == nil then
                        local mx,my = love.mouse.getPosition()
            			startPosX = v.x - mx
            			startPosY = v.y - my
            			mouseDown = v.name
            		end
				elseif isInside(v.x, v.y, v.x + v.sx, v.y + v.sy, love.mouse.getPosition()) == true and mouseDown ~= nil and menuManager.menus[v.name].zOrder < menuManager.menus[mouseDown].zOrder then
					mouseDown = nil
                end
                if startPosX ~= nil and startPosY ~= nil and v.name == mouseDown then
                    v.x = love.mouse.getX() + startPosX
                    v.y = love.mouse.getY() + startPosY
                end
				if mouseDown ~= nil and mouseDownResize ~= nil then
					mouseDownResize = nil
					startPosXResize = nil
	                startPosYResize = nil
				end
            else
                mouseDown = nil
                startPosX = nil
                startPosY = nil
            end
        end
		if v.resizable == true and v.shown == true then
			if love.mouse.isDown(1,2) == true then
				if isInside(v.x+v.sx-v.resizableSize, v.y+v.sy-v.resizableSize, v.x+v.sx, v.y+v.sy, love.mouse.getPosition()) == true then
            		if mouseDownResize == nil then
                        local mx,my = love.mouse.getPosition()
            			startPosXResize = v.sx - mx
            			startPosYResize = v.sy - my
            			mouseDownResize = v.name
            		end
				elseif isInside(v.x, v.y, v.x + v.sx, v.y + v.sy, love.mouse.getPosition()) == true and mouseDownResize ~= nil and menuManager.menus[v.name].zOrder < menuManager.menus[mouseDownResize].zOrder then
					mouseDownResize = nil
					startPosXResize = nil
	                startPosYResize = nil
                end
                if startPosXResize ~= nil and startPosYResize ~= nil and v.name == mouseDownResize then
					v.sx = love.mouse.getX() + startPosXResize
					v.sy = love.mouse.getY() + startPosYResize
					if v.sx <= v.resizableMin - 1 then
						v.sx = v.resizableMin
					end
					if v.sy <= v.resizableMin  - 1 then
						v.sy = v.resizableMin
					end
					v.canvas = love.graphics.newCanvas(v.sx, v.sy)
					for i1,v1 in ipairs(v.dragableAreaOriginal) do
						if type(v1) == "string" then
							if v1 == "x" then
								v.dragableArea[i1] = v.sx
							elseif v1 == "y" then
								v.dragableArea[i1] = v.sy
							end
						end
					end
                end
				if mouseDown ~= nil and mouseDownResize ~= nil then
					mouseDownResize = nil
					startPosXResize = nil
	                startPosYResize = nil
				end
            else
				mouseDownResize = nil
				startPosXResize = nil
                startPosYResize = nil
            end
		end
    end
end

return menuManager
