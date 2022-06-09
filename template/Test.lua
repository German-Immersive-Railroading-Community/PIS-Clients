local event = require "event"
local term = require "term"
local internet = require "internet"
local json = require "json"
local variables = require "variables"
while true do
    os.sleep(5)
    local infos = internet.request(variables.station_server_url)
    local result = ""
    for chunk in infos do result = result..chunk end
    local decoded = json.decode(result)
    print(decoded["stations"][1]["name"])
end
