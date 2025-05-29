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

    PSK:DebouncedRefreshPlayerLists()
    PSK:DebouncedRefreshBidList()
	PSK:ClearSelection()
end)


--------------------------------------------------------
-- Add up/down list buttons, parent to PSK.Headers.Main
--------------------------------------------------------

-- Move Up Button
PSK.MoveUpButton = CreateFrame("Button", nil, PSK.ContentFrame, "UIPanelButtonTemplate")
PSK.MoveUpButton:SetSize(32, 24)
PSK.MoveUpButton:SetPoint("LEFT", PSK.Headers.Main, "RIGHT", 20, 0)
PSK.MoveUpButton:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
PSK.MoveUpButton:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
PSK.MoveUpButton:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
PSK.MoveUpButton:Hide()
PSK.MoveUpButton:SetScript("OnClick", function()
	local list = (PSK.CurrentList == "Tier") and PSKDB.TierList or PSKDB.MainList
    if not list or not PSK.SelectedPlayer then return end

    for i = 2, #list do
        if list[i].name == PSK.SelectedPlayer then
            local temp = list[i]
            list[i] = list[i - 1]
            list[i - 1] = temp
            PSK.SelectedPlayer = list[i - 1].name
            PSK:RefreshPlayerLists()
            break
        end
    end

	-- Play sound
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end)



-- Move Down Button
PSK.MoveDownButton = CreateFrame("Button", nil, PSK.ContentFrame, "UIPanelButtonTemplate")
PSK.MoveDownButton:SetSize(32, 24)
PSK.MoveDownButton:SetPoint("LEFT", PSK.Headers.Main, "RIGHT", 60, 0)
PSK.MoveDownButton:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
PSK.MoveDownButton:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight")
PSK.MoveDownButton:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
PSK.MoveDownButton:Hide()
PSK.MoveDownButton:SetScript("OnClick", function()
    local list = (PSK.CurrentList == "Tier") and PSKDB.TierList or PSKDB.MainList
    if not list or not PSK.SelectedPlayer then return end

    for i = 1, #list - 1 do
        if list[i].name == PSK.SelectedPlayer then
            local temp = list[i]
            list[i] = list[i + 1]
            list[i + 1] = temp
            PSK.SelectedPlayer = list[i + 1].name
            PSK:RefreshPlayerLists()
            break
        end
    end
	
	-- Play sound
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
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
		
	print("button clicked!")
	
    if self.biddingActive then
		PlaySound(5275)
		self:SetText("Close Bidding")
		
        -- Add logic for starting bidding phase here
        PSK:Announce("[PSK] Bidding has begun! Whisper 'bid' to join.")
    else
		PlaySound(5274)
        self:SetText("Start Bidding")
        -- Add logic for closing bidding here
        PSK:Announce("[PSK] Bidding has ended.")
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
PSK.BidButton:SetWidth(buttonWidth)

local totalWidth = buttonWidth * 3 + spacing * 2
local startX = -totalWidth / 2 + buttonWidth / 2

-- Reset default positioning
PSK.ToggleListButton:ClearAllPoints()
PSK.BidButton:ClearAllPoints()

PSK.ToggleListButton:SetPoint("TOPLEFT", PSK.ContentFrame, "TOPLEFT", 10, -60)
PSK.BidButton:SetPoint("TOPRIGHT", PSK.ContentFrame, "TOPRIGHT", -95, -60)

if PSK.FinalizeUI then
    PSK:FinalizeUI()
end


------------------------------
-- Import Tier Button
------------------------------

local importTierButton = CreateFrame("Button", nil, PSK.ImportExportFrame, "UIPanelButtonTemplate")
importTierButton:SetSize(120, 30)
importTierButton:SetPoint("BOTTOMRIGHT", PSK.ImportExportFrame, "BOTTOMRIGHT", -215, 30)
importTierButton:SetText("Import (PSK)")
importTierButton:SetScript("OnClick", function()
    local json = PSK.TierListEditBox:GetText()
    PSK:ImportPSKTierList(json)
end)



------------------------------
-- Export Tier PSK Button
------------------------------

local exportTierButton = CreateFrame("Button", nil, PSK.ImportExportFrame, "UIPanelButtonTemplate")
exportTierButton:SetSize(120, 30)
exportTierButton:SetPoint("BOTTOMRIGHT", PSK.ImportExportFrame, "BOTTOMRIGHT",  -65, 30)
exportTierButton:SetText("Export (PSK)")
exportTierButton:SetScript("OnClick", function()
	PSK.TierListEditBox:SetText(PSK:ExportPSKTierList())
	PSK.TierListEditBox:HighlightText()
	PSK.TierListEditBox:SetFocus()
end)



------------------------------
-- Export Tier Readable Button
------------------------------

local exportReadableTierButton = CreateFrame("Button", nil, PSK.ImportExportFrame, "UIPanelButtonTemplate")
exportReadableTierButton:SetSize(120, 30)
exportReadableTierButton:SetPoint("BOTTOMRIGHT", PSK.ImportExportFrame, "BOTTOMRIGHT", -65, 0)
exportReadableTierButton:SetText("Export (Discord)")
exportReadableTierButton:SetScript("OnClick", function()
	local mainList, tierList = PSK:ExportReadableLists()
	PSK.TierListEditBox:SetText(tierList)
	PSK.TierListEditBox:HighlightText()
	PSK.TierListEditBox:SetFocus()
	print("[PSK] Tier List Exported in readable format")
end)



------------------------------
-- Export Main PSK Button
------------------------------

local exportMainButton = CreateFrame("Button", nil, PSK.ImportExportFrame, "UIPanelButtonTemplate")
exportMainButton:SetSize(120, 30)
exportMainButton:SetPoint("BOTTOMLEFT", PSK.ImportExportFrame, "BOTTOMLEFT",  190, 30)
exportMainButton:SetText("Export (PSK)")
exportMainButton:SetScript("OnClick", function()
    PSK.MainListEditBox:SetText(PSK:ExportPSKMainList())
	PSK.MainListEditBox:HighlightText()
	PSK.MainListEditBox:SetFocus()
end)

------------------------------
-- Export Main Readable Button
------------------------------

local exportReadableMainButton = CreateFrame("Button", nil, PSK.ImportExportFrame, "UIPanelButtonTemplate")
exportReadableMainButton:SetSize(120, 30)
exportReadableMainButton:SetPoint("BOTTOMLEFT", PSK.ImportExportFrame, "BOTTOMLEFT", 190, 0)
exportReadableMainButton:SetText("Export (Discord)")
exportReadableMainButton:SetScript("OnClick", function()
	local mainList, tierList = PSK:ExportReadableLists()
	PSK.MainListEditBox:SetText(mainList)
	PSK.MainListEditBox:HighlightText()
	PSK.MainListEditBox:SetFocus()
	print("[PSK] Main List Exported in readable format")
end)


------------------------------
-- Import Main Button
------------------------------

local importMainButton = CreateFrame("Button", nil, PSK.ImportExportFrame, "UIPanelButtonTemplate")
importMainButton:SetSize(120, 30)
importMainButton:SetPoint("BOTTOMLEFT", PSK.ImportExportFrame, "BOTTOMLEFT", 30, 30)
importMainButton:SetText("Import (PSK)")
importMainButton:SetScript("OnClick", function()
    local json = PSK.MainListEditBox:GetText()
    PSK:ImportPSKMainList(json)
end)