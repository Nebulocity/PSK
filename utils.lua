-- utils.lua
-- Helper functions for PSK
local PSK = select(2, ...)


-- Move player up in the current list
-- function MovePlayerUp(index)
    -- local list = PSKDB[PSK.CurrentList]
    -- if not list or not list[index] then return end

    -- if index > 1 then
        -- list[index], list[index - 1] = list[index - 1], list[index]
    -- end
-- end

-- Move player down in the current list
-- function MovePlayerDown(index)
    -- local list = PSKDB[PSK.CurrentList]
    -- if not list or not list[index] then return end

    -- if index < #list then
        -- list[index], list[index + 1] = list[index + 1], list[index]
    -- end
-- end

-- Award selected player (move them to bottom, remove from bid list)
function AwardPlayer(index)
	print(index)
    -- Step 1: Find the player name from the bids list
    local playerEntry = PSK.BidEntries and PSK.BidEntries[index]
    local playerName = playerEntry and playerEntry.name
	print(playerName)
    if not playerName then return end

    -- Step 2: Remove from the Bids list
    table.remove(PSK.BidEntries, index)

    -- Step 3: Find which loot list (Main or Tier) we're using
    local list = PSKDB[PSK.CurrentList]
    if not list then return end

    -- Step 4: Remove from current list if present
    for i, name in ipairs(list) do
        if name == playerName then
            table.remove(list, i)
            break
        end
    end

    -- Step 5: Insert at the bottom of the loot list
    table.insert(list, playerName)

    -- Step 6: Notify (send message)
    Announce("[PSK] Awarded loot to " .. playerName .. "!")

    -- Step 7: Refresh the screens
    PSK:RefreshGuildList()
    PSK:RefreshBidList()
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
