-- PSK Addon Main UI File

-- Main Frame
local pskFrame = CreateFrame("Frame", "PSKMainFrame", UIParent, "BasicFrameTemplateWithInset")
pskFrame:SetSize(800, 600)
pskFrame:SetPoint("CENTER")
pskFrame:SetFrameStrata("HIGH")
pskFrame:SetMovable(true)
pskFrame:EnableMouse(true)
pskFrame:RegisterForDrag("LeftButton")
pskFrame:SetScript("OnDragStart", pskFrame.StartMoving)
pskFrame:SetScript("OnDragStop", pskFrame.StopMovingOrSizing)
pskFrame.title = pskFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
pskFrame.title:SetPoint("CENTER", pskFrame.TitleBg, "CENTER", 0, 0)
pskFrame.title:SetText("PSK Roster")

-- Scroll Frame for Player List
local playerScrollFrame = CreateFrame("ScrollFrame", "PSKPlayerScrollFrame", pskFrame, "UIPanelScrollFrameTemplate")
playerScrollFrame:SetSize(300, 500)
playerScrollFrame:SetPoint("TOPLEFT", pskFrame, "TOPLEFT", 20, -40)

local playerListFrame = CreateFrame("Frame")
playerListFrame:SetSize(300, 500)
playerScrollFrame:SetScrollChild(playerListFrame)

-- Tabs (Guild, Raid, etc.)
-- (Assume your existing tab buttons are here)

-- Bid List Frame
local bidListFrame = CreateFrame("Frame", "PSKBidListFrame", pskFrame, "BasicFrameTemplateWithInset")
bidListFrame:SetSize(300, 500)
bidListFrame:SetPoint("TOPLEFT", playerScrollFrame, "TOPRIGHT", 20, 0)

local bidTitle = bidListFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
bidTitle:SetPoint("TOP", 0, -10)
bidTitle:SetText("Bids")

-- Start Bid Window Button
local startBidButton = CreateFrame("Button", "PSKStartBidButton", bidListFrame, "UIPanelButtonTemplate")
startBidButton:SetSize(140, 25)
startBidButton:SetPoint("TOPLEFT", -150, -10)
startBidButton:SetText("Start Bid Window")

-- Cancel Bid Window Button (Hidden by default)
local cancelBidButton = CreateFrame("Button", "PSKCancelBidButton", bidListFrame, "UIPanelButtonTemplate")
cancelBidButton:SetSize(140, 25)
cancelBidButton:SetPoint("TOPLEFT", startBidButton, "TOPRIGHT", 10, 0)
cancelBidButton:SetText("Cancel Bid Window")
cancelBidButton:Hide()

-- Bidding Status Variables
local biddingActive = false
local bidList = {}
local biddingTimers = {}

-- Bidding Functions

-- Utility: Send message to RAID chat
local function SendRaidWarning(msg)
    if IsInRaid() then
        SendChatMessage(msg, "RAID")
    end
end

-- Utility: Play sound (start/stop)
local function PlayBiddingSound(starting)
    if starting then
        PlaySound(8959) -- Ready Check sound
    else
        PlaySound(9278) -- UI_Error sound
    end
end

-- Utility: Flash bid frame during bidding
local function StartBidFrameGlow()
    bidListFrame:SetBackdropBorderColor(1, 1, 0) -- Yellow border
    bidListFrame:SetBackdrop({ 
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
end

local function StopBidFrameGlow()
    bidListFrame:SetBackdropBorderColor(1, 1, 1) -- Normal white border
end

-- Start a New Bidding Window
local function StartBiddingWindow()
    wipe(bidList)
    -- (Redraw bid list UI here if needed)

    biddingActive = true
    SendRaidWarning("Bidding window open!")
    PlayBiddingSound(true)
    StartBidFrameGlow()

    startBidButton:Hide()
    cancelBidButton:Show()

    -- Start Timers
    biddingTimers = {}
    table.insert(biddingTimers, C_Timer.NewTimer(30, function() SendRaidWarning("60 seconds left!") end))
    table.insert(biddingTimers, C_Timer.NewTimer(60, function() SendRaidWarning("30 seconds left!") end))
    table.insert(biddingTimers, C_Timer.NewTimer(75, function() SendRaidWarning("15 seconds left!") end))
    table.insert(biddingTimers, C_Timer.NewTimer(87, function()
        SendRaidWarning("3...")
        C_Timer.After(1, function() SendRaidWarning("2...") end)
        C_Timer.After(2, function() SendRaidWarning("1...") end)
    end))
    table.insert(biddingTimers, C_Timer.NewTimer(90, function()
        CancelBiddingWindow()
    end))
end

-- Cancel/End Bidding Window
function CancelBiddingWindow()
    biddingActive = false
    SendRaidWarning("Bidding window closed!")
    PlayBiddingSound(false)
    StopBidFrameGlow()

    startBidButton:Show()
    cancelBidButton:Hide()

    -- Cancel timers
    for _, timer in ipairs(biddingTimers) do
        if timer.Cancel then
            timer:Cancel()
        end
    end
    biddingTimers = {}
end

-- Handle Incoming Bids
local function HandleIncomingBid(playerName, message)
    if not biddingActive then return end
    if not message or not string.find(string.lower(message), "bid") then return end

    -- Check if player is in PSK list
    if not PSKDB[playerName] then return end

    -- Check if player is in the current raid
    local inRaid = false
    for i = 1, GetNumGroupMembers() do
        local name, _, _, _, _, _, _, _, _, _, _ = GetRaidRosterInfo(i)
        if name == playerName then
            inRaid = true
            break
        end
    end
    if not inRaid then return end

    -- Check if already in bid list
    for _, name in ipairs(bidList) do
        if name == playerName then
            return -- Already bid
        end
    end

    -- Add bidder
    table.insert(bidList, playerName)
    -- (Redraw bid list UI here to update names)
end


-- Event Listening

-- Chat Event Listener for "bid"
local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_RAID")
f:RegisterEvent("CHAT_MSG_RAID_LEADER")
f:RegisterEvent("CHAT_MSG_RAID_WARNING")
f:SetScript("OnEvent", function(_, event, message, sender)
    local playerName = Ambiguate(sender, "short")
    HandleIncomingBid(playerName, message)
end)

-- Button Handlers

startBidButton:SetScript("OnClick", StartBiddingWindow)
cancelBidButton:SetScript("OnClick", CancelBiddingWindow)