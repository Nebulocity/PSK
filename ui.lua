-- Main UI Frame
pskFrame = CreateFrame("Frame", "PSKMainFrame", UIParent, "BasicFrameTemplateWithInset")
pskFrame:SetSize(800, 600)
pskFrame:SetPoint("CENTER")
pskFrame:SetFrameStrata("HIGH")
pskFrame:SetMovable(true)
pskFrame:EnableMouse(true)
pskFrame:RegisterForDrag("LeftButton")
pskFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
pskFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

pskFrame.TitleBg:SetHeight(30)
pskFrame.title = pskFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
pskFrame.title:SetPoint("TOPLEFT", pskFrame.TitleBg, "TOPLEFT", 5, -3)
pskFrame.title:SetText("Perchance PSK - Perchance You Want Some Loot?")
pskFrame.statusText = pskFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
pskFrame.statusText:SetPoint("TOPLEFT", pskFrame.title, "BOTTOMLEFT", 25, -10)
pskFrame.statusText:SetText("Last updated: never")
pskFrame.statusText:SetTextColor(0.7, 0.7, 0.7)

-- Refresh Button
refreshButton = CreateFrame("Button", nil, pskFrame, "UIPanelButtonTemplate")
refreshButton:SetSize(80, 24)
refreshButton:SetPoint("TOPRIGHT", pskFrame, "TOPRIGHT", -30, -30)
refreshButton:SetText("Refresh")

refreshButton:EnableMouse(true)
refreshButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(refreshButton, "ANCHOR_RIGHT")
    GameTooltip:SetText("Click to update the guild list!", 1, 1, 1)
    GameTooltip:Show()
end)
refreshButton:SetScript("OnLeave", GameTooltip_Hide)

refreshButton:SetScript("OnClick", function()
    RefreshRoster()
end)

-- Scroll Frame
scrollFrame = CreateFrame("ScrollFrame", nil, pskFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 25, -60)
scrollFrame:SetSize(260, 500)

playerFrame = CreateFrame("Frame", nil, scrollFrame)
playerFrame:SetSize(260, 500)
scrollFrame:SetScrollChild(playerFrame)
