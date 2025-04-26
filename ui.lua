-- Full PSK UI Frame + Scroll Lists (Classic Anniversary Safe)

-- Local variables
local selectedIndex = nil
local selectedBidIndex = nil
local playerRows = {}
local bidRows = {}
local TAB_WIDTH = 120

-- Main Frame
pskFrame = CreateFrame("Frame", "PSKMainFrame", UIParent, "BasicFrameTemplateWithInset")
pskFrame:SetSize(800, 600)
pskFrame:SetPoint("CENTER")
pskFrame:SetFrameStrata("HIGH")
pskFrame:SetMovable(true)
pskFrame:EnableMouse(true)
pskFrame:RegisterForDrag("LeftButton")
pskFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
pskFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

-- Title setup
pskFrame.TitleBg:SetHeight(30)
pskFrame.title = pskFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
pskFrame.title:SetPoint("TOPLEFT", pskFrame.TitleBg, "TOPLEFT", 5, -3)
pskFrame.title:SetText("Perchance PSK - Perchance Some Loot?")

-- Status Text
pskFrame.statusText = pskFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
pskFrame.statusText:SetPoint("TOPLEFT", pskFrame.title, "BOTTOMLEFT", 25, -10)
pskFrame.statusText:SetText("Select a player to Award or Pass.")

pskFrame.countText = pskFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
pskFrame.countText:SetPoint("TOPLEFT", pskFrame.statusText, "BOTTOMLEFT", 0, -5)
pskFrame.countText:SetText("Loading...")

-- Refresh Button
local refreshStatusButton = CreateFrame("Button", nil, pskFrame, "UIPanelButtonTemplate")
refreshStatusButton:SetSize(120, 28)
refreshStatusButton:SetPoint("TOPRIGHT", pskFrame, "TOPRIGHT", -30, -30)
refreshStatusButton:SetText("Refresh Status")
refreshStatusButton:SetScript("OnClick", function()
    GuildRoster()
    C_Timer.After(1, function()
        UpdateNameList()
    end)
end)

-- Scroll Frame: Main List
local scrollFrame = CreateFrame("ScrollFrame", nil, pskFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 25, -120)
scrollFrame:SetSize(300, 400)

local playerFrame = CreateFrame("Frame", nil, scrollFrame)
playerFrame:SetSize(300, 400)
scrollFrame:SetScrollChild(playerFrame)

-- Separator
local separator = pskFrame:CreateTexture(nil, "OVERLAY")
separator:SetColorTexture(0.8, 0.8, 0.8, 0.6)
separator:SetWidth(2)
separator:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 10, 5)
separator:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 10, -5)

-- Scroll Frame: Bid List
local bidScrollFrame = CreateFrame("ScrollFrame", nil, pskFrame, "UIPanelScrollFrameTemplate")
bidScrollFrame:SetPoint("TOPLEFT", separator, "TOPRIGHT", 10, 0)
bidScrollFrame:SetSize(300, 400)

local bidFrame = CreateFrame("Frame", nil, bidScrollFrame)
bidFrame:SetSize(300, 400)
bidScrollFrame:SetScrollChild(bidFrame)

-- Bid List Header
local bidHeader = bidScrollFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
bidHeader:SetPoint("BOTTOMLEFT", bidScrollFrame, "TOPLEFT", 5, 10)
bidHeader:SetText("Bids")
bidHeader:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")


-- Tabs
local function CreateTabButton(index, text)
    local btn = CreateFrame("Button", "PSKTabButton"..index, pskFrame, "UIPanelButtonTemplate")
    btn:SetSize(TAB_WIDTH, 28)
    btn:SetText(text)
    btn:SetPoint("BOTTOMLEFT", scrollFrame, "TOPLEFT", (index-1)*(TAB_WIDTH+5), 10)
    btn:SetNormalFontObject("GameFontHighlight")
    btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    btn:GetHighlightTexture():SetAlpha(0.7)

    btn:SetScript("OnClick", function()
        PSKCurrentList = (index == 1) and "MainList" or "TierList"
        selectedIndex = nil
        UpdateNameList()
        UpdateTabHighlights()
    end)
    return btn
end

local mainTab = CreateTabButton(1, "Main List")
local tierTab = CreateTabButton(2, "Tier List")

-- Award / Pass Buttons
local awardButton = CreateFrame("Button", nil, pskFrame, "GameMenuButtonTemplate")
awardButton:SetSize(TAB_WIDTH, 28)
awardButton:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -20)
awardButton:SetText("Award Selected")
awardButton:SetEnabled(false)

local passButton = CreateFrame("Button", nil, pskFrame, "GameMenuButtonTemplate")
passButton:SetSize(TAB_WIDTH, 28)
passButton:SetPoint("LEFT", awardButton, "RIGHT", 20, 0)
passButton:SetText("Pass")

passButton:SetScript("OnClick", function()
    selectedIndex = nil
    selectedBidIndex = nil
    UpdateNameList()
end)

awardButton:SetScript("OnClick", function()
    if selectedBidIndex then
        local name = PSKBidList[selectedBidIndex]
        table.remove(PSKBidList, selectedBidIndex)
        table.insert(PSKDB[PSKCurrentList], name)
        selectedBidIndex = nil
    elseif selectedIndex then
        AwardPlayer(selectedIndex)
        selectedIndex = nil
    end
    UpdateNameList()
end)

