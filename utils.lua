-- utils.lua
-- Helper functions for PSK
local PSK = select(2, ...)


-- Move player up in the current list
function MovePlayerUp(index)
    local list = PSKDB[PSK.CurrentList]
    if not list or not list[index] then return end

    if index > 1 then
        list[index], list[index - 1] = list[index - 1], list[index]
    end
end

-- Move player down in the current list
function MovePlayerDown(index)
    local list = PSKDB[PSK.CurrentList]
    if not list or not list[index] then return end

    if index < #list then
        list[index], list[index + 1] = list[index + 1], list[index]
    end
end

-- Award selected player (move them to bottom, remove from bid list)
function AwardPlayer(index)
    local playerEntry = PSK.BidEntries and PSK.BidEntries[index]
    local playerName = playerEntry and playerEntry.name
    if not playerName then
        print("AwardPlayer: No playerName found at index", index)
        return
    end

    -- Step 1: Confirm with the user first
    StaticPopupDialogs["PSK_CONFIRM_AWARD"] = {
        text = "Are you sure you want to award loot to |cffffff00%s|r?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            -- Award confirmed
            PerformAward(index)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopup_Show("PSK_CONFIRM_AWARD", playerName)
end

function PerformAward(index)
    local playerEntry = PSK.BidEntries and PSK.BidEntries[index]
    local playerName = playerEntry and playerEntry.name
    if not playerName then
        print("PerformAward: No playerName found at index", index)
        return
    end

    print("PerformAward: Awarding loot to", playerName)

    -- Step 2: Remove from the Bids list
    table.remove(PSK.BidEntries, index)
    print("PerformAward: Removed from bid list.")

    -- Step 3: Find which loot list we're using
    local list = GetCurrentList()
    if not list then
        print("PerformAward: No loot list found for current list", PSK.CurrentList)
        return
    end

    -- Step 4: Remove from current list if present
    local found = false
    for i = #list, 1, -1 do
        if list[i]:lower() == playerName:lower() then
            table.remove(list, i)
            found = true
            print("PerformAward: Removed player from loot list at position", i)
            break
        end
    end

    if not found then
        print("PerformAward: Player", playerName, "not found in loot list!")
    end

    -- Step 5: Insert at bottom
    table.insert(list, playerName)
    print("PerformAward: Inserted player at bottom of loot list.")

        -- Step 6: Notify
    Announce("[PSK] Awarded loot to " .. playerName .. "!")

    -- Step 7: Refresh screens
    PSK:RefreshGuildList()
    PSK:RefreshBidList()

    -- Step 8: Play "ding" sound
    PlaySound(12867) -- Ready Check Complete sound

end



-- Pass action (just clears selection)
function PassPlayer()
    -- Nothing needed here -- selection will be cleared in the UI
end

-- SaveGuildMembers: save level 60s
function SaveGuildMembers()
    if not IsInGuild() then return end
    wipe(PSKDB)

    local total = GetNumGuildMembers()
    for i = 1, total do
        local name, _, _, level, classFileName, _, _, _, online = GetGuildRosterInfo(i)
        if name and level == 60 then
            name = Ambiguate(name, "short")
            local token = classFileName and string.upper(classFileName) or "UNKNOWN"
            PSKDB[name] = {
                class  = token,
                online = online,
                seen   = date("%Y-%m-%d %H:%M"),
            }
        end
    end
end

-- Refresh Roster
function RefreshRoster()
    if not IsInGuild() then return end
    GuildRoster()
end

function Announce(message)
	if IsInRaid() then
		SendChatMessage(message, "RAID")
	else
		print(message)
	end
end

function GetCurrentList()
    if PSK.CurrentList == "Main" then
        return PSKDB.MainList
    elseif PSK.CurrentList == "Tier" then
        return PSKDB.TierList
    end
end
