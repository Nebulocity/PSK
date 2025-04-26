print("PSK addon loaded!")

-- Saved-variables
PSKDB = PSKDB or {}
PSKMinimapDB = PSKMinimapDB or { hide = false, minimapPos = 195 }
PSKRequestedRoster = false

-- Event listener
local listener = CreateFrame("Frame", "PSKListener", UIParent)
listener:RegisterEvent("PLAYER_LOGIN")
listener:RegisterEvent("GUILD_ROSTER_UPDATE")
listener:RegisterEvent("CHAT_MSG_GUILD")
listener:RegisterEvent("CHAT_MSG_RAID")
listener:RegisterEvent("CHAT_MSG_WHISPER_INFORM")

listener:SetScript("OnEvent", function(self, event, message, sender, ...)

    if event == "PLAYER_LOGIN" then
        -- First login: ask for roster
        PSKRequestedRoster = true
        GuildRoster()

    elseif event == "GUILD_ROSTER_UPDATE" then
        -- Only redraw if we actually requested it
        if not PSKRequestedRoster then return end
        PSKRequestedRoster = false

        -- Now that data’s in, save & draw once
        SaveGuildMembers()
        UpdateNameList()

        -- Update header text
        pskFrame.statusText:SetText("Last updated: " .. date("%Y-%m-%d %H:%M"))

        -- Flash “Updated!” briefly
        if updatedText then
            updatedText:SetText("Updated!")
            C_Timer.After(3, function() updatedText:SetText("") end)
        end

        -- Reset & start countdown
        if nextRefreshText then
            local remaining = 600
            nextRefreshText:SetText("Next refresh in: 10:00")
            if nextRefreshText.timer then nextRefreshText.timer:Cancel() end
            nextRefreshText.timer = C_Timer.NewTicker(1, function()
                remaining = remaining - 1
                if remaining >= 0 then
                    nextRefreshText:SetText(string.format("Next refresh in: %d:%02d",
                        math.floor(remaining/60), remaining%60))
                else
                    nextRefreshText:SetText("") end
            end)
        end

        -- Update online counter
        if guildCounterText then
            local total, online = 0, 0
            for _, data in pairs(PSKDB) do
                total = total + 1
                if data.online then online = online + 1 end
            end
            guildCounterText:SetText(
                string.format("Max-Level Guild Members Online: %d/%d", online, total)
            )
        end

    elseif event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_WHISPER_INFORM" then
        if message:lower():find("bid") then
            print(sender .. " has listed their bid!")
        end
    end
end)

-- Slash-command to show the UI
SLASH_PSK1 = "/psk"
SlashCmdList["PSK"] = function() pskFrame:Show() end

-- Allow Escape to close
tinsert(UISpecialFrames, "PSKMainFrame")
