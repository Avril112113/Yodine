-- Made by Dude112113, Hi
local json = require "json"
local socket = require "socket"

local SERVER_PORT = 32354


local notification_handlers = {}
local pending_results = {}
local id = 0
local server
local client

local function start_server(ip, port)
	ip = ip or "localhost"
	port = port or SERVER_PORT
	server = socket.bind(ip, port)
end
local function get_server()
	return server
end
local function stop_server()
	if server ~= nil then
		server:close()
		server = nil
	end
end
local function accept_client()
	client = server:accept()
end
local function get_client()
	return client
end


local function send(data)
	local content = json.encode(data)
	local msg = ("Content-Length: %d\r\n\r\n%s"):format(#content, content)
	client:send(msg)
end

local function handle_notification(data)
	local handler = notification_handlers[data.method]
	if handler == nil then
		print("Missing notifcation handler for " .. tostring(data.method))
	else
		handler(data.params)
	end
end


---@param method string
---@param params table
local function notify(method, params)
	send {
		jsonrpc = "2.0",
		method = method,
		params = params,
	}
end

---@param method string
---@param params table
---@param callback function @ optional
local function request(method, params, callback)
	id = id + 1
	send {
		jsonrpc = "2.0",
		id=id,
		method = method,
		params = params,
	}
	pending_results[id] = {
		error=nil,
		result=nil,
		id=id,
		callback=callback
	}
	return pending_results[id]
end


local function receive(timeout)
	client:settimeout(timeout)
	local msg, err = client:receive()
	if err == "timeout" then
		return
	elseif err == "closed" then
		client = nil
		return
	elseif err ~= nil then
		print("error during receive", err)
		return nil, err
	end
	msg = json.decode(msg)
	if msg.id then
		return pending_results[msg.id]
	else
		handle_notification(msg)
	end
end


return {
	start_server=start_server,
	get_server=get_server,
	stop_server=stop_server,
	accept_client=accept_client,
	get_client=get_client,
	notify=notify,
	request=request,
	receive=receive,
	notification_handlers=notification_handlers
}
