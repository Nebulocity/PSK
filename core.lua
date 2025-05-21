-- core.lua


local PSK = select(2, ...)

-- Ensure PSKDB is initialized correctly
if not PSKDB then PSKDB = {} end
if not PSKDB.Settings then PSKDB.Settings = {} end
if not PSKDB.MainList then PSKDB.MainList = {} end
if not PSKDB.TierList then PSKDB.TierList = {} end
if not PSKDB.Players then PSKDB.Players = {} end
if not PSKDB.LootLogs then PSKDB.LootLogs = {} end

_G.PSKGlobal = _G.PSKGlobal or {}
PSKGlobal.LootDrops = PSKGlobal.LootDrops or {}
PSK.LootDrops = PSKGlobal.LootDrops

-- Copy settings to table
PSK.Settings = CopyTable(PSKDB.Settings)

-- Set default loot threshold if not present
if not PSKDB.Settings.lootThreshold then
    PSK.Settings.lootThreshold = PSK.Settings.lootThreshold or GetLootThreshold() or 3
	PSKDB.Settings.lootThreshold = PSK.Settings.lootThreshold
end

-- Main Variables
BiddingOpen = false
PSK.BidEntries = {}
PSK.CurrentList = "Main"

----------------------------------------
-- Zug zug
----------------------------------------

