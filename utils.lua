---------------------------------------------------
-- This file is for helper functions for the addon
---------------------------------------------------

local PSK = select(2, ...)

-- Debounce flags
local refreshPlayerScheduled = false
local refreshBidScheduled = false
local refreshLootScheduled = false
local refreshLogScheduled = false
local refreshAvailablePlayers = false

-- Facilitates row pools.
PSK.RowPool = PSK.RowPool or {}

---------------------------------------------------
-- Set/Get important details we'll need below
---------------------------------------------------

PSK.ScrollChildren = PSK.ScrollChildren or {}
PSK.Headers = PSK.Headers or {}
PSK.ScrollFrames = PSK.ScrollFrames or {}

local DEFAULT_COLUMN_WIDTH = 220
local COLUMN_HEIGHT = 355

CLASS_NAME_TO_FILE = {
    ["Warrior"] = "WARRIOR",
    ["Paladin"] = "PALADIN",
    ["Hunter"]  = "HUNTER",
    ["Rogue"]   = "ROGUE",
    ["Priest"]  = "PRIEST",
    ["Shaman"]  = "SHAMAN",
    ["Mage"]    = "MAGE",
    ["Warlock"] = "WARLOCK",
    ["Druid"]   = "DRUID",
}

-- DO NOT OVERWRITE 'RAID_CLASS_COLORS'!!!
-- It will break other addons...
local CLASS_COLORS = RAID_CLASS_COLORS or {
    WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
    PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
    HUNTER  = { r = 0.67, g = 0.83, b = 0.45 },
    ROGUE   = { r = 1.00, g = 0.96, b = 0.41 },
    PRIEST  = { r = 1.00, g = 1.00, b = 1.00 },
    SHAMAN  = { r = 0.00, g = 0.44, b = 0.87 },
    MAGE    = { r = 0.41, g = 0.80, b = 0.94 },
    WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
    DRUID   = { r = 1.00, g = 0.49, b = 0.04 },
}


---------------------------------
-- Award loot to selected player
---------------------------------

function PSK:AwardPlayer(index)
    local playerEntry = PSK.BidEntries and PSK.BidEntries[index]
    local playerName = playerEntry and playerEntry.name
	
    if not playerName then
        print("AwardPlayer: No playerName found at index", index)
        return
    end

    -- Step 1: Confirm with the user first
    StaticPopupDialogs["PSK_CONFIRM_AWARD"] = {
        text = "Are you sure you want to award loot to |cffffff00%s|r?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            -- Award confirmed
            PerformAward(index)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopup_Show("PSK_CONFIRM_AWARD", playerName)
end


---------------------------------
-- Perform the award
---------------------------------

function PerformAward(index)

    local playerEntry = PSK.BidEntries and PSK.BidEntries[index]
    local playerName = playerEntry and playerEntry.name
	PSK.SelectedPlayer = playerName
    local playerClass = playerEntry and playerEntry.class
    local list = (PSK.CurrentList == "Main") and PSKDB.MainList or PSKDB.TierList
    
	-- Use the selected item instead of relying on index
	local item = PSK.SelectedItemData

	-- In case an item wasn't selected for award, or it became deselected
	if not item then
		print("[PSK] Error: No selected item found for award")
		return
	end

    -- Animate selected loot row fading out
    if PSK.SelectedLootRow and PSK.SelectedLootRow.bg then
        local row = PSK.SelectedLootRow
        local fade = row:CreateAnimationGroup()
        local fadeOut = fade:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(1)
        fadeOut:SetToAlpha(0)
        fadeOut:SetDuration(0.5)
        fadeOut:SetOrder(1)

        fade:SetScript("OnFinished", function()
            row.bg:SetColorTexture(0, 0, 0, 0)
            PSK.SelectedLootRow = nil
            PSK.SelectedItem = nil
            if not PSK.BiddingOpen then
                PSK.BidButton:Disable()
            end
            PSK:DebouncedRefreshLootList()
        end)

        fade:Play()
    else
        PSK.SelectedLootRow = nil
        PSK.SelectedItem = nil
        if not PSK.BiddingOpen then
            PSK.BidButton:Disable()
        end
        PSK:DebouncedRefreshLootList()
    end

	-- Reorder standings based on current list and selected player
	if PSK.SelectedPlayer then
		PSK:ReorderListOnAward(PSK.CurrentList)
		
		-- Update dateLastRaided for all raid members in the Main or Tier list
		local now = date("%m/%d/%Y")

		local function updateRaidersDateLastRaided(list)
			for _, entry in ipairs(list) do
				for i = 1, MAX_RAID_MEMBERS do
					local unit = "raid" .. i
					if UnitExists(unit) then
						local name = Ambiguate(UnitName(unit), "short")
						if name == entry.name then
							entry.dateLastRaided = now
							break
						end
					end
				end
			end
		end

		if PSKDB.MainList then
			updateRaidersDateLastRaided(PSKDB.MainList)
		end
		if PSKDB.TierList then
			updateRaidersDateLastRaided(PSKDB.TierList)
		end

	else
		print("[PSK] Error: No selected player found to reorder list.")
	end

	-- Clear bidders after awarding
	PSK.BiddingOpen = false
	PSK.BidEntries = {}
	PSK:RefreshBidList()

	-- Clear selection
	PSK.SelectedItem = nil
	PSK.SelectedItemData = nil
	PSK.SelectedLootRow = nil


	-- Get class color
	local color = RAID_CLASS_COLORS[playerClass or "SHAMAN"] or { r = 1, g = 1, b = 1 }
	local coloredName = string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, playerName)

	
	-- Get item details before clearing selection
	local itemLink = item.itemLink
	local itemName = GetItemInfo(itemLink) or "Unknown Item"

	if itemLink then 
		PSK:Announce("[PSK] " .. itemLink .. " awarded to " .. playerName)
	end



    -- Log the award
    PSKDB.LootLogs = PSKDB.LootLogs or {}

	table.insert(PSKDB.LootLogs, {
		player = playerName,
		class = playerClass or "SHAMAN",
		itemLink = item.itemLink,
		itemTexture = item.itemTexture or "Interface\\Icons\\INV_Misc_QuestionMark",
		timestamp = date("%I:%M%p %m/%d/%Y"),
	})


    -- Remove from visible + persistent loot lists
    local itemLinkToRemove = item.itemLink
	local textureToRemove = item.itemTexture or "Interface\\Icons\\INV_Misc_QuestionMark"
	local timestampToRemove = item.timestamp
	
	local function removeItemFromList(list)
		for i = #list, 1, -1 do
			local entry = list[i]

			if entry.itemLink == itemLinkToRemove and entry.timestamp == timestampToRemove then
				print(">>> Match found — removing loot entry.")
				table.remove(list, i)
				break
			end
		end
	end

	removeItemFromList(PSKDB.LootDrops)


    if PSK.RefreshLogList then
        PSK:DebouncedRefreshLogList()
    end

    PSK:RefreshPlayerLists()
    PSK:RefreshBidList()
    PlaySound(12867)
