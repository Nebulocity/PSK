------------------------------------------------------------
-- Handles guild data gathering, bidding session management
------------------------------------------------------------

local PSK = select(2, ...)

-- Main Variables
PSKBiddingActive = false
PSK.BidEntries = {}
PSK.CurrentList = "Main"

----------------------------------------
-- Event Frame for Updates
----------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event)
    PSK:UpdateGuildData()
end)

--------------------------
-- Chat Frame for Bidding
--------------------------

local chatFrame = CreateFrame("Frame")
chatFrame:RegisterEvent("CHAT_MSG_RAID")
chatFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
chatFrame:RegisterEvent("CHAT_MSG_PARTY")
chatFrame:RegisterEvent("CHAT_MSG_SAY")

chatFrame:SetScript("OnEvent", function(self, event, msg, sender)
    if not PSKBiddingActive then return end
    if not sender then return end

    msg = msg:lower()
    if msg:find("bid") then
        local simpleName = sender:match("^(.-)%-.+") or sender
        PSK:AddBid(simpleName)
    end
end)


----------------------------------------
-- Update Guild Data
----------------------------------------

function PSK:UpdateGuildData()
    if not IsInGuild() then return end

    GuildRoster()

    if not PSKDB.Players then
        PSKDB.Players = {}
    end

    for i = 1, GetNumGuildMembers() do
        local name, rank, rankIndex, level, class, zone, note, officerNote, online, status, classFileName = GetGuildRosterInfo(i)

        if name then
            name = Ambiguate(name, "none") -- Remove realm name if needed
            if not PSKDB.Players[name] then
                PSKDB.Players[name] = {}
            end

            PSKDB.Players[name].class = classFileName
            PSKDB.Players[name].online = online
            PSKDB.Players[name].inRaid = UnitInRaid(name) ~= nil
			PSKDB.Players[name].level = level
			PSKDB.Players[name].zone = zone
        end
    end

    -- Refresh displays
    PSK:RefreshGuildList()
    PSK:RefreshBidList()
end

----------------------------------------
-- Bidding System
----------------------------------------

function PSK:StartBidding()
	PSKBiddingActive = true
	PSKBiddingOpen = true
	PSKBidTimer = 90
	
	Announce("[PSK] Bidding started!  Type 'Bid' to place a bid.")
	
	if PSK.BidButon	then
		PSK.BidButton:SetText("Stop Bidding")
		
		if PSK.BidButton.Border then 
			PSK.BidButton.Border.SetAlpha(1)
			PSK.BidButton.Border:Show()
			PSK.BidButton.Border.Pulse:Stop()
			PSK.BidButton.Border.Pulse:Play()
		end
	end	
	
	-- Clear bid entries every time bidding has started
    PSK.BidEntries = {}
	
    local listName = (PSK.CurrentList == "Tier") and "Tier List" or "Main List"
    Announce("[PSK] Bidding has started for the " .. listName .. "! 90 seconds remaining.")

    C_Timer.After(10, function()
        if PSKBiddingActive then
            Announce("[PSK] 60 seconds left to bid!")
        end
    end)
    C_Timer.After(20, function()
        if PSKBiddingActive then
            Announce("[PSK] 30 seconds left to bid!")
        end
    end)
    C_Timer.After(30, function()
        if PSKBiddingActive then
            Announce("[PSK] 15 seconds left to bid!")
        end
    end)
    C_Timer.After(35, function() -- Close for real after 90
        if PSKBiddingActive then
            PSK:CloseBidding()
        end
    end)

    PSK:RefreshBidList()
end


function PSK:CloseBidding()
	PSKBiddingActive = false
	PSKBiddingOpen = false
	
	Announce("[PSK] Bidding closed!")
	
	if PSK.BidButton then
		PSK.BidButton.SetText("Start Bidding")
		
		if PSK.BidButton.Border then
			PSK.BidButton.Border.Pulse:Stop()
			PSK.BidButton.Border:SetAlpha(1)
			PSK.BidButton.Border:Hide()
		end
	end

    PSK:RefreshBidList()
end

function PSK:AddBid(name)
    if not name then return end

    for _, entry in ipairs(PSK.BidEntries) do
        if entry.name == name then
            return -- Already bid
        end
    end

    local names = {}
    if PSK.CurrentList == "Main" and PSKDB.MainList then
        names = PSKDB.MainList
    elseif PSK.CurrentList == "Tier" and PSKDB.TierList then
        names = PSKDB.TierList
    end

    for index, playerName in ipairs(names) do
        if playerName == name then
            local playerData = PSKDB.Players and PSKDB.Players[name] or {}

            table.insert(PSK.BidEntries, {
                position = index,
                name = name,
                class = playerData.class,
                online = playerData.online,
                inRaid = playerData.inRaid,
            })

            PSK:RefreshBidList()
            break
        end
    end
end
