----------------------------------------------------------
-- This file is for import/export functions for the addon
----------------------------------------------------------

local PSK = select(2, ...)
local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")


------------------------------------------
-- Export readable lists (for Discord, etc)
------------------------------------------

function PSK:ExportReadableLists()
	local function formatList(list)
		local output = {}
		table.insert(output, string.format("#  %-14s %-10s %s", "Name", "Class", "Last Raided"))

		for i, entry in ipairs(list or {}) do
			local name, class, date

			if type(entry) == "table" then
				name = entry.name or "Unknown"
				class = entry.class or "Unknown"
				date = entry.dateLastRaided or "Never"
			else
				name = tostring(entry)
				class = "Unknown"
				date = "Never"
			end

			-- Capitalize first letter only
			class = class:lower():gsub("^%l", string.upper)

			table.insert(output, string.format("%-2d %-14s %-10s %s", i, name, class, date))
		end

		return "\n" .. table.concat(output, "\n") .. "\n"
	end

	local main = "**Main List**\n" .. formatList(PSKDB.MainList)
	local tier = "**Tier List**\n" .. formatList(PSKDB.TierList)

	return main, tier
end






-------------------------------------
-- Cleans a PSK list for serializing
-------------------------------------

local function cleanList(list)
    local result = {}
    for _, entry in ipairs(list or {}) do
        local name = entry.name or entry
        table.insert(result, {
            name = name,
            class = (entry.class or (PSKDB.Players and PSKDB.Players[name] and PSKDB.Players[name].class)) or "UNKNOWN",
            dateLastRaided = entry.dateLastRaided or "Never"
        })
    end
    return result
end


--------------------------------------------
-- Validates and normalizes table structure
--------------------------------------------

local function sanitizeList(data)
    local cleaned = {}
    for _, entry in ipairs(data) do
        -- Fix nested tables if needed
        if type(entry.name) == "table" then
            entry = entry.name
        end

        table.insert(cleaned, {
            name = entry.name or "Unknown",
            class = entry.class or "UNKNOWN",
            dateLastRaided = entry.dateLastRaided or "Never"
        })
    end
    return cleaned
end



-------------------------------
-- Gets a player's Class
-------------------------------

function PSK:GetClassForPlayer(name)
	GuildRoster() -- ensure it's fresh
	local shortName = Ambiguate(name, "short")

	for i = 1, GetNumGuildMembers() do
		local gName, _, _, _, _, _, _, _, _, _, classFile = GetGuildRosterInfo(i)
		if Ambiguate(gName or "", "short") == shortName then
			return classFile or "UNKNOWN"
		end
	end

	return "UNKNOWN"
end



---------------------------
-- Export/Import PSK Tier List
---------------------------


function PSK:ExportPSKTierList()
    local cleanedList = cleanList(PSKDB.TierList)

    local serialized = LibSerialize:Serialize(cleanedList)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)

    return encoded
end

function PSK:ImportPSKTierList(encoded)
    local compressed = LibDeflate:DecodeForPrint(encoded)
    if not compressed then print("Invalid encoded string") return end

    local serialized = LibDeflate:DecompressDeflate(compressed)
    if not serialized then print("Failed to decompress") return end

    local success, data = LibSerialize:Deserialize(serialized)
    if not success then print("Failed to deserialize") return end

    PSKDB.TierList = sanitizeList(data)
	PSKDB.LastUpdated = time()
	print("Time udpated: " .. PSKDB.LastUpdated)
    PSK:DebouncedRefreshPlayerLists()
    print("[PSK] Tier list successfully imported.")
end


---------------------------
-- Export/Import PSK Main List
---------------------------

function PSK:ExportPSKMainList()
    local cleanedList = cleanList(PSKDB.MainList)

    local serialized = LibSerialize:Serialize(cleanedList)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)

    return encoded
end

function PSK:ImportPSKMainList(encoded)
    local compressed = LibDeflate:DecodeForPrint(encoded)
    if not compressed then print("Invalid encoded string") return end

    local serialized = LibDeflate:DecompressDeflate(compressed)
    if not serialized then print("Failed to decompress") return end

    local success, data = LibSerialize:Deserialize(serialized)
    if not success then print("Failed to deserialize") return end

    PSKDB.MainList = sanitizeList(data)
	PSKDB.LastUpdated = time()
	print("Time udpated: " .. PSKDB.LastUpdated)
    PSK:DebouncedRefreshPlayerLists()
    print("[PSK] Main list successfully imported.")
end


function PSK:ImportOldStyleList(text)
	GuildRoster()

	local entries = {}

	for line in text:gmatch("[^\r\n]+") do
		
		local name = strtrim(line):gsub("[,]+$", "")

		if name ~= "" then
			table.insert(entries, {
				name = name,
				class = PSK:GetClassForPlayer(name),
				dateLastRaided = "Never",
			})
		end
	end
	
	PSKDB.LastUpdated = time()
	
	return entries
end


-------------------------------------------------
-- Imports a flat, comma-separated list of naems
-------------------------------------------------

function PSK:ImportOldPSKMainList(text)
	local data = PSK:ImportOldStyleList(text)
	PSKDB.MainList = data
	PSKDB.LastUpdated = time()
	print("Time udpated: " .. PSKDB.LastUpdated)
	PSK:DebouncedRefreshPlayerLists()
	print("[PSK] Old-style Main list imported.")
end



function PSK:ImportOldPSKTierList(text)
	local data = PSK:ImportOldStyleList(text)
	PSKDB.TierList = data
	PSKDB.LastUpdated = time()
	print("Time udpated: " .. PSKDB.LastUpdated)
	PSK:DebouncedRefreshPlayerLists()
	print("[PSK] Old-style Tier list imported.")
end


-------------------------------------------------
-- For Exporting/Importing loot drops 
-------------------------------------------------


function PSK:ExportPSKLootDrops()
    local LibSerialize = LibStub("LibSerialize")
    local LibDeflate = LibStub("LibDeflate")

    local data = PSKDB.LootDrops or {}
    local serialized = LibSerialize:Serialize(data)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)

    return encoded
end

function PSK:ImportPSKLootDrops(encoded)
    local LibSerialize = LibStub("LibSerialize")
    local LibDeflate = LibStub("LibDeflate")

    local compressed = LibDeflate:DecodeForPrint(encoded)
    if not compressed then print("[PSK] Invalid encoded string") return end

    local serialized = LibDeflate:DecompressDeflate(compressed)
    if not serialized then print("[PSK] Failed to decompress loot data") return end

    local success, data = LibSerialize:Deserialize(serialized)
    if not success then print("[PSK] Failed to deserialize loot data") return end

    PSKDB.LootDrops = data or {}
    PSK:DebouncedRefreshLootList()
    print("[PSK] Loot drops successfully imported.")
end
