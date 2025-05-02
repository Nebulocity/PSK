-- core.lua

local PSK = select(2, ...)

-- For bidding
if not PSKDB.MainList then PSKDB.MainList = {} end
if not PSKDB.TierList then PSKDB.TierList = {} end

local threshold = (PSK.Settings and PSK.Settings.lootThreshold) or 3

if rarity and rarity >= threshold then
    -- add to loot
end


BiddingOpen = false
PSK.BidEntries = {}
PSK.CurrentList = "Main"

local CLASS_COLORS = RAID_CLASS_COLORS or {
    WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
    PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
    HUNTER =  { r = 0.67, g = 0.83, b = 0.45 },
    ROGUE =   { r = 1.00, g = 0.96, b = 0.41 },
    PRIEST =  { r = 1.00, g = 1.00, b = 1.00 },
    SHAMAN =  { r = 0.00, g = 0.44, b = 0.87 },
    MAGE =    { r = 0.25, g = 0.78, b = 0.92 },
    WARLOCK = { r = 0.53, g = 0.53, b = 0.93 },
    MONK =    { r = 0.00, g = 1.00, b = 0.59 },
    DRUID =   { r = 1.00, g = 0.49, b = 0.04 },
}


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
    if not PSK.LootRecordingActive then return end
    if not IsMasterLooter() then return end

    PSK.LootDrops = {}

    local numItems = GetNumLootItems()
    local threshold = PSK.Settings.lootThreshold or 3

    for i = 1, numItems do
        local itemLink = GetLootSlotLink(i)
        local itemTexture = GetLootSlotInfo(i)

        if itemLink and itemTexture then
            local _, _, rarity = GetItemInfo(itemLink)
            if rarity and rarity >= threshold then
                table.insert(PSK.LootDrops, {
                    itemLink = itemLink,
                    itemTexture = itemTexture
                })
            end
        end
    end

    PSK:RefreshLootList()
end



local function IsMasterLooter()
	local lootMethod = GetLootMethod()
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
-- Bidding System 
----------------------------------------

function PSK:StartBidding()
    if BiddingOpen then return end
		
	if not PSK.SelectedItem then
		print("You must select an item before starting bidding.")
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

function PSK:CloseBidding()
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



-- Slash command: /pskadd <top|bottom> <main|tier> <name>
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

-- Removes a player's name from the currently viewed list.
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



local function CapitalizeName(name)
    return name:sub(1, 1):upper() .. name:sub(2):lower()
end

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

