-- Main PSK UI Frame Setup

-- Create the main addon frame
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
pskFrame.title:SetText("Perchance PSK - Perchance You Want Some Loot?")

-- Status text ("Last Updated")
pskFrame.statusText = pskFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
pskFrame.statusText:SetPoint("TOPLEFT", pskFrame.title, "BOTTOMLEFT", 25, -10)
pskFrame.statusText:SetText("Last updated: never")
pskFrame.statusText:SetTextColor(0.7, 0.7, 0.7)

-- Refresh Button
refreshButton = CreateFrame("Button", nil, pskFrame, "UIPanelButtonTemplate")
refreshButton:SetSize(80, 24)
refreshButton:SetPoint("TOPRIGHT", pskFrame, "TOPRIGHT", -30, -30)
refreshButton:SetText("Refresh")
refreshButton:SetScript("OnClick", function() RefreshRoster() end)

-- Tooltip for the refresh button
refreshButton:EnableMouse(true)
refreshButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(refreshButton, "ANCHOR_RIGHT")
    GameTooltip:SetText("Click to update the guild list!", 1, 1, 1)
    GameTooltip:Show()
end)
refreshButton:SetScript("OnLeave", GameTooltip_Hide)

-- Create the Scroll Frame for the guild list
scrollFrame = CreateFrame("ScrollFrame", nil, pskFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 25, -60)
scrollFrame:SetSize(260, 500)

playerFrame = CreateFrame("Frame", nil, scrollFrame)
playerFrame:SetSize(260, 500)
scrollFrame:SetScrollChild(playerFrame)

-- Create "Updated!" notification text
updatedText = pskFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
updatedText:SetPoint("TOP", refreshButton, "BOTTOM", 0, -5)
updatedText:SetText("")
updatedText:SetTextColor(0, 1, 0)

-- Create "Next Refresh In" countdown text
nextRefreshText = pskFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
nextRefreshText:SetPoint("TOP", updatedText, "BOTTOM", 0, -2)
nextRefreshText:SetText("")
nextRefreshText:SetTextColor(0.7, 0.7, 0.7)

-- Create Guild Online Counter
guildCounterText = pskFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
guildCounterText:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -5)
guildCounterText:SetText("Max-Level Guild Members Online: 0/0")
guildCounterText:SetTextColor(0.8, 0.8, 1)

-- Background behind the scroll area
local bg = scrollFrame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(scrollFrame)
bg:SetColorTexture(0, 0, 0, 0.2)
