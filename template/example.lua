--This file is licensed under the Apache License 2.0
--Copyright (c) GIRC 2022
--For a documented version please look at the "template.lua" file

local vars =
{
    screen_table = {
        "55fff663-f3d1-464c-8ad6-1c73ba86f16a",
        {
            "94cec5a2-10f4-4a4a-b889-86b3e67a1951",
            "ca8e3ec7-55b6-4ab9-950f-688d9a30644c"
        }
    },
    station_server_url = "girc.eu:1337",
    station_name = "Gro%C3%9Fpostwitz",
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

local function makeRequest(url)
    local infos = internet.request(url)
    local result = ""
    for chunk in infos do result = result .. chunk end
    return json.decode(result)
end

local function writeToScreen(net_adress, platform_number, station_name)
    local platform_lines = makeRequest(Request_url .. "/lines/" .. tostring(platform_number))
    gpu.bind(net_adress)
    gpu.setResolution(25, 8,25)
    --Next line (probably commented) is for debugging, to see the error message
    --gpu.setResolution(100, 50)
    gpu.setBackground(colors.dark_blue)
    term.clear()
    local j = 1
    local offset = 0
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
