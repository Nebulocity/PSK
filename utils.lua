-- utils.lua
-- Helper functions for PSK
local PSK = select(2, ...)

PSK.ScrollChildren = PSK.ScrollChildren or {}
PSK.Headers = PSK.Headers or {}
PSK.ScrollFrames = PSK.ScrollFrames or {}


-- Award selected player (move them to bottom, remove from bid list)
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

function PerformAward(index)
    local playerEntry = PSK.BidEntries and PSK.BidEntries[index]
    local playerName = playerEntry and playerEntry.name
    local list = (PSK.CurrentList == "Main") and PSKDB.MainList or PSKDB.TierList

	-- Fade out the selected loot row
	if PSK.SelectedLootRow and PSK.SelectedLootRow.bg then
		local row = PSK.SelectedLootRow
		local fade = row:CreateAnimationGroup()
		local fadeOut = fade:CreateAnimation("Alpha")
		fadeOut:SetFromAlpha(1)
		fadeOut:SetToAlpha(0)
		fadeOut:SetDuration(0.5)
		fadeOut:SetOrder(1)

		fade:SetScript("OnFinished", function()
			-- After fade completes, clear the selection
			row.bg:SetColorTexture(0, 0, 0, 0)
			PSK.SelectedLootRow = nil
			PSK.SelectedItem = nil
			if not BiddingOpen then
				PSK.BidButton:Disable()
			end

			PSK.LootDrops = {}
			PSK:RefreshLootList()
		end)

		fade:Play()
	else
		-- If no selected row, just fallback clear logic
		PSK.SelectedLootRow = nil
		PSK.SelectedItem = nil
		
		if not BiddingOpen then
			PSK.BidButton:Disable()
		end

		PSK.LootDrops = {}
		PSK:RefreshLootList()
	end

    table.remove(PSK.BidEntries, index)

    local found = false
    for i = #list, 1, -1 do
        if list[i]:lower() == playerName:lower() then
            table.remove(list, i)
            found = true
            break
        end
    end

    table.insert(list, playerName)

	local item = PSK.SelectedItem
	if item then
		Announce("[PSK] " .. playerName .. " receives " .. item .. "!")
	else
		Announce("[PSK] " .. playerName .. " receives loot.")
	end


    Announce("[PSK] Awarded loot to " .. playerName .. "!")
		
    PSK:RefreshGuildList()
    PSK:RefreshBidList()
    PlaySound(12867)
end




-- Pass action (just clears selection)
function PassPlayer()
    -- Nothing needed here -- selection will be cleared in the UI
end

-- SaveGuildMembers: save level 60s
function SaveGuildMembers()
    if not IsInGuild() then return end
    wipe(PSKDB)

    local total = GetNumGuildMembers()
    for i = 1, total do
        local name, _, _, level, classFileName, _, _, _, online = GetGuildRosterInfo(i)
        if name and level == 60 then
            name = Ambiguate(name, "short")
            local token = classFileName and string.upper(classFileName) or "UNKNOWN"
            PSKDB[name] = {
                class  = token,
                online = online,
                seen   = date("%Y-%m-%d %H:%M"),
            }
        end
    end
end

-- Refresh Roster
function RefreshRoster()
    if not IsInGuild() then return end
    GuildRoster()
end

function Announce(message)
	if IsInRaid() then
		--SendChatMessage(message, "RAID")
		SendChatMessage(message, "PARTY")
	else
		print(message)
	end
end

local DEFAULT_COLUMN_WIDTH = 220

local COLUMN_HEIGHT = 355

-- Helper to create bordered scroll frames with header
-- utils.lua
-- Helper to create bordered scroll frames with header