end


-----------------------------------------------------------
-- Adjust standings when a player is awarded:
-- 	Non-raid member standings are frozen
-- 	Raid member standings move around them
-- 	In the event of a tie, non-Raid goes 1 position lower
-----------------------------------------------------------

function PSK:ReorderListOnAward(listName)
    if not listName or (listName ~= "Main" and listName ~= "Tier") then
        PSK:Announce("[PSK] Invalid list name: " .. tostring(listName))
        return
    end

    local list = (listName == "Main") and PSKDB.MainList or PSKDB.TierList
    if not list or type(list) ~= "table" then
        PSK:Announce("[PSK] List not found or invalid: " .. tostring(listName))
        return
    end

    local awarded = PSK.SelectedPlayer
    if not awarded then
        PSK:Announce("[PSK] No player selected for awarding.")
        return
    end

    local shortAwarded = PSK.CapitalizeName(Ambiguate(awarded, "short"))

	-- Remove awarded player from the list (match by name)
    local awardedEntry

    for i = #list, 1, -1 do
        local entry = list[i]
        if type(entry) == "table" and entry.name and Ambiguate(entry.name, "short") == shortAwarded then
            awardedEntry = table.remove(list, i)
            break
        end
    end
	
	-- Re-insert at the bottom
    table.insert(list, awardedEntry)
	
    -- Track original positions
    local originalIndex = {}
    for i, entry in ipairs(list) do
        if type(entry) == "table" and entry.name then
            originalIndex[Ambiguate(entry.name, "short")] = i
        else
            PSK:Announce(string.format("[PSK] Skipping invalid entry at index %d: %s", i, tostring(entry)))
        end
    end

    if not awardedEntry then
        PSK:Announce("[PSK] Could not find awarded player in list: " .. shortAwarded)
        return
    end  

    -- Build raid lookup
    local raidLookup = {}
    for i = 1, GetNumGroupMembers() do
        local name = GetRaidRosterInfo(i)
        if name then
            raidLookup[Ambiguate(name, "short")] = true
        end
    end

    -- Bubble raid members over non-raid members (except awarded at bottom)
    for i = #list - 1, 2, -1 do
        local curr = list[i]
        local prev = list[i - 1]
        if curr and prev and curr.name and prev.name then
            local sc = Ambiguate(curr.name, "short")
            local sp = Ambiguate(prev.name, "short")
            if raidLookup[sc] and not raidLookup[sp] then
                list[i], list[i - 1] = list[i - 1], list[i]
            end
        end
    end

    -- Edge case for first two entries
    if #list >= 2 and list[1] and list[2] and list[1].name and list[2].name then
        local s1 = Ambiguate(list[1].name, "short")
        local s2 = Ambiguate(list[2].name, "short")
        if raidLookup[s2] and not raidLookup[s1] then
            list[1], list[2] = list[2], list[1]
        end
    end

    -- Build diff
    local diff = {}
    for i, entry in ipairs(list) do
        if type(entry) == "table" and entry.name then
            local shortName = Ambiguate(entry.name, "short")
            local from = originalIndex[shortName]
            if from and from ~= i then
                table.insert(diff, {
                    name = shortName,
                    from = from,
                    to = i,
                    status = raidLookup[shortName] and "Raid" or "Non-Raid"
                })
            end
        end
    end

    -- DEBUG: Announce movements
    -- PSK:Announce("---- [PSK] List Reordered ----")
    -- if #diff == 0 then
        -- PSK:Announce("No players moved.")
    -- else
        -- for _, entry in ipairs(diff) do
            -- PSK:Announce(string.format("%s (%s) moved from %d to %d", entry.name, entry.status, entry.from, entry.to))
        -- end
    -- end
    -- PSK:Announce(string.format("%s was awarded and moved to the bottom.", shortAwarded))
end




function PSK:SafeAmbiguate(name)
    return name and Ambiguate(name, "short") or ""
end



-- function PSK:ReorderListOnAward(listName, awardedPlayer)
    -- local list = (listName == "Tier") and PSKDB.TierList or PSKDB.MainList
    -- if not list then return end

	-- print("Reordering %s list after awarding to: %s", listName, awardedPlayer)
	
    -- -- Get a lookup of all raid members
    -- local raidRoster = {}
    -- for i = 1, GetNumGroupMembers() do
        -- local name = GetRaidRosterInfo(i)
        -- if name then
            -- local baseName = Ambiguate(name, "short")
            -- raidRoster[baseName] = true
        -- end
    -- end

    -- -- Build categorized lists
    -- local inRaid = {}
    -- local notInRaid = {}

    -- -- Preserve order while separating raid members and non-raid
    -- for i = 1, #list do
        -- local name = list[i]
        -- if name == awardedPlayer then
            -- -- Skip for now (we’ll reinsert them)
			-- print("Skipping awarded player: %s", name)
        -- elseif raidRoster[name] then
			-- -- If they're in the raid (raidRoster[name] = true
            -- table.insert(inRaid, name)
			-- print("In-raid member kept: %s", name)
        -- else
			-- -- If they're not in the raid (raidRoster[name] = false
            -- table.insert(notInRaid, name)
			-- print("Non-raid member preserved: %s", name)
        -- end
    -- end

    -- -- Add awarded player to bottom of inRaid list
    -- table.insert(inRaid, awardedPlayer)
	-- print("Awarded player added to bottom of raid list: %s", awardedPlayer)
	
	
    -- -- Merge back: interweave non-raiders into their original positions
    -- local newList = {}
    -- local raidIndex, nonRaidIndex = 1, 1
    -- for i = 1, #list do
        -- local expectedName = list[i]
        -- local isInRaid = raidRoster[expectedName]
        -- local nextRaid = inRaid[raidIndex]
        -- local nextNonRaid = notInRaid[nonRaidIndex]

        -- if not isInRaid and nextNonRaid == expectedName then
            -- table.insert(newList, nextNonRaid)
			-- print("Added non-raid: %s", nextNonRaid)
            -- nonRaidIndex = nonRaidIndex + 1
        -- elseif isInRaid and nextRaid then
            -- table.insert(newList, nextRaid)
			-- print("Added raid member: %s", nextRaid)
            -- raidIndex = raidIndex + 1
        -- elseif nextNonRaid then
            -- -- Tie breaker: non-raid loses
            -- table.insert(newList, nextNonRaid)
			-- print("Added raid member: %s", nextRaid)
            -- nonRaidIndex = nonRaidIndex + 1
        -- end
    -- end

    -- -- Fallback in case of mismatch
    -- while raidIndex <= #inRaid do
        -- table.insert(newList, inRaid[raidIndex])
		-- print("Added remaining raid member: %s", inRaid[raidIndex])
        -- raidIndex = raidIndex + 1
    -- end
	
    -- while nonRaidIndex <= #notInRaid do
        -- table.insert(newList, notInRaid[nonRaidIndex])
		-- print("Added remaining non-raid: %s", notInRaid[nonRaidIndex])
        -- nonRaidIndex = nonRaidIndex + 1
    -- end

	-- print("New %s list order:", listName)
    -- for i, name in ipairs(newList) do
        -- print("  %d. %s", i, name)
    -- end
	
    -- -- Save result
    -- if listName == "Tier" then
        -- PSKDB.TierList = newList
    -- else
        -- PSKDB.MainList = newList
    -- end
	
