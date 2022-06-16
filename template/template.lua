--This is template file from which a PC can be set up
--This file is licensed under the Apache License 2.0
--Copyright (c) GIRC 2022

--The only table you'll ever need to edit in order for the program to work
local vars =
    {
        --The table which keeps the screen-net-adresses of every platform
        --This is unique for every station
        --Attention: The first entry will be the first platform, the second the second platform and so on
        screen_table = {
            "Net-Adress of screen of platform 1",
            "Net-Adress of screen of platform 2",
            --Next example is for a platform (3 in this case) with multiple screens
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
        station_name = "StationNameOnServer",

        --How often in seconds the platforms should be refreshed
        --Must be an integer
        refresh_time = 30
    }

local gpu = require("component").gpu
local term = require "term"
local internet = require "internet"
local json = require "json"

local colors = {
    dark_blue = 0x050cb5,
    white = 0xffffff,
    dark_red = 0x85094d,
    green = 0x2e990b
}

--Makes a request and gives its body back as a json object
local function makeRequest(url)
    local infos = internet.request(url)
    local result = ""
    for chunk in infos do result = result .. chunk end
    return json.decode(result)
end

--Writes the lines of a platform from a station to a specified screen
local function writeToScreen(net_adress, platform_number, station_name)
    local platform_lines = makeRequest(Request_url .. "/lines/" .. tostring(platform_number))
    gpu.bind(net_adress)
    gpu.setResolution(25, 8,25)
    gpu.setBackground(colors.dark_blue)
    term.clear()
    local j = 1
    local offset = 0
    --Writes the lines to the current screen, max 3 because of 3*2+1=7 > no more room
    --since vertical resolution is 8,25 (see above)
    for k, line in pairs(platform_lines) do
        if line.displayName == nil then break end
        local y = 0+offset*2*j
        gpu.setForeground(colors.white)
        term.setCursor(1, y)
        term.write(line.displayName)
        gpu.setForeground(colors.green)
        term.write(" " .. line.departure)
        if tonumber(line.delay) ~= 0 then
            gpu.setForeground(colors.dark_red)
            local delay = ""
            if tonumber(line.delay) > 0 then delay = "+" .. line.delay else delay = line.delay end
            term.write(delay)
        end
        --Handles anomalies (canceled trains, ...)
        for k, station in pairs(line.stations) do
            if station["station"]["name"] == station_name then
                if y == 0 then term.setCursor(1, y+2) else term.setCursor(1, y+1) end
                if station.cancelled == true then
                    gpu.setForeground(colors.dark_red)
                    term.write("Dieser Zug entfällt!")
                elseif station.changedPlatform ~= 0 then
                    gpu.setForeground(colors.white)
                    term.write("Verkehrt Bahnsteig " .. tostring(station.changedPlatform))
                end
            end
        end
        if j == 3 then break end
        j = j + 1
        offset = 1
    end
end


gpu.setForeground(colors.white)
Request_url = vars.station_server_url .. "/api/station/" .. vars.station_name
local infos = makeRequest(Request_url)

while true do
    -- Goes trough all the platforms the station has
    --Nil-check for good measurement
    if infos == nil then error("No information for the station available") end
    for i = 1, tonumber(infos["platforms"]), 1 do
        local net_adress = vars["screen_table"][i]
        --Checks if the platform has multiple screens
        if type(net_adress) == "table" then
            for key, subscreen_net_adress in pairs(net_adress) do
                writeToScreen(subscreen_net_adress, i, infos.name)
            end
        else
            writeToScreen(net_adress, i, infos.name)
        end
    end
    os.sleep(vars.refresh_time)
end
