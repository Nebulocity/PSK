
local PSK = select(2, ...)


-- Ensure settings exist
if not PSKDB then PSKDB = {} end
PSKDB.Settings = PSKDB.Settings or { buttonSoundsEnabled = true, lootThreshold = 1 } -- change to 3 for rare
PSK.Settings = CopyTable(PSKDB.Settings)

-- Initialize containers
PSK.ScrollFrames = {}
PSK.ScrollChildren = {}
PSK.Headers = {}

-- Create main frame
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

-- Title
PSK.MainFrame.title = PSK.MainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
PSK.MainFrame.title:SetPoint("CENTER", PSK.MainFrame.TitleBg, "CENTER", 0, 0)
PSK.MainFrame.title:SetText("Perchance PSK - Perchance Some Loot?")

-- Tabbed content frames
PSK.ContentFrame = CreateFrame("Frame", nil, PSK.MainFrame)
PSK.ContentFrame:SetAllPoints()

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


PSK.CurrentList = "Main"

-- Scroll frames parented to ContentFrame
local mainListCount = #PSKDB.MainList or 0
local guildScroll, guildChild, guildFrame, guildHeader =
    CreateBorderedScrollFrame("PSKScrollFrame", PSK.ContentFrame, 10, -110, "PSK Main (" .. mainListCount .. ")")
PSK.ScrollFrames.Main = guildScroll
PSK.ScrollChildren.Main = guildChild
guildHeader:ClearAllPoints()
guildHeader:SetPoint("TOPLEFT", guildScroll, "TOPLEFT", 0, 20)
PSK.Headers.Main = guildHeader

local lootScroll, lootChild, lootFrame, lootHeader =
    CreateBorderedScrollFrame("PSKLootScrollFrame", PSK.ContentFrame, 240, -110, "Loot Drops (0)")
PSK.ScrollFrames.Loot = lootScroll
PSK.ScrollChildren.Loot = lootChild
lootHeader:ClearAllPoints()
lootHeader:SetPoint("TOPLEFT", lootScroll, "TOPLEFT", 0, 20)
PSK.Headers.Loot = lootHeader


-- Flashing red warning above Loot Drops
local lootRecordingWarning = PSK.ContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
lootRecordingWarning:SetPoint("BOTTOMLEFT", lootHeader, "TOPLEFT", 30, 4)
lootRecordingWarning:SetText("Loot is not being recorded!")
lootRecordingWarning:SetTextColor(1, 0, 0)
lootRecordingWarning:Hide()

-- Pulse animation
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

-- Store reference
PSK.RecordingWarningDrops = lootRecordingWarning


-- Clear loot drops button
clearLootButton = CreateFrame("Button", nil, PSK.ContentFrame, "GameMenuButtonTemplate")
clearLootButton:SetPoint("RIGHT", lootHeader, "RIGHT", 55, 0)
clearLootButton:SetSize(40, -20)
clearLootButton:SetText("Clear")

clearLootButton:SetScript("OnClick", function()
    StaticPopup_Show("PSK_CONFIRM_CLEAR_LOOT")
end)
clearLootButton:SetMotionScriptsWhileDisabled(true)
clearLootButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(clearLootButton, "ANCHOR_RIGHT")
    GameTooltip:SetText("Clear Loot List", 1, 1, 1)
    GameTooltip:AddLine("This will delete all tracked loot.", nil, nil, nil, true)
    GameTooltip:Show()
end)
clearLootButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)


