-- Guild + Bidding Events for PSK

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

-- Chat Event: Auto-detect "bid" in raid chat
local bidEventFrame = CreateFrame("Frame")
bidEventFrame:RegisterEvent("CHAT_MSG_RAID")
bidEventFrame:RegisterEvent("CHAT_MSG_GUILD")
bidEventFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")

bidEventFrame:SetScript("OnEvent", function(_, event, msg, sender)
    if not msg or not sender then return end
    msg = string.lower(msg)

    if msg:find("bid") then
        sender = Ambiguate(sender, "short")

        if not PSKBidList then PSKBidList = {} end

        -- Check if already in the bid list
        for _, name in ipairs(PSKBidList) do
            if name == sender then
                return -- already exists
            end
        end

        table.insert(PSKBidList, sender)

        -- Optionally print confirmation
        print("|cff00ff00PSK:|r Bid received from " .. sender)

        -- Update the UI if it's open
        if pskFrame and pskFrame:IsShown() then
            UpdateNameList()
        end
    end
end)
