--This is template file from which a PC can be set up

local gpu = require("component").gpu
local term = require "term"
local internet = require "internet"
local json = require "json"

local vars = 
    {
        --The table which keeps the screen-net-adresses of every platform
        --This is unique for every station
        screen_table = {
            "Net-Adress of screen of platform 1",
            "Net-Adress of screen of platform 2",
            --next example is for a platform (3 in this case) with multiple screens
            {
                "Net-Adress of screen 1 of platform 3",
                "Net-Adress of screen 2 of platform 3",
                "Net-Adress of screen 3 of platform 3"
            },
            "Net-Adress of screen of platform 4"
        },

        --The URL (IP *should* work too) of the server running a PIS server instance
        --This probably is the same for every ingame PC, except you have multiple PIS instances
        station_server_url = "url.stations.server(:port)",

        --The internal station name that is registered on the server
        --Attention: This is NOT the display name
        station_name = "StationNameOnServer"
}

local function writeToScreen(net_adress, platform_lines)
    gpu.bind(net_adress)
    gpu.setResolution(25, 8,25)
    --gpu.setResolution(100, 50)
    gpu.setBackground(0x050cb5)
    gpu.setForeground(0xffffff)
    term.clear()
    local j = 1
    local offset = 0
    for k, line in pairs(platform_lines) do
        if line.displayName == nil then break end
        -- Linienname, Abfahrt, Verspätung, Gleisverlegung, Ausfall
        term.setCursor(0, 0+offset*2*j)
        term.write(line.displayName)
        gpu.setForeground(0x2e990b)
        term.write(" " .. line.departure)
        if tonumber(line.delay) ~= 0 then
            gpu.setForeground(0x85094d)
            local delay = ""
            if tonumber(line.delay) > 0 then delay = "+" .. line.delay else delay = line.delay end
            term.write(" " .. delay)
        end
        if j == 4 then break end
        j = j + 1
        offset = 1
    end
end

local function makeRequest(url)
    local infos = internet.request(url)
    local result = ""
    for chunk in infos do result = result .. chunk end
    return json.decode(result)
end

gpu.setForeground(0xffffff)
local request_url = vars.station_server_url .. "/api/station/" .. vars.station_name
local infos = makeRequest(request_url)

-- Goes trough all the platforms the station has
for i = 1, tonumber(infos["platforms"]), 1 do
    local platform_lines = makeRequest(request_url .. "/lines/" .. tostring(i))
    local net_adress = vars["screen_table"][i]
    --Checks if the platform has multiple screens
    if type(net_adress) == "table" then
        for key, subscreen_net_adress in pairs(net_adress) do
            writeToScreen(subscreen_net_adress, platform_lines)
        end
    else
        writeToScreen(net_adress, platform_lines)
    end
end

os.exit()