local DEFAULT_COLUMN_WIDTH = 220
local COLUMN_HEIGHT = 355

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

    -- Rebuild PSK.LootDrops from logs
    -- PSK.LootDrops = {}
    -- for _, log in ipairs(PSKDB.LootLogs) do
        -- local itemName, _, _, _, _, _, _, _, _, icon = GetItemInfo(log.itemLink)
        -- table.insert(PSK.LootDrops, {
            -- itemLink = log.itemLink,
            -- itemTexture = icon or "Interface\\Icons\\INV_Misc_QuestionMark",
            -- itemName = itemName or "Unknown"
        -- })
    -- end

    local scrollChild = PSK.ScrollChildren.Loot
    local header = PSK.Headers.Loot
    if not scrollChild or not header then return end

    -- Clear previous children
    for _, child in ipairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    local yOffset = -5
    for index, loot in ipairs(PSK.LootDrops) do
        local row = CreateFrame("Button", nil, scrollChild)
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetColorTexture(0, 0, 0, 0)
        row:SetSize(240, 20)
        row:SetPoint("TOP", 0, yOffset)

        local iconTexture = row:CreateTexture(nil, "ARTWORK")
        iconTexture:SetSize(16, 16)
        iconTexture:SetPoint("LEFT", row, "LEFT", 5, 0)
        iconTexture:SetTexture(loot.itemTexture)

        local itemText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        itemText:SetPoint("LEFT", iconTexture, "RIGHT", 8, 0)
        itemText:SetText(loot.itemLink)

        -- Click to highlight and select
        row:SetScript("OnClick", function()
            if PSK.SelectedLootRow and PSK.SelectedLootRow.bg then
                PSK.SelectedLootRow.bg:SetColorTexture(0, 0, 0, 0)
            end

            row.bg:SetColorTexture(0.2, 0.6, 1, 0.2)
            PSK.SelectedLootRow = row
            PSK.SelectedItem = loot.itemLink
            PSK.BidButton:Enable()

            Announce("[PSK] Selected item for bidding: " .. loot.itemLink)

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

        yOffset = yOffset - 22
    end

    -- Update header
    local threshold = PSK.Settings.lootThreshold or 3
    local rarityNames = {
        [0] = "Poor", [1] = "Common", [2] = "Uncommon",
        [3] = "Rare", [4] = "Epic", [5] = "Legendary"
    }
    local rarityName = rarityNames[threshold] or "?"
    header:SetText("Loot Drops (" .. #PSK.LootDrops .. ") " .. rarityName .. "+")
end


function PSK:RefreshLogList()
    if not PSKDB.LootLogs then return end

    local scrollChild = PSK.ScrollChildren.Logs
    local header = PSK.Headers.Logs
    if not scrollChild or not header then return end

    -- Clear previous children
    for _, child in ipairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    local yOffset = -5
    for index = #PSKDB.LootLogs, 1, -1 do -- newest first
        local log = PSKDB.LootLogs[index]

        local row = CreateFrame("Frame", nil, scrollChild)
        row:SetSize(650, 20)
        row:SetPoint("TOPLEFT", 0, yOffset)

        -- Class icon (optional; skip if not using for now)
        --[[
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("LEFT", row, "LEFT", 5, 0)
        PSK:SetClassIcon(icon, log.class)
        ]]

        -- Player Name
        local playerText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        playerText:SetPoint("LEFT", row, "LEFT", 5, 0)
        playerText:SetText(log.player)

        -- Item Link
        local itemText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        itemText:SetPoint("LEFT", playerText, "RIGHT", 10, 0)
        itemText:SetText(log.itemLink)

        -- Timestamp
        local timeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        timeText:SetPoint("LEFT", row, "LEFT", 480, 0)
        timeText:SetText(log.timestamp)

        yOffset = yOffset - 22
    end

    -- Optional header update
    if header then
        header:SetText("Loot Log (" .. #PSKDB.LootLogs .. ")")
    end
end


----------------------------------------
-- Refresh Guild List (for Main or Tier)
----------------------------------------

function PSK:RefreshGuildList()
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
    for index, name in ipairs(names) do
        local row = CreateFrame("Button", nil, scrollChild)

        row:SetSize(200, 20)
        row:SetPoint("TOPLEFT", 0, yOffset)

        -- Background for status glow
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetColorTexture(1, 0.5, 0, 0.2)
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
            level = level,
            zone = zone,
        }

        -- Position
        local posText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        posText:SetPoint("LEFT", row, "LEFT", 5, 0)
        posText:SetText(index)

        -- Class icon
        local classIcon = row:CreateTexture(nil, "ARTWORK")
        classIcon:SetSize(16, 16)
        classIcon:SetPoint("LEFT", posText, "RIGHT", 8, 0)
        classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
        if CLASS_ICON_TCOORDS[class] then
            classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
        end

        -- Name
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("LEFT", classIcon, "RIGHT", 8, 0)
        nameText:SetText(name)

        -- Status
        local statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        statusText:SetPoint("LEFT", nameText, "RIGHT", 10, 0)

        if inRaid then
            statusText:SetText("In Raid")
            statusText:SetTextColor(1, 0.5, 0)
            row.bg:Show()
            row.elapsed = 0
            row:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = (self.elapsed or 0) + elapsed
                local alpha = 0.2 + 0.1 * math.sin(self.elapsed * 3)
                self.bg:SetAlpha(alpha)
            end)
        elseif online then
            statusText:SetText("Online")
            statusText:SetTextColor(0, 1, 0)
            row.bg:Hide()
        else
            statusText:SetText("Offline")
            statusText:SetTextColor(0.5, 0.5, 0.5)
            row.bg:Hide()
            nameText:SetAlpha(0.5)
            classIcon:SetAlpha(0.5)
        end

        -- Tooltip
        row:SetScript("OnEnter", function(self)
            if self.playerData then
                GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR_RIGHT")
                GameTooltip:ClearLines()
                local tcoords = CLASS_ICON_TCOORDS[self.playerData.class or "WARRIOR"]
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

        yOffset = yOffset - 22
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

    -- Update header
    local bidCount = #PSK.BidEntries
    header:SetText("Bids (" .. bidCount .. ")")

    -- Wipe list
    for _, child in ipairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    local yOffset = -5
    for index, bidData in ipairs(PSK.BidEntries) do
        local row = CreateFrame("Button", nil, scrollChild)
		row.bg = row:CreateTexture(nil, "BACKGROUND")
		row.bg:SetAllPoints()
		row.bg:SetColorTexture(0, 0, 0, 0) -- Transparent by default
		row.bg:Hide()

        row:SetSize(220, 20)
        row:SetPoint("TOPLEFT", 0, yOffset)
        row:EnableMouse(true)

        -- Position number
        local posText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        posText:SetPoint("LEFT", row, "LEFT", 5, 0)
        posText:SetText(bidData.position)

        -- Class Icon
        local class = bidData.class or "SHAMAN"
        local classIcon = row:CreateTexture(nil, "ARTWORK")
        classIcon:SetSize(16, 16)
        classIcon:SetPoint("LEFT", posText, "RIGHT", 4, 0)
        classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
        if CLASS_ICON_TCOORDS[class] then
            classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
        end

        -- Name
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("LEFT", classIcon, "RIGHT", 4, 0)
        nameText:SetText(bidData.name)


		-- Award Button (to the right of the name)
		local awardButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
		awardButton:SetSize(16, 16)
		awardButton:SetPoint("LEFT", nameText, "RIGHT", 30, 0)
		awardButton:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Check")
		awardButton:GetNormalTexture():SetTexCoord(0.2, 0.8, 0.2, 0.8)
		awardButton.index = index
		awardButton:SetText("")
		awardButton:SetFrameLevel(row:GetFrameLevel() + 1)
		awardButton:SetScript("OnClick", function(self)
			if self.index then
				local row = self:GetParent()
				if row and row.bg then
					row.bg:SetColorTexture(0, 1, 0, 0.4) -- bright green
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
			end
		end)
		
		awardButton:SetScript("OnEnter", function(self)
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

		awardButton:SetScript("OnLeave", function(self)
			local row = self:GetParent()
			if row and row.bg then
				row.bg:Hide()
			end
			GameTooltip:Hide()
		end)


		-- Pass Button (to the right of Award)
		local passButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
		passButton:SetSize(16, 16)
		passButton:SetPoint("LEFT", awardButton, "RIGHT", 15, 0)
		passButton:SetFrameLevel(row:GetFrameLevel() + 1)

		local passTexture = passButton:CreateTexture(nil, "ARTWORK")
		passTexture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
		passTexture:SetAllPoints(passButton)
		passTexture:SetTexCoord(0.2, 0.8, 0.2, 0.8)
		passButton:SetNormalTexture(passTexture)

		passButton.index = index
		passButton:SetText("")
		passButton:SetScript("OnClick", function(self)
			if self.index then
				table.remove(PSK.BidEntries, self.index)
				PSK:RefreshBidList()
			end
		end)
	
		passButton:SetScript("OnEnter", function(self)
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

		passButton:SetScript("OnLeave", function(self)
			local row = self:GetParent()
			if row and row.bg then
				row.bg:Hide()
			end
			GameTooltip:Hide()
		end)




        yOffset = yOffset - 22
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


PSK:RefreshLootList()
PSK:RefreshLogList()
