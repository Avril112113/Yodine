local loveframes = require "loveframes"
local menus = require "menus"


local OpenSavesMenu = {}
menus.OpenSavesMenu = OpenSavesMenu
local base = loveframes.Create("button")
OpenSavesMenu.base = base

base:SetSize(74, 70)
base:SetText("")
base:SetImage(GetImage("imgs/save and load.png"))

function base:OnClick()
	menus.SavesMenu.base:SetVisible(not menus.SavesMenu.base.visible)
	menus.SavesMenu.base:MakeTop()
end

function OpenSavesMenu:update()
	base:SetPos((love.graphics.getWidth() - base.width) / 2, 5)
end
