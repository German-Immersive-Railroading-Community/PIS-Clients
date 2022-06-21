--This file is licensed under the Apache License 2.0
--Copyright (c) GIRC 2022
--For a documented version please look at the "template.lua" file

local vars =
{
    screen_table = {
        {
            "bf04027b-60f8-454d-8b0d-61bf70fcffbe",
            "5519b17f-f568-48ea-b6b4-39871631c374"
        },
        {
            "b2fecfe2-7d88-4374-8a40-870066eb8837",
            "fb5dc77d-75fe-4c45-94e5-c0030d602da9"
        }
    },
    station_server_url = "http://girc.eu:1337",
    station_name = "B%C3%A4rnbach",
    refresh_time = 30
}

local gpu = require("component").gpu
local term = require "term"
local internet = require "internet"
local json = require "json"

local colors = {
    white = 0xffffff,
    dark_red = 0x85094d,
    green = 0x2e990b,
    blue = 0x0373fc,
    black = 0x000000,
    orange = 0xc28d11
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
    gpu.setResolution(40,8.5)
    --Next line (probably commented) is for debugging, to see the error message
    --gpu.setResolution(100, 50)
    gpu.setBackground(colors.black)
    term.clear()
    local j = 1
    local offset = 0
    gpu.setForeground(colors.white)
    term.setCursor(1,2)
    term.write("Folgende:")
    for k, line in pairs(platform_lines) do
        if line.displayName == nil then break end
        local y = 0+offset*2*j
        gpu.setForeground(colors.blue)
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
                    gpu.setForeground(colors.orange)
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
