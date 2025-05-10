
local PSK = select(2, ...)

------------------------
-- Ensure settings exist
------------------------

if not PSKDB then PSKDB = {} end
PSKDB.Settings = PSKDB.Settings or { buttonSoundsEnabled = true, lootThreshold = 1 } -- change to 3 for rare
PSK.Settings = CopyTable(PSKDB.Settings)
local mainListCount = #PSKDB.MainList or 0
local pskTabScrollFrameHeight = -115
local manageTabScrollFrameHeight = -87

------------------------
-- Initialize containers
------------------------

PSK.ScrollFrames = {}
PSK.ScrollChildren = {}
PSK.Headers = {}

------------------------
-- Create main frame
------------------------

PSK.MainFrame = CreateFrame("Frame", "PSKMainFrame", UIParent, "BasicFrameTemplateWithInset")
PSK.MainFrame:SetSize(705, 500)
PSK.MainFrame:SetPoint("CENTER")
PSK.MainFrame:SetMovable(true)
PSK.MainFrame:EnableMouse(true)
PSK.MainFrame:RegisterForDrag("LeftButton")
PSK.MainFrame:SetScript("OnDragStart", PSK.MainFrame.StartMoving)
PSK.MainFrame:SetScript("OnDragStop", PSK.MainFrame.StopMovingOrSizing)
PSK.MainFrame:SetFrameStrata("HIGH")
PSK.MainFrame:SetFrameLevel(200)
table.insert(UISpecialFrames, "PSKMainFrame")

------------------------
-- MainFrame Title
------------------------

PSK.MainFrame.title = PSK.MainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
PSK.MainFrame.title:SetPoint("CENTER", PSK.MainFrame.TitleBg, "CENTER", 0, 0)
PSK.MainFrame.title:SetText("Perchance PSK - Perchance Some Loot?")

------------------------
-- Tabbed content frames
------------------------

PSK.ContentFrame = CreateFrame("Frame", nil, PSK.MainFrame)
PSK.ContentFrame:SetAllPoints()

------------------------
-- Settings Frame (tab)
------------------------

PSK.SettingsFrame = CreateFrame("Frame", nil, PSK.MainFrame, "BackdropTemplate")
PSK.SettingsFrame:SetPoint("TOPLEFT", 8, -28)
PSK.SettingsFrame:SetPoint("BOTTOMRIGHT", -6, 8)
PSK.SettingsFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
PSK.SettingsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.85)
PSK.SettingsFrame:Hide()

------------------------
-- Logs Frame (tab)
------------------------

PSK.LogsFrame = CreateFrame("Frame", nil, PSK.MainFrame, "BackdropTemplate")
PSK.LogsFrame:SetPoint("TOPLEFT", 8, -28)
PSK.LogsFrame:SetPoint("BOTTOMRIGHT", -6, 8)
PSK.LogsFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
PSK.LogsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.85)
PSK.LogsFrame:Hide()

------------------------
-- Manage Frame (tab)
------------------------

PSK.ManageFrame = CreateFrame("Frame", nil, PSK.MainFrame, "BackdropTemplate")
PSK.ManageFrame:SetPoint("TOPLEFT", 8, -28)
PSK.ManageFrame:SetPoint("BOTTOMRIGHT", -6, 8)
PSK.ManageFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
PSK.ManageFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.85)
PSK.ManageFrame:Hide()


---------------------------------------------
-- Set the default selected list (main/tier)
---------------------------------------------

PSK.CurrentList = "Main"


----------------------------------------------
-- Parent Player scroll frame to ContentFrame
----------------------------------------------

local playerScroll, playerChild, playerFrame, playerHeader =
    CreateBorderedScrollFrame("PSKScrollFrame", PSK.ContentFrame, 10, pskTabScrollFrameHeight, "PSK Main (" .. mainListCount .. ")")
PSK.ScrollFrames.Main = playerScroll
PSK.ScrollChildren.Main = playerChild
playerHeader:ClearAllPoints()
playerHeader:SetPoint("TOPLEFT", playerScroll, "TOPLEFT", 0, 20)
PSK.Headers.Main = playerHeader


----------------------------------------------
-- Parent Loot scroll frame to ContentFrame
----------------------------------------------

local lootScroll, lootChild, lootFrame, lootHeader =
    CreateBorderedScrollFrame("PSKLootScrollFrame", PSK.ContentFrame, 240, pskTabScrollFrameHeight, "Loot Drops")
