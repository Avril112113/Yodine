local json = require "json"
local Map = require "Map"


local saves_system = {}


function saves_system.fetch_save_list()
	local saves = {}
	for _, path in ipairs(love.filesystem.getDirectoryItems("/")) do
		local file_info = love.filesystem.getInfo(path .. "/save.yodine.json", "file")
		if file_info ~= nil then
			table.insert(saves, {
				dir=path,
				name=path,
				size=file_info.size,
				save_time=file_info.modtime
			})
		end
	end
	return saves
end

function saves_system.save(map, name)
	assert(map ~= nil, "map == nil")
	assert(name ~= nil, "name == nil")
	if love.filesystem.getInfo(name, "directory") == nil then
		love.filesystem.createDirectory(name)
	end
	local save_file = name .. "/save.yodine.json"
	local existing_save_info = love.filesystem.getInfo(save_file)
	if existing_save_info ~= nil then
		love.filesystem.write(name .. "/save.yodine." .. tostring(existing_save_info.modtime) .. ".json", love.filesystem.read(save_file))
	end
	local saveMap = LoadedMap:jsonify()
	local saveMapStr = json.encode(saveMap)
	love.filesystem.write(save_file, saveMapStr)
end

function saves_system.load(save)
	if love.filesystem.getInfo(save.dir, "directory") == nil then
		return nil
	end
	local saveMapStr = love.filesystem.read(save.dir .. "/save.yodine.json")
	local saveMap = json.decode(saveMapStr)
	return Map.new(saveMap)
end


return saves_system
