-- Utility function to find an available modem
local function findModem()
    for _, side in ipairs(peripheral.getNames()) do
        if peripheral.getType(side) == "modem" and peripheral.call(side, "isWireless") then
            return side
        end
    end
    return nil
end

-- Server Program: ping_server.lua
local protocol = "ping_protocol"

-- Find and open the modem
local modemSide = findModem()
if not modemSide then
    error("No modem found!")
end
rednet.open(modemSide)
rednet.host(protocol, "PingServer")

print("Ping server started, hosting protocol:", protocol)

-- Get server's own GPS position
local function getPosition()
    local x, y, z = gps.locate(2)  -- Wait up to 2 seconds for GPS to respond
    if x then
        return { x = x, y = y, z = z }
    else
        print("Failed to get GPS location.")
        return nil
    end
end

while true do
    -- Wait for a message with the protocol
    local senderID, message, receivedProtocol = rednet.receive(protocol)
    
    -- If the message is "ping", respond back with "pong" and the server's position
    if message == "ping" then
        local position = getPosition()
        if position then
            rednet.send(senderID, { response = "pong", position = position }, protocol)
        else
            rednet.send(senderID, { response = "pong", position = nil }, protocol)  -- Indicate position unavailable
        end
    end
end
