-- Made by Dude112113, Hi
local json = require "json"
local socket = require "socket"


local DEFAULT_PORT = 57082
local DEBUG = true

local ErrorCodes = {
	ParseError = -32700;
	InvalidRequest = -32600;
	MethodNotFound = -32601;
	InvalidParams = -32602;
	InternalError = -32603;
	serverErrorStart = -32099;
	serverErrorEnd = -32000;
	ServerNotInitialized = -32002;
	UnknownErrorCode = -32001;

	RequestCancelled = -32800;
	ContentModified = -32801;
}


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


local lsp = {
	languageHandlerBase = {
		h_onDidOpen=function() end,
		h_onDidClose=function() end,
		h_onDidChange=function() end,
	},
	languageHandler = nil,
	coroutines = {}
}
lsp.languageHandlerBase.__index = lsp.languageHandlerBase

local lsp_client = {}
lsp_client.__index = lsp_client
function lsp_client.new(sock)
	local self = setmetatable({
		sock=sock
	}, lsp_client)
	self.handler = lsp.languageHandler.new()
	self.handler._client = self

	self.capabilities = {
		textDocumentSync={
			openClose=self.handler.h_onDidOpen ~= nil or self.handler.h_onDidClose ~= nil,
			change=self.handler.h_onDidChange ~= nil,
			willSave=false,
			willSaveWaitUntil=false,
			save=false
		},
		hoverProvider=self.handler.h_onHover ~= nil,
		completionProvider=self.handler.h_onCompletion ~= nil and {
			resolveProvider=self.handler.h_onCompletionResolve,
			triggerCharacters=self.handler.completionTriggers or {}
		},
		signatureHelpProvider={
			triggerCharacters={}
		},
		definitionProvider=false,
		typeDefinitionProvider=false,
		implementationProvider=false,
		referencesProvider=self.handler.h_onReferences ~= nil,
		documentHighlightProvider=self.handler.h_onHighlight ~= nil,
		documentSymbolProvider=false,
		workspaceSymbolProvider=false,
		codeActionProvider=false,  -- {codeActionKinds=[]}
		codeLensProvider={
			resolveProvider=self.handler.h_onCodeLens ~= nil
		},
		documentFormattingProvider=false,
		documentRangeFormattingProvider=false,
		documentOnTypeFormattingProvider=false,
		renameProvider=false,
		documentLinkProvider=false,  -- {resolveProvider=false}
		colorProvider=false,
		foldingRangeProvider=false,
		executeCommandProvider={
			commands=self:getHandlerCommands()
		},
		workspace={
			workspaceFolders={
				supported=false,
				changeNotifications=false
			}
		}
	}
	return self
end
function lsp_client:getHandlerCommands()
	local cmdList = {}
	for k, v in pairs(self.handler) do
		if k:sub(0, 4) == "cmd_" then
			table.insert(cmdList, k:sub(5):gsub("_", "."))
		end
	end
	return cmdList
end
function lsp_client:handle_packet(data)
	if data.method == nil then
		self:send_rpc {
			id=data.id,
			error={
				code=ErrorCodes.InvalidRequest,
				data="Invalid method"
			}
		}
		return
	end
	local handler = lsp.method_handlers[data.method]
	if handler == nil then
		self:send_rpc {
			id=data.id,
			error={
				code=ErrorCodes.MethodNotFound,
				data="Failed to find handler for method: " .. tostring(data.method)
			}
		}
		return
	end
	if data.id == nil then
		-- Notification
		if DEBUG then print("Handling notification " .. tostring(data.method)) end
		handler(self, data.params)
	else
		-- Request
		if DEBUG then print("Handling request " .. tostring(data.method) .. " with id " .. tostring(data.id)) end
		local result, err = handler(self, data.params)
		self:send_rpc {
			id=data.id,
			result=result,
			error=err
		}
	end
end
function lsp_client:main()
	local cs = lsp.coroutines

	print(self.sock)

	::client_loop::
	local content_line, err = self.sock:receive("*l")
	if err == "timeout" then
		coroutine.yield()
		goto client_loop
	elseif err == "closed" then
		cs[self] = nil
		print("Client disconnected: " .. tostring(self.sock))
		return
	elseif err ~= nil then
		print("Got error wile receiving:", err)
		coroutine.yield()
		goto client_loop
	end
	local length = tonumber(content_line:sub(17))
	local content_json, err = self.sock:receive(length+2)
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
		lsp.handle_packet(data)
	end
	goto client_loop
end


function lsp.update()
	for k, c in pairs(lsp.coroutines) do
		-- Might want to add a time check using debug.sethook?
		coroutine.resume(c)
		if coroutine.status(c) == "dead" then
			print("Encountered dead coroutine, cleaning it up. (was there an error? or did its not cleanup after its self?)")
			lsp.coroutines[k] = nil
		end
	end
end

---@type tcp_socket
local server
function lsp.create_coroutines()
	local cs = lsp.coroutines
	cs["accept"] = coroutine.create(function()
		::server_loop::
		local sock, err = server:accept()
		if err == "timeout" then
			coroutine.yield()
			goto server_loop
		elseif err ~= nil then
			print("Failed to accept client: " .. tostring(err))
			coroutine.yield()
			goto server_loop
		else  -- client ~= nil
			print("Setting up client: " .. tostring(sock))
			sock:settimeout(0)
			local client = lsp_client.new(sock)
			cs[client] = coroutine.create(function()
				local ok, err = pcall(function() client:main() end)
				if not ok and err ~= nil then
					print("Error while handling " .. tostring(sock) .. ": ", err)
					sock:close()
				end
			end)
		end
		coroutine.yield()
		goto server_loop
	end)
end
function lsp.start_server(ip, port)
	if lsp.languageHandler == nil then
		error("Attempt to start server without lsp.languageHandler defined.")
	elseif lsp.languageHandler.new == nil then
		error("Attempt to start server without lsp.languageHandler.new() defined.")
	elseif getmetatable(lsp.languageHandler) ~= lsp.languageHandlerBase then
		error("lsp.languageHandler does not have lsp.languageHandlerBase set as it's metatable.")
	end
	ip = ip or "*"
	port = port or DEFAULT_PORT
	---@type tcp_socket
	server = assert(socket.bind(ip, port))
	server:settimeout(0)
	lsp.create_coroutines()
end
function lsp.stop_server()
	for k, _ in pairs(lsp.coroutines) do
		lsp.coroutines[k] = nil
	end
	server:close()
	server = nil
end
function lsp.get_server()
	return server
end


return lsp