-- end


----------------------------------------------
-- Announce to party/raid 
----------------------------------------------

function PSK:Announce(message)
    local playerName = UnitName("player")

    if IsInRaid() then
        SendChatMessage(message, "RAID")
    elseif IsInGroup() then
        SendChatMessage(message, "PARTY")
    else
        SendChatMessage(message, "WHISPER", nil, playerName)
    end
	
end


---------------------------------------------------------
-- Create scrollable list container with head/backdrop.
---------------------------------------------------------

function CreateBorderedScrollFrame(name, parent, x, y, titleText, customWidth)
    local COLUMN_WIDTH = customWidth or 220
    local COLUMN_HEIGHT = 355

    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetSize(COLUMN_WIDTH, COLUMN_HEIGHT + 20)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    container:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    container:SetBackdropColor(0.1, 0.1, 0.1, 0.85)

    -- Header text (was parented to 'parent', now to 'container')
    local header = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("BOTTOMLEFT", container, "TOPLEFT", 5, 10)
    header:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    header:SetTextColor(1, 0.85, 0.1)
    header:SetText(titleText)

    -- ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", name, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(COLUMN_WIDTH - 26, COLUMN_HEIGHT)
    scrollFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 5, -5)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(COLUMN_WIDTH - 40, COLUMN_HEIGHT)
    scrollFrame:SetScrollChild(scrollChild)

    return scrollFrame, scrollChild, container, header
end



----------------------------------------
-- Refresh Loot List
----------------------------------------

