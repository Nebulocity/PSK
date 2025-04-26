-- guild.lua
-- Save guild roster separately

function CountGuildLevel60s()
    local total60 = 0
    local online60 = 0

    if not IsInGuild() then
        return total60, online60
    end

    for i = 1, GetNumGuildMembers() do
        local name, _, _, level, _, _, _, _, online = GetGuildRosterInfo(i)
        if name and level == 60 then
            total60 = total60 + 1
            if online then
                online60 = online60 + 1
            end
        end
    end

    return total60, online60
end


function SaveGuildMembers()
    print("PSK: SaveGuildMembers called.")

    if not IsInGuild() then return end

    if not PSKDB.roster then
        PSKDB.roster = {}
    end

    wipe(PSKDB.roster)

    local total = GetNumGuildMembers()
    for i = 1, total do
        local name, _, _, level, classFileName, _, _, _, online = GetGuildRosterInfo(i)
        if name then
            name = Ambiguate(name, "short")
            if level == 60 then
                PSKDB.roster[name] = {
                    class = classFileName,
                    online = online,
                    seen = date("%Y-%m-%d %H:%M"),
                }
            end
        end
    end
end

function RefreshRoster()
    if not IsInGuild() then return end
    PlayRandomPeonSound()
    PSKRequestedRoster = true
    GuildRoster()
end
