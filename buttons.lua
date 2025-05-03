local PSK = select(2, ...)
_G.PSKGlobal = PSK

-- Switch Main/Tier List Button
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
        header:SetText((listKey == "Main" and "PSK Main" or "PSK Tier") .. " (" .. count .. ")")
    end

	if PSK.PlayRandomPeonSound then
		PSK:PlayRandomPeonSound()
	end

    PSK:RefreshGuildList()
    PSK:RefreshBidList()
end)


-- Record Loot Button
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



-- Toggle Bidding Button (Start <-> Close)
PSK.BidButton = CreateFrame("Button", nil, PSK.ContentFrame, "GameMenuButtonTemplate")
PSK.BidButton:SetSize(140, 30)
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

if not BiddingOpen then
    PSK.BidButton:Disable()
end


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
		
		if PSK.Settings.buttonSoundsEnabled then
			PlaySoundFile("Interface\\AddOns\\PSK\\media\\GoblinMaleZanyNPCGreeting01.ogg", "Master")
		end

	end
end)


-- Center the three top buttons horizontally
local spacing = 20
local buttonWidth = 140

PSK.ToggleListButton:SetWidth(buttonWidth)
PSK.RecordLootButton:SetWidth(buttonWidth)
PSK.BidButton:SetWidth(buttonWidth)

local totalWidth = buttonWidth * 3 + spacing * 2
local startX = -totalWidth / 2 + buttonWidth / 2


-- Clear and SetPoints go down here too
PSK.ToggleListButton:ClearAllPoints()
PSK.RecordLootButton:ClearAllPoints()
PSK.BidButton:ClearAllPoints()

PSK.ToggleListButton:SetPoint("TOP", PSK.ContentFrame, "TOP", startX, -40)
PSK.RecordLootButton:SetPoint("LEFT", PSK.ToggleListButton, "RIGHT", spacing, 0)
PSK.BidButton:SetPoint("LEFT", PSK.RecordLootButton, "RIGHT", spacing, 0)



if PSK.FinalizeUI then
    PSK:FinalizeUI()
end
