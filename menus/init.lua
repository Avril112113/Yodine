-- needs to be before requires to prevent require loops
local menus = {}
package.loaded["menus"] = menus


local loveframes = require "loveframes"


-- Patch terrible text colors
-- when its a dark skin the text is hard to see due to its color
local textColor = {0.9, 0.9, 0.9, 1}
local color = function(s, a) return {loveframes.Color(s, a)} end
for i, v in pairs(loveframes.skins) do
	if i:sub(1, 4) == "Dark" then
		v.controls.color_fore0  = color "e5e5e5"
	end
end

-- TODO: make customizable
loveframes.SetActiveSkin("Dark green")

-- find and load all menus
for _, fileName in pairs(love.filesystem.getDirectoryItems("menus")) do
	local fileNameExcExt = fileName:sub(0, -5)
	if fileName:sub(-3, -1) == "lua" and fileNameExcExt ~= "init" then
		require("menus." .. fileNameExcExt)
	end
end


return menus
