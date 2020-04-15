local DYaml = require "DYaml"
local Map = require "Map"
local devices = require "devices"


---@class Save
local Save = {
	---@type string
	dir=nil,
	---@type string
	name=nil,
	---@type number
	size=nil,
	---@type number
	save_time=nil
}

---@class LoadedSave
local LoadedSave = {
	---@type Map
	map=nil,
	---@type Save
	save=nil
}


local SaveSystem = {
	---@type LoadedSave
	loadedSave=nil
}


---@return Save[]
function SaveSystem.fetch_save_list()
	local saves = {}
	for _, path in ipairs(love.filesystem.getDirectoryItems("/")) do
		local file_info = love.filesystem.getInfo(path .. "/save.yaml", "file")
		if file_info ~= nil then
			table.insert(saves, {
				dir="/"..path,
				name=path,
				size=file_info.size,
				save_time=file_info.modtime
			})
		end
	end
	return saves
end

function SaveSystem.get_save_info(saveName)
	local file_info = love.filesystem.getInfo(saveName .. "/save.yaml", "file")
	if file_info ~= nil then
		return {
			dir="/"..saveName,
			name=saveName,
			size=file_info.size,
			save_time=file_info.modtime
		}
	end
end

---@param name string
--- Save current loaded save with the given name
function SaveSystem.save(name, makeBackup)
	assert(name ~= nil, "name == nil")
	if love.filesystem.getInfo(name, "directory") == nil then
		love.filesystem.createDirectory(name)
	end
	local save_file = name .. "/save.yaml"
	if makeBackup ~= false then
		local existing_save_info = love.filesystem.getInfo(save_file)
		if existing_save_info ~= nil then
			love.filesystem.write(name .. "/save." .. tostring(existing_save_info.modtime) .. ".yaml", love.filesystem.read(save_file))
		end
	end
	-- local sstart = os.clock()
	local serializedSave = SaveSystem.loadedSave.map:serialize()
	-- local send = os.clock()
	-- local dstart = os.clock()
	local saveMapStr = DYaml.Dumper.dump({
		serializedSave
	})
	-- local dend = os.clock()
	-- print("Took " .. (send - sstart) .. "s to serialize and " .. (dend - dstart) .. "s to dump")
	love.filesystem.write(save_file, saveMapStr)
end

---@param save Save
function SaveSystem.load(save)
	local saveInfo = SaveSystem.get_save_info(save.name)
	if saveInfo == nil then
		return nil
	end
	-- Since we get the save info anyway, we can make sure its correct
	save = saveInfo
	local saveMapStr = love.filesystem.read(save.dir .. "/save.yaml")
	local saveMap = DYaml.Loader.load(saveMapStr, {
		unhandled_tag=function(tag, value)
			local save_name = tag:sub(2)
			local device = devices.registered_save_name[save_name]
			if device == nil then
				DYaml.Loader.default_unhandled_tag(tag, value)
			else
				value._tagged_device = device
			end
		end
	})[1]
	SaveSystem.loadedSave = {
		save=save
	}
	-- while deserializing the map, they might need the save info like the directory to the save folder
	SaveSystem.loadedSave.map = Map.deserialize(saveMap)
	return SaveSystem.loadedSave
end

local function recursiveRemove(path)
	if love.filesystem.getInfo(path , "directory") then
		for _, child in pairs(love.filesystem.getDirectoryItems(path)) do
			recursiveRemove(path .. '/' .. child)
			love.filesystem.remove(path .. '/' .. child)
		end
	elseif love.filesystem.getInfo(path) then
		love.filesystem.remove(path)
	end
	love.filesystem.remove(path)
end
function SaveSystem.loadTempSave()
	local tmpSave = SaveSystem.get_save_info("%TMP%")
	if tmpSave == nil then
		SaveSystem.loadedSave = {
			map=Map.new(),
			save={
				dir="%TMP%",
				name="%TMP%",
				size=0,
				save_time=0
			}
		}
		SaveSystem.save("%TMP%")
		tmpSave = SaveSystem.get_save_info("%TMP%")
	end
	SaveSystem.load(tmpSave)
end

return SaveSystem
