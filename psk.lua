-- psk.lua
-- Main runtime hub for PSK

print("PSK addon loaded.")

PSKDB = PSKDB or {}
PSKCurrentList = "MainList"

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(2, function()
            if IsInGuild() then
                GuildRoster()
                C_Timer.After(1, function()
                    SaveGuildMembers()
                    UpdateNameList()
                end)
            end
        end)
    elseif event == "GUILD_ROSTER_UPDATE" then
        if PSKRequestedRoster then
            PSKRequestedRoster = false
            SaveGuildMembers()
            UpdateNameList()
        end
    end
end)

SLASH_PSK1 = "/psk"
SlashCmdList["PSK"] = function()
    if not pskFrame then
        print("PSK: Frame not ready yet.")
        return
    end
    GuildRoster()
    C_Timer.After(1, function()
        pskFrame:Show()
        UpdateNameList()
    end)
end

tinsert(UISpecialFrames, "PSKMainFrame")