PSK.ScrollFrames.Loot = lootScroll
PSK.ScrollChildren.Loot = lootChild
lootHeader:ClearAllPoints()
lootHeader:SetPoint("TOPLEFT", lootScroll, "TOPLEFT", 0, 20)
PSK.Headers.Loot = lootHeader

----------------------------------------------
-- Parent Bidding scroll frame to ContentFrame
----------------------------------------------

local bidCount = (PSK.BidEntries and #PSK.BidEntries) or 0
local bidScroll, bidChild, bidFrame, bidHeader =
    CreateBorderedScrollFrame("PSKBidScrollFrame", PSK.ContentFrame, 470, pskTabScrollFrameHeight, "Bids (" .. bidCount .. ")", 220)
PSK.ScrollFrames.Bid = bidScroll
PSK.ScrollChildren.Bid = bidChild
bidHeader:ClearAllPoints()
bidHeader:SetPoint("TOPLEFT", bidScroll, "TOPLEFT", 0, 20)
PSK.Headers.Bid = bidHeader

-----------------------------------------------
--  Parent Manage List Headers to ManageFrame
-----------------------------------------------

local mainHeader = PSK.ManageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mainHeader:SetPoint("TOPLEFT", 10, -10)
-- mainHeader:SetText("Available for Main List")

local tierHeader = PSK.ManageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
tierHeader:SetPoint("TOPLEFT", 365, -10)
-- tierHeader:SetText("Available for Tier List")

-- Create the two scroll lists
local mainScroll, mainChild, mainFrame, mainScrollHeader = CreateBorderedScrollFrame("PSKMainAvailableScroll", PSK.ManageFrame, 2, manageTabScrollFrameHeight, "Available PSK Main Members")
local tierScroll, tierChild, tierFrame, tierScrollHeader = CreateBorderedScrollFrame("PSKTierAvailableScroll", PSK.ManageFrame, 232, manageTabScrollFrameHeight, "Available PSK Tier Members")

-- Add Instructions Label to Manage Frame
-- local instructionsLabel = PSK.ManageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
-- instructionsLabel:SetPoint("TOP", PSK.ManageFrame, "TOP", 0, -25)
-- instructionsLabel:SetText("Click the + sign to add a player to each respective list.")
-- instructionsLabel:SetTextColor(1, 0.85, 0.1)  -- Gold-like color

-- Set headers for scroll lists
mainScrollHeader:SetPoint("TOPLEFT", mainScroll, "TOPLEFT", 0, 20)
tierScrollHeader:SetPoint("TOPLEFT", tierScroll, "TOPLEFT", 0, 20)

-- Store these for later updates
PSK.ScrollFrames.MainAvailable = mainScroll
PSK.ScrollChildren.MainAvailable = mainChild or CreateFrame("Frame", nil, mainScroll)
PSK.Headers.MainAvailable = mainScrollHeader

PSK.ScrollFrames.TierAvailable = tierScroll
PSK.ScrollChildren.TierAvailable = tierChild or CreateFrame("Frame", nil, tierScroll)
PSK.Headers.TierAvailable = tierScrollHeader


-----------------------------------------
-- Add Background for Instructions Label
-----------------------------------------

local instructionsBg = CreateFrame("Frame", nil, PSK.ManageFrame, "BackdropTemplate")
instructionsBg:SetPoint("TOPLEFT", 10, -10)
instructionsBg:SetPoint("TOPRIGHT", -10, -10)
instructionsBg:SetHeight(40)
instructionsBg:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
instructionsBg:SetBackdropColor(0.1, 0.1, 0.1, 0.85)

-- Create Inline Icon and Text
local instructionContainer = CreateFrame("Frame", nil, instructionsBg)
instructionContainer:SetSize(600, 40)  -- Width should match the width of instructionsBg
instructionContainer:SetPoint("TOPLEFT", instructionsBg, "TOPLEFT", -10, 0)

-- Add the First Part of the Text
local textLeft = instructionContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
textLeft:SetPoint("LEFT", instructionContainer, "LEFT", 10, -10)
textLeft:SetText("Click the ")
textLeft:SetTextColor(1, 0.85, 0.1)

-- Add the + Icon
local plusIcon = instructionContainer:CreateTexture(nil, "OVERLAY")
plusIcon:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
plusIcon:SetSize(24, 24)
plusIcon:SetPoint("LEFT", textLeft, "RIGHT", 4, -2)

-- Add the Second Part of the Text
local textRight = instructionContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
textRight:SetPoint("LEFT", plusIcon, "RIGHT", 4, 2)
textRight:SetText(" to add a player to each respective list.")
textRight:SetTextColor(1, 0.85, 0.1)




------------------------------------------------
-- Dialog for clearing loot drops
------------------------------------------------

StaticPopupDialogs["PSK_CONFIRM_CLEAR_LOOT"] = {
    text = "Are you sure you want to clear all loot drops?",
    button1 = "Yes",
    button2 = "Cancel",
	OnAccept = function()
		wipe(PSKDB.LootDrops)
		PSK.LootDrops = PSKDB.LootDrops
		PSK:RefreshLootList()
	end

}

----------------------------------------------
-- Warning if loot not being recorded
----------------------------------------------

local lootRecordingWarning = PSK.ContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
lootRecordingWarning:SetPoint("CENTER", lootHeader, "CENTER", 80, 20)
lootRecordingWarning:SetText(">>> Loot is not being recorded! <<<")
lootRecordingWarning:SetTextColor(1, 0, 0)
lootRecordingWarning:Hide()

----------------------------------------------
-- Pulse the loot warning
----------------------------------------------
local lootPulse = lootRecordingWarning:CreateAnimationGroup()

local lootFadeOut = lootPulse:CreateAnimation("Alpha")
lootFadeOut:SetFromAlpha(1)
lootFadeOut:SetToAlpha(0.2)
lootFadeOut:SetDuration(0.5)
lootFadeOut:SetOrder(1)

local lootFadeIn = lootPulse:CreateAnimation("Alpha")
lootFadeIn:SetFromAlpha(0.2)
lootFadeIn:SetToAlpha(1)
lootFadeIn:SetDuration(0.5)
lootFadeIn:SetOrder(2)

lootPulse:SetLooping("REPEAT")
lootRecordingWarning.pulse = lootPulse

------------------------------------------------
-- To check whether loot is recording elsewhere
------------------------------------------------
PSK.RecordingWarningDrops = lootRecordingWarning

------------------------------
-- Create Log scroll frame
------------------------------

local logScroll, logChild, logFrame, logHeader =
    CreateBorderedScrollFrame("PSKLogScrollFrame", PSK.LogsFrame, 20, -40, "Loot Logs", 645, 700)
PSK.ScrollFrames.Logs = logScroll
PSK.ScrollChildren.Logs = logChild
PSK.Headers.Logs = logHeader

----------------------------------
-- Warning for not recording loot
----------------------------------

local recordingWarning = PSK.LogsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
recordingWarning:SetPoint("LEFT", logHeader, "RIGHT", 10, 0)
recordingWarning:SetText("Loot is not being recorded!")
recordingWarning:SetTextColor(1, 0, 0)
recordingWarning:Hide()

----------------------------------
-- Warning pulse animation
----------------------------------

local pulse = recordingWarning:CreateAnimationGroup()
local fadeOut = pulse:CreateAnimation("Alpha")
fadeOut:SetFromAlpha(1)
fadeOut:SetToAlpha(0.2)
fadeOut:SetDuration(0.5)
fadeOut:SetOrder(1)

local fadeIn = pulse:CreateAnimation("Alpha")
fadeIn:SetFromAlpha(0.2)
fadeIn:SetToAlpha(1)
fadeIn:SetDuration(0.5)
fadeIn:SetOrder(2)

pulse:SetLooping("REPEAT")
recordingWarning.pulse = pulse

PSK.RecordingWarningLogs = recordingWarning

------------------------------
-- Set loot thresholds
------------------------------

local threshold = PSK.Settings and PSK.Settings.lootThreshold or 3
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

------------------------------
-- Set Loot Threshold Header
------------------------------

local rarityName = PSK.RarityNames[threshold] or "?"
local upArrow = "|TInterface\\AddOns\\PSK\\media\\arrow_up.tga:24:24|t"
local dropCount = #PSK.LootDrops
lootHeader:SetText("Loot Drops")
-- lootHeader:SetText("Loot Drops (" .. tostring(#(PSK.LootDrops or {})) .. ") " .. rarityName .. "+")







------------------------------
-- Create Tabs for MainFrame
------------------------------

PSK.Tabs = {}
PanelTemplates_SetNumTabs(PSK.MainFrame, 4)

------------------------------
-- Set Tab 1 (PSK)
------------------------------

local tab1 = CreateFrame("Button", "PSKMainFrameTab1", PSK.MainFrame, "CharacterFrameTabButtonTemplate")
tab1:SetID(1)
tab1:SetText("PSK")
tab1:SetPoint("BOTTOMLEFT", PSK.MainFrame, "BOTTOMLEFT", 10, -30)
PanelTemplates_TabResize(tab1, 0)
PSK.Tabs[1] = tab1

------------------------------
-- Set Tab 2 (Manage)
------------------------------

local tab2 = CreateFrame("Button", "PSKMainFrameTab2", PSK.MainFrame, "CharacterFrameTabButtonTemplate")
tab2:SetID(2)
tab2:SetText("Manage")
tab2:SetPoint("LEFT", tab1, "RIGHT", -16, 0)
PanelTemplates_TabResize(tab2, 0)
PSK.Tabs[2] = tab2

------------------------------
-- Set Tab 3 (Settings)
------------------------------

local tab3 = CreateFrame("Button", "PSKMainFrameTab3", PSK.MainFrame, "CharacterFrameTabButtonTemplate")
tab3:SetID(3)
tab3:SetText("Settings")
tab3:SetPoint("LEFT", tab2, "RIGHT", -16, 0)
PanelTemplates_TabResize(tab3, 0)
PSK.Tabs[3] = tab3

------------------------------
-- Set Tab 4 (Logs)
------------------------------

local tab4 = CreateFrame("Button", "PSKMainFrameTab4", PSK.MainFrame, "CharacterFrameTabButtonTemplate")
tab4:SetID(4)
tab4:SetText("Logs")
tab4:SetPoint("LEFT", tab3, "RIGHT", -16, 0)
PanelTemplates_TabResize(tab4, 0)
PSK.Tabs[4] = tab4

------------------------------
-- Create Settings UI
------------------------------

local settingsTitle = PSK.SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
settingsTitle:SetPoint("TOP", 0, -40)
settingsTitle:SetText("PSK Settings")

--------------------------------
-- Enable/Disable Sound Effects
--------------------------------

local soundCheckbox = CreateFrame("CheckButton", nil, PSK.SettingsFrame, "ChatConfigCheckButtonTemplate")
soundCheckbox:SetPoint("TOPLEFT", 20, -80) 
soundCheckbox.Text:SetText("Button Sounds")
soundCheckbox:SetChecked(PSK.Settings.buttonSoundsEnabled)

soundCheckbox:SetScript("OnClick", function(self)
    local enabled = self:GetChecked()
    PSK.Settings.buttonSoundsEnabled = enabled

    -- Ensure PSKDB.Settings exists before we update it
    if not PSKDB then PSKDB = {} end
    if not PSKDB.Settings then PSKDB.Settings = {} end
    PSKDB.Settings.buttonSoundsEnabled = enabled

    print("[PSK] Button sounds " .. (enabled and "enabled." or "disabled."))
end)

--------------------------------
-- Tab-switching Logic
--------------------------------
hooksecurefunc("PanelTemplates_Tab_OnClick", function(self)
    local tabID = self:GetID()
    PanelTemplates_SetTab(PSK.MainFrame, tabID)

    -- Hide all frames first
    PSK.ContentFrame:Hide()
    PSK.SettingsFrame:Hide()
    PSK.LogsFrame:Hide()
    PSK.ManageFrame:Hide()  -- Fix: Explicitly hide the Manage tab

    -- Show the selected frame
    if tabID == 1 then
        PSK.ContentFrame:Show()
    elseif tabID == 2 then
        PSK.ManageFrame:Show()
        PSK:RefreshAvailableMembers()
    elseif tabID == 3 then
        PSK.SettingsFrame:Show()
    elseif tabID == 4 then
        PSK.LogsFrame:Show()
    end
end)


----------------------------------
-- Sets the default selected tab
----------------------------------

PanelTemplates_SetTab(PSK.MainFrame, 1)
PSK.ContentFrame:Show()
PSK.SettingsFrame:Hide()
PSK.ManageFrame:Hide()
PSK.LogsFrame:Hide()

print("[PSK] Manage Tab Initialized")

----------------------------------
-- Refresh lists on load
----------------------------------



-- Timed refresh to ensure logs/loot lists are ready on player login
C_Timer.After(0.1, function()
    if PSK.RefreshLogList then
        PSK:RefreshLogList()
		PSK:RefreshLootList()
		PSK:RefreshPlayerList()
		PSK:RefreshBidList()
		-- PSK:UpdateVisiblePlayerInfo()
		PSK:UpdateLootThresholdLabel()
		-- PSK:CreateGuildMemberDropdown()

    end
end)

