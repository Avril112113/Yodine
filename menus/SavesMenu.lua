local loveframes = require "loveframes"
local menus = require "menus"
local SaveSystem = require "SaveSystem"


local SavesMenu = {}
menus.SavesMenu = SavesMenu
local base = loveframes.Create("frame")
SavesMenu.base = base

local padding = 2

-- base:SetVisible(false)
base:SetName("Save and Load")
base:SetResizable(false)
base:SetDraggable(false)
base:SetVisible(false)

function base:OnClose()
	base:SetVisible(false)
	return false
end

local SaveNameEdit = loveframes.Create("textinput", base)
SaveNameEdit:SetText("save")

function SaveNameEdit:Update()
	local pattern = "[/\\*?<>:|]"
	if self:GetText():find(pattern) then
		self:SetText(self:GetText():gsub(pattern, ""))
	end
end

local SaveButton = loveframes.Create("button", base)
SaveButton:SetText("Save")

function SaveButton:OnClick()
	SaveSystem.save(SaveNameEdit:GetText())
	SavesMenu.refreshSavesList()
end

local SavesList = loveframes.Create("list", base)
local LoadSaveButton = loveframes.Create("button", base)
LoadSaveButton:SetText("Load Selected Save")

---@type Save
local selectedSave

function LoadSaveButton:OnClick()
	if selectedSave ~= nil then
		local loadedSave = SaveSystem.load(selectedSave)
		if loadedSave.map ~= nil then
			SaveSystem.loadedSave.map = loadedSave.map
			ClearSelectedDevices()
			base:SetVisible(false)
		else
			SavesMenu.refreshSavesList()
		end
	end
end

function SavesMenu.refreshSavesList()
	SavesList:Clear()
	for _, save in ipairs(SaveSystem.fetch_save_list()) do
		local button = loveframes.Create("button")
		button:SetText(save.name)
		button.groupIndex = 1
		function button:OnClick()
			selectedSave = save
			SaveNameEdit:SetText(save.name)
		end
		SavesList:AddItem(button)
	end
end
SavesMenu.refreshSavesList()

local ShowInFileBrowser = loveframes.Create("button", base)
ShowInFileBrowser:SetText("Show In File Browser")
function ShowInFileBrowser:OnClick()
	local path = "file://" .. love.filesystem.getSaveDirectory()
	if selectedSave ~= nil then
		path = path .. selectedSave.dir
	end
	love.system.openURL(path)
end

function SavesMenu:update()
	local width = 350
	local base_frame_height = 25

	SaveNameEdit:SetSize(width-padding-50, 25)
	SaveNameEdit:SetPos(padding, padding + base_frame_height)
	SaveButton:SetSize(50-padding, SaveNameEdit.height)
	SaveButton:SetPos(padding + SaveNameEdit.staticx + SaveNameEdit.width, padding + base_frame_height)

	SavesList:SetSize(width-padding, 400)
	SavesList:SetPos(padding, padding + SaveNameEdit.staticy + SaveNameEdit.height)

	LoadSaveButton:SetSize(width/2-padding, 28)
	LoadSaveButton:SetPos(padding, padding + SavesList.staticy + SavesList.height)
	ShowInFileBrowser:SetSize(width/2-padding, 28)
	ShowInFileBrowser:SetPos(padding + width/2, padding + SavesList.staticy + SavesList.height)

	base:SetSize(ShowInFileBrowser.staticx + ShowInFileBrowser.width + padding, ShowInFileBrowser.staticy + ShowInFileBrowser.height + padding)
	base:SetPos((love.graphics.getWidth() - width) / 2, (love.graphics.getHeight() - base.height) / 2)
end
