-- ui.lua

local PSK = select(2, ...)

-- Create the main frame
local frame = CreateFrame("Frame", "PSKMainFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(640, 480)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetFrameStrata("HIGH")
frame:SetFrameLevel(200)

PSK.MainFrame = frame
PSK.CurrentList = "Main" -- Default selection

-- Title
frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)
frame.title:SetText("Perchance PSK - Perchance Some Loot?")

-- Toggle Main/Tier Button
local toggleButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
toggleButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -35)
toggleButton:SetSize(140, 30)
toggleButton:SetText("Switch to Tier List")
toggleButton:SetScript("OnClick", function()
    if PSK.CurrentList == "Main" then
        PSK.CurrentList = "Tier"
        toggleButton:SetText("Switch to Main List")
    else
        PSK.CurrentList = "Main"
        toggleButton:SetText("Switch to Tier List")
    end

	
    -- Update the title based on list
    if PSK.CurrentList == "Main" then
		local mainListCount = #PSKDB.MainList
		PSK.ListHeader:SetText("PSK Tier List (" .. mainListCount .. ")")
		
		if PSK.CurrentList == "Main" then
			PSK.ListHeader:SetText("PSK Main List (" .. mainListCount .. ")")
		elseif PSK.CurrentList == "Tier" then
			local tierListCount = #PSKDB.TierList
			PSK.ListHeader:SetText("PSK Tier List (" .. tierListCount .. ")")
		end
    else
	local tierListCount = #PSKDB.TierList
			PSK.ListHeader:SetText("PSK Tier List (" .. tierListCount .. ")")
    end

    PSK:RefreshGuildList()
    PSK:RefreshBidList()
end)

-- Start/Close Bidding Button
local biddingButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
biddingButton:SetPoint("LEFT", toggleButton, "RIGHT", 10, 0)
biddingButton:SetSize(140, 30)
biddingButton:SetText("Start Bidding")
biddingButton:SetScript("OnClick", function()
    if PSK.BiddingOpen then
        PSK:CloseBidding()
    else
        PSK:StartBidding()
    end
end)

-- Left "List" Header
PSK.ListHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
PSK.ListHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -80)
local mainListCount = #PSKDB.MainList
PSK.ListHeader:SetText("PSK Main List (" .. mainListCount .. ")")

-- Right "Bids" Header
PSK.BidHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
PSK.BidHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 325, -80)
local bidCount = #PSK.BidEntries
PSK.BidHeader:SetText("Bids (" .. bidCount .. ")")


-- Main List ScrollFrame
local scrollFrame = CreateFrame("ScrollFrame", "PSKScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(250, 355)
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -110)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(480, 355)
scrollFrame:SetScrollChild(scrollChild)
PSK.ScrollChild = scrollChild

-- Bid List ScrollFrame
local bidScrollFrame = CreateFrame("ScrollFrame", "PSKBidScrollFrame", frame, "UIPanelScrollFrameTemplate")
bidScrollFrame:SetSize(250, 355)
bidScrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 325, -110)

local bidScrollChild = CreateFrame("Frame", nil, bidScrollFrame)
bidScrollChild:SetSize(430, 355)
bidScrollFrame:SetScrollChild(bidScrollChild)
PSK.BidScrollChild = bidScrollChild

----------------------------------------
-- Refresh Guild List (for Main or Tier)
----------------------------------------

