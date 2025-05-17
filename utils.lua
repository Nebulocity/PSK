---------------------------------------------------
-- This file is for helper functions for the addon
---------------------------------------------------

local PSK = select(2, ...)

-- Facilites row pools.
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

function AwardPlayer(index)
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
    local playerClass = playerEntry and playerEntry.class
    local list = (PSK.CurrentList == "Main") and PSKDB.MainList or PSKDB.TierList
    
	-- Use the selected item instead of relying on index
	local item = PSK.SelectedItemData

	-- Defensive fallback
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
            if not BiddingOpen then
                PSK.BidButton:Disable()
            end
            PSK:RefreshLootList()
        end)

        fade:Play()
    else
        PSK.SelectedLootRow = nil
        PSK.SelectedItem = nil
        if not BiddingOpen then
            PSK.BidButton:Disable()
        end
        PSK:RefreshLootList()
    end

    -- Remove from bids
    table.remove(PSK.BidEntries, index)

    -- Move awarded player to end of list
    for i = #list, 1, -1 do
        if list[i]:lower() == playerName:lower() then
            table.remove(list, i)
            break
        end
    end
	
    table.insert(list, playerName)

	-- Get class color
	local color = RAID_CLASS_COLORS[playerClass or "SHAMAN"] or { r = 1, g = 1, b = 1 }
	local coloredName = string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, playerName)

	local itemLink = PSK.SelectedItem
	local itemName = GetItemInfo(itemLink) or itemLink
	Announce("[PSK] " .. itemLink .. " awarded to " .. playerName)

    -- Log the award
    table.insert(PSKDB.LootLogs, {
        player = playerName,
        class = playerClass or "PRIEST",
        itemLink = item.itemLink,
        itemTexture = item.itemTexture or "Interface\\Icons\\INV_Misc_QuestionMark",
        timestamp = date("%I:%M%p %m/%d/%Y"),
    })

    -- Remove from visible + persistent loot lists
    table.remove(PSK.LootDrops, index)
    table.remove(PSKGlobal.LootDrops, index)

    if PSK.RefreshLogList then
        PSK:RefreshLogList()
    end

    PSK:RefreshPlayerList()
    PSK:RefreshBidList()
    PlaySound(12867)
end



---------------------------------
-- Pass on current player
---------------------------------

function PassPlayer()
    -- Nothing needed here -- selection will be cleared in the UI
end


----------------------------------------------
-- Announce to party/raid 
----------------------------------------------

function Announce(message)
    local playerName = UnitName("player")

    if IsInRaid() then
        SendChatMessage(message, "RAID")
    elseif IsInGroup() then
        SendChatMessage(message, "PARTY")
    else
        SendChatMessage(message, "WHISPER", nil, playerName)
    end
	
end


