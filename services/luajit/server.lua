local socket = require("socket")
local bridge = require("bridge")

local function json_encode(tbl)
    local items = {}
    for k, v in pairs(tbl) do
        local val = type(v) == "string" and '"'..v..'"' or tostring(v)
        table.insert(items, '"'..k..'":'..val)
    end
    return "{"..table.concat(items, ",").."}"
end

local port = tonumber(os.getenv("PORT")) or 8082
local server = socket.bind("*", port)
print("LuaJIT Service listening on port " .. port)
server:settimeout(0.1)

while true do
    local client = server:accept()
    if client then
        client:settimeout(10)
        local request = client:receive()
        if request then
            local response_data = {status="ok", service="luajit"}
            if request:match("GET /health") then
                response_data.healthy = true
            elseif request:match("GET /benchmark") then
                response_data = bridge.benchmark(10000)
                response_data.service = "luajit"
            end
            local json = json_encode(response_data)
            local response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: "..#json.."\r\n\r\n"..json
            client:send(response)
        end
        client:close()
    end
end
