-- core.lua

local PSK = select(2, ...)

-- For bidding
if not PSKDB.MainList then
    PSKDB.MainList = {}
end

if not PSKDB.TierList then
    PSKDB.TierList = {}
end


-- Main Variables
BiddingOpen = false
PSK.BidEntries = {}
PSK.CurrentList = "Main"

----------------------------------------
-- Zug zug
----------------------------------------

function PlayRandomPeonSound()
    local normalSounds = {
        "Sound\\Creature\\Peon\\PeonYes1.ogg",
        "Sound\\Creature\\Peon\\PeonYes2.ogg",
    }
    local rareSound = "Sound\\Creature\\Peon\\PeonWhat3.ogg" -- "Me not that kind of orc!"

    if math.random(1, 100) <= 5 then
        PlaySoundFile(rareSound)
        return true
    else
        PlaySoundFile(normalSounds[math.random(1, #normalSounds)])
        return false
    end
end


----------------------------------------
-- Storage for current loot drops
----------------------------------------
PSK.LootDrops = {} -- [1] {itemLink = "", itemTexture = "", itemName = "", itemID = number}

local lootFrame = CreateFrame("Frame")
lootFrame:RegisterEvent("LOOT_OPENED")

lootFrame:SetScript("OnEvent", function(self, event)
    if event == "LOOT_OPENED" then
        PSK:CaptureLoot()
    end
end)

function PSK:CaptureLoot()
    wipe(PSK.LootDrops)

    local numLootItems = GetNumLootItems()
    for i = 1, numLootItems do
        local itemLink = GetLootSlotLink(i)
        local icon, name, quantity, quality, locked = GetLootSlotInfo(i)

        if itemLink and name then
            table.insert(PSK.LootDrops, {
                itemLink = itemLink,
                itemName = name,
                itemTexture = icon,
                itemID = tonumber(string.match(itemLink, "item:(%d+):")),
            })
        end
    end

    PSK:RefreshLootList()
end



----------------------------------------
-- Event Frame for Updates
----------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event)
    UpdateGuildData()
end)

----------------------------------------
-- Update Guild Data (live)
----------------------------------------

function UpdateGuildData()
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

function StartBidding()
    if BiddingOpen then return end
		
    BiddingOpen = true
    PSK.BidEntries = {}
	
	if PSK.BidButton then
        PSK.BidButton:SetText("Stop Bidding")
		
        if PSK.BidButton.Border then
            PSK.BidButton.Border:SetAlpha(1)
            PSK.BidButton.Border:Show()
            PSK.BidButton.Border.Pulse:Stop()
            PSK.BidButton.Border.Pulse:Play()
        end
    end
	
    local listName = (PSK.CurrentList == "Tier") and "Tier List" or "Main List"
    
	Announce("[PSK] Bidding has started for the " .. listName .. "! 90 seconds remaining.")

	C_Timer.After(30, function()
		if BiddingOpen then
			Announce("[PSK] 60 seconds left to bid!")
		end
	end)

	C_Timer.After(60, function()
		if BiddingOpen then
			Announce("[PSK] 30 seconds left to bid!")
		end
	end)

	C_Timer.After(75, function()
		if BiddingOpen then
			Announce("[PSK] 15 seconds left to bid!")
		end
	end)

	C_Timer.After(90, function()
		if BiddingOpen then
			CloseBidding()
		end
	end)


    PSK:RefreshBidList()
end

function CloseBidding()
    BiddingOpen = false 

    Announce("[PSK] Bidding closed!")
	
	if PSK.BidButton then
        PSK.BidButton:SetText("Start Bidding")
        
		if PSK.BidButton.Border then
            PSK.BidButton.Border.Pulse:Stop()
            PSK.BidButton.Border:SetAlpha(1) -- Reset after stopping animation
            PSK.BidButton.Border:Hide()
        end
    end
	
    PSK:RefreshBidList()
end

local chatFrame = CreateFrame("Frame")
chatFrame:RegisterEvent("CHAT_MSG_RAID")
chatFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
chatFrame:RegisterEvent("CHAT_MSG_PARTY")
chatFrame:RegisterEvent("CHAT_MSG_SAY")

chatFrame:SetScript("OnEvent", function(self, event, msg, sender)
    if not BiddingOpen then return end
    if not sender then return end

    msg = msg:lower()
    if msg:find("bid") then
        local simpleName = sender:match("^(.-)%-.+") or sender
        AddBid(simpleName)
    end
end)

function AddBid(name)
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


-- Register slash command AFTER player login
local slashFrame = CreateFrame("Frame")
slashFrame:RegisterEvent("PLAYER_LOGIN")

slashFrame:SetScript("OnEvent", function()
    SLASH_PSK1 = "/psk"
    SlashCmdList["PSK"] = function()
        if PSK and PSK.MainFrame then
            if PSK.MainFrame:IsShown() then
                PSK.MainFrame:Hide()
            else
                PSK.MainFrame:Show()
            end
        else
            print("PSK: MainFrame is not available yet.")
        end
    end
end)