local threshold = PSK.Settings and PSK.Settings.lootThreshold or 3
local rarityNames = {
    [0] = "Poor",
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary"
}
local rarityName = rarityNames[threshold] or "?"
local upArrow = "|TInterface\\AddOns\\PSK\\media\\arrow_up.tga:24:24|t"
local dropCount = #PSK.LootDrops
lootHeader:SetText("Loot Drops (" .. tostring(#(PSK.LootDrops or {})) .. ") " .. rarityName .. "+")




local bidCount = (PSK.BidEntries and #PSK.BidEntries) or 0
local bidScroll, bidChild, bidFrame, bidHeader =
    CreateBorderedScrollFrame("PSKBidScrollFrame", PSK.ContentFrame, 470, -110, "Bids (" .. bidCount .. ")", 220)
PSK.ScrollFrames.Bid = bidScroll
PSK.ScrollChildren.Bid = bidChild
bidHeader:ClearAllPoints()
bidHeader:SetPoint("TOPLEFT", bidScroll, "TOPLEFT", 0, 20)
PSK.Headers.Bid = bidHeader

-- Tabs
PSK.Tabs = {}
PanelTemplates_SetNumTabs(PSK.MainFrame, 3)

local tab1 = CreateFrame("Button", "PSKMainFrameTab1", PSK.MainFrame, "CharacterFrameTabButtonTemplate")
tab1:SetID(1)
tab1:SetText("PSK")
tab1:SetPoint("BOTTOMLEFT", PSK.MainFrame, "BOTTOMLEFT", 10, -30)
PanelTemplates_TabResize(tab1, 0)
PSK.Tabs[1] = tab1

local tab2 = CreateFrame("Button", "PSKMainFrameTab2", PSK.MainFrame, "CharacterFrameTabButtonTemplate")
tab2:SetID(2)
tab2:SetText("Settings")
tab2:SetPoint("LEFT", tab1, "RIGHT", -16, 0)
PanelTemplates_TabResize(tab2, 0)
PSK.Tabs[2] = tab2

local tab3 = CreateFrame("Button", "PSKMainFrameTab3", PSK.MainFrame, "CharacterFrameTabButtonTemplate")
tab3:SetID(3)
tab3:SetText("Logs")
tab3:SetPoint("LEFT", tab2, "RIGHT", -16, 0)
PanelTemplates_TabResize(tab3, 0)
PSK.Tabs[3] = tab3

local logScroll, logChild, logFrame, logHeader =
    CreateBorderedScrollFrame("PSKLogScrollFrame", PSK.LogsFrame, 20, -40, "Loot Logs", 645, 700)
PSK.ScrollFrames.Logs = logScroll
PSK.ScrollChildren.Logs = logChild
PSK.Headers.Logs = logHeader

-- Flashing red "Loot is not being recorded!" warning
local recordingWarning = PSK.LogsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
recordingWarning:SetPoint("LEFT", logHeader, "RIGHT", 10, 0)
recordingWarning:SetText("Loot is not being recorded!")
recordingWarning:SetTextColor(1, 0, 0)
recordingWarning:Hide()

-- Pulse animation
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

-- Settings tab UI
local settingsTitle = PSK.SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
settingsTitle:SetPoint("TOP", 0, -40)
settingsTitle:SetText("PSK Settings")

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


---------------------
-- Logs
---------------------


-- Tab switching logic
hooksecurefunc("PanelTemplates_Tab_OnClick", function(self)
    local tabID = self:GetID()
    PanelTemplates_SetTab(PSK.MainFrame, tabID)

    -- Hide all frames first
    PSK.ContentFrame:Hide()
    PSK.SettingsFrame:Hide()
    PSK.LogsFrame:Hide()

    if tabID == 1 then
        PSK.ContentFrame:Show()
    elseif tabID == 2 then
        PSK.SettingsFrame:Show()
    elseif tabID == 3 then
        PSK.LogsFrame:Show()
    end
end)

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


-- Default selection
PanelTemplates_SetTab(PSK.MainFrame, 1)
PSK.ContentFrame:Show()
PSK.SettingsFrame:Hide()

-- Refresh on load
PSK:RefreshGuildList()
PSK:RefreshBidList()

C_Timer.After(0.1, function()
    if PSK.RefreshLogList then
        PSK:RefreshLogList()
		PSK:RefreshLootList()
    end
end)

