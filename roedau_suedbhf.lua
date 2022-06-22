--This file is licensed under the Apache License 2.0
--Copyright (c) GIRC 2022
--For a documented version please look at the "template.lua" file

local vars =
{
    screen_table = {
        {
            "1ccee37d-3f3c-411b-9a78-84ac658370d2",
            "871d47d4-baae-4eb1-9763-3a27977d9c24",
            "729dde66-ce28-4ae3-a8c8-e5398761eaa0"
        },
        {
            "e5d9ab56-a178-4532-95ef-d5a68cde00dc",
            "2e71e531-754b-461c-b66e-b4a6ef54d2aa",
            "780239db-daff-44e7-b767-a0b878d84d7d"
        },
        {
            "3722c79f-97e5-46c3-a544-f8e316381102",
            "7c0cc0d5-0e52-423f-a265-4f45f6210c02",
            "e2d134d9-2d79-4e81-9071-82283d7ef1da"
        }
    },
    station_server_url = "girc.eu:1337",
    station_name = "R%C3%B6dau_S%C3%BCdbahnhof",
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
