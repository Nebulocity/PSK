-- core.lua

-- core.lua, right at the top
-- At the top of core.lua
local PSK = select(2, ...)
_G.PSKGlobal = _G.PSKGlobal or {}

-- Initialize saved variables
PSKDB = PSKDB or {}

-- Use the persistent loot drop list
PSKGlobal.LootDrops = PSKGlobal.LootDrops or {}
PSK.LootDrops = PSKGlobal.LootDrops

-- Also initialize logs etc
PSKDB.LootLogs = PSKDB.LootLogs or {}



-- For Tracking
PSKDB = PSKDB or {}             
if not PSKDB.MainList then PSKDB.MainList = {} end
if not PSKDB.TierList then PSKDB.TierList = {} end



local threshold = (PSK.Settings and PSK.Settings.lootThreshold) or 3

if rarity and rarity > threshold then
    -- add to loot
end


BiddingOpen = false
PSK.BidEntries = {}
PSK.CurrentList = "Main"

-- Main Variables
BiddingOpen = false
PSK.BidEntries = {}
PSK.CurrentList = "Main"

----------------------------------------
-- Zug zug
----------------------------------------

function PSK:PlayRandomPeonSound()
    if not PSK.Settings or not PSK.Settings.buttonSoundsEnabled then
        return false
    end

    local normalSounds = {
        "Sound\\Creature\\Peon\\PeonYes1.ogg",
        "Sound\\Creature\\Peon\\PeonYes2.ogg",
    }
    local rareSound = "Sound\\Creature\\Peon\\PeonWhat3.ogg"

    if math.random(1, 100) <= 5 then
        PlaySoundFile(rareSound)
        return true
    else
        PlaySoundFile(normalSounds[math.random(1, #normalSounds)])
        return false
    end
end



----------------------------------------
-- Record Loot
----------------------------------------

local lootFrame = CreateFrame("Frame") 
lootFrame:RegisterEvent("CHAT_MSG_LOOT")

lootFrame:SetScript("OnEvent", function(self, event, msg)
    if PSK.LootRecordingActive then
        local player, itemLink = msg:match("([^%s]+) receives loot: (.+)")
        if not itemLink then
            itemLink = msg:match("You receive loot: (.+)")
            player = UnitName("player")
        end

        if itemLink then
            print("[PSK DEBUG] Loot message matched. Player:", player, "Item:", itemLink)

            C_Timer.After(0.2, function()
                local itemName, _, rarity, _, _, _, _, _, _, icon = GetItemInfo(itemLink)
                local threshold = PSK.Settings.lootThreshold or 3

                print("[PSK DEBUG] Item:", itemName or "nil", "Rarity:", rarity or "nil", "Threshold:", threshold)

                if rarity and rarity >= threshold then
                    print("[PSK DEBUG] Rarity is sufficient, logging loot.")

                    if not PSKDB.LootDrops then PSKDB.LootDrops = {} end

					-- table.insert(PSK.LootDrops, {
						-- itemLink = itemLink,
						-- itemTexture = icon
					-- })

					if not PSKDB.LootLogs then PSKDB.LootLogs = {} end
                    local class = PSKDB.Players[player] and PSKDB.Players[player].class or "SHAMAN"
					
					table.insert(PSKGlobal.LootDrops, {
						itemLink = itemLink,
						itemTexture = icon,
						player = player,
						class = class,
						timestamp = date("%I:%M %p %m/%d/%Y")
					})


                    PSK:RefreshLootList()

                    
					
					local hour, minute = GetGameTime()
					local ampm = (hour >= 12) and "PM" or "AM"
					hour = (hour % 12 == 0) and 12 or (hour % 12)
					local timeString = string.format("%d:%02d%s", hour, minute, ampm)
					local dateString = date("%m/%d/%Y")  -- still uses system date
					local fullTimestamp = timeString .. " " .. dateString
					timestamp = fullTimestamp


                    if PSK.RefreshLogList then
                        PSK:RefreshLogList()
                    end
                else
                    print("[PSK DEBUG] Rarity not high enough or unknown. Skipping log.")
                end
            end)
        end
    end
end)





----------------------------------------
-- Only Record for Master Looter
----------------------------------------

local function IsMasterLooter()
	-- local lootMethod = GetLootMethod()
	return lootMethod == "master"
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

-- function UpdateGuildData()
--     if not IsInGuild() then return end
-- 
--     GuildRoster()
-- 
--     if not PSKDB.Players then
--         PSKDB.Players = {}
--     end
-- 
--     for i = 1, GetNumGuildMembers() do
--         local name, rank, rankIndex, level, class, zone, note, officerNote, online, status, classFileName = GetGuildRosterInfo(i)
-- 
--         if name then
--             name = Ambiguate(name, "none") -- Remove realm name if needed
--             if not PSKDB.Players[name] then
--                 PSKDB.Players[name] = {}
--             end
-- 
--             PSKDB.Players[name].class = classFileName
--             PSKDB.Players[name].online = online
--             PSKDB.Players[name].inRaid = UnitInRaid(name) ~= nil
-- 			PSKDB.Players[name].level = level
-- 			PSKDB.Players[name].zone = zone
--         end
--     end
-- 
    -- Refresh displays
--     PSK:RefreshGuildList()
--     PSK:RefreshBidList()
--  end

----------------------------------------
-- Bidding System 
----------------------------------------

function PSK:StartBidding()
    if BiddingOpen then return end
		
	if not PSK.SelectedItem then
		print("You must select an item before starting bidding.")
		
		if not PSK.Settings or not PSK.Settings.buttonSoundsEnabled then
			return false
		end
	
		PlaySound(SOUNDKIT.GS_TITLE_OPTION_EXIT)
		return
	end

	
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
    
	local itemLink = PSK.SelectedItem
	local itemName = GetItemInfo(itemLink) or itemLink
	Announce("[PSK] Bidding has started for " .. itemName .. "! 15 seconds remaining.")



	C_Timer.After(5, function()
		if BiddingOpen then
			Announce("[PSK] 10 seconds left to bid!")
		end
	end)

	C_Timer.After(10, function()
		if BiddingOpen then
			Announce("[PSK] 5 seconds left to bid!")
		end
	end)

	C_Timer.After(11, function()
		if BiddingOpen then
			Announce("[PSK] 4 seconds left to bid!")
		end
	end)
	
	C_Timer.After(12, function()
		if BiddingOpen then
			Announce("[PSK] 3 seconds left to bid!")
		end
	end)
	
	C_Timer.After(13, function()
		if BiddingOpen then
			Announce("[PSK] 2 seconds left to bid!")
		end
	end)
	
	C_Timer.After(14, function()
		if BiddingOpen then
			Announce("[PSK] 1 seconds left to bid!")
		end
	end)

	C_Timer.After(15, function()
		if BiddingOpen then
			PSK:CloseBidding()
		end
	end)


    PSK:RefreshBidList()
end

function PSK:CloseBidding()
    BiddingOpen = false
    PSK.BidButton:SetText("Start Bidding")
    PSK:RefreshBidList()

    if #PSK.BidEntries == 0 then
        Announce("[PSK] No bids were placed.")
    else
        Announce("[PSK] Bidding closed. Bidders:")
        for _, entry in ipairs(PSK.BidEntries) do
            local line = string.format("%d. %s", entry.position, entry.name)
            Announce(line)
        end
    end
end


------------------------------------------
-- Scan these channels for the word "bid"
------------------------------------------

local chatFrame = CreateFrame("Frame")
chatFrame:RegisterEvent("CHAT_MSG_RAID")
chatFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
chatFrame:RegisterEvent("CHAT_MSG_PARTY")
chatFrame:RegisterEvent("CHAT_MSG_SAY")
chatFrame:RegisterEvent("CHAT_MSG_WHISPER")
chatFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
chatFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")

chatFrame:SetScript("OnEvent", function(self, event, msg, sender)
    if not BiddingOpen then return end
    if not sender then return end

    msg = msg:lower()
    if msg:find("bid") then
        local simpleName = sender:match("^(.-)%-.+") or sender
        AddBid(simpleName)
    end
	
	if msg:find("retract") then
        local simpleName = sender:match("^(.-)%-.+") or sender
        RetractBid(simpleName)
    end
end)

------------------------------------------
-- Add a bid
------------------------------------------

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

------------------------------------------
-- Scan these channels for the word "retract"
------------------------------------------

function RetractBid(name)
    if not name then return end

    for i, entry in ipairs(PSK.BidEntries) do
        if entry.name == name then
            table.remove(PSK.BidEntries, i)
            PSK:RefreshBidList()
            return
        end
    end
end


------------------------------------------
-- Console commands to open addon
------------------------------------------

local slashFrame = CreateFrame("Frame")
slashFrame:RegisterEvent("PLAYER_LOGIN")

slashFrame:SetScript("OnEvent", function()
    SLASH_PSK1 = "/psk"
    SlashCmdList["PSK"] = function(msg)
		msg = msg and msg:lower():gsub("^%s+", "") or ""

		if msg == "help" then
			PSK:PrintHelp()
			return
		elseif msg == "list" then
			PSK:PrintCurrentList()
			return
		end


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

------------------------------------------
-- Console command to export lists
------------------------------------------

SLASH_PSKEXPORT1 = "/pskexport"
SlashCmdList["PSKEXPORT"] = function(msg)
    msg = msg and msg:lower():gsub("^%s+", "") or ""

    if msg == "all" then
        PSK:ExportList("Main")
        PSK:ExportList("Tier")
    else
        PSK:ExportList(PSK.CurrentList or "Main")
    end
end


function PSK:ExportList(listType)
    local list = (listType == "Tier") and PSKDB.TierList or PSKDB.MainList

    if #list == 0 then
        print("[PSK] " .. listType .. " list is empty.")
        return
    end

    local exportLine = table.concat(list, ", ")
    PSK:ShowExportWindow(exportLine)
end

------------------------------------------
-- Console command to print command help
------------------------------------------

function PSK:PrintHelp()
    print(" ")
    print("|cff00ff00[PSK Addon Help]|r")
    print("/psk                     - Toggle the PSK window")
    print("/psk help                - Show this help menu")
    print("/psk list                - Show players in the current list")
    print("/pskadd <top|bottom> <main|tier> <name>    - Add player to a list")
    print("/pskremove <name>        - Remove player from current list")
    print("/pskremove all <name>    - Remove player from both lists")
    -- print("/pskexport               - Export current list as plain text")
	-- print("/pskexport [all]         - Export current or both lists")
    print(" ")
end

------------------------------------------------
-- Print the currently selected list to console
------------------------------------------------

function PSK:PrintCurrentList()
    local listType = PSK.CurrentList or "Main"
    local list = (listType == "Tier") and PSKDB.TierList or PSKDB.MainList

    print(" ")
    print("|cff00ff00[PSK: " .. listType .. " List]|r")

    if #list == 0 then
        print("(Empty)")
        return
    end

    for i, name in ipairs(list) do
        local playerData = PSKDB.Players[name]
        local class = playerData and playerData.class or "UNKNOWN"
        class = string.upper(class)

        local color = CLASS_COLORS[class] or { r = 0.8, g = 0.8, b = 0.8 }
        local hex = string.format("|cff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)

        local status = ""
        if playerData and playerData.online == false then
            status = " |cff888888(offline)|r"
        end

        print(i .. ". " .. hex .. name .. "|r" .. status)
    end
end


------------------------------------------
-- Console command to add a player
-- /pskadd <top|bottom> <main|tier> <name>
------------------------------------------

SLASH_PSKADD1 = "/pskadd"
SlashCmdList["PSKADD"] = function(msg)
    -- Hooray for REGEX!  lol
	local position, listType, name = msg:match("^(%S+)%s+(%S+)%s+(.+)$")

	if not position or not listType or not name then
        print("Usage: /pskadd <top | bottom> <main | tier> <playerName>")
        return
    end

    position = position:lower()
    listType = listType:lower()

    if position ~= "top" and position ~= "bottom" then
        print("Invalid position. Use 'top' or 'bottom'.")
        return
    end

    if listType ~= "main" and listType ~= "tier" then
        print("Invalid list type. Use 'main' or 'tier'.")
        return
    end

    PSK:AddPlayerFromCommand(name, listType, position)
end

-----------------------------------------------------------------
-- Console command to remove a player from main/tier/both lists
-----------------------------------------------------------------

SLASH_PSKREMOVE1 = "/pskremove"
SlashCmdList["PSKREMOVE"] = function(msg)
    local scope, name

    if msg:find("all%s+") then
        scope, name = msg:match("^(all)%s+(%S+)")
    else
        name = msg:match("^(%S+)")
        scope = "current"
    end

    if not name then
        print("Usage: /pskremove <playerName> or /pskremove all <playerName>")
        return
    end

    PSK:RemovePlayerByScope(scope, name)
end

function PSK:RemovePlayerByScope(scope, rawName)
    local nameLower = Ambiguate(rawName, "short"):gsub("%s+", ""):lower()
    local nameProper = rawName:sub(1, 1):upper() .. rawName:sub(2):lower()
    local removed = false

    local function tryRemove(list, listName)
        for i = #list, 1, -1 do
            if Ambiguate(list[i], "short"):lower() == nameLower then
                table.remove(list, i)
                print("[PSK] Removed " .. nameProper .. " from the " .. listName .. " list.")
                return true
            end
        end
        return false
    end

    if scope == "all" then
        removed = tryRemove(PSKDB.MainList, "Main") or removed
        removed = tryRemove(PSKDB.TierList, "Tier") or removed
    else
        local currentList = (PSK.CurrentList == "Tier") and PSKDB.TierList or PSKDB.MainList
        local currentName = (PSK.CurrentList == "Tier") and "Tier" or "Main"
        removed = tryRemove(currentList, currentName)
    end

    if not removed then
        print("[PSK] Could not find " .. nameProper .. " in the specified list(s).")
    end

    PSK:RefreshGuildList()
end

------------------------------------------------
-- Capitalize names that get added to the lists
------------------------------------------------

local function CapitalizeName(name)
    return name:sub(1, 1):upper() .. name:sub(2):lower()
end

------------------------------------------
-- Function add player from slash command
------------------------------------------

function PSK:AddPlayerFromCommand(name, listType, position)
    -- Normalize and clean input
    local rawName = Ambiguate(name, "short"):gsub("%s+", "")
    local nameLower = rawName:lower()
    local nameProper = CapitalizeName(rawName)

    -- Check if name is in guild
    local foundInGuild = false
    for i = 1, GetNumGuildMembers() do
        local gName = GetGuildRosterInfo(i)
        if gName and Ambiguate(gName, "short"):lower() == nameLower then
            foundInGuild = true
            break
        end
    end

    -- Check if name is in raid or party
    local foundInRaidOrParty = false
    local unit = nil

    if IsInRaid() then
        for i = 1, MAX_RAID_MEMBERS do
            local u = "raid" .. i
            if UnitExists(u) and Ambiguate(UnitName(u), "short"):lower() == nameLower then
                foundInRaidOrParty = true
                unit = u
                break
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local u = "party" .. i
            if UnitExists(u) and Ambiguate(UnitName(u), "short"):lower() == nameLower then
                foundInRaidOrParty = true
                unit = u
                break
            end
        end
    end

    if not foundInGuild and not foundInRaidOrParty then
        print("[PSK] Error: '" .. nameProper .. "' is not in your guild, raid, or party. Cannot add.")
        return
    end

    -- Choose target list
    local list = (listType == "tier") and PSKDB.TierList or PSKDB.MainList

    -- Check for duplicates
    for _, existing in ipairs(list) do
        if Ambiguate(existing, "short"):lower() == nameLower then
            print("[PSK] " .. nameProper .. " is already in the " .. listType .. " list.")
            return
        end
    end

    -- Add to top or bottom
    if position == "top" then
        table.insert(list, 1, nameProper)
    else
        table.insert(list, nameProper)
    end

    -- Fill in player data if not already in the DB
    if not PSKDB.Players[nameProper] then
        local class = "UNKNOWN"
        local level = "???"
        local zone = "Unknown"
        local online = false
        local inRaid = false

        -- Try guild roster first
        for i = 1, GetNumGuildMembers() do
            local gName, _, _, gLevel, _, gZone, _, _, gOnline, _, gClassFile = GetGuildRosterInfo(i)
            if gName and Ambiguate(gName, "short"):lower() == nameLower then
                class = gClassFile or class
                level = gLevel or level
                zone = gZone or zone
                online = gOnline or false
                break
            end
        end

        -- If not found, use party/raid unit data
        if class == "UNKNOWN" and unit then
            local _, classFile = UnitClass(unit)
            class = classFile or class
            level = UnitLevel(unit) or level
            zone = GetZoneText()
            online = UnitIsConnected(unit)
            inRaid = UnitInRaid(unit) ~= nil
        end

        PSKDB.Players[nameProper] = {
            class = class,
            online = online,
            inRaid = inRaid,
            level = level,
            zone = zone,
        }
    end

    print("[PSK] Added " .. nameProper .. " to the " .. listType .. " list at the " .. position .. ".")
    PSK:RefreshGuildList()
end