function PSK:PlayRandomPeonSound()
    if not PSK.Settings or not PSK.Settings.buttonSoundsEnabled then
        return false
    end

    local normalSounds = {
        "Sound\\Creature\\Peon\\PeonYes1.ogg",
        "Sound\\Creature\\Peon\\PeonYes2.ogg",
    }
    local rareSound = "Sound\\Creature\\Peon\\PeonWhat3.ogg"

    if math.random(1, 100) <= 5 then
        PlaySoundFile(rareSound)
        return true
    else
        PlaySoundFile(normalSounds[math.random(1, #normalSounds)])
        return false
    end
end



----------------------------------------
-- Record Loot 
----------------------------------------

----------------------------------------
-- Event frame for loot master looting
----------------------------------------

local lootViewFrame = CreateFrame("Frame")
lootViewFrame:RegisterEvent("LOOT_OPENED")

lootViewFrame:SetScript("OnEvent", function(self, event, autoLoot)
    if not PSK.LootRecordingActive then return end
	
    --if not IsMasterLooter() then return end  -- Only record if you're the ML

	local numItems = GetNumLootItems()
	local lootLinks = {}

	for i = 1, numItems do
		if LootSlotHasItem(i) then
			local itemLink = GetLootSlotLink(i)
			if itemLink then
				table.insert(lootLinks, itemLink)

				C_Timer.After(0.1, function()
					local name, _, rarity, _, _, _, _, _, _, icon = GetItemInfo(itemLink)
					local threshold = PSK.Settings.lootThreshold or 3
					if rarity and rarity >= threshold then
						local playerName = UnitName("player")
						local class = PSKDB.Players[playerName] and PSKDB.Players[playerName].class or "SHAMAN"

						table.insert(PSKGlobal.LootDrops, {
							itemLink = itemLink,
							itemTexture = icon,
							player = playerName,
							class = class,
							timestamp = date("%I:%M %p %m/%d/%Y")
						})

						PSK:DebouncedRefreshLootList()
						if PSK.RefreshLogList then
							PSK:DebouncedRefreshLogList()
						end

						print("[PSK] Master Looter viewed loot: " .. itemLink)
					end
				end)
			end
		end
	end

	-- Announce loot bag contents
	if #lootLinks > 0 then
		local message = "[PSK] Loot Bag: " .. table.concat(lootLinks, ", ")
		Announce(message)
	end

end)


-- local lootFrame = CreateFrame("Frame") 
-- lootFrame:RegisterEvent("CHAT_MSG_LOOT")

-- lootFrame:SetScript("OnEvent", function(self, event, msg)
    -- if not PSK.LootRecordingActive then return end

    -- Check if the loot message is for the player
    -- local playerName = UnitName("player")
    -- local youLooted = msg:match("You receive loot: (.+)")
    -- local playerLooted, itemLink = msg:match("^([^%s]+) receives loot: (.+)")

    -- Ignore messages that are not the current player
    -- if playerLooted and playerLooted ~= playerName then
        -- return
    -- end

    -- Use the correct item link based on the message
    -- itemLink = itemLink or youLooted

    -- Process the item if it's valid
    -- if itemLink then
        -- C_Timer.After(0.2, function()
            -- local itemName, _, rarity, _, _, _, _, _, _, icon = GetItemInfo(itemLink)
            -- local threshold = PSK.Settings.lootThreshold or 3

            -- Only record items that meet the threshold
            -- if rarity and rarity >= threshold then
                -- local class = PSKDB.Players[playerName] and PSKDB.Players[playerName].class or "SHAMAN"

                -- table.insert(PSKGlobal.LootDrops, {
                    -- itemLink = itemLink,
                    -- itemTexture = icon,
                    -- player = playerName,
                    -- class = class,
                    -- timestamp = date("%I:%M %p %m/%d/%Y")
                -- })

                -- PSK:DebouncedRefreshLootList()

                -- if PSK.RefreshLogList then
                    -- PSK:RefreshLogList()
                -- end

                -- print("[PSK] Loot recorded: " .. itemLink .. " (" .. playerName .. ")")
            -- end
        -- end)
    -- end
-- end)




--------------------------------------------------------------------
-- Listen for loot method changes, which includes threshold changes
--------------------------------------------------------------------

local thresholdFrame = CreateFrame("Frame")
thresholdFrame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
-- thresholdFrame:RegisterEvent("LOOT_THRESHOLD_CHANGED")
thresholdFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PARTY_LOOT_METHOD_CHANGED" then
        local newThreshold = GetLootThreshold() or 3

        -- Update PSK settings
        PSK.Settings.lootThreshold = newThreshold
        PSKDB.Settings.lootThreshold = newThreshold

        -- Update the UI label
        if PSK.UpdateLootThresholdLabel then
            PSK:UpdateLootThresholdLabel()
        end
    end
end)


----------------------------------------
-- Bidding System 
----------------------------------------

function PSK:StartBidding()
    if BiddingOpen then return end
		
	if not PSK.SelectedItem then
		print("You must select an item before starting bidding.")
		
		if not PSK.Settings or not PSK.Settings.buttonSoundsEnabled then
			return false
		end
	
		PlaySound(SOUNDKIT.GS_TITLE_OPTION_EXIT)
		return
	end

    BiddingOpen = true
    PSK.BidEntries = {}
	
	if PSK.BidButton then
        PSK.BidButton:SetText("Stop Bidding")
		
        if PSK.BidButton.Border then
            PSK.BidButton.Border:SetAlpha(1)
            PSK.BidButton.Border:Show()
            PSK.BidButton.Border.Pulse:Stop()
            PSK.BidButton.Border.Pulse:Play()
        end
    end
	
    local listName = (PSK.CurrentList == "Tier") and "Tier List" or "Main List"
    
	local itemLink = PSK.SelectedItem
	local itemName = GetItemInfo(itemLink) or itemLink
	
    -- Use the full item link for clickable text
	SendChatMessage("[PSK] Bidding has started for " .. itemLink .. "! 20 seconds remaining.", "RAID_WARNING")
	Announce("[PSK] Type 'bid' in /raid, /party, or /whisper to bid.")
	Announce("[PSK] Type 'retract' in /raid, /party, or /whisper to retract.")
	Announce("[PSK] -----------------------------------------------------------------")

    -- Countdown Messages
    local countdownTimes = {20, 15, 10, 5, 4, 3, 2, 1}
    for _, seconds in ipairs(countdownTimes) do
        C_Timer.After(20 - seconds, function()
            if BiddingOpen then
                Announce("[PSK] " .. seconds .. " seconds left to bid on " .. itemLink .. "!")
            end
        end)
    end

    -- Auto-close bidding after 15 seconds
    C_Timer.After(15, function()
        if BiddingOpen then
            PSK:CloseBidding()
        end
    end)

    PSK:DebouncedRefreshBidList()
end


function PSK:CloseBidding()
    BiddingOpen = false
    PSK.BidButton:SetText("Start Bidding")
    PSK:DebouncedRefreshBidList()

    if #PSK.BidEntries == 0 then
		SendChatMessage("[PSK] No bids were placed.", "RAID_WARNING")
    else
		SendChatMessage("[PSK] Bidding closed. Bidders:", "RAID_WARNING")
        local currentList = (PSK.CurrentList == "Tier") and PSKDB.TierList or PSKDB.MainList
		local indexMap = {}
		for i, name in ipairs(currentList) do
			indexMap[name] = i
		end

		-- Sort bids by position in list, unknowns to bottom
		table.sort(PSK.BidEntries, function(a, b)
			local aIndex = indexMap[a.name] or math.huge
			local bIndex = indexMap[b.name] or math.huge
			return aIndex < bIndex
		end)

		for i, entry in ipairs(PSK.BidEntries) do
			local listPos = indexMap[entry.name]
			if listPos then
				Announce(string.format("[PSK] %d. %s (Pos %d)", i, entry.name, listPos))
			else
				Announce(string.format("[PSK] %d. %s (Not Listed)", i, entry.name))
			end
		end

    end
end

----------------------------------------
-- Auto-Refresh Player Lists on Events
----------------------------------------

-- local eventFrame = CreateFrame("Frame")
-- eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
-- eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
-- eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- eventFrame:RegisterEvent("PLAYER_LOGIN")
-- eventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
-- eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
-- eventFrame:RegisterEvent("PARTY_MEMBER_ENABLE")
-- eventFrame:RegisterEvent("PARTY_MEMBER_DISABLE")
-- eventFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
-- eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

PSK.EventFrame = CreateFrame("Frame")
PSK.EventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
PSK.EventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
PSK.EventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
PSK.EventFrame:RegisterEvent("LOOT_OPENED")

-- eventFrame:SetScript("OnEvent", function(self, event, ...)
    -- -- Force a guild roster refresh
    -- GuildRoster()

    -- -- Update player data
    -- PSK:UpdatePlayerData()

    -- -- Refresh lists
    -- if PSK and PSK.RefreshAvailableMembers then
        -- PSK:DebouncedRefreshAvailablePlayerList()
    -- end
	
    -- if PSK and PSK.RefreshPlayerList then
        -- PSK:RefreshPlayerList()
    -- end
	
	-- if event == "GROUP_ROSTER_UPDATE" then
		-- PSK:RefreshGroupMemberData()
	-- end

-- end)

PSK.EventFrame:SetScript("OnEvent", function(_, event, ...)

    if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_FLAGS_CHANGED" then
        PSK:DebouncedRefreshPlayerList()
        PSK:DebouncedRefreshBidList()
    elseif event == "GUILD_ROSTER_UPDATE" then
		PSK:DebouncedRefreshAvailablePlayerList()
        PSK:DebouncedRefreshPlayerList()
    elseif event == "LOOT_OPENED" then
        PSK:DebouncedRefreshLootList()
        PSK:DebouncedRefreshLogList()
    end
end)

print("[PSK] Auto-Refresh Enabled for Guild, Party, and Raid Events")





------------------------------------------
-- Scan these channels for the word "bid"
------------------------------------------

local chatFrame = CreateFrame("Frame")
chatFrame:RegisterEvent("CHAT_MSG_RAID")
chatFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
chatFrame:RegisterEvent("CHAT_MSG_PARTY")
chatFrame:RegisterEvent("CHAT_MSG_SAY")
chatFrame:RegisterEvent("CHAT_MSG_WHISPER")
chatFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
chatFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")

chatFrame:SetScript("OnEvent", function(self, event, msg, sender)
    if not BiddingOpen then return end
    if not sender then return end

    -- Ignore messages from the addon itself
    if msg:find("^%[PSK%]") then
        return
    end

    -- Strip realm name if present
    local simpleName = Ambiguate(sender, "short")
    msg = msg:lower()

    -- Handle bid messages
    if msg:find("bid") then
        AddBid(simpleName)
    end
	
    -- Handle retract messages
    if msg:find("retract") then
        RetractBid(simpleName)
    end
end)


------------------------------------------
-- Add a bid, including unlisted players
------------------------------------------

function AddBid(name)
    if not name then return end

    -- Prevent duplicate bids
    for _, entry in ipairs(PSK.BidEntries) do
        if entry.name == name then
            return -- Already bid
        end
    end

    -- Attempt to find the player in the main or tier lists
    local playerData = PSKDB.Players and PSKDB.Players[name]
    local playerInList = false

    local function isPlayerInList(list)
        for index, playerName in ipairs(list) do
            if playerName == name then
                playerInList = true
                return index
            end
        end
        return nil
    end

    local position = isPlayerInList(PSKDB.MainList) or isPlayerInList(PSKDB.TierList) or (#PSK.BidEntries + 1)

    -- Add to BidEntries with a note if they aren't in the main or tier list
    table.insert(PSK.BidEntries, {
        position = position,
        name = name,
        class = playerData and playerData.class or "UNKNOWN",
        online = playerData and playerData.online or false,
        inRaid = playerData and playerData.inRaid or false,
        notListed = not playerInList,
    })

    PSK:DebouncedRefreshBidList()

    -- Print a warning if the player isn't in the lists
    if not playerInList then
        print("[PSK] Warning: " .. name .. " is not in the Main or Tier lists.")
    end
end


------------------------------------------
-- Scan these channels for the word "retract"
------------------------------------------

function RetractBid(name)
    if not name then return end

    for i, entry in ipairs(PSK.BidEntries) do
        if entry.name == name then
            table.remove(PSK.BidEntries, i)
            PSK:DebouncedRefreshBidList()
            return
        end
    end
end


--------------------------------------------------------------
-- Clear the player selection when switching main/tier lists
--------------------------------------------------------------

function PSK:ClearSelection()
    PSK.SelectedPlayer = nil
    PSK.SelectedPlayerRow = nil
    PSK:DebouncedRefreshPlayerList()
end


------------------------------------------
-- Console commands to open addon
------------------------------------------

local slashFrame = CreateFrame("Frame")
slashFrame:RegisterEvent("PLAYER_LOGIN")

slashFrame:SetScript("OnEvent", function()
    SLASH_PSK1 = "/psk"
    SlashCmdList["PSK"] = function(msg)
		msg = msg and msg:lower():gsub("^%s+", "") or ""

		if msg == "help" then
			PSK:PrintHelp()
			return
		elseif msg == "list" then
			PSK:PrintCurrentList()
			return
		end


		if PSK and PSK.MainFrame then
			if PSK.MainFrame:IsShown() then
				PSK.MainFrame:Hide()
			else
				PSK.MainFrame:Show()
			end
		else
			print("PSK: MainFrame is not available yet.")
		end
	end

end)

------------------------------------------
-- Console command to export lists
------------------------------------------

-- SLASH_PSKEXPORT1 = "/pskexport"
-- SlashCmdList["PSKEXPORT"] = function(msg)
    -- msg = msg and msg:lower():gsub("^%s+", "") or ""

    -- if msg == "all" then
        -- PSK:ExportList("Main")
        -- PSK:ExportList("Tier")
    -- else
        -- PSK:ExportList(PSK.CurrentList or "Main")
    -- end
-- end


-- function PSK:ExportList(listType)
    -- local list = (listType == "Tier") and PSKDB.TierList or PSKDB.MainList

    -- if #list == 0 then
        -- print("[PSK] " .. listType .. " list is empty.")
        -- return
    -- end

    -- local exportLine = table.concat(list, ", ")
    -- PSK:ShowExportWindow(exportLine)
-- end

------------------------------------------
-- Console command to print command help
------------------------------------------

function PSK:PrintHelp()
    print(" ")
    print("|cff00ff00[PSK Addon Help]|r")
    print("/psk                     - Toggle the PSK window")
    print("/psk help                - Show this help menu")
    print("/psk list                - Show players in the current list")
    print("/pskadd <top|bottom> <main|tier> <name>    - Add player to a list")
    print("/pskremove <name>        - Remove player from current list")
    print("/pskremove all <name>    - Remove player from both lists")
    -- print("/pskexport               - Export current list as plain text")
	-- print("/pskexport [all]         - Export current or both lists")
    print(" ")
end

------------------------------------------------
-- Print the currently selected list to console
------------------------------------------------

function PSK:PrintCurrentList()
    local listType = PSK.CurrentList or "Main"
    local list = (listType == "Tier") and PSKDB.TierList or PSKDB.MainList

    print(" ")
    print("|cff00ff00[PSK: " .. listType .. " List]|r")

    if #list == 0 then
        print("(Empty)")
        return
    end

    for i, name in ipairs(list) do
        local playerData = PSKDB.Players[name]
        local class = playerData and playerData.class or "UNKNOWN"
        class = string.upper(class)

        local color = CLASS_COLORS[class] or { r = 0.8, g = 0.8, b = 0.8 }
        local hex = string.format("|cff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)

        local status = ""
        if playerData and playerData.online == false then
            status = " |cff888888(offline)|r"
        end

        print(i .. ". " .. hex .. name .. "|r" .. status)
    end
end


------------------------------------------
-- Console command to add a player
-- /pskadd <top|bottom> <main|tier> <name>
------------------------------------------

SLASH_PSKADD1 = "/pskadd"
SlashCmdList["PSKADD"] = function(msg)
    -- Hooray for REGEX!  lol
	local position, listType, name = msg:match("^(%S+)%s+(%S+)%s+(.+)$")

	if not position or not listType or not name then
        print("Usage: /pskadd <top | bottom> <main | tier> <playerName>")
        return
    end

    position = position:lower()
    listType = listType:lower()

    if position ~= "top" and position ~= "bottom" then
        print("Invalid position. Use 'top' or 'bottom'.")
        return
    end

    if listType ~= "main" and listType ~= "tier" then
        print("Invalid list type. Use 'main' or 'tier'.")
        return
    end

    PSK:AddPlayerFromCommand(name, listType, position)
end

-----------------------------------------------------------------
-- Console command to remove a player from main/tier/both lists
-----------------------------------------------------------------

SLASH_PSKREMOVE1 = "/pskremove"
SlashCmdList["PSKREMOVE"] = function(msg)
    local scope, name

    if msg:find("all%s+") then
        scope, name = msg:match("^(all)%s+(%S+)")
    else
        name = msg:match("^(%S+)")
        scope = "current"
    end

    if not name then
        print("Usage: /pskremove <playerName> or /pskremove all <playerName>")
        return
    end

    PSK:RemovePlayerByScope(scope, name)
end

function PSK:RemovePlayerByScope(scope, rawName)
    local nameLower = Ambiguate(rawName, "short"):gsub("%s+", ""):lower()
    local nameProper = rawName:sub(1, 1):upper() .. rawName:sub(2):lower()
    local removed = false

    local function tryRemove(list, listName)
        for i = #list, 1, -1 do
            if Ambiguate(list[i], "short"):lower() == nameLower then
                table.remove(list, i)
                print("[PSK] Removed " .. nameProper .. " from the " .. listName .. " list.")
                return true
            end
        end
        return false
    end

    if scope == "all" then
        removed = tryRemove(PSKDB.MainList, "Main") or removed
        removed = tryRemove(PSKDB.TierList, "Tier") or removed
    else
        local currentList = (PSK.CurrentList == "Tier") and PSKDB.TierList or PSKDB.MainList
        local currentName = (PSK.CurrentList == "Tier") and "Tier" or "Main"
        removed = tryRemove(currentList, currentName)
    end

    if not removed then
        print("[PSK] Could not find " .. nameProper .. " in the specified list(s).")
    end

    PSK:DebouncedRefreshPlayerList()
end

------------------------------------------------
-- Capitalize names that get added to the lists
------------------------------------------------

function PSKCapitalizeName(name)
    return name:sub(1, 1):upper() .. name:sub(2):lower()
end

------------------------------------------
-- Function add player from slash command
------------------------------------------

function PSK:AddPlayerFromCommand(name, listType, position)
    -- Normalize and clean input
    local rawName = Ambiguate(name, "short"):gsub("%s+", "")
    local nameLower = rawName:lower()
    local nameProper = PSKCapitalizeName(rawName)

    -- Check if name is in player
    local foundInPlayer = false
    for i = 1, GetNumGuildMembers() do
        local gName = GetGuildRosterInfo(i)
        if gName and Ambiguate(gName, "short"):lower() == nameLower then
            foundInPlayer = true
            break
        end
    end

    -- Check if name is in raid or party
    local foundInRaidOrParty = false
    local unit = nil

    if IsInRaid() then
        for i = 1, MAX_RAID_MEMBERS do
            local u = "raid" .. i
            if UnitExists(u) and Ambiguate(UnitName(u), "short"):lower() == nameLower then
                foundInRaidOrParty = true
                unit = u
                break
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local u = "party" .. i
            if UnitExists(u) and Ambiguate(UnitName(u), "short"):lower() == nameLower then
                foundInRaidOrParty = true
                unit = u
                break
            end
        end
    end
	
	-- -- Non-guild members can be added.
    -- if not foundInPlayer and not foundInRaidOrParty then
        -- print("[PSK] Error: '" .. nameProper .. "' is not in your player, raid, or party. Cannot add.")
        -- return
    -- end

    -- Choose target list
    local list = (listType == "tier") and PSKDB.TierList or PSKDB.MainList

    -- Check for duplicates
    for _, existing in ipairs(list) do
        if Ambiguate(existing, "short"):lower() == nameLower then
            print("[PSK] " .. nameProper .. " is already in the " .. listType .. " list.")
            return
        end
    end

    -- Add to top or bottom
    if position == "top" then
        table.insert(list, 1, nameProper)
    else
        table.insert(list, nameProper)
    end

    -- Fill in player data if not already in the DB
    if not PSKDB.Players[nameProper] then
        local class = "SHAMAN" 
        local level = "???"
        local zone = "Unknown"
        local online = false
        local inRaid = false

        -- Try guild roster first
        for i = 1, GetNumGuildMembers() do
            local gName, _, _, gLevel, _, gZone, _, _, gOnline, _, gClassFile = GetGuildRosterInfo(i)
            if gName and Ambiguate(gName, "short"):lower() == nameLower then
                class = gClassFile or class
                level = gLevel or level
                zone = gZone or zone
                online = gOnline or false
                break
            end
        end

        -- If the player is in your raid or party, fill in more accurate data
		if unit then
			local _, classFile = UnitClass(unit)
			class = classFile or class
			level = UnitLevel(unit) or level
			zone = GetZoneText()
			online = UnitIsConnected(unit)
			inRaid = UnitInRaid(unit) ~= nil
		end


        PSKDB.Players[nameProper] = {
            class = class,
            online = online,
            inRaid = inRaid,
            level = level,
            zone = zone,
        }
		
		if not foundInPlayer and not foundInRaidOrParty then
			print("[PSK] Warning: " .. nameProper .. " is not in your guild, raid, or party. Added with default info.")
		end
    end

    print("[PSK] Added " .. nameProper .. " to the " .. listType .. " list at the " .. position .. ".")
    PSK:DebouncedRefreshPlayerList()
end




local f = CreateFrame("Frame")
f:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")

f:SetScript("OnEvent", function(self, event, ...)
    if event == "PARTY_LOOT_METHOD_CHANGED" then
        PSK:UpdateLootThresholdLabel()
    end
end)