----------------------------------------------
-- I CAN'T REMEMBER WHAT THIS FRAME IS FOR?
----------------------------------------------

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
    if not PSKDB.LootLogs then return end

    local scrollChild = PSK.ScrollChildren.Loot
    local header = PSK.Headers.Loot
    if not scrollChild or not header then return end

    -- Clear previous children
    for _, child in ipairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    if PSK.RecordingWarningDrops then
        if not PSK.LootRecordingActive then
            PSK.RecordingWarningDrops:Show()
            if not PSK.RecordingWarningDrops.pulse:IsPlaying() then
                PSK.RecordingWarningDrops.pulse:Play()
            end
        else
            PSK.RecordingWarningDrops:Hide()
            PSK.RecordingWarningDrops.pulse:Stop()
        end
    end

    if PSK.RecordingWarningLogs then
        if not PSK.LootRecordingActive then
            PSK.RecordingWarningLogs:Show()
            if not PSK.RecordingWarningLogs.pulse:IsPlaying() then
                PSK.RecordingWarningLogs.pulse:Play()
            end
        else
            PSK.RecordingWarningLogs:Hide()
            PSK.RecordingWarningLogs.pulse:Stop()
        end
    end

    PSK.RowPool = PSK.RowPool or {}
    PSK.RowPool[scrollChild] = PSK.RowPool[scrollChild] or {}
    local pool = PSK.RowPool[scrollChild]

    local yOffset = -5

    for index, loot in ipairs(PSKGlobal.LootDrops) do
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
                print("[PSK] Selected item for bidding: " .. row.itemLink)

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
    for i = #PSKGlobal.LootDrops + 1, #pool do
        if pool[i] then pool[i]:Hide() end
    end

    local threshold = PSK.Settings.lootThreshold or 3
    local rarityNames = {
        [0] = "Poor", [1] = "Common", [2] = "Uncommon",
        [3] = "Rare", [4] = "Epic", [5] = "Legendary"
    }
    local rarityName = rarityNames[threshold] or "?"
    -- header:SetText("Loot Drops (" .. #PSKGlobal.LootDrops .. ") " .. rarityName .. "+")
    header:SetText("Loot Drops")

    -- PSK:BroadcastUpdate("RefreshLootList")
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

function PSK:RefreshPlayerList()

	if InCombatLockdown() then
		if PSK.EventFrame and PSK.EventFrame.RegisterEvent then
			PSK.EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		end
		return
	end

	
    if not PSKDB or not PSK.CurrentList then return end
	
	-- Ensure the player data is up to date
	PSK:UpdatePlayerData()


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
    for index, name in ipairs(names) do

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
		
		row.bg:Hide()		
		
        -- Pull real player info
        local playerData = PSKDB.Players and PSKDB.Players[name]
        local class = (playerData and playerData.class) or "SHAMAN"
        local online = (playerData and playerData.online) or false
        local inRaid = (playerData and playerData.inRaid) or false
        local level = (playerData and playerData.level) or "???"
        local zone = (playerData and playerData.zone) or "???"

        row.playerData = {
            class = class,
            online = online,
            inRaid = inRaid,
            name = name,
            level = playerData and playerData.level or "???",
			zone = playerData and playerData.zone or "???"
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
		local fileClass = string.upper(playerClass)

		-- Corrected class color lookup
		local classColor = RAID_CLASS_COLORS[fileClass] or { r = 1, g = 1, b = 1 }

		-- Create the player name text with the correct color
		if not row.nameText then
			row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			row.nameText:SetPoint("LEFT", row.classIcon, "RIGHT", 8, 0)
		end
		row.nameText:SetText(name)
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
            PSK.SelectedPlayerRow = index
            PSK.SelectedPlayer = name
            PSK:RefreshPlayerList()
        end)

        -- Highlight the selected row
        if PSK.SelectedPlayer == name then
            row.bg:Show()

            -- Add Up Arrow with Flash Animation
			local upButton = CreateFrame("Button", nil, row)
			upButton:SetSize(24, 24)
			upButton:SetPoint("RIGHT", row, "RIGHT", -20, 0)
			upButton:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
			upButton:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
			upButton:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")

			upButton:SetScript("OnClick", function()
				if index > 1 then
					local movedName = table.remove(names, index)
					table.insert(names, index - 1, movedName)
					PSK.SelectedPlayer = movedName
					PSK.SelectedPlayerRow = index - 1
					PSK:RefreshPlayerList()

					-- Flash effect
					row.bg:SetColorTexture(0.2, 0.8, 0.2, 0.4)
					C_Timer.After(0.1, function()
						row.bg:SetColorTexture(0, 0.5, 1, 0.15)
					end)

					-- Play sound
					PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
				end
			end)


            -- Add Down Arrow with Flash Animation
			local downButton = CreateFrame("Button", nil, row)
			downButton:SetSize(24, 24)
			downButton:SetPoint("RIGHT", row, "RIGHT", 0, 0)
			downButton:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
			downButton:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight")
			downButton:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")

			downButton:SetScript("OnClick", function()
				if index < #names then
					local movedName = table.remove(names, index)
					table.insert(names, index + 1, movedName)
					PSK.SelectedPlayer = movedName
					PSK.SelectedPlayerRow = index + 1
					PSK:RefreshPlayerList()

					-- Flash effect
					row.bg:SetColorTexture(0.8, 0.2, 0.2, 0.4)
					C_Timer.After(0.1, function()
						row.bg:SetColorTexture(0, 0.5, 1, 0.15)
					end)

					-- Play sound
					PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
				end
			end)
        end

        -- Tooltip
		if not row.tooltipBound then
			row:SetScript("OnEnter", function(self)
				if self.playerData then
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:ClearLines()
					local tcoords = CLASS_ICON_TCOORDS[class]
					if tcoords then
						local icon = string.format("|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:%d:%d:%d:%d|t ",
							tcoords[1]*256, tcoords[2]*256, tcoords[3]*256, tcoords[4]*256)
						GameTooltip:AddLine(icon .. self.playerData.name, RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b)
					else
						GameTooltip:AddLine(self.playerData.name or "Unknown")
					end

					GameTooltip:AddLine("Level: " .. self.playerData.level, 0.8, 0.8, 0.8)
					GameTooltip:AddLine("Location: " .. self.playerData.zone, 0.8, 0.8, 0.8)
					GameTooltip:Show()
				end
			end)
			row:SetScript("OnLeave", GameTooltip_Hide)
			
			row.tooltipBound = true
		end 
		
        yOffset = yOffset - 22
    end
	
	-- Hide unused rows in the pool
	local pool = PSK.RowPool[scrollChild] or {}
	for i = #names + 1, #pool do
		if pool[i] then
			pool[i]:Hide()
		end
	end
	
	-- Broadcast update
	-- PSK:BroadcastUpdate("RefreshPlayerList")
end


--------------------------------------------------------
-- Update player databases to ensure data is up to date
--------------------------------------------------------
function PSK:UpdatePlayerData()
    if not PSKDB.Players then
        PSKDB.Players = {}
    end

    for i = 1, GetNumGuildMembers() do
        local fullName, _, _, level, _, _, _, _, online, _, classFileName = GetGuildRosterInfo(i)
        local shortName = Ambiguate(fullName or "", "short")
        local class = classFileName or "SHAMAN"

        -- Ensure the player data is stored
        if not PSKDB.Players[shortName] then
            PSKDB.Players[shortName] = {
                class = class,
                online = online,
                inRaid = false,
                level = level,
                zone = "Unknown",
            }
        end

        -- Update online status
        PSKDB.Players[shortName].online = online

        -- Check if the player is in your current raid
        if IsInRaid() then
            for j = 1, GetNumGroupMembers() do
                local unit = "raid" .. j
                if UnitName(unit) == shortName then
                    PSKDB.Players[shortName].inRaid = true
                    PSKDB.Players[shortName].online = true
                    break
                else
                    PSKDB.Players[shortName].inRaid = false
                end
            end
        else
            PSKDB.Players[shortName].inRaid = false
        end
    end
end



---------------------------------------------------
-- Handle delayed refresh after combat
---------------------------------------------------
-- Create a dedicated event frame for combat-related events
if not PSK.EventFrame then
    PSK.EventFrame = CreateFrame("Frame")
end

-- Register the event
PSK.EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

-- Handle the event
PSK.EventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        PSK:RefreshPlayerList()
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        print("[PSK] Player list updated after combat.")
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

---------------------------------------------------
-- Refresh the Available player lists
---------------------------------------------------

function PSK:RefreshAvailableMembers()
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
            if not tContains(mainList, shortName) then
                table.insert(availableMain, {name = shortName, online = online, class = class})
            end
            if not tContains(tierList, shortName) then
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
            local list = (parent == mainChild) and PSKDB.MainList or PSKDB.TierList
            table.insert(list, player.name)
            PSK:RefreshAvailableMembers()
            PSK:RefreshPlayerList()
            print("[PSK] Added " .. player.name .. " to the " .. ((parent == mainChild) and "Main" or "Tier") .. " List.")
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




---------------------------------------------------
-- Highlight the selected player in main/tier list
---------------------------------------------------

function PSK:HighlightSelectedPlayer()
    local scrollChildren = PSK.ScrollChildren.Main
    if not scrollChildren or not PSK.SelectedPlayer then return end

    for _, row in ipairs({scrollChildren:GetChildren()}) do
        if row.playerData and row.playerData.name == PSK.SelectedPlayer then
            if not row.Highlight then
                row.Highlight = row:CreateTexture(nil, "ARTWORK")
                row.Highlight:SetAllPoints(row)
                row.Highlight:SetBlendMode("ADD")
            end

            -- Set highlight to class color
            local class = row.playerData.class or "SHAMAN"
            local color = RAID_CLASS_COLORS[class] or { r = 1, g = 1, b = 1 }
            row.Highlight:SetColorTexture(color.r, color.g, color.b, 0.25)
            row.Highlight:Show()
        else
            if row.Highlight then
                row.Highlight:Hide()
            end
        end
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

    -- Sort by position (assumes indexMap is defined elsewhere)
    table.sort(PSK.BidEntries, function(a, b)
        local indexA = indexMap[a] or math.huge
        local indexB = indexMap[b] or math.huge
        return indexA < indexB
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
        row.posText:SetText(bidData.position)

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

        -- Warning Icon
        if bidData.notListed and not row.warningIcon then
            row.warningIcon = row:CreateTexture(nil, "OVERLAY")
            row.warningIcon:SetSize(16, 16)
            row.warningIcon:SetPoint("LEFT", row.nameText, "RIGHT", 8, 0)
            row.warningIcon:SetTexture("Interface\\Common\\UI-StopButton")

            row.warningIcon:SetScript("OnEnter", function()
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:SetText(bidData.name, 1, 0.2, 0.2)
                GameTooltip:AddLine("This player is not in the Main or Tier lists.", 1, 0.7, 0.2)
                GameTooltip:Show()
            end)
            row.warningIcon:SetScript("OnLeave", GameTooltip_Hide)

            local pulse = row:CreateAnimationGroup()
            local fadeOut = pulse:CreateAnimation("Alpha")
            fadeOut:SetFromAlpha(0.8)
            fadeOut:SetToAlpha(0.4)
            fadeOut:SetDuration(0.5)
            fadeOut:SetOrder(1)
            local fadeIn = pulse:CreateAnimation("Alpha")
            fadeIn:SetFromAlpha(0.4)
            fadeIn:SetToAlpha(0.8)
            fadeIn:SetDuration(0.5)
            fadeIn:SetOrder(2)
            pulse:SetLooping("REPEAT")
            pulse:Play()

            row.bg:SetColorTexture(1, 0, 0, 0.2)
            row.bg:Show()
        end

        -- Award Button
        if not row.awardButton then
            row.awardButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.awardButton:SetSize(16, 16)
            row.awardButton:SetPoint("LEFT", row.nameText, "RIGHT", 30, 0)
            row.awardButton:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Check")
            row.awardButton:GetNormalTexture():SetTexCoord(0.2, 0.8, 0.2, 0.8)
            row.awardButton:SetText("")
        end
        row.awardButton.index = index
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
            AwardPlayer(self.index)
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

        -- Pass Button
        if not row.passButton then
            row.passButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.passButton:SetSize(16, 16)
            row.passButton:SetPoint("LEFT", row.awardButton, "RIGHT", 15, 0)

            local passTexture = row.passButton:CreateTexture(nil, "ARTWORK")
            passTexture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
            passTexture:SetAllPoints(row.passButton)
            passTexture:SetTexCoord(0.2, 0.8, 0.2, 0.8)
            row.passButton:SetNormalTexture(passTexture)

            row.passButton:SetText("")
        end
        row.passButton.index = index
        row.passButton:SetScript("OnClick", function(self)
            if self.index then
                table.remove(PSK.BidEntries, self.index)
                PSK:RefreshBidList()
            end
        end)
        row.passButton:SetScript("OnEnter", function(self)
            local row = self:GetParent()
            if row and row.bg then
                row.bg:SetColorTexture(1, 0.2, 0.2, 0.25)
                row.bg:Show()
            end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Pass on Loot", 1, 1, 1)
            GameTooltip:AddLine("Click to remove this player from bidding.", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        row.passButton:SetScript("OnLeave", function(self)
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


----------------------------------------
-- Get Loot Threshold
----------------------------------------

function PSK:GetLootThresholdName()
	local threshold = GetLootThreshold()
	local qualityNames = {
		[0] = "Poor",
		[1] = "Common",
		[2] = "Uncommon",
		[3] = "Rare",
		[4] = "Epic",
		[5] = "Legendary"
	}

	return qualityNames[threshold] or ("Unknown (" .. threshold .. ")")
end

-------------------------------------------
-- Update the Loot Threshold On Change
-------------------------------------------

function PSK:UpdateLootThresholdLabel(newThreshold)
    if not PSK.LootLabel then return end

    -- Use the provided threshold, or default to the current settings
    local threshold = newThreshold or PSK.Settings.lootThreshold or 3

    -- Update the settings
    PSK.Settings.lootThreshold = threshold
    PSKDB.Settings.lootThreshold = threshold

    -- Get the name and color for the threshold
    local name = PSK.RarityNames[threshold] or "Rare"
    local color = PSK.RarityColors[threshold] or "ffffff"

    -- Update the label
    PSK.LootLabel:SetText("|cff" .. color .. name .. "+|r")
end


--------------------------------------------
-- Add Import/Export Section to Settings Tab
--------------------------------------------

function PSK:ExportLists()
    -- Format the lists with one name per line, comma-separated
    local function formatList(list)
        local formatted = {}
        for _, name in ipairs(list or {}) do
            table.insert(formatted, name .. ",")
        end
        return table.concat(formatted, "\n")
    end
    
    local mainList = formatList(PSKDB.MainList or {})
    local tierList = formatList(PSKDB.TierList or {})
    
    return mainList, tierList
end


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
            -- if guildMembers[trimmedName:lower()] then
                -- table.insert(PSKDB.MainList, trimmedName)
            -- else
                -- print("|cffff0000[PSK] Warning: " .. trimmedName .. " is not in your guild and was not added to the Main List.|r")
            -- end
        end
    end

    -- Import Tier List
    for name in tierText:gmatch("[^,\n]+") do
        local trimmedName = name:match("^%s*(.-)%s*$")
        if trimmedName ~= "" then
            
			table.insert(PSKDB.TierList, trimmedName)
			-- if guildMembers[trimmedName:lower()] then
                -- table.insert(PSKDB.TierList, trimmedName)
            -- else
                -- print("|cffff0000[PSK] Warning: " .. trimmedName .. " is not in your guild and was not added to the Tier List.|r")
            -- end
        end
    end

    -- Update the UI
    PSK:RefreshPlayerList()
    print("[PSK] Import complete. Main List: " .. #PSKDB.MainList .. " players, Tier List: " .. #PSKDB.TierList .. " players.")
end


-------------------------------------------
-- Refresh member data when group changes.
-------------------------------------------

function PSK:RefreshGroupMemberData()
    local function updateIfNeeded(unit)
        if not UnitExists(unit) then return end

        local name = Ambiguate(UnitName(unit), "short")
        if not name then return end

        local listed = false
        for _, n in ipairs(PSKDB.MainList) do
            if Ambiguate(n, "short") == name then
                listed = true
                break
            end
        end
        for _, n in ipairs(PSKDB.TierList) do
            if Ambiguate(n, "short") == name then
                listed = true
                break
            end
        end

        if not listed then return end

        local data = PSKDB.Players[name]
		local needsUpdate = false

		if not data then
			needsUpdate = true
		else
			if data.class == "UNKNOWN" or data.class == "SHAMAN" then
				needsUpdate = true
			elseif data.level == "???" or not tonumber(data.level) then
				needsUpdate = true
			end
		end


        if needsUpdate then
            local _, class = UnitClass(unit)
            local level = UnitLevel(unit)
            local zone = GetZoneText()
            local online = UnitIsConnected(unit)
            local inRaid = UnitInRaid(unit) ~= nil

            PSKDB.Players[name] = {
                class = class or "UNKNOWN",
                level = level or "???",
                zone = zone or "Unknown",
                online = online or false,
                inRaid = inRaid,
            }

            PSK:RefreshPlayerList()
        end
    end

    if IsInRaid() then
        for i = 1, MAX_RAID_MEMBERS do
            updateIfNeeded("raid" .. i)
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            updateIfNeeded("party" .. i)
        end
        updateIfNeeded("player") -- also update the user themselves if listed
    end
end


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


PSK:RefreshLogList()
