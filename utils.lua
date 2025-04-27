-- utils.lua
-- Helper functions for PSK

-- Move player up in the current list
function MovePlayerUp(index)
    local list = PSKDB[PSKCurrentList]
    if not list or not list[index] then return end

    if index > 1 then
        list[index], list[index - 1] = list[index - 1], list[index]
    end
end

-- Move player down in the current list
function MovePlayerDown(index)
    local list = PSKDB[PSKCurrentList]
    if not list or not list[index] then return end

    if index < #list then
        list[index], list[index + 1] = list[index + 1], list[index]
    end
end

-- Award selected player (move them to bottom, remove from bid list)
function AwardPlayer(index)
    -- Step 1: Find the player name from the bids list
    local player = PSKBidList and PSKBidList[index]
    if not player then return end

    -- Step 2: Remove from the Bids list
    table.remove(PSKBidList, index)

    -- Step 3: Find which loot list (Main or Tier) we're using
    local list = PSKDB[PSKCurrentList]
    if not list then return end

    -- Step 4: Remove from current list if present
    for i, name in ipairs(list) do
        if name == player then
            table.remove(list, i)
            break
        end
    end

    -- Step 5: Insert at the bottom of the loot list
    table.insert(list, player)

    -- Step 6: Notify (send message)
    PSK:Announce("Awarded loot to " .. player .. "!")  -- safer than SendChatMessage directly

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

-- Removes a player from a list
function RemoveFromList(list, name)
    for i, v in ipairs(list) do
        if v == name then
            table.remove(list, i)
            return true
        end
    end
    return false
end

function AddToListEnd(list, name)
    table.insert(list, name)
end


function Announce(message)
    if IsInRaid() then
        SendChatMessage(message, "RAID")
    else
        print(message)
    end
end