-- ui.lua

local PSK = select(2, ...)

-- Initialize containers
PSK.ScrollFrames = {}
PSK.ScrollChildren = {}
PSK.Headers = {}



-- Create the main frame
local frame = CreateFrame("Frame", "PSKMainFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(700, 500)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetFrameStrata("HIGH")
frame:SetFrameLevel(200)

PSK.MainFrame = frame
PSK.CurrentList = "Main" -- Default selection

-- Title
frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)
frame.title:SetText("Perchance PSK - Perchance Some Loot?")


-- Switch Main/Tier List Button
PSK.ToggleListButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
PSK.ToggleListButton:SetSize(140, 30)
PSK.ToggleListButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 140, -40)
PSK.ToggleListButton:SetText("Switch to Tier List")

PSK.ToggleListButton:SetScript("OnClick", function()
    if PSK.CurrentList == "Main" then
        PSK.CurrentList = "Tier"
        PSK.ToggleListButton:SetText("Switch to Main List")
    else
        PSK.CurrentList = "Main"
        PSK.ToggleListButton:SetText("Switch to Tier List")
    end

    -- Update Header Text
    local listKey = PSK.CurrentList
    local header = PSK.Headers.Main
    local count = listKey == "Main" and #PSKDB.MainList or #PSKDB.TierList
    if header then
        header:SetText((listKey == "Main" and "Guild Members" or "Tier List") .. " (" .. count .. ")")
    end

    PSK:RefreshGuildList()
    PSK:RefreshBidList()
end)

-- Toggle Bidding Button (Start <-> Close)
PSK.BidButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
PSK.BidButton:SetSize(140, 30)

-- Recenter both buttons with respect to the main frame center
PSK.ToggleListButton:SetPoint("TOP", frame, "TOP", -80, -40) -- slightly left of center

PSK.BidButton:SetText("Start Bidding")
PSK.BidButton.biddingActive = false

PSK.BidButton:SetScript("OnClick", function(self)
    self.biddingActive = not self.biddingActive

    if self.biddingActive then
        self:SetText("Close Bidding")
        -- Add logic for starting bidding phase here
        Announce("[PSK] Bidding has begun! Whisper 'bid' to join.")
    else
        self:SetText("Start Bidding")
        -- Add logic for closing bidding here
        Announce("[PSK] Bidding has ended.")
    end
end)


-- Create a Glow Border Frame
PSK.BidButton.Border = CreateFrame("Frame", nil, PSK.BidButton, "BackdropTemplate")
PSK.BidButton.Border:SetAllPoints()
PSK.BidButton.Border:SetFrameLevel(PSK.BidButton:GetFrameLevel() + 1)

PSK.BidButton.Border:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", -- simple thin border
    edgeSize = 15,
})

PSK.BidButton.Border:SetBackdropBorderColor(0, 1, 0, 1) -- Bright green
PSK.BidButton.Border:Hide() -- Hidden initially

-- Pulse Animation for the Border
local pulse = PSK.BidButton.Border:CreateAnimationGroup()

local fadeOut = pulse:CreateAnimation("Alpha")
fadeOut:SetFromAlpha(1)
fadeOut:SetToAlpha(0.5)
fadeOut:SetDuration(0.7)
fadeOut:SetOrder(1)

local fadeIn = pulse:CreateAnimation("Alpha")
fadeIn:SetFromAlpha(0.5)
fadeIn:SetToAlpha(1)
fadeIn:SetDuration(0.7)
fadeIn:SetOrder(2)

pulse:SetLooping("REPEAT")

-- Save the animation
PSK.BidButton.Border.Pulse = pulse

PSK.BidButton:SetPoint("LEFT", PSK.ToggleListButton, "RIGHT", 10, 0)
PSK.BidButton:SetSize(160, 30)
PSK.BidButton:SetText("Start Bidding")
PSK.BidButton:SetScript("OnClick", function()
	if BiddingOpen then
		PSK.BidButton.Border.Pulse:Stop()
		PSK.BidButton.Border:SetAlpha(1) -- Fully visible, not pulsing
		CloseBidding()
	else
		PSK.BidButton.Border:Show()
		PSK.BidButton.Border.Pulse:Play()
		StartBidding()
	end
end)


