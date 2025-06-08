-- core.lua


local PSK = select(2, ...)

-- Ensure PSKDB is initialized correctly
if not PSKDB then PSKDB = {} end
if not PSKDB.Settings then PSKDB.Settings = {} end
if not PSKDB.MainList then PSKDB.MainList = {} end
if not PSKDB.TierList then PSKDB.TierList = {} end
if not PSKDB.LootDrops then PSKDB.LootDrops = {} end
if not PSKDB.LootLogs then PSKDB.LootLogs = {} end

_G.PSKGlobal = _G.PSKGlobal or {}


-- Copy settings to table
PSK.Settings = CopyTable(PSKDB.Settings)

-- Set default loot threshold if not present
if not PSKDB.Settings.lootThreshold then
    PSK.Settings.lootThreshold = PSK.Settings.lootThreshold or 4
	PSKDB.Settings.lootThreshold = PSK.Settings.lootThreshold
end

PSK.RarityNames = {
	[0] = "Poor",
	[1] = "Common",
	[2] = "Uncommon",
	[3] = "Rare",
	[4] = "Epic",
	[5] = "Legendary"
}

 PSK.RarityColors = {
	[0] = "9d9d9d", -- Poor
	[1] = "ffffff", -- Common
	[2] = "1eff00", -- Uncommon
	[3] = "0070dd", -- Rare
	[4] = "a335ee", -- Epic
	[5] = "ff8000", -- Legendary
}


-- Main Variables
PSK.BiddingOpen = false
PSK.BidEntries = {}
PSK.CurrentList = "Main"
PSK.RollResults = PSK.RollResults or {}
PSK.ManualCancel = false

-- Holds timer references, so they can be started/stopped manually.
PSK.BidTimers = {}


----------------------------------------
-- Zug zug
----------------------------------------

