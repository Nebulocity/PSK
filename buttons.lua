local PSK = select(2, ...)
_G.PSKGlobal = PSK


---------------------------------
-- Switch between Main/Tier List
---------------------------------

PSK.ToggleListButton = CreateFrame("Button", nil, PSK.ContentFrame, "GameMenuButtonTemplate")
PSK.ToggleListButton:SetSize(140, 30)
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
        header:SetText((listKey == "Main" and "PSK Main List" or "PSK Tier List") .. " (" .. count .. ")")
    end

	if PSK.PlayRandomPeonSound then
		PSK:PlayRandomPeonSound()
	end

    PSK:DebouncedRefreshPlayerList()
    PSK:DebouncedRefreshBidList()
	PSK:ClearSelection()
end)


------------------------------
-- Button to record loot drops
------------------------------

PSK.RecordLootButton = CreateFrame("Button", nil, PSK.ContentFrame, "GameMenuButtonTemplate")
PSK.RecordLootButton:SetSize(140, 30)
PSK.RecordLootButton:SetText("Record Loot")
PSK.LootRecordingActive = false

PSK.RecordLootButton:SetScript("OnClick", function(self)
    PSK.LootRecordingActive = not PSK.LootRecordingActive
	
    if PSK.LootRecordingActive then
        self:SetText("Stop Recording")

		if PSK.RecordingWarningDrops then
			PSK.RecordingWarningDrops:Hide()
		end
		
		if PSK.RecordingWarningLogs then
			PSK.RecordingWarningLogs:Hide()
		end
		
    else
        self:SetText("Record Loot")
        
		if PSK.RecordingWarningDrops then
			PSK.RecordingWarningDrops:Show()
		end
		
		if PSK.RecordingWarningLogs then
			PSK.RecordingWarningLogs:Show()
		end
		
    end
end)


------------------------------
-- Button to clear loot drops
------------------------------

PSK.ClearLootButton = CreateFrame("Button", nil, PSK.ContentFrame, "GameMenuButtonTemplate")
PSK.ClearLootButton:SetPoint("RIGHT", PSK.Headers.Loot, "RIGHT", 145, 0)
PSK.ClearLootButton:SetSize(60, -20)
PSK.ClearLootButton:SetText("Clear")

PSK.ClearLootButton:SetScript("OnClick", function()
    StaticPopup_Show("PSK_CONFIRM_CLEAR_LOOT")
end)

PSK.ClearLootButton:SetMotionScriptsWhileDisabled(true)
PSK.ClearLootButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(PSK.ClearLootButton, "ANCHOR_RIGHT")
    GameTooltip:SetText("Clear Loot List", 1, 1, 1)
    GameTooltip:AddLine("This will delete all tracked loot.", nil, nil, nil, true)
    GameTooltip:Show()
end)

PSK.ClearLootButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)


------------------------------
-- Display Rarity
------------------------------

PSK.LootLabel = PSK.ContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
PSK.LootLabel:SetPoint("RIGHT", PSK.ClearLootButton, "LEFT", -5, -1)
local threshold = PSK.Settings.lootThreshold or 3
local color = PSK.RarityColors[threshold] or "ffffff"
local name = PSK.RarityNames[threshold] or "Rare"

PSK.LootLabel:SetText("|cff" .. color .. name .. "+|r")


------------------------------
-- Button to start bidding
------------------------------

PSK.BidButton = CreateFrame("Button", nil, PSK.ContentFrame, "GameMenuButtonTemplate")
PSK.BidButton:SetSize(140, 30)
PSK.BidButton:SetText("Start Bidding")
PSK.BidButton.biddingActive = false

PSK.BidButton:SetScript("OnClick", function(self)
    self.biddingActive = not self.biddingActive
	
	
    if self.biddingActive then
		PlaySound(5275)
		self:SetText("Close Bidding")
		
        -- Add logic for starting bidding phase here
        Announce("[PSK] Bidding has begun! Whisper 'bid' to join.")
    else
		PlaySound(5274)
        self:SetText("Start Bidding")
        -- Add logic for closing bidding here
        Announce("[PSK] Bidding has ended.")
    end
end)

------------------------------
-- Active bidding glow
------------------------------

PSK.BidButton.Border = CreateFrame("Frame", nil, PSK.BidButton, "BackdropTemplate")
PSK.BidButton.Border:SetAllPoints()
PSK.BidButton.Border:SetFrameLevel(PSK.BidButton:GetFrameLevel() + 1)

PSK.BidButton.Border:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", -- simple thin border
    edgeSize = 15,
})

PSK.BidButton.Border:SetBackdropBorderColor(0, 1, 0, 1) -- Bright green
PSK.BidButton.Border:Hide() -- Hidden initially


------------------------------
-- Active bidding pulse
------------------------------
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

PSK.BidButton.Border.Pulse = pulse

PSK.BidButton:SetPoint("LEFT", PSK.ToggleListButton, "RIGHT", 10, 0)
PSK.BidButton:SetSize(160, 30)
PSK.BidButton:SetText("Start Bidding")

if not BiddingOpen then
    PSK.BidButton:Disable()
end

-----------------------------------------
-- Set script on button, bidding effects
-----------------------------------------

PSK.BidButton:SetScript("OnClick", function()
	if BiddingOpen then
		PSK.BidButton.Border.Pulse:Stop()
		PSK.BidButton.Border:SetAlpha(1) -- Fully visible, not pulsing
		PSK:CloseBidding()

		if PSK.Settings.buttonSoundsEnabled then
			PlaySound(5275)
		end

	else
		PSK.BidButton.Border:Show()
		PSK.BidButton.Border.Pulse:Play()
		PSK:StartBidding()
		PlaySound(5274)
		if PSK.Settings.buttonSoundsEnabled then
			PlaySoundFile("Interface\\AddOns\\PSK\\media\\GoblinMaleZanyNPCGreeting01.ogg", "Master")
		end

	end
end)


---------------------------------------------
-- Center buttons at top of PSK.ContentFrame
---------------------------------------------

local spacing = 20
local buttonWidth = 140

PSK.ToggleListButton:SetWidth(buttonWidth)
PSK.RecordLootButton:SetWidth(buttonWidth)
PSK.BidButton:SetWidth(buttonWidth)

local totalWidth = buttonWidth * 3 + spacing * 2
local startX = -totalWidth / 2 + buttonWidth / 2

-- Reset default positioning
PSK.ToggleListButton:ClearAllPoints()
PSK.RecordLootButton:ClearAllPoints()
PSK.BidButton:ClearAllPoints()

PSK.ToggleListButton:SetPoint("TOP", PSK.ContentFrame, "TOP", startX, -40)
PSK.RecordLootButton:SetPoint("LEFT", PSK.ToggleListButton, "RIGHT", spacing, 0)
PSK.BidButton:SetPoint("LEFT", PSK.RecordLootButton, "RIGHT", spacing, 0)

if PSK.FinalizeUI then
    PSK:FinalizeUI()
end
