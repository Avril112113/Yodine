package.path = "libs/?.lua;libs/?/init.lua;" .. package.path

local rpc = require "rpc"

rpc.start_server()

while rpc.get_server() ~= nil do
	rpc.update()
end

print("Exit.")
os.exit()
