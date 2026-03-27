-- PolyRaft LuaJIT Consensus (Simplified)
local socket = require("socket")

local config = {
    node_id = "luajit_consensus",
    port = 5003,
    heartbeat_interval = 0.1,
    election_timeout = 0.5,
}

local state = {
    current_state = "follower",
    current_term = 0,
    leader_id = nil,
    last_heartbeat = socket.gettime(),
}

local function become_candidate()
    state.current_term = state.current_term + 1
    print(string.format("[Term %d] Becoming CANDIDATE", state.current_term))
    state.current_state = "candidate"
end

local function become_leader()
    print(string.format("[Term %d] Becoming LEADER!", state.current_term))
    state.current_state = "leader"
    state.leader_id = config.node_id
end

local function check_election_timeout()
    local now = socket.gettime()
    if state.current_state ~= "leader" and 
       (now - state.last_heartbeat) > config.election_timeout then
        become_candidate()
        -- Simulate winning election
        become_leader()
        state.last_heartbeat = now
    end
end

local function send_heartbeat()
    if state.current_state == "leader" then
        print(string.format("[Term %d] Heartbeat", state.current_term))
    end
end

local function simple_json(data)
    -- Very simple JSON encoder
    local result = "{"
    local first = true
    for k, v in pairs(data) do
        if not first then result = result .. "," end
        first = false
        result = result .. string.format('"%s":"%s"', k, tostring(v))
    end
    return result .. "}"
end

local function start_server()
    local server = socket.bind("*", config.port)
    server:settimeout(0.01)
    
    print("═══════════════════════════════════════")
    print("  PolyRaft LuaJIT Consensus")
    print("  Port: " .. config.port)
    print("═══════════════════════════════════════")
    print("\nLuaJIT consensus ready!")
    print("  State: " .. state.current_state)
    
    local last_heartbeat = socket.gettime()
    
    while true do
        local client = server:accept()
        if client then
            client:settimeout(1)
            local request = client:receive("*l")
            if request then
                local response = simple_json({
                    service = "polyraft-consensus",
                    status = "healthy",
                    state = state.current_state,
                    term = state.current_term,
                    leader = state.leader_id or "none"
                })
                local http = string.format(
                    "HTTP/1.1 200 OK\r\n" ..
                    "Content-Type: application/json\r\n" ..
                    "Access-Control-Allow-Origin: *\r\n" ..
                    "Content-Length: %d\r\n\r\n%s",
                    #response, response
                )
                client:send(http)
            end
            client:close()
        end
        
        local now = socket.gettime()
        check_election_timeout()
        
        if now - last_heartbeat > config.heartbeat_interval then
            if state.current_state == "leader" then
                send_heartbeat()
            end
            last_heartbeat = now
        end
        
        socket.sleep(0.01)
    end
end

print("Starting PolyRaft LuaJIT Consensus...")
start_server()
