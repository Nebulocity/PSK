
local PSK = select(2, ...)

------------------------
-- Ensure settings exist
------------------------

if not PSKDB then PSKDB = {} end
PSKDB.Settings = PSKDB.Settings or { buttonSoundsEnabled = true, lootThreshold = 3 } -- default to 3 for rare
PSK.Settings = CopyTable(PSKDB.Settings)
-- local mainListCount = #PSKDB.MainList or 0
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

------------------------------
-- Import/Export Frame (Tab)
------------------------------

PSK.ImportExportFrame = CreateFrame("Frame", "PSKImportExportFrame", PSK.MainFrame, "BackdropTemplate")
PSK.ImportExportFrame:SetPoint("TOPLEFT", 8, -28)
PSK.ImportExportFrame:SetPoint("BOTTOMRIGHT", -6, 8)
PSK.ImportExportFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
PSK.ImportExportFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.85)
PSK.ImportExportFrame:Hide()


------------------------------
-- Import/Export Frames
------------------------------

-- Path to custom parchment texture
local parchmentTexture = "Interface\\AddOns\\PSK\\Media\\parchment.png"


------------------------------
-- Create Main List Frame
------------------------------

local mainListFrame = CreateFrame("Frame", "PSKMainListFrame", PSK.ImportExportFrame, "BackdropTemplate")
mainListFrame:SetPoint("TOPLEFT", 20, -60)
mainListFrame:SetSize(300, 340)
mainListFrame:SetBackdrop({
    bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 256, edgeSize = 16,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
})
mainListFrame:SetBackdropColor(1, 1, 1, 0.9)

-- Create Main List Title
local mainListTitle = mainListFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
mainListTitle:SetPoint("TOP", 0, -10)
mainListTitle:SetText("Main List")

-- Create Main List Scroll Frame
local mainScrollFrame = CreateFrame("ScrollFrame", "PSKMainListScrollFrame", mainListFrame, "UIPanelScrollFrameTemplate")
mainScrollFrame:SetPoint("TOPLEFT", 10, -40)
mainScrollFrame:SetSize(280, 280)


-- Create Main List Edit Box
local mainEditBox = CreateFrame("EditBox", "PSKMainListEditBox", mainScrollFrame, "BackdropTemplate")
mainEditBox:SetMultiLine(true)
mainEditBox:SetFontObject(GameFontHighlight)
mainEditBox:SetAutoFocus(false)
mainEditBox:SetSize(280, 280)
mainEditBox:SetTextInsets(10, 10, 10, 10)
mainEditBox:SetBackdrop(nil) -- Remove the white border
mainScrollFrame:SetScrollChild(mainEditBox)

-- Escape key handling for Main Edit Box
mainEditBox:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        self:ClearFocus()
        self:EnableKeyboard(false)
        C_Timer.After(0.1, function() self:EnableKeyboard(true) end)  -- Re-enable keyboard input
    end
end)

PSK.MainListEditBox = mainEditBox

-- Placeholder text for main edit box
mainEditBox:SetScript("OnShow", function(self)
    if self:GetText() == "" then
        self:SetText("|cff999999Type your main list here...|r")
    end
end)

mainEditBox:SetScript("OnEditFocusGained", function(self)
    if self:GetText() == "|cff999999Type your main list here...|r" then
        self:SetText("")
    end
end)

mainEditBox:SetScript("OnEditFocusLost", function(self)
    if self:GetText() == "" then
        self:SetText("|cff999999Type your main list here...|r")
    end
end)

------------------------------
-- Create Tier List Frame
------------------------------

local tierListFrame = CreateFrame("Frame", "PSKTierListFrame", PSK.ImportExportFrame, "BackdropTemplate")
tierListFrame:SetPoint("TOPLEFT", mainListFrame, "TOPRIGHT", 20, 0)
tierListFrame:SetSize(300, 340)
tierListFrame:SetBackdrop({
    bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 256, edgeSize = 16,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
})
tierListFrame:SetBackdropColor(1, 1, 1, 0.9)

-- Create Tier List Title
local tierListTitle = tierListFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
tierListTitle:SetPoint("TOP", 0, -10)
tierListTitle:SetText("Tier List")

-- Create Tier List Scroll Frame
local tierScrollFrame = CreateFrame("ScrollFrame", "PSKTierListScrollFrame", tierListFrame, "UIPanelScrollFrameTemplate")
tierScrollFrame:SetPoint("TOPLEFT", 10, -40)
tierScrollFrame:SetSize(280, 280)

-- Remove the default scroll frame background
local scrollBg = _G["PSKTierListScrollFrameBG"]
if scrollBg then
    scrollBg:SetTexture(nil)
end

-- Create Tier List Edit Box
local tierEditBox = CreateFrame("EditBox", "PSKTierListEditBox", tierScrollFrame, "BackdropTemplate")
tierEditBox:SetMultiLine(true)
tierEditBox:SetFontObject(GameFontHighlight)
tierEditBox:SetAutoFocus(false)
tierEditBox:SetSize(280, 280)
tierEditBox:SetTextInsets(10, 10, 10, 10)
tierEditBox:SetBackdrop(nil) -- Remove the white border

-- Escape key handling for Tier Edit Box
tierEditBox:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        self:ClearFocus()
        self:EnableKeyboard(false)
        C_Timer.After(0.1, function() self:EnableKeyboard(true) end)  -- Re-enable keyboard input
    end
end)

tierScrollFrame:SetScrollChild(tierEditBox)

-- Add placeholder text for Tier List
tierEditBox:SetScript("OnShow", function(self)
    if self:GetText() == "" then
        self:SetText("|cff999999Type your tier list here...|r")
    end
end)