-- function PSK:PlayRandomPeonSound()
    -- if not PSK.Settings or not PSK.Settings.buttonSoundsEnabled then
        -- return false
    -- end

    -- local normalSounds = {
        -- "Sound\\Creature\\Peon\\PeonYes1.ogg",
        -- "Sound\\Creature\\Peon\\PeonYes2.ogg",
    -- }
    -- local rareSound = "Sound\\Creature\\Peon\\PeonWhat3.ogg"

    -- if math.random(1, 100) <= 5 then
        -- PlaySoundFile(rareSound)
        -- return true
    -- else
        -- PlaySoundFile(normalSounds[math.random(1, #normalSounds)])
        -- return false
    -- end
-- end



----------------------------------------
-- Record Loot 
----------------------------------------

----------------------------------------
-- Event frame for looting
----------------------------------------

local lootViewFrame = CreateFrame("Frame")
lootViewFrame:RegisterEvent("LOOT_OPENED")

lootViewFrame:SetScript("OnEvent", function(self, event, autoLoot)

    -- if not IsMasterLooter() then return end
    if not PSK.Settings or not PSK.Settings.lootThreshold then return end

    local numItems = GetNumLootItems()
    local lootLinks = {}

    for i = 1, numItems do 	
        
		if LootSlotHasItem(i) then
            
			local itemLink = GetLootSlotLink(i)
            
			if itemLink then
			
                local rarity = select(3, GetItemInfo(itemLink))
				
                if rarity and rarity >= PSK.Settings.lootThreshold then
				
					if not PSK:IsLootAlreadyRecorded(itemLink) then
						local itemLink = GetLootSlotLink(i)
						local texture = GetLootSlotInfo(i) 

						if itemLink and texture then
							local _, _, _, _, iconTexture = GetItemInfoInstant(itemLink)
							
							table.insert(lootLinks, itemLink)  -- just for announcing
							
							table.insert(PSKDB.LootDrops, { -- For loot tracking
								itemLink = itemLink,
								itemTexture = iconTexture or "Interface\\Icons\\INV_Misc_QuestionMark",
								timestamp = date("%Y-%m-%d %H:%M:%S"),
							})
						end
					end
                end
            end
        end
    end

    -- Announce loot contents
	if #lootLinks > 0 then
		local message = "[PSK] Loot Bag: " .. table.concat(lootLinks, ", ")
		PSK:Announce(message)
		PSK:RefreshLootList()
		local lootLinks = {}
	end
	

end)



--------------------------------------------------------------------
-- Listen for loot method changes, which includes threshold changes
--------------------------------------------------------------------

-- local thresholdFrame = CreateFrame("Frame")
-- thresholdFrame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
-- thresholdFrame:SetScript("OnEvent", function(self, event, ...)
    -- if event == "PARTY_LOOT_METHOD_CHANGED" then
        -- local newThreshold = GetLootThreshold() or 4

        -- -- Update PSK settings
        -- PSK.Settings.lootThreshold = newThreshold
        -- PSKDB.Settings.lootThreshold = newThreshold

        -- -- Update the UI label
        -- if PSK.UpdateLootThresholdLabel then
            -- PSK:UpdateLootThresholdLabel()
        -- end
    -- end
-- end)


----------------------------------------
-- Start Bidding
----------------------------------------

function PSK:StartBidding()
    if PSK.BiddingOpen then return end
		
	if not PSK.SelectedItem then
		print("You must select an item before starting bidding.")
		
		if not PSK.Settings or not PSK.Settings.buttonSoundsEnabled then
			return false
		end
	
		PlaySound(SOUNDKIT.GS_TITLE_OPTION_EXIT)
		return
	end

    PSK.BiddingOpen = true
	
	-- Clear old timers just in case
	PSK.BidTimers = {}
    PSK.BidEntries = {}
	
	-- Cancel any active roll timers before starting new bidding
	if PSK.RollTimers then
		for _, timer in ipairs(PSK.RollTimers) do
			if timer.Cancel then
				timer:Cancel()
			end
		end
	end

	PSK.RollTimers = {}
	PSK.RollTimerActive = false

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
	
	SendChatMessage("[PSK] [" .. listName .. "] Bidding has started for " .. itemLink .. "!", "RAID_WARNING")
	PSK:Announce("[PSK] Type 'bid' in /raid, /party, or /whisper to bid.")
	PSK:Announce("[PSK] Type 'retract' in /raid, /party, or /whisper to retract.")
	PSK:Announce("[PSK] -----------------------------------------------------------------")

    -- Countdown Messages
    local countdownTimes = {20, 15, 10, 5, 4, 3, 2, 1}
	for _, seconds in ipairs(countdownTimes) do
		local timer = C_Timer.NewTimer(20 - seconds, function()
			if PSK.BiddingOpen then
				if seconds == 20 or seconds == 15 or seconds == 10 then
					PSK:Announce("[PSK] " .. seconds .. " seconds left on: " .. itemLink .. "!")
				else
					PSK:Announce("[PSK] " .. seconds .. " seconds left!")
				end
			end
		end)
		table.insert(PSK.BidTimers, timer)
	end

    -- Auto-close timer
	local closeTimer = C_Timer.NewTimer(20, function()
		if PSK.BiddingOpen then
			PSK:CloseBidding(false)
		end
	end)
	table.insert(PSK.BidTimers, closeTimer)

    PSK:DebouncedRefreshBidList()
end


----------------------------------------
-- Close Bidding
----------------------------------------

function PSK:CloseBidding(suppressRoll)
    PSK.BiddingOpen = false
    PSK.BidButton:SetText("Start Bidding")
	
	-- Cancel any active timers
    if PSK.BidTimers then
        for _, timer in ipairs(PSK.BidTimers) do
            if timer.Cancel then
                timer:Cancel()
            end
        end
    end
	
	if PSK.RollTimers then
        for _, timer in ipairs(PSK.RollTimers) do
            if timer.Cancel then
                timer:Cancel()
            end
        end
    end
	
	local itemLink = PSK.SelectedItem
	local itemName = GetItemInfo(itemLink) or itemLink
	
    PSK.BidTimers = {}
	PSK.RollTimers = {}
	PSK.RollTimerActive = false
	wipe(PSK.RollResults)
	
    PSK:RefreshBidList()

    if #PSK.BidEntries == 0 then
		if suppressRoll == false then
		
			SendChatMessage("[PSK] No bids were placed.", "RAID_WARNING")
			SendChatMessage("[PSK] Proceeding to roll-off!", "RAID_WARNING")
			PSK:Announce("[PSK] /roll 100 for MS, /roll 99 for OS!")

			-- Start 20 second timer
			PSK.RollTimerActive = true
			PSK.BiddingOpen = false
			
			local rollTimer = C_Timer.After(20, function()
				PSK:EvaluateRolls(itemLink)
				PSK.RollTimerActive = false
				PSK:CancelRollTimers()
			end)
			
			-- Countdown Messages
			local countdownTimes = {20, 15, 10, 5, 4, 3, 2, 1}
			for _, seconds in ipairs(countdownTimes) do
				local timer = C_Timer.NewTimer(20 - seconds, function()
					if seconds == 20 or seconds == 15 or seconds == 10 then
						PSK:Announce("[PSK] " .. seconds .. " seconds left to roll on " .. itemLink .. "!")
					else
						PSK:Announce("[PSK] " .. seconds .. " seconds left!")
					end
				end)
				table.insert(PSK.RollTimers, timer)
			end
		
			table.insert(PSK.RollTimers, rollTimer)
		end
    else
		SendChatMessage("[PSK] Bidding closed. Bidders:", "RAID_WARNING")
        
		-- Determine the current list
		local currentList = (PSK.CurrentList == "Tier") and PSKDB.TierList or PSKDB.MainList
		
		-- Get mapping of players and positions in the current list
		local indexMap = {}
		
		for i, entry in ipairs(currentList) do
			indexMap[entry.name] = i
		end

		-- Sort bids by position in list, unknowns to bottom
		table.sort(PSK.BidEntries, function(a, b)
			local aIndex = indexMap[a.name] or math.huge
			local bIndex = indexMap[b.name] or math.huge
			return aIndex < bIndex
		end)

		-- PSK:Announce list of sorted bid entries
		for i, entry in ipairs(PSK.BidEntries) do
			local listPos = indexMap[entry.name]
			if listPos then
				PSK:Announce(string.format("[PSK] %d. %s (%d in %s List)", i, entry.name, listPos, PSK.CurrentList))
			else
				PSK:Announce(string.format("[PSK] %d. %s (Not listed in %s List)", i, entry.name, PSK.CurrentList))
			end
		end

    end
end


----------------------------------------
-- Roll-off if no bids were placed
----------------------------------------

function PSK:EvaluateRolls(itemLink)
    if not PSK.RollTimerActive then return end  

	local highestMainRoll = -1
	local highestOffRoll = -1
	local mainSpecWinners = {}
	local offSpecWinners = {}
	local winner = nil
	local winnerClass = "SHAMAN"
	
	
    for player, data in pairs(PSK.RollResults) do
        if data.min == 1 and data.max == 100 then
            if data.roll > highestMainRoll then
				highestMainRoll = data.roll
				mainSpecWinners = { player }
			elseif data.roll == highestMainRoll then
				table.insert(mainSpecWinners, player)
			end
        elseif data.min == 1 and data.max == 99 then
			if data.roll > highestOffRoll then
				highestOffRoll = data.roll
				offSpecWinners = { player }
			elseif data.roll == highestMainRoll then
				table.insert(offSpecWinners, player)
			end
        end
    end

    
	if #mainSpecWinners > 0 then
		if #mainSpecWinners == 1 then
			winner = PSK.CapitalizeName(mainSpecWinners[1])
			PSK:Announce(string.format("[PSK] %s wins %s with a Main Spec roll of %d!", PSK.CapitalizeName(mainSpecWinners[1]), itemLink or "", highestMainRoll))
		else
			PSK:Announce(string.format("[PSK] Tie detected for Main Spec roll of %d between: %s", highestMainRoll, table.concat(mainSpecWinners, ", ")))
			-- Optional: trigger a second roll-off among them or ask for a reroll
		end
	elseif #offSpecWinners > 0 then
		if #offSpecWinners == 1 then
			winner = PSK.CapitalizeName(offSpecWinners[1])
			PSK:Announce(string.format("[PSK] %s wins %s with an Off Spec roll of %d!", PSK.CapitalizeName(offSpecWinners[1]), itemLink or "", highestOffRoll))
		else
			PSK:Announce(string.format("[PSK] Tie detected for Off Spec roll of %d between: %s", highestOffRoll, table.concat(offSpecWinners, ", ")))
			-- Optional: trigger a second roll-off among them or ask for a reroll
		end
	else
		PSK:Announce("[PSK] No valid rolls detected.")
	end

	-- Add the roll winner to BidEntries so they appear in the UI
	if winner then
		-- Try to detect class from raid
		for i = 1, MAX_RAID_MEMBERS do
			local unit = "raid" .. i
			if UnitExists(unit) and Ambiguate(UnitName(unit), "short") == winner then
				local _, classToken = UnitClass(unit)
				winnerClass = classToken or winnerClass
				break
			end
		end

		table.insert(PSK.BidEntries, {
			position = 1,
			name = winner,
			class = winnerClass,
			online = true,
			inRaid = true,
			notListed = true,
		})

		PSK:RefreshBidList()
	end
	
    wipe(PSK.RollResults)
end



-------------------------------------------
-- Frame for updating PSK lists on update.
-------------------------------------------

PSK.RosterFrame = CreateFrame("Frame")
PSK.RosterFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
PSK.RosterFrame:SetScript("OnEvent", function(_, event, ...)
	if PSK and PSK.RefreshAvailableMembers then
		PSK:DebouncedRefreshAvailablePlayerList()
	end
		
	if PSK and PSK.CurrentList then
		local original = PSK.CurrentList
		PSK.CurrentList = "Main"
		PSK:DebouncedRefreshPlayerLists()
		PSK.CurrentList = "Tier"
		PSK:DebouncedRefreshPlayerLists()
		PSK.CurrentList = original
	end
end)

----------------------------------------
-- Auto-Refresh Player Lists on Events
----------------------------------------
PSK.EventFrame = CreateFrame("Frame")
PSK.EventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
PSK.EventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
PSK.EventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
PSK.EventFrame:RegisterEvent("LOOT_OPENED")
PSK.EventFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
PSK.EventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
PSK.EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

PSK.EventFrame:SetScript("OnEvent", function(_, event, ...)
    -- Events where we trigger a guild roster scan
	GuildRoster()

    -- Handle group/raid changes
    if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_FLAGS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        if PSK and PSK.CurrentList then
            local original = PSK.CurrentList
            PSK.CurrentList = "Main"
            PSK:DebouncedRefreshPlayerLists()
            PSK.CurrentList = "Tier"
            PSK:DebouncedRefreshPlayerLists()
            PSK.CurrentList = original
        end
        return
    end

    -- Loot opened
    if event == "LOOT_OPENED" then
        PSK:DebouncedRefreshLootList()
        PSK:DebouncedRefreshLogList()
    end
end)




-------------------------------------------------------
-- Scan these channels for the word "bid" or for rolls
-------------------------------------------------------

local chatFrame = CreateFrame("Frame")
chatFrame:RegisterEvent("CHAT_MSG_RAID")
chatFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
chatFrame:RegisterEvent("CHAT_MSG_PARTY")
chatFrame:RegisterEvent("CHAT_MSG_SAY")
chatFrame:RegisterEvent("CHAT_MSG_WHISPER")
chatFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
chatFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
chatFrame:RegisterEvent("CHAT_MSG_SYSTEM")

chatFrame:SetScript("OnEvent", function(self, event, msg, sender)
    if not PSK.BiddingOpen and not PSK.RollTimerActive then return end

    if not sender then return end

    -- Ignore messages from the addon itself
    if msg:find("^%[PSK%]") then
        return
    end

    -- Strip realm name if present
    local simpleName = Ambiguate(sender, "short")
    msg = msg:lower()

    -- Handle bid messages
    if msg:find("bid") and PSK.BiddingOpen then
        AddBid(simpleName)
    end
	
    -- Handle retract messages
    if msg:find("retract") and PSK.BiddingOpen then
        RetractBid(simpleName)
    end
	
	-- Capture rolls during an active roll-off (raid only!)
	if event == "CHAT_MSG_SYSTEM" and PSK.RollTimerActive then
		
		local player, roll, low, high = string.match(msg, "^(%a+) rolls (%d+) %((%d+)%-(%d+)%)")
		
		if player and roll and low and high then
		
			-- Debug: Print the raw capture
			print(string.format("[PSK Debug] Detected roll: %s rolled %s (%s-%s)", PSK.CapitalizeName(player), roll, low, high))

			-- Verify player is in the raid
			local isInRaid = true -- set to false after debugging
			
			for i = 1, MAX_RAID_MEMBERS do
				local unit = "raid" .. i
				
				local unitRawName = UnitName(unit)
				
				if UnitExists(unit) and unitRawName then
					local unitName = Ambiguate(unitRawName, "short"):lower()
					local rollName = Ambiguate(player, "short"):lower()

					if unitName == rollName then
						isInRaid = true
						break
					end
				end
			end

			if isInRaid then
				if not PSK.RollResults then PSK.RollResults = {} end
				
				PSK.RollResults[player] = {
					roll = tonumber(roll),
					min = tonumber(low),
					max = tonumber(high),
					timestamp = GetTime()
				}
			end
		end
	end

end)


------------------------------------------
-- Cancel roll timers
------------------------------------------

function PSK:CancelRollTimers()
    if PSK.RollTimers then
        for _, timer in ipairs(PSK.RollTimers) do
            if timer.Cancel then
                timer:Cancel()
            end
        end
    end
    PSK.RollTimers = {}
    PSK.RollTimerActive = false
end


------------------------------------------
-- Add a bid, including unlisted players
------------------------------------------

function AddBid(name)
    if not name then return end

    -- Prevent duplicate bids
    for _, entry in ipairs(PSK.BidEntries) do
        if entry.name == name then return end
    end

    -- Fallback class if not detected
    local class = "SHAMAN"
    local unit = nil

    -- Try to find unit for class info
    if IsInRaid() then
        for i = 1, MAX_RAID_MEMBERS do
            local u = "raid" .. i
            if UnitExists(u) and Ambiguate(UnitName(u), "short") == name then
                unit = u
                break
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local u = "party" .. i
            if UnitExists(u) and Ambiguate(UnitName(u), "short") == name then
                unit = u
                break
            end
        end
    end

    if unit then
        local _, classToken = UnitClass(unit)
        class = classToken or class
    end

    -- Determine list to use
    local list = (PSK.CurrentList == "Tier") and PSKDB.TierList or PSKDB.MainList
    local found = false

    for _, player in ipairs(list) do
        if player.name == name then
            found = true
            break
        end
    end

    -- Add to list if not found
    if not found then
        table.insert(list, {
            name = name,
            class = class,
            dateLastRaided = "Never"
        })
    end

    -- Get position in list
    local position = nil
    for i, player in ipairs(list) do
        if player.name == name then
            position = i
            break
        end
    end

    -- Add bid
    -- table.insert(PSK.BidEntries, {
        -- position = position or (#PSK.BidEntries + 1),
        -- name = name,
        -- class = class,
        -- online = true,
        -- inRaid = UnitInRaid(unit) ~= nil,
        -- notListed = false,
    -- })
	
	table.insert(PSK.BidEntries, {
		position = position or (#PSK.BidEntries + 1),
		name = name,
		class = class,
		online = true,
		inRaid = UnitInRaid(unit) ~= nil,
		notListed = false,
		listType = PSK.CurrentList,     -- "Main" or "Tier"
		listPosition = position or 9999 -- more explicit field for client use
	})


	PSK:SendSync("UPDATE_BIDS", PSK.BidEntries)
    PSK:RefreshBidList()
end


----------------------------------------
-- Function add player from slash command
----------------------------------------

function PSK:AddPlayerFromCommand(name, listType, position)
    -- Normalize and clean input
    local rawName = Ambiguate(name, "short"):gsub("%s+", "")
    local nameLower = rawName:lower()
    local nameProper = PSK.CapitalizeName(rawName)

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
	

    -- Choose target list
    local list = (listType == "tier") and PSKDB.TierList or PSKDB.MainList

    -- Check for duplicates
    for _, existing in ipairs(list) do
		local existingName = type(existing) == "table" and existing.name or existing
		if existingName and Ambiguate(existingName, "short"):lower() == nameLower then
			print("[PSK] " .. nameProper .. " is already in the " .. listType .. " list.")
			return
		end
	end

    -- Add to top or bottom
    local entry = {
		name = nameProper,
		class = PSK:GetClassForPlayer(name),
		dateLastRaided = "Never"
	}
	
	if position == "top" then
		table.insert(list, 1, entry)
	else
		table.insert(list, entry)
	end

    print("[PSK] Added " .. nameProper .. " to the " .. listType .. " list at the " .. position .. ".")
    PSK:DebouncedRefreshPlayerLists()
end

------------------------------------------
-- Retract a bid
------------------------------------------

function RetractBid(name)
    if not name then return end

    for i, entry in ipairs(PSK.BidEntries) do
        if entry.name == name then
            table.remove(PSK.BidEntries, i)
            break
        end
    end

    PSK:RefreshBidList()
end


--------------------------------------------------------------
-- Clear the player selection when switching main/tier lists
--------------------------------------------------------------

function PSK:ClearSelection()
    PSK.SelectedPlayer = nil
    PSK.SelectedPlayerRow = nil
    PSK:DebouncedRefreshPlayerLists()
end


------------------------------------------
-- Console commands to open addon
------------------------------------------

local slashFrame = CreateFrame("Frame")
slashFrame:RegisterEvent("PLAYER_LOGIN")

slashFrame:SetScript("OnEvent", function()
    SLASH_PSK1 = "/psk"
    SlashCmdList["PSK"] = function()
		if PSK and PSK.MainFrame then
			if PSK.MainFrame:IsShown() then
				PSK.MainFrame:Hide()
			else
				PSK.MainFrame:Show()
			end
		end
	end

end)

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

------------------------------------------
-- Console commands for help
------------------------------------------

SLASH_PSKHELP1  = "/pskhelp"
SlashCmdList["PSKHELP"] = function()
	PSK:PrintHelp()
end

------------------------------------------
-- Console command to print command help
------------------------------------------

function PSK:PrintHelp()
    print(" ")
    print("|cff00ff00[PSK Addon Help]|r")
    print("/psk                     - Toggle the PSK window")
    print("/pskhelp                - Show this help menu")
	print("/pskadd <top or bottom> <main or tier> <name>    - Add player to a list")
	print("/pskclear                - !!! CLEARS PSK LISTS - IRREVERSIBLE !!!")
    print(" ")
end


------------------------------------------
-- Console command to clear PSK lists
------------------------------------------
SLASH_PSKCLEAR1 = "/pskclear"
SlashCmdList["PSKCLEAR"] = function()
    StaticPopup_Show("PSK_CONFIRM_CLEAR_LISTS")
end


StaticPopupDialogs["PSK_CONFIRM_CLEAR_LISTS"] = {
    text = "This will permanently clear both the Main and Tier lists.\nAre you sure?",
    button1 = "Yes",
    button2 = "Cancel",
    OnAccept = function()
        PSKDB.MainList = {}
        PSKDB.TierList = {}
        PSK:DebouncedRefreshPlayerLists()
        PSK:DebouncedRefreshAvailablePlayerLists()
        print("[PSK] All PSK lists have been cleared.")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}


----------------------------------------------
-- Capitalize names that get added to the lists
----------------------------------------------

function PSK.CapitalizeName(name)
    return name:sub(1, 1):upper() .. name:sub(2):lower()
end
