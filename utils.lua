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
    local list = PSKDB[PSKCurrentList]
    if not list or not list[index] then return end

    local player = list[index]
    table.remove(list, index)
    table.insert(list, player)

    SendChatMessage("PSK: Awarded to " .. player .. "!", "GUILD")

    -- REMOVE FROM BID LIST IF PRESENT
    if PSKBidList then
        for i, name in ipairs(PSKBidList) do
            if name == player then
                table.remove(PSKBidList, i)
                break
            end
        end
    end
end




-- Pass action (just clears selection)
function PassPlayer()
    -- Nothing needed here -- selection will be cleared in the UI
end
