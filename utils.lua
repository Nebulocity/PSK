-- utils.lua
-- Helper functions for PSK

-- Move player up in current list
function MovePlayerUp(index)
    local list = PSKDB[PSKCurrentList]
    if not list or not list[index] then return end
    if index > 1 then
        list[index], list[index - 1] = list[index - 1], list[index]
    end
end

-- Move player down in current list
function MovePlayerDown(index)
    local list = PSKDB[PSKCurrentList]
    if not list or not list[index] then return end
    if index < #list then
        list[index], list[index + 1] = list[index + 1], list[index]
    end
end

-- Award selected player
function AwardPlayer(index)
    local list = PSKDB[PSKCurrentList]
    if not list or not list[index] then return end

    local player = list[index]
    table.remove(list, index)
    table.insert(list, player)

    SendChatMessage("PSK: Awarded to " .. player .. "!", "GUILD")
end

-- Pass action
function PassPlayer()
    -- Selection clears automatically
end
