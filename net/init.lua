---@type RemosInternalAPI
local _remos = getmetatable(remos)

local function log(...)
    local args = {...}
    for i = 1, #args do
        args[i] = tostring(args[i])  -- Ensure each argument is a string
    end

    remos.notification("o", table.concat(args, " "))
end

local function findModem()
    for _, side in ipairs(peripheral.getNames()) do
        if peripheral.getType(side) == "modem" and peripheral.call(side, "isWireless") then
            return side
        end
    end
    return nil
end

-- Client Program: ping_client.lua
local protocol = "ping_protocol"
local pingInterval = 5  -- seconds between pings

-- Find and open the modem
local modemSide = findModem()
if not modemSide then
    error("No modem found!")
end
rednet.open(modemSide)

-- Function to get the client's GPS position
local function getPosition()
    local x, y, z = gps.locate(2)  -- Wait 2 seconds for a response
    if x then
        return { x = x, y = y, z = z }
    else
        log("Failed to get GPS location.")
        return nil
    end
end

-- Calculate Euclidean distance between two points
local function calculateDistance(pos1, pos2)
    return math.sqrt((pos2.x - pos1.x)^2 + (pos2.y - pos1.y)^2 + (pos2.z - pos1.z)^2)
end

local function sendPing(serverID)
    -- Send a ping to each server
    rednet.send(serverID, "ping", protocol)

    -- Wait for a response containing the server's position
    return rednet.receive(protocol, 3)
end

-- Ping the nearest server
local function pingNearestServer()
    -- Lookup all computers hosting the specified protocol
    local servers = {rednet.lookup(protocol)}
    if not servers then
        log("No servers found for protocol:", protocol)
        return
    end

    -- Get the client's position
    local clientPosition = getPosition()
    if not clientPosition then return end

    -- Find the nearest server by distance
    local nearestServer = nil
    local nearestDistance = math.huge  -- Start with a large number


    for _, serverID in ipairs(servers) do
        local id, message = sendPing(serverID)
    
        if id == serverID and type(message) == "table" and message.response == "pong" and message.position then
            -- Calculate the distance to this server
            local distance = calculateDistance(clientPosition, message.position)
            if distance < nearestDistance then
                nearestServer = serverID
                nearestDistance = distance
            end
        end
    end

    -- Ping the nearest server if found
    if nearestServer then
        log("Nearest server ID:", nearestServer, "at distance:", nearestDistance)
    else
        log("No nearby servers found with valid positions.")
    end
end

-- Main loop to ping periodically
while true do
    pingNearestServer()
    sleep(pingInterval)
end
