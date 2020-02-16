local socket = require "socket"

local client = socket.connect("localhost", 57082)
client:settimeout(0)

while true do
	local data, err = client:receive("*l")
	if err == "closed" then
		break
	elseif err == "timeout" then
	elseif err ~= nil then
		print(err)
	else
		print(data)
	end
end
