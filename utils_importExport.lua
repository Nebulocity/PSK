----------------------------------------------------------
-- This file is for import/export functions for the addon
----------------------------------------------------------

local PSK = select(2, ...)

--------------------------------------------------
-- Export a list in a readable format for players
--------------------------------------------------

function PSK:ExportReadableList(listType)
	local list = (listType == "Tier") and PSKDB.tierList or PSKDB.MainList
	
	if not list then return "" end
	
	local output = {}
	
	for i, entry in ipairs(list) do
		local name = entry.name or "Unknown"
		local class = entry.class or "UNKNOWN"
		local date = entry.dateLastRaided or "Never"
		
		table.insert(output, string.format("%d, %s, %s, %s", i, name, class, date))
		
	end
	
	return table.concat(output, "\n")
end


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


-------------------------------------------
-- Import Lists from Separate Text Boxes
-------------------------------------------

function PSK:ImportLists()
    local mainText = PSK.MainListEditBox:GetText()
    local tierText = PSK.TierListEditBox:GetText()

    -- Clear current lists
    PSKDB.MainList = {}
    PSKDB.TierList = {}

    -- Get all guild members
    local guildMembers = {}
    if IsInGuild() then
        for i = 1, GetNumGuildMembers() do
            local fullName = GetGuildRosterInfo(i)
            if fullName then
                local shortName = Ambiguate(fullName, "short")
                guildMembers[shortName:lower()] = true
            end
        end
    end

    -- Import Main List
    for name in mainText:gmatch("[^,\n]+") do
        local trimmedName = name:match("^%s*(.-)%s*$")
        if trimmedName ~= "" then
			table.insert(PSKDB.MainList, trimmedName)
        end
    end

    -- Import Tier List
    for name in tierText:gmatch("[^,\n]+") do
        local trimmedName = name:match("^%s*(.-)%s*$")
        if trimmedName ~= "" then
			table.insert(PSKDB.TierList, trimmedName)
        end
    end

    -- Update the UI
    PSK:DebouncedRefreshPlayerList()
    print("[PSK] Import complete. Main List: " .. #PSKDB.MainList .. " players, Tier List: " .. #PSKDB.TierList .. " players.")
end