tierEditBox:SetScript("OnEditFocusGained", function(self)
    if self:GetText() == "|cff999999Type your tier list here...|r" then
        self:SetText("")
    end
end)

tierEditBox:SetScript("OnEditFocusLost", function(self)
    if self:GetText() == "" then
        self:SetText("|cff999999Type your tier list here...|r")
    end
end)

PSK.TierListEditBox = tierEditBox



---------------------------------------------
-- Set the default selected list (main/tier)
---------------------------------------------

PSK.CurrentList = "Main"


----------------------------------------------
-- Parent Player scroll frame to ContentFrame
----------------------------------------------

local playerScroll, playerChild, playerFrame, playerHeader =
    CreateBorderedScrollFrame("PSKScrollFrame", PSK.ContentFrame, 10, pskTabScrollFrameHeight, "PSK Main ( .. mainListCount .. )")
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

--------------------------------------------
-- Parent Bidding scroll frame to ContentFrame
----------------------------------------------

local bidCount = (PSK.BidEntries and #PSK.BidEntries) or 0
local bidScroll, bidChild, bidFrame, bidHeader =
    CreateBorderedScrollFrame("PSKBidScrollFrame", PSK.ContentFrame, 470, pskTabScrollFrameHeight, "Bids ( .. bidCount .. )", 220)
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

local tierHeader = PSK.ManageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
tierHeader:SetPoint("TOPLEFT", 365, -10)

-- Create the two scroll lists
local mainScroll, mainChild, mainFrame, mainScrollHeader = CreateBorderedScrollFrame("PSKMainAvailableScroll", PSK.ManageFrame, 2, manageTabScrollFrameHeight, "Available PSK Main Members")
local tierScroll, tierChild, tierFrame, tierScrollHeader = CreateBorderedScrollFrame("PSKTierAvailableScroll", PSK.ManageFrame, 232, manageTabScrollFrameHeight, "Available PSK Tier Members")

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
		PSKDB.LootDrops = PSKDB.LootDrops or {}
		wipe(PSKDB.LootDrops)
		PSK:RefreshLootList()
	end

}


------------------------------
-- Create Log scroll frame
------------------------------

local logScroll, logChild, logFrame, logHeader =
    CreateBorderedScrollFrame("PSKLogScrollFrame", PSK.LogsFrame, 20, -40, "Loot Logs", 645, 700)
PSK.ScrollFrames.Logs = logScroll
PSK.ScrollChildren.Logs = logChild
PSK.Headers.Logs = logHeader



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
-- Set Tab 3 (Logs)
------------------------------

local tab3 = CreateFrame("Button", "PSKMainFrameTab3", PSK.MainFrame, "CharacterFrameTabButtonTemplate")
tab3:SetID(3)
tab3:SetText("Logs")
tab3:SetPoint("LEFT", tab2, "RIGHT", -16, 0)
PanelTemplates_TabResize(tab3, 0)
PSK.Tabs[3] = tab3

------------------------------
-- Tab 4 (Import/Export)
------------------------------

local tab4 = CreateFrame("Button", "PSKMainFrameTab4", PSK.MainFrame, "CharacterFrameTabButtonTemplate")
tab4:SetID(4)
tab4:SetText("Import/Export")
tab4:SetPoint("LEFT", tab3, "RIGHT", -16, 0)
PanelTemplates_TabResize(tab4, 0)
PSK.Tabs[4] = tab4



------------------------------
-- Tab-Switching Logic
------------------------------

hooksecurefunc("PanelTemplates_Tab_OnClick", function(self)

	-- Only respond to tab clicks that are children of PSKMainFrame
    if not self or not self:GetParent() or self:GetParent():GetName() ~= "PSKMainFrame" then
        return
    end
	
    local tabID = self:GetID()
	
    -- PanelTemplates_SetTab(PSK.MainFrame, tabID)
	for i, tab in ipairs(PSK.Tabs) do
		if i == tabID then
			PanelTemplates_SelectTab(tab)
		else
			PanelTemplates_DeselectTab(tab)
		end
	end


    -- Hide all frames first
    PSK.ContentFrame:Hide()
    PSK.SettingsFrame:Hide()
    PSK.LogsFrame:Hide()
    PSK.ManageFrame:Hide()
    PSK.ImportExportFrame:Hide()

    -- Show the selected frame
    if tabID == 1 then
        PSK.ContentFrame:Show()
    elseif tabID == 2 then
        PSK.ManageFrame:Show()
        PSK:DebouncedRefreshAvailablePlayerLists()
    elseif tabID == 3 then
        PSK.LogsFrame:Show()
    elseif tabID == 4 then
        PSK.ImportExportFrame:Show()
    end
end)



-- Static popup dialog
    StaticPopupDialogs["PSK_CONFIRM_IMPORT"] = {
        text = "Are you sure you want to import these lists? This will overwrite your current Main and Tier lists.",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            PSK:ImportLists(mainText, tierText)
            PSK.MainListEditBox:SetText("")
            PSK.TierListEditBox:SetText("")
            print("[PSK] Lists Imported Successfully")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
	
			
	
----------------------------------
-- Set the default selected tab
----------------------------------

PanelTemplates_SetTab(PSK.MainFrame, 1)

PSK.ContentFrame:Show()
PSK.SettingsFrame:Hide()
PSK.ManageFrame:Hide()
PSK.LogsFrame:Hide()
PSKImportExportFrame:Hide()


----------------------------------
-- Refresh lists on load
----------------------------------

C_Timer.After(0.1, function()
	PSK:DebouncedRefreshAvailablePlayerLists()
	PSK:DebouncedRefreshPlayerLists()
	PSK:DebouncedRefreshLootList()
	-- PSK:CreateImportExportSection()
	PSK:DebouncedRefreshLogList()	
	PSK:DebouncedRefreshBidList()
end)

