-- core.lua

local PSK = select(2, ...)

-- Main Variables
PSK.BiddingOpen = false
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

----------------------------------------
-- Update Guild Data (live)
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
-- Bidding System (Unchanged)
----------------------------------------

function PSK:StartBidding()
    if PSK.BiddingOpen then return end
    PSK.BiddingOpen = true
    PSK.BidEntries = {}

    local listName = (PSK.CurrentList == "Tier") and "Tier List" or "Main List"
    Announce("[PSK] Bidding has started for the " .. listName .. "! 90 seconds remaining.")

    C_Timer.After(10, function()
        if PSK.BiddingOpen then
            Announce("[PSK] 60 seconds left to bid!")
        end
    end)
    C_Timer.After(20, function()
        if PSK.BiddingOpen then
            Announce("[PSK] 30 seconds left to bid!")
        end
    end)
    C_Timer.After(30, function()
        if PSK.BiddingOpen then
            Announce("[PSK] 15 seconds left to bid!")
        end
    end)
    C_Timer.After(35, function() -- Close for real after 90
        if PSK.BiddingOpen then
            PSK:CloseBidding()
        end
    end)

    PSK:RefreshBidList()
end

function PSK:CloseBidding()
    if not PSK.BiddingOpen then return end
    PSK.BiddingOpen = false
    Announce("[PSK] Bidding closed!")
    PSK:RefreshBidList()
end

local chatFrame = CreateFrame("Frame")
chatFrame:RegisterEvent("CHAT_MSG_RAID")
chatFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
chatFrame:RegisterEvent("CHAT_MSG_PARTY")
chatFrame:RegisterEvent("CHAT_MSG_SAY")

chatFrame:SetScript("OnEvent", function(self, event, msg, sender)
    if not PSK.BiddingOpen then return end
    if not sender then return end

    msg = msg:lower()
    if msg:find("bid") then
        local simpleName = sender:match("^(.-)%-.+") or sender
        PSK:AddBid(simpleName)
    end
end)

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