-- Highlight Tabs
function UpdateTabHighlights()
    if PSKCurrentList == "MainList" then
        mainTab:SetNormalFontObject("GameFontHighlight")
        tierTab:SetNormalFontObject("GameFontNormalSmall")
    else
        tierTab:SetNormalFontObject("GameFontHighlight")
        mainTab:SetNormalFontObject("GameFontNormalSmall")
    end
end

-- Create player row
local function CreatePlayerRow(parent, name, isOnline, inRaid, classToken)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(parent:GetWidth()-20, 24)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.4)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("LEFT", 5, 0)

    local coords = CLASS_ICON_TCOORDS[classToken]
    if coords then
        icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        icon:SetTexCoord(unpack(coords))
    else
        icon:SetColorTexture(0.4, 0.4, 0.4)
    end

    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    nameText:SetText(name)

    if RAID_CLASS_COLORS[classToken] then
        local c = RAID_CLASS_COLORS[classToken]
        nameText:SetTextColor(c.r, c.g, c.b)
    elseif isOnline then
        nameText:SetTextColor(1, 1, 0)
    else
        nameText:SetTextColor(0.5, 0.5, 0.5)
    end

    local statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("LEFT", nameText, "RIGHT", 8, 0)
    if inRaid then
        statusText:SetText("[Raid]")
        statusText:SetTextColor(0, 1, 0)
    elseif isOnline then
        statusText:SetText("[Online]")
        statusText:SetTextColor(1, 1, 0)
    else
        statusText:SetText("[Offline]")
        statusText:SetTextColor(0.5, 0.5, 0.5)
    end

    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    row:GetHighlightTexture():SetAlpha(0.6)

    return row, bg
end

-- Update List
function UpdateNameList()
    if not playerFrame then return end

    local list = PSKDB[PSKCurrentList]
    if not list then
        pskFrame.countText:SetText("No list loaded.")
        return
    end

    for _, row in ipairs(playerRows) do
        row:Hide()
        row:SetParent(nil)
    end
    for _, row in ipairs(bidRows) do
        row:Hide()
        row:SetParent(nil)
    end
    playerRows = {}
    bidRows = {}

    -- Max Level Count
    local total60, online60 = 0, 0
    for name, data in pairs(PSKDB) do
        if type(data) == "table" and data.seen and data.class then
            total60 = total60 + 1
            if data.online then
                online60 = online60 + 1
            end
        end
    end
    pskFrame.countText:SetText(string.format("Level 60s: %d / %d Online", online60, total60))

    -- Create Main List Rows
    local yOffset = -5
    for i, name in ipairs(list) do
        local isOnline, inRaid, classToken = false, false, "SHAMAN"
        for j = 1, GetNumGuildMembers() do
            local gName, _, _, _, classFileName, _, _, _, online = GetGuildRosterInfo(j)
            if gName then
                gName = Ambiguate(gName, "short")
                if gName == name and classFileName then
                    classToken = string.upper(classFileName)
                    isOnline = online
                    break
                end
            end
        end
        for k = 1, GetNumGroupMembers() do
            local rName = GetRaidRosterInfo(k)
            if rName == name then
                inRaid = true
                break
            end
        end

        local row, bg = CreatePlayerRow(playerFrame, name, isOnline, inRaid, classToken)
        row:SetPoint("TOPLEFT", 0, yOffset)

        if i == selectedIndex then
            bg:SetColorTexture(1, 1, 0, 0.3)
        end

        row:SetScript("OnClick", function()
            selectedIndex = i
            selectedBidIndex = nil
            UpdateNameList()
        end)

        table.insert(playerRows, row)
        yOffset = yOffset - 26
    end

    -- Create Bid List Rows
    if not PSKBidList then PSKBidList = {} end
    local yOffsetBids = -5
    for i, name in ipairs(PSKBidList) do
        local isOnline, inRaid, classToken = false, false, "SHAMAN"
        for j = 1, GetNumGuildMembers() do
            local gName, _, _, _, classFileName, _, _, _, online = GetGuildRosterInfo(j)
            if gName then
                gName = Ambiguate(gName, "short")
                if gName == name and classFileName then
                    classToken = string.upper(classFileName)
                    isOnline = online
                    break
                end
            end
        end
        for k = 1, GetNumGroupMembers() do
            local rName = GetRaidRosterInfo(k)
            if rName == name then
                inRaid = true
                break
            end
        end

        local row, bg = CreatePlayerRow(bidFrame, name, isOnline, inRaid, classToken)
        row:SetPoint("TOPLEFT", 0, yOffsetBids)

        if i == selectedBidIndex then
            bg:SetColorTexture(1, 1, 0, 0.3)
        end

        row:SetScript("OnClick", function()
            selectedBidIndex = i
            selectedIndex = nil
            UpdateNameList()
        end)

        table.insert(bidRows, row)
        yOffsetBids = yOffsetBids - 26
    end

    awardButton:SetEnabled(selectedIndex ~= nil or selectedBidIndex ~= nil)
    UpdateTabHighlights()
end