function PSK:RefreshLootList()

	if not PSKDB or not PSKDB.LootDrops then return end


    local scrollChild = PSK.ScrollChildren.Loot
    local header = PSK.Headers.Loot
    if not scrollChild or not header then return end

    -- Clear previous children
    for _, child in ipairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    PSK.RowPool = PSK.RowPool or {}
    PSK.RowPool[scrollChild] = PSK.RowPool[scrollChild] or {}
    local pool = PSK.RowPool[scrollChild]

    local yOffset = -5

    for index, loot in ipairs(PSKDB.LootDrops) do
        local row = pool[index]
        if not row then
            row = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            row:SetSize(240, 20)
            row:SetFrameLevel(scrollChild:GetFrameLevel() + 1)
            pool[index] = row
        end

        row:SetParent(scrollChild)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, yOffset)
        row:Show()

        -- Setup visuals once
        if not row.bg then
            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()
        end
        row.bg:SetColorTexture(0, 0, 0, 0)

        if not row.iconTexture then
            row.iconTexture = row:CreateTexture(nil, "ARTWORK")
            row.iconTexture:SetSize(16, 16)
            row.iconTexture:SetPoint("LEFT", row, "LEFT", 5, 0)

            row.itemText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.itemText:SetPoint("LEFT", row.iconTexture, "RIGHT", 8, 0)

            row:SetScript("OnEnter", function()
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(row.itemLink or "")
                GameTooltip:Show()
            end)

            row:SetScript("OnLeave", GameTooltip_Hide)

            row:SetScript("OnClick", function()
                if PSK.SelectedLootRow and PSK.SelectedLootRow.bg then
                    PSK.SelectedLootRow.bg:SetColorTexture(0, 0, 0, 0)
                end
                row.bg:SetColorTexture(0.2, 0.6, 1, 0.2)
                PSK.SelectedLootRow = row
                PSK.SelectedItem = row.itemLink
                PSK.SelectedItemData = row.lootData
                PSK.BidButton:Enable()

                local pulse = row:CreateAnimationGroup()
                local fadeOut = pulse:CreateAnimation("Alpha")
                fadeOut:SetFromAlpha(1)
                fadeOut:SetToAlpha(0.4)
                fadeOut:SetDuration(0.2)
                fadeOut:SetOrder(1)

                local fadeIn = pulse:CreateAnimation("Alpha")
                fadeIn:SetFromAlpha(0.4)
                fadeIn:SetToAlpha(1)
                fadeIn:SetDuration(0.2)
                fadeIn:SetOrder(2)

                pulse:SetLooping("NONE")
                pulse:Play()
            end)
        end

        -- Update visuals each loop
        row.iconTexture:SetTexture(loot.itemTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.itemText:SetText(loot.itemLink or "Unknown")
        row.itemLink = loot.itemLink
        row.lootData = loot

        yOffset = yOffset - 22
    end

    -- Hide unused rows
    for i = #PSKDB.LootDrops + 1, #pool do
        if pool[i] then pool[i]:Hide() end
    end

    header:SetText("Loot Drops (" .. #PSKDB.LootDrops .. ")")

    -- PSK:BroadcastUpdate("RefreshLootList")
end


----------------------------------------
-- Helper function for looting
----------------------------------------

function PSK:IsLootAlreadyRecorded(itemLink)
    for _, entry in ipairs(PSKDB.LootDrops or {}) do
        if entry.itemLink == itemLink then
            return true
        end
    end
    return false
end






----------------------------------------
-- Refresh Log list
----------------------------------------

function PSK:RefreshLogList()
    if not PSKDB.LootLogs then return end

    local scrollChild = PSK.ScrollChildren.Logs
    local header = PSK.Headers.Logs

    if PSK.RecordingWarning then
        if not PSK.LootRecordingActive then
            PSK.RecordingWarning:Show()
            if not PSK.RecordingWarning.pulse:IsPlaying() then
                PSK.RecordingWarning.pulse:Play()
            end
        else
            PSK.RecordingWarning:Hide()
            PSK.RecordingWarning.pulse:Stop()
        end
    end

    if not scrollChild or not header then return end

    -- Clear previous children
    for _, child in ipairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    PSK.RowPool = PSK.RowPool or {}
    PSK.RowPool[scrollChild] = PSK.RowPool[scrollChild] or {}
    local pool = PSK.RowPool[scrollChild]

    local yOffset = -5
    for index = #PSKDB.LootLogs, 1, -1 do
        local log = PSKDB.LootLogs[index]
        local rowIndex = #PSKDB.LootLogs - index + 1

        local row = pool[rowIndex]
        if not row then
            row = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            row:SetSize(650, 20)
            pool[rowIndex] = row
        end

        row:SetParent(scrollChild)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, yOffset)
        row:Show()

        -- Class Icon
        if not row.classIcon then
            row.classIcon = row:CreateTexture(nil, "ARTWORK")
            row.classIcon:SetSize(16, 16)
            row.classIcon:SetPoint("LEFT", row, "LEFT", 5, 0)
        end
        if log.class then
            local class = log.class:upper()
            local texCoord = CLASS_ICON_TCOORDS[class]
            if texCoord then
                row.classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CharacterCreate-Classes")
                row.classIcon:SetTexCoord(unpack(texCoord))
            else
                row.classIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                row.classIcon:SetTexCoord(0, 1, 0, 1)
            end
        else
            row.classIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            row.classIcon:SetTexCoord(0, 1, 0, 1)
        end

        -- Player Name
        if not row.playerText then
            row.playerText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.playerText:SetPoint("LEFT", row.classIcon, "RIGHT", 5, 0)
        end
        local playerClass = log.class and log.class:upper() or "SHAMAN"
        local classColor = RAID_CLASS_COLORS[playerClass] or { r = 1, g = 1, b = 1 }
        row.playerText:SetText(log.player)
        row.playerText:SetTextColor(classColor.r, classColor.g, classColor.b)

        -- Fetch item icon if missing
        if not log.itemTexture and log.itemLink then
            local _, _, _, _, _, _, _, _, _, fetchedIcon = GetItemInfo(log.itemLink)
            log.itemTexture = fetchedIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
        end

        -- Item icon
        if not row.iconTexture then
            row.iconTexture = row:CreateTexture(nil, "ARTWORK")
            row.iconTexture:SetSize(16, 16)
            row.iconTexture:SetPoint("LEFT", row.playerText, "RIGHT", 6, 0)
        end
        row.iconTexture:SetTexture(log.itemTexture or "Interface\\Icons\\INV_Misc_QuestionMark")

        -- Item text
        if not row.itemText then
            row.itemText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.itemText:SetPoint("LEFT", row.iconTexture, "RIGHT", 6, 0)

            row.itemText:SetScript("OnEnter", function()
                GameTooltip:SetOwner(row.itemText, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(row.itemLink or "")
                GameTooltip:Show()
            end)
            row.itemText:SetScript("OnLeave", GameTooltip_Hide)
        end

        local itemName, _, itemRarity = GetItemInfo(log.itemLink)
        local r, g, b = 1, 1, 1
        if itemRarity then
            r, g, b = GetItemQualityColor(itemRarity)
        end
        row.itemText:SetText(itemName or log.itemLink)
        row.itemText:SetTextColor(r, g, b)
        row.itemLink = log.itemLink

        -- Timestamp
        if not row.timeText then
            row.timeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.timeText:SetPoint("LEFT", row, "LEFT", 480, 0)
        end
        row.timeText:SetText(log.timestamp)

        yOffset = yOffset - 22
    end

    -- Hide unused rows
    for i = #PSKDB.LootLogs + 1, #pool do
        if pool[i] then pool[i]:Hide() end
    end

    if header then
        header:SetText("Loot Logs (" .. #PSKDB.LootLogs .. ")")
    end

    -- PSK:BroadcastUpdate("RefreshLogList")
end



----------------------------------------
-- Refresh Player List (for Main or Tier)
----------------------------------------

function PSK:RefreshPlayerLists()

	if InCombatLockdown() then
		if PSK.EventFrame and PSK.EventFrame.RegisterEvent then
			PSK.EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		end
		return
	end

    if not PSKDB or not PSK.CurrentList then return end

    local scrollChild = PSK.ScrollChildren.Main
    local header = PSK.Headers.Main
    if not scrollChild or not header then return end

    -- Clear previous list
    for _, child in ipairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    local names = {}
    if PSK.CurrentList == "Main" and PSKDB.MainList then
        names = PSKDB.MainList
    elseif PSK.CurrentList == "Tier" and PSKDB.TierList then
        names = PSKDB.TierList
    end

    -- Update header text
    header:SetText((PSK.CurrentList == "Main" and "PSK Main" or "PSK Tier") .. " (" .. #names .. ")")

    local yOffset = -5
    for index, entry in ipairs(names) do
		local name = entry.name
		local storedDate = entry.dateLastRaided or "Never"

		local row = PSK:GetOrCreateRow(index, scrollChild, "Player")
		
		-- row:SetParent(scrollChild)
		row:ClearAllPoints()
		row:SetSize(200, 20)
		row:SetPoint("TOPLEFT", 0, yOffset)
		row:Show()
	
		-- Background for status glow
		if not row.bg then
			row.bg = row:CreateTexture(nil, "BACKGROUND")
			row.bg:SetAllPoints()
			row.bg:SetColorTexture(0, 0.5, 1, 0.15)  -- Light blue for selection
		end
		
		-- row.bg:Hide()		

		
		
        -- Get live data from raid/group/guild APIs
		local class, level, zone, online, inRaid = "SHAMAN", "???", "???", false, false

		-- Try raid/group info first
		if IsInRaid() then
			for i = 1, MAX_RAID_MEMBERS do
				local unit = "raid" .. i
				if UnitExists(unit) and Ambiguate(UnitName(unit), "short") == name then
					local _, classToken = UnitClass(unit)
					class = classToken or class
					level = UnitLevel(unit) or level
					zone = GetZoneText()
					online = UnitIsConnected(unit)
					inRaid = true
					break
				end
			end
		elseif IsInGroup() then
			for i = 1, GetNumGroupMembers() - 1 do
				local unit = "party" .. i
				if UnitExists(unit) and Ambiguate(UnitName(unit), "short") == name then
					local _, classToken = UnitClass(unit)
					class = classToken or class
					level = UnitLevel(unit) or level
					zone = GetZoneText()
					online = UnitIsConnected(unit)
					inRaid = false
					break
				end
			end
		end

		-- Fallback to Guild Roster
		if class == "SHAMAN" and GetNumGuildMembers() > 0 then
			for i = 1, GetNumGuildMembers() do
				local gName, _, _, gLevel, _, gZone, _, _, gOnline, _, gClassFile = GetGuildRosterInfo(i)
				local gShortName = Ambiguate(gName or "", "short")
				if gShortName == name then
					class = gClassFile or class
					level = gLevel or level
					zone = gZone or zone
					online = gOnline or false
					break
				end
			end
		end

        row.playerData = {
			name = name,
			class = class,
			online = online,
			inRaid = inRaid,
			level = level,
			zone = zone,
			dateLastRaided = storedDate
		}

        -- Position
		if not row.posText then
			row.posText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			row.posText:SetPoint("LEFT", row, "LEFT", 5, 0)
		end
		row.posText:SetText(index)

        -- Class icon
		if not row.classIcon then
			row.classIcon = row:CreateTexture(nil, "ARTWORK")
			row.classIcon:SetSize(16, 16)
			row.classIcon:SetPoint("LEFT", row.posText, "RIGHT", 8, 0)
		end
		
		if CLASS_ICON_TCOORDS[class] then
			row.classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
			row.classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
		else
			row.classIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			row.classIcon:SetTexCoord(0, 1, 0, 1)
		end

		
		-- Extract the player class
		local playerClass = playerData and playerData.class or "SHAMAN"
		local fileClass = string.upper(row.playerData.class or "SHAMAN")
		
		-- Corrected class color lookup
		local classColor = RAID_CLASS_COLORS[fileClass] or { r = 1, g = 1, b = 1 }

		-- Create the player name text with the correct color
		if not row.nameText then
			row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			row.nameText:SetPoint("LEFT", row.classIcon, "RIGHT", 8, 0)
		end
		
		row.nameText:SetText(row.playerData.name)
		row.nameText:SetTextColor(classColor.r, classColor.g, classColor.b)

		-- Status
		if not row.statusText then
			row.statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			row.statusText:SetPoint("LEFT", row.nameText, "RIGHT", 10, 0)
		end
		
		if inRaid then
			row.statusText:SetText("In Raid")
			row.statusText:SetTextColor(1, 0.5, 0)
			row.nameText:SetAlpha(1)
			row.classIcon:SetAlpha(1)
			row.bg:Show()
		elseif online then
			row.statusText:SetText("Online")
			row.statusText:SetTextColor(0, 1, 0)
			row.nameText:SetAlpha(1)
			row.classIcon:SetAlpha(1)
			row.bg:Hide()
		else
			row.statusText:SetText("Offline")
			row.statusText:SetTextColor(0.5, 0.5, 0.5)
			row.bg:Hide()
			row.nameText:SetAlpha(0.5)
			row.classIcon:SetAlpha(0.5)
		end
		
	
		-- Click to select row
        row:SetScript("OnClick", function()
			if PSK.SelectedPlayer == name then
				-- Deselect
				PSK.SelectedPlayer = nil
				PSK.SelectedPlayerRow = nil
				PSK.MoveUpButton:Hide()
				PSK.MoveDownButton:Hide()
				PSK.DeleteButton:Hide()
			else
				-- Select
				PSK.SelectedPlayer = name
				PSK.SelectedPlayerRow = index
				PSK.MoveUpButton:Show()
				PSK.MoveDownButton:Show()
				PSK.DeleteButton:Show()
			end

			PSK:RefreshPlayerLists()

		end)


	
        -- Highlight the selected row
        if PSK.SelectedPlayer == name then
			row.bg:SetColorTexture(0.2, 0.8, 0.2, 0.25)  -- soft green with some transparency
			row.bg:Show()
        end
		
        -- Tooltip
		row:SetScript("OnEnter", function(self)
			if self.playerData then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:ClearLines()

				local class = self.playerData.class or "SHAMAN"
				local name = self.playerData.name or "Unknown"
				local tcoords = CLASS_ICON_TCOORDS[class]
				if tcoords then
					local icon = string.format("|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:%d:%d:%d:%d|t ",
						tcoords[1]*256, tcoords[2]*256, tcoords[3]*256, tcoords[4]*256)
					local classColor = RAID_CLASS_COLORS[class] or {r = 1, g = 1, b = 1}
					GameTooltip:AddLine(icon .. name, classColor.r, classColor.g, classColor.b)
				else
					GameTooltip:AddLine(name)
				end

				GameTooltip:AddLine("Level: " .. tostring(self.playerData.level), 0.8, 0.8, 0.8)
				GameTooltip:AddLine("Location: " .. tostring(self.playerData.zone), 0.8, 0.8, 0.8)
				GameTooltip:AddLine("Last Raided: " .. tostring(self.playerData.dateLastRaided), 0.8, 0.8, 0.8)
				GameTooltip:Show()
			end
		end)

		row:SetScript("OnLeave", GameTooltip_Hide)

		
        yOffset = yOffset - 22
    end
	
	-- Hide unused rows in the pool
	local pool = PSK.RowPool[scrollChild] or {}
	for i = #names + 1, #pool do
		if pool[i] then
			pool[i]:Hide()
		end
	end
	
	-- if not PSK.SelectedPlayer then
		-- PSK.MoveUpButton:Hide()
		-- PSK.MoveDownButton:Hide()
	-- end


	-- Broadcast update
	-- SK:BroadcastUpdate("RefreshPlayerList")
end


--------------------------------------------------------
-- Update player databases to ensure data is up to date
--------------------------------------------------------
-- function PSK:UpdatePlayerData()
    -- if not PSKDB.Players then
        -- PSKDB.Players = {}
    -- end

    -- for i = 1, GetNumGuildMembers() do
        -- local fullName, _, _, level, _, _, _, _, online, _, classFileName = GetGuildRosterInfo(i)
        -- local shortName = Ambiguate(fullName or "", "short")
        -- local class = classFileName or "SHAMAN"

        -- -- Ensure the player data is stored
        -- if not PSKDB.Players[shortName] then
            -- PSKDB.Players[shortName] = {
                -- class = class,
                -- online = online,
                -- inRaid = false,
                -- level = level,
                -- zone = "Unknown",
            -- }
        -- end

        -- -- Update online status
        -- PSKDB.Players[shortName].online = online

        -- -- Check if the player is in your current raid
        -- if IsInRaid() then
            -- for j = 1, GetNumGroupMembers() do
                -- local unit = "raid" .. j
                -- if UnitName(unit) == shortName then
                    -- PSKDB.Players[shortName].inRaid = true
                    -- PSKDB.Players[shortName].online = true
                    -- break
                -- else
                    -- PSKDB.Players[shortName].inRaid = false
                -- end
            -- end
        -- else
            -- PSKDB.Players[shortName].inRaid = false
        -- end
    -- end
-- end



---------------------------------------------------
-- Handle delayed refresh after combat
---------------------------------------------------
-- -- Create a dedicated event frame for combat-related events
if not PSK.EventFrame then
    PSK.EventFrame = CreateFrame("Frame")
end

-- Register the event
PSK.EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

-- Handle the event
PSK.EventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        PSK:DebouncedRefreshPlayerLists()
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
end)


---------------------------------------------------
-- Sorts the Available player lists
---------------------------------------------------

local function SortPlayers(players)
    table.sort(players, function(a, b)
        -- Prioritize online players first
        if a.online and not b.online then
            return true
        elseif not a.online and b.online then
            return false
        else
            -- Sort alphabetically if both are online or both are offline
            return a.name < b.name
        end
    end)
end


------------------------------------------
-- Check if player is in list
------------------------------------------

function PSK:IsPlayerInList(list, targetName)
    for _, entry in ipairs(list) do
        if type(entry) == "table" and entry.name == targetName then
            return true
        elseif type(entry) == "string" and entry == targetName then
            return true
        end
    end
    return false
end




---------------------------------------------------
-- Refresh the Available player lists
---------------------------------------------------

function PSK:RefreshAvailablePlayerLists()
	-- Get or Init lists in databases
	PSKDB.MainList = PSKDB.MainList or {}
    PSKDB.TierList = PSKDB.TierList or {}
	
    -- Get the scroll children
    local mainChild = PSK.ScrollChildren.MainAvailable
    local tierChild = PSK.ScrollChildren.TierAvailable

    if not mainChild or not tierChild then
        print("[PSK] Error: MainAvailable or TierAvailable scroll frames are not initialized.")
        return
    end

    -- Clear previous children
    for _, child in ipairs({mainChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    for _, child in ipairs({tierChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    local mainList = PSKDB.MainList or {}
    local tierList = PSKDB.TierList or {}

    local availableMain = {}
    local availableTier = {}

    -- Populate available lists
    for i = 1, GetNumGuildMembers() do
        local fullName, _, _, level, _, _, _, _, online, _, classFileName = GetGuildRosterInfo(i)
        local shortName = Ambiguate(fullName or "", "short")
        local class = classFileName or "SHAMAN"

        if level == 60 then
            if not PSK:IsPlayerInList(mainList, shortName) then
                table.insert(availableMain, {name = shortName, online = online, class = class})
            end
			
            if not PSK:IsPlayerInList(tierList, shortName) then
                table.insert(availableTier, {name = shortName, online = online, class = class})
            end
        end
    end

    -- Sort lists alphabetically
	SortPlayers(availableMain)
	SortPlayers(availableTier)

     -- Function to add player rows
    local function AddPlayerRow(parent, player)
        local row = CreateFrame("Frame", nil, parent)
        row:SetSize(320, 20)
        row:SetPoint("TOPLEFT", 5, yOffset)

        -- Add Button
        local addButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        addButton:SetSize(20, 20)
        addButton:SetText("+")
        addButton:SetPoint("LEFT", row, "LEFT", 0, 0)
        addButton:SetScript("OnClick", function()
			addButton:Disable()
			C_Timer.After(0.5, function() addButton:Enable() end)

			local listName = (parent == mainChild) and "Main" or "Tier"
			local list = (listName == "Main") and PSKDB.MainList or PSKDB.TierList

			-- Prevent duplicate entries
			for _, entry in ipairs(list) do
				if type(entry) == "table" and entry.name == player.name then
					print("[PSK] " .. player.name .. " is already in the " .. listName .. " list.")
					return
				end
			end

			table.insert(list, {
				name = player.name,
				class = player.class or "UNKNOWN",
				dateLastRaided = "Never"
			})

			PSK:DebouncedRefreshAvailablePlayerLists()
			PSK:DebouncedRefreshPlayerLists()
			print("[PSK] Added " .. player.name .. " to the " .. listName .. " List.")
		end)



        -- Class Icon
        local classIcon = row:CreateTexture(nil, "ARTWORK")
        classIcon:SetSize(16, 16)
        classIcon:SetPoint("LEFT", addButton, "RIGHT", 5, 0)
        classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
        local texCoord = CLASS_ICON_TCOORDS[player.class]
        if texCoord then
            classIcon:SetTexCoord(unpack(texCoord))
        end

        -- Player Name
		local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		nameText:SetPoint("LEFT", classIcon, "RIGHT", 10, 0)

		-- Correct class color lookup
		local playerClass = player.class:upper()
		local classColor = RAID_CLASS_COLORS[playerClass] or { r = 1, g = 1, b = 1 }
		nameText:SetText(player.name)
		nameText:SetTextColor(classColor.r, classColor.g, classColor.b)
	
	
        -- Player Status
        local statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        statusText:SetPoint("LEFT", nameText, "RIGHT", 10, 0)

        -- Determine status
        local inRaid = false
        local online = player.online

        -- Check if the player is in your current raid
        if IsInRaid() then
            for i = 1, GetNumGroupMembers() do
                local unit = "raid" .. i
                if UnitName(unit) == player.name then
                    inRaid = true
                    online = true
                    break
                end
            end
        end

        -- Set status text and color
        if inRaid then
            statusText:SetText("In Raid")
            statusText:SetTextColor(1, 0.5, 0)  -- Orange for in raid
        elseif online then
            statusText:SetText("Online")
            statusText:SetTextColor(0, 1, 0)  -- Green for online
        else
            statusText:SetText("Offline")
            statusText:SetTextColor(0.5, 0.5, 0.5)  -- Gray for offline
            nameText:SetAlpha(0.5)
            classIcon:SetAlpha(0.5)
        end

        -- Add tooltip for more details
        row:SetScript("OnEnter", function()
            GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
            GameTooltip:SetText(player.name, 1, 1, 1)
            GameTooltip:AddLine("Class: " .. player.class, 0.8, 0.8, 0.8)
            GameTooltip:AddLine("Status: " .. (inRaid and "In Raid" or (online and "Online" or "Offline")), 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", GameTooltip_Hide)

        yOffset = yOffset - 22
    end

    -- Populate the Main List
    yOffset = -5
    for _, player in ipairs(availableMain) do
        AddPlayerRow(mainChild, player)
    end

    -- Populate the Tier List
    yOffset = -5
    for _, player in ipairs(availableTier) do
        AddPlayerRow(tierChild, player)
    end

end



----------------------------------------
-- Refresh Bid List
----------------------------------------

function PSK:RefreshBidList()
    if not PSK.BidEntries then return end

    local scrollChild = PSK.ScrollChildren.Bid
    local header = PSK.Headers.Bid
    if not scrollChild or not header then return end

    PSK.RowPool = PSK.RowPool or {}
    PSK.RowPool[scrollChild] = PSK.RowPool[scrollChild] or {}
    local pool = PSK.RowPool[scrollChild]

    local bidCount = #PSK.BidEntries
    header:SetText("Bids (" .. bidCount .. ")")

    -- Wipe visible list
    for _, child in ipairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Build index map from current list
	local indexMap = {}
	local list = (PSK.CurrentList == "Tier") and PSKDB.TierList or PSKDB.MainList
	if not list then list = {} end  -- fallback to empty table if nil

	for i, name in ipairs(list) do
		indexMap[name] = i
	end

	-- Sort bidders by list position; if not in list, push to end
	table.sort(PSK.BidEntries, function(a, b)
		local aIndex = indexMap[a.name] or math.huge
		local bIndex = indexMap[b.name] or math.huge
		return aIndex < bIndex
	end)

    local yOffset = -5
    for index, bidData in ipairs(PSK.BidEntries) do
        local row = pool[index]
        if not row then
            row = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            row:SetSize(220, 20)
            row:SetFrameLevel(scrollChild:GetFrameLevel() + 1)
            pool[index] = row
        end

        row:SetParent(scrollChild)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, yOffset)
        row:Show()

        -- Background
        if not row.bg then
            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()
        end
        row.bg:SetColorTexture(0, 0, 0, 0)
        row.bg:Hide()

        row:EnableMouse(true)

        -- Position
        if not row.posText then
            row.posText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.posText:SetPoint("LEFT", row, "LEFT", 5, 0)
        end
		
		row.posText:SetText(index)
        -- row.posText:SetText(bidData.position)

        -- Class Icon
        local class = bidData.class or "SHAMAN"
        if not row.classIcon then
            row.classIcon = row:CreateTexture(nil, "ARTWORK")
            row.classIcon:SetSize(16, 16)
            row.classIcon:SetPoint("LEFT", row.posText, "RIGHT", 4, 0)
        end
        if CLASS_ICON_TCOORDS[class] then
            row.classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
            row.classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
        end

        -- Name
        if not row.nameText then
            row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.nameText:SetPoint("LEFT", row.classIcon, "RIGHT", 4, 0)
        end
        row.nameText:SetText(bidData.name)


        -- Award Button
        if not row.awardButton then
            row.awardButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.awardButton:SetSize(16, 16)
            row.awardButton:SetPoint("LEFT", row.nameText, "RIGHT", 30, 0)
            row.awardButton:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Check")
            row.awardButton:GetNormalTexture():SetTexCoord(0.2, 0.8, 0.2, 0.8)
            row.awardButton:SetText("")
        end
		
        local safeIndex = index  -- capture correctly

		row.awardButton:SetScript("OnClick", function(self)
			local row = self:GetParent()
			if row and row.bg then
				row.bg:SetColorTexture(0, 1, 0, 0.4)
				local pulse = row:CreateAnimationGroup()
				local fadeOut = pulse:CreateAnimation("Alpha")
				fadeOut:SetFromAlpha(1)
				fadeOut:SetToAlpha(0)
				fadeOut:SetDuration(0.4)
				fadeOut:SetOrder(1)
				local fadeIn = pulse:CreateAnimation("Alpha")
				fadeIn:SetFromAlpha(0)
				fadeIn:SetToAlpha(1)
				fadeIn:SetDuration(0.4)
				fadeIn:SetOrder(2)
				pulse:SetLooping("NONE")
				pulse:Play()
			end

			PSK.SelectedPlayer = bidData.name
			PSK:AwardPlayer(safeIndex)
		end)
		
        row.awardButton:SetScript("OnEnter", function(self)
            local row = self:GetParent()
            if row and row.bg then
                row.bg:SetColorTexture(0.2, 1, 0.2, 0.25)
                row.bg:Show()
            end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Award Loot", 1, 1, 1)
            GameTooltip:AddLine("Click to award loot to this player.", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
		
        row.awardButton:SetScript("OnLeave", function(self)
            local row = self:GetParent()
            if row and row.bg then
                row.bg:Hide()
            end
            GameTooltip:Hide()
        end)

        yOffset = yOffset - 22
    end

    -- Hide unused bid rows
    for i = #PSK.BidEntries + 1, #pool do
        if pool[i] then pool[i]:Hide() end
    end
end




-------------------------------------------
-- Refresh member data when group changes.
-------------------------------------------

-- function PSK:RefreshGroupMemberData()
    -- local function updateIfNeeded(unit)
        -- if not UnitExists(unit) then return end

        -- local name = Ambiguate(UnitName(unit), "short")
        -- if not name then return end

        -- local listed = false
        -- for _, n in ipairs(PSKDB.MainList) do
            -- if Ambiguate(n, "short") == name then
                -- listed = true
                -- break
            -- end
        -- end
        -- for _, n in ipairs(PSKDB.TierList) do
            -- if Ambiguate(n, "short") == name then
                -- listed = true
                -- break
            -- end
        -- end

        -- if not listed then return end

        -- local data = PSKDB.Players[name]
		-- local needsUpdate = false

		-- if not data then
			-- needsUpdate = true
		-- else
			-- if data.class == "UNKNOWN" or data.class == "SHAMAN" then
				-- needsUpdate = true
			-- elseif data.level == "???" or not tonumber(data.level) then
				-- needsUpdate = true
			-- end
		-- end


        -- if needsUpdate then
            -- local _, class = UnitClass(unit)
            -- local level = UnitLevel(unit)
            -- local zone = GetZoneText()
            -- local online = UnitIsConnected(unit)
            -- local inRaid = UnitInRaid(unit) ~= nil

            -- PSKDB.Players[name] = {
                -- class = class or "UNKNOWN",
                -- level = level or "???",
                -- zone = zone or "Unknown",
                -- online = online or false,
                -- inRaid = inRaid,
            -- }

            -- PSK:DebouncedRefreshPlayerLists()
        -- end
    -- end

    -- if IsInRaid() then
        -- for i = 1, MAX_RAID_MEMBERS do
            -- updateIfNeeded("raid" .. i)
        -- end
    -- elseif IsInGroup() then
        -- for i = 1, GetNumGroupMembers() - 1 do
            -- updateIfNeeded("party" .. i)
        -- end
        -- updateIfNeeded("player") -- also update the user themselves if listed
    -- end
-- end


------------------------------------------------
-- Function to enable reusing of rows
-- This should prevent redrawing every refresh
------------------------------------------------

function PSK:GetOrCreateRow(index, parent, rowType)
    PSK.RowPool = PSK.RowPool or {}
    PSK.RowPool[parent] = PSK.RowPool[parent] or {}
    local pool = PSK.RowPool[parent]

    local row = pool[index]
    if not row then
        row = CreateFrame("Button", nil, parent, "BackdropTemplate")
        row:SetSize(650, 20)
        row:SetFrameLevel(parent:GetFrameLevel() + 1)

        -- Background
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetColorTexture(0, 0, 0, 0)
        row.bg:Hide()

        pool[index] = row
    end

	if row:GetParent() ~= parent then
		row:SetParent(parent)
	end

    -- Log rows setup
    if rowType == "Log" and not row.classIcon then
        row.classIcon = row:CreateTexture(nil, "ARTWORK")
        row.classIcon:SetSize(16, 16)
        row.classIcon:SetPoint("LEFT", row, "LEFT", 5, 0)

        row.playerText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.playerText:SetPoint("LEFT", row.classIcon, "RIGHT", 5, 0)

        row.iconTexture = row:CreateTexture(nil, "ARTWORK")
        row.iconTexture:SetSize(16, 16)
        row.iconTexture:SetPoint("LEFT", row.playerText, "RIGHT", 6, 0)

        row.itemText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.itemText:SetPoint("LEFT", row.iconTexture, "RIGHT", 6, 0)

        row.timeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.timeText:SetPoint("LEFT", row, "LEFT", 480, 0)
    end

    -- Player/Bid rows setup (minimal setup here; add more as needed)
    if rowType == "Player" and not row.posText then
        row.posText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.posText:SetPoint("LEFT", row, "LEFT", 5, 0)

        row.classIcon = row:CreateTexture(nil, "ARTWORK")
        row.classIcon:SetSize(16, 16)
        row.classIcon:SetPoint("LEFT", row.posText, "RIGHT", 8, 0)

        row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.nameText:SetPoint("LEFT", row.classIcon, "RIGHT", 8, 0)

        row.statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.statusText:SetPoint("LEFT", row.nameText, "RIGHT", 10, 0)
    end

    return row
end


-------------------------------------------
-- Refresh only after a short delay
-------------------------------------------

function PSK:DebouncedRefreshAvailablePlayerLists()
    if refreshAvailablePlayers then return end
    refreshAvailablePlayers = true
    C_Timer.After(0.5, function()
        refreshAvailablePlayers = false
        PSK:RefreshAvailablePlayerLists()
    end)
end

function PSK:DebouncedRefreshPlayerLists()
    if refreshPlayerScheduled then return end
    refreshPlayerScheduled = true
    C_Timer.After(0.5, function()
        refreshPlayerScheduled = false
        PSK:RefreshPlayerLists()
    end)
end

function PSK:DebouncedRefreshBidList()
    if refreshBidScheduled then return end
    refreshBidScheduled = true
    C_Timer.After(0.5, function()
        refreshBidScheduled = false
        PSK:RefreshBidList()
    end)
end

function PSK:DebouncedRefreshLootList()
    if refreshLootScheduled then return end
    refreshLootScheduled = true
    C_Timer.After(0.5, function()
        refreshLootScheduled = false
        PSK:RefreshLootList()
    end)
end

function PSK:DebouncedRefreshLogList()
    if refreshLogScheduled then return end
    refreshLogScheduled = true
    C_Timer.After(0.5, function()
        refreshLogScheduled = false
        PSK:RefreshLogList()
    end)
end

-------------------------------------------
-- Logging function
-------------------------------------------

-- function print(msg, ...)
	-- if PSK.Settings and PSK.Settings.debugEnabled then
		-- print("[PSK DEBUG]    ", string.format(msg, ...))
	-- end
-- end



--------------------------------------------
-- Update last raid date
--------------------------------------------

-- function PSK:UpdateLastRaidDate(playerName)
	-- local function update(list)
		-- for _, entry in ipairs(list) do
			-- if entry.name == playerName then
				-- entry.dateLastRaided = date("%m-%d-%Y")
				-- return
			-- end
		-- end
	-- end
	
	-- update(PSKDB.MainList)
	-- update(PSKDB.TierList)
-- end



------------------------------
-- Converts table name entry
------------------------------

-- function PSK:GetName(entry)
    -- return type(entry) == "table" and entry.name or entry
-- end


-------------------------------------------
-- Serialize Data
-------------------------------------------

-- function PSK:Serialize(tbl)
	-- return table.concat( { tbl.type, tbl.timestamp }, "|")


-------------------------------------------
-- Broadcast Update
-------------------------------------------

-- function PSK:BroadcastUpdate(eventType)
	-- local payload = {
		-- type = eventType,
		-- timestamp = time()
	-- }
	
	-- local message = PSK:Serialize(payload)
	
	-- C_ChatInfo.SendAddonMessage(PSK.PSK_PREFIX, message, "GUILD") -- RAID, PARTY, and WHISPER work also
	
-- end


PSK:DebouncedRefreshLogList()
