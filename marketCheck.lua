-- Made by Sova
local M = { market = "Loading" }

local function getVehicleConfigPart()
	if (not v.config.partConfigFilename) then return "" end
	return v.config.partConfigFilename:gsub("vehicles/", "")
end

-- Reading a JSON file from a path
local function readJsonFile(filePath)
	local file = io.open(filePath, "r")
	if not file then
		-- log("E", "Market_check", "Failed to open file " .. filePath)
		return nil
	end

	local content = file:read("*a")
	file:close()

	local data, pos, err = json.decode(content, 1, nil)
	if err then
		-- log("E", "Market_check", "JSON parsing error: " .. err)
		return nil
	end

	return data
end


-- Market definition by the Description variable
local function detectMarket(description)
	if not description then return nil end
	if description:match("JDM") then
		return "JDM"
	elseif description:match("USDM") then
		return "USDM"
	elseif description:match("EUDM") then
		return "EUDM"
	else
		return nil
	end
end

-- Define market by country if Description variable is not found
local function detectMarketByCountry(country)
	if not country then return "Other" end
	country = country:lower()
	if country:match("japan") then
		return "JDM"
	elseif country:match("usa") or country:match("united States") then
		return "USDM"
	elseif country:match("europe") or country:match("germany") or country:match("france") then
		return "EUDM"
	else
		return "Other"
	end
end

-- Main function
local function getVehiclePreset()
	local vehConfig = getVehicleConfigPart()
	if vehConfig == "" then return end

	-- Separate path and file name
	local path, name = vehConfig:match("([^/]+)/([^/]+)%.pc")
	if not path or not name then
		-- log("E", "Market_check", "The path or file name could not be parsed")
		return
	end

	-- Forming a name for the JSON file
	local jsonFileName = "info_" .. name .. ".json"
	local jsonConfFilePath = "vehicles/" .. path .. "/" .. jsonFileName
	local jsonCarFilePath = "vehicles/" .. path .. "/" .. "info.json"

	-- Reading JSON for a specific vehicle
	local data = readJsonFile(jsonConfFilePath)
	local market

	if data then
		-- First, we try to define the market by Description variable
		market = detectMarket(data.Description)
	end

	if not market then
		-- If not found, read the general info.json
		local infoData = readJsonFile(jsonCarFilePath)
		if infoData and infoData.Country then
			market = detectMarketByCountry(infoData.Country)
		else
			market = "Other"
		end
	end
	M.market = market

	-- log("I", "Market_check", "Spawned car: " .. vehConfig .. " | Market: " .. market)

	extensions.hook("marketAvailable", market)

    return market
end

local function onExtensionLoaded()
	electrics.values.sConfig = getVehiclePreset()
end

M.onExtensionLoaded	= onExtensionLoaded
return M