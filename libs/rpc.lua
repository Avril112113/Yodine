-- Made by Dude112113, Hi
local json = require "json"
local socket = require "socket"


local DEFAULT_PORT = 57082
local DEBUG = true


local function str_table(tbl, indent, depth)
	depth = depth or 0
	indent = indent or "    "

	local s = indent:rep(depth) .. "{"
	for i, v in pairs(tbl) do
		if type(v) == "table" then
			s = s .. indent:rep(depth+1) .. str_table(v, indent, depth + 1)
		else
			s = s .. "\n" .. indent:rep(depth+1) .. tostring(i) .. " = " .. tostring(v) .. ","
		end
	end
	return s .. "\n" .. indent:rep(depth) .. "}"
end


local coroutines = {}
local function update()
	for k, c in pairs(coroutines) do
		-- Might want to add a time check using debug.sethook?
		coroutine.resume(c)
		if coroutine.status(c) == "dead" then
			print("Encountered dead coroutine, cleaning it up. (was there an error? or did its not cleanup after its self?)")
			coroutines[k] = nil
		end
	end
end

---@type tcp_socket
local server
local function create_coroutines()
	local cs = coroutines
	cs["accept"] = coroutine.create(function()
		::server_loop::
		local client, err = server:accept()
		if err == "timeout" then
			coroutine.yield()
			goto server_loop
		elseif err ~= nil then
			print("Failed to accept client: " .. tostring(err))
			coroutine.yield()
			goto server_loop
		else  -- client ~= nil
			print("Setting up client: " .. tostring(client))
			client:settimeout(0)
			cs[client] = coroutine.create(function()
				local ok, err = pcall(function()
					::client_loop::
					local content_line, err = client:receive("*l")
					if err == "timeout" then
						coroutine.yield()
						goto client_loop
					elseif err == "closed" then
						cs[client] = nil
						print("Client disconnected: " .. tostring(client))
						return
					elseif err ~= nil then
						print("Got error wile receiving:", err)
						coroutine.yield()
						goto client_loop
					end
					local length = tonumber(content_line:sub(17))
					local content_json, err = client:receive(length+2)
					if err ~= nil then
						print("Got error wile receiving (from length):", err)
						coroutine.yield()
						goto client_loop
					end
					content_json = content_json:sub(3)
					if DEBUG then print("Received content:", content_json) end
					local data = json.decode(content_json)
					if type(data) ~= "table" then
						print(json.decode(content_json))
						print("Got malformed data...", data)
					else
						if DEBUG then print("Received content decoded:\n" .. str_table(data)) end
					end
					goto client_loop
				end)
				if not ok and err ~= nil then
					print("Error while handling " .. tostring(client) .. ": ", err)
					client:close()
				end
			end)
		end
		coroutine.yield()
		goto server_loop
	end)
end
local function start_server(ip, port)
	ip = ip or "*"
	port = port or DEFAULT_PORT
	---@type tcp_socket
	server = assert(socket.bind(ip, port))
	server:settimeout(0)
	create_coroutines()
end
local function stop_server()
	for k, _ in pairs(coroutines) do
		coroutines[k] = nil
	end
	server:close()
	server = nil
end
local function get_server()
	return server
end


return {
	update=update,

	start_server=start_server,
	stop_server=stop_server,
	get_server=get_server
}