-- Main List ScrollFrame
local mainListCount = #PSKDB.MainList or 0
local guildScroll, guildChild, guildFrame, guildHeader =
    CreateBorderedScrollFrame("PSKScrollFrame", frame, 10, -110, "Guild Members (" .. mainListCount .. ")")
PSK.ScrollFrames.Main = guildScroll
PSK.ScrollChildren.Main = guildChild
PSK.Headers.Main = guildHeader

-- Loot Drop ScrollFrame
local lootScroll, lootChild, lootFrame, lootHeader =
    CreateBorderedScrollFrame("PSKLootScrollFrame", frame, 240, -110, "Loot Drops (0)")
PSK.ScrollFrames.Loot = lootScroll
PSK.ScrollChildren.Loot = lootChild
PSK.Headers.Loot = lootHeader

-- Bid List ScrollFrame
local bidCount = #PSK.BidEntries or 0
local bidScroll, bidChild, bidFrame, bidHeader =
    CreateBorderedScrollFrame("PSKBidScrollFrame", frame, 470, -110, "Bids (" .. bidCount .. ")", 220)



PSK.ScrollFrames.Bid = bidScroll
PSK.ScrollChildren.Bid = bidChild
PSK.Headers.Bid = bidHeader






----------------------------------------
-- Refresh Loot List
----------------------------------------

function PSK:RefreshLootList()
    if not PSK.LootDrops then return end

    local scrollChild = PSK.ScrollChildren.Loot
    local header = PSK.Headers.Loot
    if not scrollChild or not header then return end

    -- Clear previous loot
    for _, child in ipairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    local yOffset = -5
    for index, loot in ipairs(PSK.LootDrops) do
        local row = CreateFrame("Button", nil, scrollChild)
        row:SetSize(240, 20)
        row:SetPoint("TOP", 0, yOffset)

        -- Icon
        local iconTexture = row:CreateTexture(nil, "ARTWORK")
        iconTexture:SetSize(16, 16)
        iconTexture:SetPoint("LEFT", row, "LEFT", 5, 0)
        iconTexture:SetTexture(loot.itemTexture)

        -- Item Link Text
        local itemText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        itemText:SetPoint("LEFT", iconTexture, "RIGHT", 8, 0)
        itemText:SetText(loot.itemLink)

        -- Highlight on click
        row:SetScript("OnClick", function()
            PSK.SelectedItem = loot.itemLink
            Announce("[PSK] Selected item for bidding: " .. loot.itemLink)
        end)

        yOffset = yOffset - 22
    end

    -- Update header
    header:SetText("Loot Drops (" .. #PSK.LootDrops .. ")")
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
    header:SetText((PSK.CurrentList == "Main" and "Guild Members" or "Tier List") .. " (" .. #names .. ")")

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
        row:SetSize(220, 20)
        row:SetPoint("TOPLEFT", 0, yOffset)
        row:EnableMouse(true)

        -- Background (optional visual testing)
        -- row.bg = row:CreateTexture(nil, "BACKGROUND")
        -- row.bg:SetAllPoints()
        -- row.bg:SetColorTexture(0, 0.3, 0.1, 0.2)

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

        --- Award Button (right-aligned)
		local awardButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
		awardButton:SetSize(16, 16)
		awardButton:SetPoint("RIGHT", row, "RIGHT", -22, 0)
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



		-- Pass Button (left of Award)
		local passButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
		passButton:SetSize(16, 16)
		passButton:SetPoint("RIGHT", awardButton, "LEFT", -4, 0)
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


        yOffset = yOffset - 22
    end
end




PSK:RefreshGuildList()
PSK:RefreshBidList()
