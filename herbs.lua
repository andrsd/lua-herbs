--
-- herbs.lua
-- David Andrs, 2016
--

-- When announce watering is needed (between 0 and 1)
THRESHOLD = 0.5
-- Include config
dofile("config.lua")

-- MCP3008
MCP3008 = require("MCP3008")

MISO = 6  --> GPIO12
MOSI = 5  --> GPIO14
CLK = 7   --> GPIO13
CS = 0    --> GPIO16
mcp = MCP3008.new(CLK, MOSI, MISO, CS)

-- Herbs
herb_name = {
	"thyme",
	"sage",
	"basil"
	"parsley",
	"chives",
	"rosemary"
}


dry = { }
for i, name in ipairs(herb_name) do
	local status, value = mcp:read(i)
	if status == MCP3008.OK then
		local percent = value / 1023.0;
		print(string.format("CH%d = %.02f\r\n", i, percent))
		if percent < THRESHOLD then
			table.insert(dry, name)
		end
	else
		print("Error reading CH0\r\n")
	end
end

if #dry > 0 then
	-- Form the message
	local msg = { }
	if #dry == 1 then
		table.insert(msg, dry[0])
		table.insert(msg, " needs water.")
	else
		for i, name in ipairs(dry) do
			table.insert(msg, name)
			if i < #dry - 1 then
				table.insert(msg, ", ")
			elseif i < #dry then
				table.insert(msg, " and ")
			end
		end
		table.insert(msg, " need water.")
	end
	msg = table.concat(msg, "")

	-- connect to WIFI
	wifi.setmode(wifi.STATION)
	wifi.sta.config(WIFI_SSID, WIFI_PASSWD)
	attempts = 0
	repeat
		attempts++
		wifi.sta.connect()
		-- wait 1 second
		tmr.delay(1000000)
	until wifi.sta.status() == STAMODE.STATION_GOT_IP or attempts == 10

	-- Send HTTP event
	if wifi.sta.status() == STAMODE.STATION_GOT_IP then
		if MAKER_KEY ~= "" then
			local url = string.format("https://maker.ifttt.com/trigger/herbs/with/key/%s", MAKER_KEY)
			local headers = "Content-Type: application/json\r\n"
			local body = string.format("'{ \"value1\" : \"%s\" }'", msg)
			http.post(url, headers, body, nil)
		end
		wifi.sta.disconnect()
	end
end
