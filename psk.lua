-- Main runtime hub for PSK

print("PSK addon loaded.")

PSKDB = PSKDB or {}
PSKCurrentList = "MainList"

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_RAID")
eventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
eventFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        if IsInGuild() then
            GuildRoster()
            C_Timer.After(2, function()
                UpdateNameList()
            end)
        end
    elseif event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID_WARNING" then
        local msg, sender = ...
        if msg and sender then
            local cleanSender = Ambiguate(sender, "short")
            if string.lower(msg) == "bid" then
                if not PSKBidList then PSKBidList = {} end

                -- Don't add duplicates
                local alreadyListed = false
                for _, n in ipairs(PSKBidList) do
                    if n == cleanSender then
                        alreadyListed = true
                        break
                    end
                end

                if not alreadyListed then
                    table.insert(PSKBidList, cleanSender)
                    UpdateBidList()
                end
            end
        end
    end
end)

-- Escape to close frame
tinsert(UISpecialFrames, "PSKMainFrame")


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
