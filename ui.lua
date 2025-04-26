-- ui.lua
-- Main PSK UI Frame + Tabs + Scrollable Player List (Classic Safe Version)

-- Local variables
local selectedIndex = nil
local playerRows = {}
local TAB_WIDTH = 120

-- Create main PSK frame
pskFrame = CreateFrame("Frame", "PSKMainFrame", UIParent, "BasicFrameTemplateWithInset")
pskFrame:SetSize(600, 600)
pskFrame:SetPoint("CENTER")
pskFrame:SetFrameStrata("HIGH")
pskFrame:SetMovable(true)
pskFrame:EnableMouse(true)
pskFrame:RegisterForDrag("LeftButton")
pskFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
pskFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

-- Title
pskFrame.TitleBg:SetHeight(30)
pskFrame.title = pskFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
pskFrame.title:SetPoint("TOPLEFT", pskFrame.TitleBg, "TOPLEFT", 5, -3)
pskFrame.title:SetText("Perchance PSK - Suicide Kings Manager")

-- Scroll Frame
local scrollFrame = CreateFrame("ScrollFrame", nil, pskFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 25, -120)
scrollFrame:SetSize(300, 400)

local playerFrame = CreateFrame("Frame", nil, scrollFrame)
playerFrame:SetSize(300, 400)
scrollFrame:SetScrollChild(playerFrame)

-- Create tabs
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

-- Separator
local separator = pskFrame:CreateTexture(nil, "OVERLAY")
separator:SetColorTexture(0.8, 0.8, 0.8, 0.4)
separator:SetHeight(1)
separator:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 5)
separator:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, 5)

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

-- Award/Pass Buttons
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
    UpdateNameList()
end)

awardButton:SetScript("OnClick", function()
    if selectedIndex then
        AwardPlayer(selectedIndex)
        selectedIndex = nil
        UpdateNameList()
    end
end)

-- Highlight tabs
function UpdateTabHighlights()
    if PSKCurrentList == "MainList" then
        mainTab:SetNormalFontObject("GameFontHighlight")
        tierTab:SetNormalFontObject("GameFontNormalSmall")
    else
        tierTab:SetNormalFontObject("GameFontHighlight")
        mainTab:SetNormalFontObject("GameFontNormalSmall")
    end
end

-- Update list
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
    playerRows = {}

	-- Count max level 60s online versus in guild.
	local total60, online60 = CountGuildLevel60s()
    pskFrame.countText:SetText(string.format("Level 60s: %d / %d Online", online60, total60))



    playerFrame:SetHeight(#list * 30)
    local yOffset = -5

    for i, name in ipairs(list) do
        local row = CreateFrame("Button", nil, playerFrame)
        row:SetSize(scrollFrame:GetWidth() - 20, 24)
        row:SetPoint("TOPLEFT", 0, yOffset)

        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0.4)

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("LEFT", 5, 0)

        local classToken = "SHAMAN"
        local isOnline = false
        local inRaid = false

        -- Guild roster check
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

        -- Raid check
        for k = 1, GetNumGroupMembers() do
            local rName = GetRaidRosterInfo(k)
            if rName and rName == name then
                inRaid = true
                break
            end
        end

        -- Set class icon
        local coords = CLASS_ICON_TCOORDS[classToken]
        if coords then
            icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
            icon:SetTexCoord(unpack(coords))
        else
            icon:SetColorTexture(0.4, 0.4, 0.4)
        end

        -- Player name text
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        nameText:SetText(name)

        -- Status tag
        local statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        statusText:SetPoint("LEFT", nameText, "RIGHT", 8, 0)

        -- Color handling
        if not isOnline then
            -- Offline: gray everything
            nameText:SetTextColor(0.5, 0.5, 0.5)
            statusText:SetText("[Offline]")
            statusText:SetTextColor(0.5, 0.5, 0.5)
        elseif inRaid then
            -- In Raid: class color + green tag
            if RAID_CLASS_COLORS[classToken] then
                local c = RAID_CLASS_COLORS[classToken]
                nameText:SetTextColor(c.r, c.g, c.b)
            else
                nameText:SetTextColor(1, 1, 1)
            end
            statusText:SetText("[RAID]")
            statusText:SetTextColor(0, 1, 0)
        else
            -- Online (not in raid): class color + yellow tag
            if RAID_CLASS_COLORS[classToken] then
                local c = RAID_CLASS_COLORS[classToken]
                nameText:SetTextColor(c.r, c.g, c.b)
            else
                nameText:SetTextColor(1, 1, 1)
            end
            statusText:SetText("[Online]")
            statusText:SetTextColor(1, 1, 0)
        end

        if i == selectedIndex then
            bg:SetColorTexture(1, 1, 0, 0.3)
        end

        row:SetScript("OnClick", function()
            selectedIndex = i
            UpdateNameList()
        end)

        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row:GetHighlightTexture():SetAlpha(0.6)

        table.insert(playerRows, row)

        yOffset = yOffset - 26
    end

    awardButton:SetEnabled(selectedIndex ~= nil)
    UpdateTabHighlights()
end
