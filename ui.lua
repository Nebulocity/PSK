local PSK = select(2, ...)

-- Ensure settings exist
if not PSKDB then PSKDB = {} end
PSKDB.Settings = PSKDB.Settings or { buttonSoundsEnabled = true }
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
PSK.SettingsFrame:SetAllPoints()
PSK.SettingsFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
PSK.SettingsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.85)
PSK.SettingsFrame:Hide()

PSK.CurrentList = "Main"

-- Scroll frames parented to ContentFrame
local mainListCount = #PSKDB.MainList or 0
local guildScroll, guildChild, guildFrame, guildHeader =
    CreateBorderedScrollFrame("PSKScrollFrame", PSK.ContentFrame, 10, -110, "PSK Main (" .. mainListCount .. ")")
PSK.ScrollFrames.Main = guildScroll
PSK.ScrollChildren.Main = guildChild
PSK.Headers.Main = guildHeader

local lootScroll, lootChild, lootFrame, lootHeader =
    CreateBorderedScrollFrame("PSKLootScrollFrame", PSK.ContentFrame, 240, -110, "Loot Drops (0)")
PSK.ScrollFrames.Loot = lootScroll
PSK.ScrollChildren.Loot = lootChild
PSK.Headers.Loot = lootHeader

local bidCount = (PSK.BidEntries and #PSK.BidEntries) or 0
local bidScroll, bidChild, bidFrame, bidHeader =
    CreateBorderedScrollFrame("PSKBidScrollFrame", PSK.ContentFrame, 470, -110, "Bids (" .. bidCount .. ")", 220)
PSK.ScrollFrames.Bid = bidScroll
PSK.ScrollChildren.Bid = bidChild
PSK.Headers.Bid = bidHeader

-- Tabs
PSK.Tabs = {}
PanelTemplates_SetNumTabs(PSK.MainFrame, 2)

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


-- Tab switching logic
hooksecurefunc("PanelTemplates_Tab_OnClick", function(self)
    local tabID = self:GetID()
    PanelTemplates_SetTab(PSK.MainFrame, tabID)

    if tabID == 1 then
        PSK.ContentFrame:Show()
        PSK.SettingsFrame:Hide()
    else
        PSK.ContentFrame:Hide()
        PSK.SettingsFrame:Show()
    end
end)

-- Default selection
PanelTemplates_SetTab(PSK.MainFrame, 1)
PSK.ContentFrame:Show()
PSK.SettingsFrame:Hide()

-- Refresh on load
PSK:RefreshGuildList()
PSK:RefreshBidList()
