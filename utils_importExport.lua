----------------------------------------------------------
-- This file is for import/export functions for the addon
----------------------------------------------------------

local PSK = select(2, ...)
local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")

--------------------------------------------
-- Add Import/Export Section to Settings Tab
--------------------------------------------

-- function PSK:ExportLists()
    -- -- Format the lists with one name per line, comma-separated
    -- local function formatList(list)
        -- local formatted = {}
        -- for _, name in ipairs(list or {}) do
            -- table.insert(formatted, name .. ",")
        -- end
        -- return table.concat(formatted, "\n")
    -- end
    
    -- local mainList = formatList(PSKDB.MainList or {})
    -- local tierList = formatList(PSKDB.TierList or {})
    
    -- return mainList, tierList
-- end



--------------------------------------------
-- Export readable lists (for Discord, etc)
--------------------------------------------

-- function PSK:ExportReadableLists()
	-- local function formatList(list)
		-- local output = {}
		-- for i, entry in ipairs(list or {}) do
			-- local name, class, date

			-- if type(entry) == "table" then
				-- name = entry.name or "Unknown"
				-- class = entry.class
				-- date = entry.dateLastRaided
			-- else
				-- name = tostring(entry)
			-- end

			-- -- Try to get missing data from PSKDB.Players
			-- if name and (not class or class == "UNKNOWN") then
				-- local playerData = PSKDB.Players and PSKDB.Players[name]
				-- if playerData then
					-- class = playerData.class or "UNKNOWN"
					-- date = date or playerData.dateLastRaided
				-- end
			-- end

			-- -- Default fallbacks
			-- class = class or "UNKNOWN"
			-- date = date or "Never"

			-- table.insert(output, string.format("%d, %s, %s, %s", i, name, class, date))
		-- end
		-- return table.concat(output, "\n")
	-- end

	-- local main = formatList(PSKDB.MainList)
	-- local tier = formatList(PSKDB.TierList)
	-- return main, tier
-- end



-------------------------------------
-- Cleans a PSK list for serializing
-------------------------------------

-- local function cleanList(list)
    -- local result = {}
    -- for _, entry in ipairs(list or {}) do
        -- local name = entry.name or entry
        -- table.insert(result, {
            -- name = name,
            -- class = (entry.class or (PSKDB.Players and PSKDB.Players[name] and PSKDB.Players[name].class)) or "UNKNOWN",
            -- dateLastRaided = entry.dateLastRaided or "Never"
        -- })
    -- end
    -- return result
-- end


--------------------------------------------
-- Validates and normalizes table structure
--------------------------------------------

-- local function sanitizeList(data)
    -- local cleaned = {}
    -- for _, entry in ipairs(data) do
        -- -- Fix nested tables if needed
        -- if type(entry.name) == "table" then
            -- entry = entry.name
        -- end

        -- table.insert(cleaned, {
            -- name = entry.name or "Unknown",
            -- class = entry.class or "UNKNOWN",
            -- dateLastRaided = entry.dateLastRaided or "Never"
        -- })
    -- end
    -- return cleaned
-- end




---------------------------
-- Export/Import PSK Tier List
---------------------------


-- function PSK:ExportPSKTierList()
    -- local cleanedList = cleanList(PSKDB.TierList)

    -- local serialized = LibSerialize:Serialize(cleanedList)
    -- local compressed = LibDeflate:CompressDeflate(serialized)
    -- local encoded = LibDeflate:EncodeForPrint(compressed)

    -- return encoded
-- end

-- function PSK:ImportPSKTierList(encoded)
    -- local compressed = LibDeflate:DecodeForPrint(encoded)
    -- if not compressed then print("Invalid encoded string") return end

    -- local serialized = LibDeflate:DecompressDeflate(compressed)
    -- if not serialized then print("Failed to decompress") return end

    -- local success, data = LibSerialize:Deserialize(serialized)
    -- if not success then print("Failed to deserialize") return end

    -- PSKDB.TierList = sanitizeList(data)
    -- PSK:DebouncedRefreshPlayerLists()
    -- print("[PSK] Tier list successfully imported.")
-- end


---------------------------
-- Export/Import PSK Main List
---------------------------

-- function PSK:ExportPSKMainList()
    -- local cleanedList = cleanList(PSKDB.MainList)

    -- local serialized = LibSerialize:Serialize(cleanedList)
    -- local compressed = LibDeflate:CompressDeflate(serialized)
    -- local encoded = LibDeflate:EncodeForPrint(compressed)

    -- return encoded
-- end

-- function PSK:ImportPSKMainList(encoded)
    -- local compressed = LibDeflate:DecodeForPrint(encoded)
    -- if not compressed then print("Invalid encoded string") return end

    -- local serialized = LibDeflate:DecompressDeflate(compressed)
    -- if not serialized then print("Failed to decompress") return end

    -- local success, data = LibSerialize:Deserialize(serialized)
    -- if not success then print("Failed to deserialize") return end

    -- PSKDB.MainList = sanitizeList(data)
    -- PSK:DebouncedRefreshPlayerLists()
    -- print("[PSK] Main list successfully imported.")
-- end