function PSK:RefreshGuildList()
    if not PSKDB or not PSK.CurrentList then return end

    -- Wipe previous list
    if PSK.ScrollChild then
        for i, child in ipairs({PSK.ScrollChild:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end
    end

    local names = {}
    if PSK.CurrentList == "Main" and PSKDB.MainList then
        names = PSKDB.MainList
    elseif PSK.CurrentList == "Tier" and PSKDB.TierList then
        names = PSKDB.TierList
    end

    local yOffset = -5
    for index, name in ipairs(names) do
        local row = CreateFrame("Frame", nil, PSK.ScrollChild)
		row:SetSize(200, 20)
        row:SetPoint("TOPLEFT", 0, yOffset)
		
		-- Background for status glow
		row.bg = row:CreateTexture(nil, "BACKGROUND")
		row.bg:SetAllPoints()
		row.bg:SetColorTexture(1, 0.5, 0, 0.2) -- soft orange, 20% opacity
		row.bg:Hide() -- Hide by default
	
		-- Pull real player info
		local playerData = PSKDB.Players and PSKDB.Players[name]
		local class = (playerData and playerData.class) or "SHAMAN"
		local online = (playerData and playerData.online) or false
		local inRaid = (playerData and playerData.inRaid) or false
		local level = (playerData and playerData.level) or "???"
		local zone = (playerData and playerData.zone) or "???"
		
		row.playerData = {
			class = class,
			online = online,
			inRaid = inRaid,
			name = name,
			level = level,
			zone = zone,
		}

		-- Position Text
		local posText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		posText:SetPoint("LEFT", row, "LEFT", 5, 0)
		posText:SetText(index)

		-- Class Icon
		local classIcon = row:CreateTexture(nil, "ARTWORK")
		classIcon:SetSize(16, 16)
		classIcon:SetPoint("LEFT", posText, "RIGHT", 8, 0)
		classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
		if CLASS_ICON_TCOORDS[class] then
			classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
		else
			classIcon:SetTexCoord(0,1,0,1)
		end

		-- Name Text
		local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		nameText:SetPoint("LEFT", classIcon, "RIGHT", 8, 0)
		nameText:SetText(name)

		-- Status Text
		local statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		statusText:SetPoint("LEFT", nameText, "RIGHT", 10, 0)

		if inRaid then
			statusText:SetText("In Raid")
			statusText:SetTextColor(1, 0.5, 0) -- Orange
			row.bg:Show()

			-- Add gentle pulse if In Raid
			row.elapsed = 0
			row:SetScript("OnUpdate", function(self, elapsed)
				self.elapsed = (self.elapsed or 0) + elapsed
				local alpha = 0.2 + 0.1 * math.sin(self.elapsed * 3) -- Pulse between 0.1-0.3
				self.bg:SetAlpha(alpha)
			end)
		elseif online then
			statusText:SetText("Online")
			statusText:SetTextColor(0, 1, 0) -- Green
			row.bg:Hide()
		else
			statusText:SetText("Offline")
			statusText:SetTextColor(0.5, 0.5, 0.5) -- Gray
			row.bg:Hide()
			nameText:SetAlpha(0.5)
			classIcon:SetAlpha(0.5)
		end

		-- Tooltips
		row:SetScript("OnEnter", function(self)
			if self.playerData then
				GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR_RIGHT")
				GameTooltip:ClearLines()

				local class = self.playerData.class or "WARRIOR"
				local color = RAID_CLASS_COLORS[class] or { r = 1, g = 1, b = 1 }
				local icon = ""

				if CLASS_ICON_TCOORDS[class] then
					local tcoords = CLASS_ICON_TCOORDS[class]
					icon = string.format(
						"|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:%d:%d:%d:%d|t ",
						tcoords[1]*256, tcoords[2]*256, tcoords[3]*256, tcoords[4]*256
					)
				end

				GameTooltip:AddLine(icon .. (self.playerData.name or "Unknown"), color.r, color.g, color.b)

				if self.playerData.level then
					GameTooltip:AddLine("Level: " .. self.playerData.level, 0.8, 0.8, 0.8)
				end

				if self.playerData.zone and self.playerData.zone ~= "" then
					GameTooltip:AddLine("Location: " .. self.playerData.zone, 0.8, 0.8, 0.8)
				end

				GameTooltip:Show()
			end
		end)

		row:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
			


		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR_RIGHT")
		GameTooltip:ClearLines() -- 🧹 Clear previous tooltip lines just in case

		-- Offset for next row
        yOffset = yOffset - 22
    end
end

----------------------------------------
-- Refresh Bid List
----------------------------------------

function PSK:RefreshBidList()
    if not PSK.BidEntries then return end

	local bidCount = #PSK.BidEntries
	PSK.BidHeader:SetText("Bids (" .. bidCount .. ")")


    -- Wipe previous bid list
    if PSK.BidScrollChild then
        for i, child in ipairs({PSK.BidScrollChild:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end
    end

    local yOffset = -5
    for index, bidData in ipairs(PSK.BidEntries) do
        local row = CreateFrame("Frame", nil, PSK.BidScrollChild)
        row:SetSize(410, 20)
        row:SetPoint("TOPLEFT", 0, yOffset)

        -- Position
        local posText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        posText:SetPoint("LEFT", row, "LEFT", 5, 0)
        posText:SetText(bidData.position)

        -- Class Icon
        local classIcon = row:CreateTexture(nil, "ARTWORK")
        classIcon:SetSize(16, 16)
        classIcon:SetPoint("LEFT", posText, "RIGHT", 8, 0)
        classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")

        local class = "SHAMAN" -- Default placeholder
        if CLASS_ICON_TCOORDS[class] then
            classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
        else
            classIcon:SetTexCoord(0,1,0,1)
        end

        -- Name
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("LEFT", classIcon, "RIGHT", 8, 0)
        nameText:SetText(bidData.name)

        -- Status
        local statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        statusText:SetPoint("LEFT", nameText, "RIGHT", 10, 0)
        statusText:SetText("Unknown")
        statusText:SetTextColor(1, 1, 1)

		-- Award Button
		local awardButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
		awardButton:SetSize(20, 20)
		awardButton:SetPoint("LEFT", statusText, "RIGHT", 8, 0)
		awardButton:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Check")
		awardButton:GetNormalTexture():SetTexCoord(0.2, 0.8, 0.2, 0.8)
		awardButton:SetScript("OnClick", function()
			AwardPlayer(index)
		end)
		awardButton:SetText("") -- clear text

		-- Pass Button
		local passButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
		passButton:SetSize(20, 20)
		passButton:SetPoint("LEFT", awardButton, "RIGHT", 8, 0)
		passButton:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
		passButton:GetNormalTexture():SetTexCoord(0.2, 0.8, 0.2, 0.8)
		passButton:SetScript("OnClick", function()
			table.remove(PSKBidList, index)
			PSK:RefreshBidList()
		end)
		passButton:SetText("") -- clear text

		-- After creating Award button
		local awardButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
		awardButton:SetSize(20, 20)
		awardButton:SetPoint("LEFT", statusText, "RIGHT", 8, 0)
		awardButton:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Check")
		awardButton:GetNormalTexture():SetTexCoord(0.2, 0.8, 0.2, 0.8)
		awardButton:SetScript("OnClick", function()
			AwardPlayer(index)
		end)
		awardButton:SetText("") -- no weird text

		-- 💥 Pulse visually
		PSK:PulseButton(awardButton)
		
		-- Row offset
        yOffset = yOffset - 22
    end
end

PSK:RefreshGuildList()
PSK:RefreshBidList()
