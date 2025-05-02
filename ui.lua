
local PSK = select(2, ...)

-- Ensure settings exist
if not PSKDB then PSKDB = {} end
PSKDB.Settings = PSKDB.Settings or { buttonSoundsEnabled = true, lootThreshold = 3 }
PSK.Settings = CopyTable(PSKDB.Settings)

local LOOT_RARITY = {
    Rare = 3,
    Epic = 4,
    Legendary = 5,
}

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


-- Loot Threshold Label
local thresholdLabel = PSK.SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
thresholdLabel:SetPoint("TOPLEFT", soundCheckbox, "BOTTOMLEFT", 0, -30)
thresholdLabel:SetText("Loot Threshold:")

-- Loot Threshold Dropdown
local thresholdDropdown = CreateFrame("Frame", "PSKLootThresholdDropdown", PSK.SettingsFrame, "UIDropDownMenuTemplate")
thresholdDropdown:SetPoint("TOPLEFT", thresholdLabel, "BOTTOMLEFT", -15, -5)
UIDropDownMenu_SetWidth(thresholdDropdown, 150)

local lootOptions = {
    { text = "|cff0070ddRare (Blue)|r", value = 2 },
    { text = "|cffa335eeEpic (Purple)|r", value = 3 },
    { text = "|cffff8000Legendary (Orange)|r", value = 4 },
}

local function OnLootThresholdSelect(_, value)
    PSK.Settings.lootThreshold = value
    PSKDB.Settings.lootThreshold = value
    UIDropDownMenu_SetSelectedValue(thresholdDropdown, value)
    for _, option in ipairs(lootOptions) do
        if option.value == value then
            UIDropDownMenu_SetText(thresholdDropdown, option.text)
            break
        end
    end
    print("[PSK] Loot threshold set to " .. (value == 2 and "Rare" or value == 3 and "Epic" or "Legendary"))
end

UIDropDownMenu_Initialize(thresholdDropdown, function(self, level)
    for _, option in ipairs(lootOptions) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = option.text
        info.value = option.value
        info.func = OnLootThresholdSelect
        info.checked = (option.value == PSK.Settings.lootThreshold)
        UIDropDownMenu_AddButton(info, level)
    end
end)

-- AFTER initializing, set selection and text
C_Timer.After(0, function()
    UIDropDownMenu_SetSelectedValue(thresholdDropdown, PSK.Settings.lootThreshold)
    for _, option in ipairs(lootOptions) do
        if option.value == PSK.Settings.lootThreshold then
            UIDropDownMenu_SetText(thresholdDropdown, option.text)
            break
        end
    end
end)


UIDropDownMenu_SetWidth(thresholdDropdown, 150)

-- UIDropDownMenu_SetSelectedValue(thresholdDropdown, PSK.Settings.lootThreshold)
-- for _, option in ipairs(lootOptions) do
    -- if option.value == PSK.Settings.lootThreshold then
        -- UIDropDownMenu_SetText(thresholdDropdown, option.text)
        -- break
    -- end
-- end


-- Test Loot Threshold Button
local testThresholdButton = CreateFrame("Button", nil, PSK.SettingsFrame, "GameMenuButtonTemplate")
testThresholdButton:SetSize(160, 24)
testThresholdButton:SetPoint("TOPLEFT", thresholdDropdown, "BOTTOMLEFT", 20, -10)
testThresholdButton:SetText("Test Loot Threshold")

testThresholdButton:SetScript("OnClick", function()
    local threshold = PSK.Settings.lootThreshold or 3
    local testItems = {
        { name = "Green Sword", rarity = 1, color = "|cff1eff00" },
        { name = "Blue Shield", rarity = 2, color = "|cff0070dd" },
        { name = "Epic Wand", rarity = 3, color = "|cffa335ee" },
        { name = "Legendary Helm", rarity = 4, color = "|cffff8000" },
    }

    print("|cffffff00[PSK]|r --- Testing Loot Threshold ---")
    for _, item in ipairs(testItems) do
        local coloredName = item.color .. item.name .. "|r"
        if item.rarity >= threshold then
            print("✔ Would record: " .. coloredName)
        else
            print("✘ Would skip: " .. coloredName)
        end
    end
    print("|cffffff00[PSK]|r --- End Test ---")
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
