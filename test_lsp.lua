package.path = "libs/?.lua;libs/?/init.lua;" .. package.path

local lsp = require "lsp"

lsp.start_server()

while lsp.get_server() ~= nil do
	lsp.update()
end

print("Exit.")
os.exit()
