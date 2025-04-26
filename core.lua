print("PSK addon loaded!")

-- Persistent database setup
if not PSKDB then
    PSKDB = {}
end

if not PSKMinimapDB then
    PSKMinimapDB = { hide = false, minimapPos = 195 }
end

-- Cleanup: remove invalid entries that may have numeric class values
for k, v in pairs(PSKDB) do
    if type(v.class) ~= "string" then
        print("Removing invalid class entry for", k)
        PSKDB[k] = nil
    end
end

-- Event listener
local listener = CreateFrame("Frame")

listener:SetScript("OnEvent", function(self, event, message, sender, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        hasRequestedRoster = true
        if refreshButton and refreshButton.pulse and not refreshButton.pulse:IsPlaying() then
            refreshButton.pulse:Play()
        end
    elseif event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_WHISPER_INFORM" then
        if message:lower():find("bid") then
            print(sender .. " has listed their bid!")
        end
    end
end)

listener:RegisterEvent("CHAT_MSG_GUILD")
listener:RegisterEvent("CHAT_MSG_RAID")
listener:RegisterEvent("PLAYER_ENTERING_WORLD")
listener:RegisterEvent("GUILD_ROSTER_UPDATE")
listener:RegisterEvent("PLAYER_LOGIN")
listener:RegisterEvent("CHAT_MSG_WHISPER_INFORM")

-- Slash command to open the frame
SLASH_PSK1 = "/psk"
SlashCmdList["PSK"] = function()
    pskFrame:Show()
end

-- Escape key to close
table.insert(UISpecialFrames, "PSKMainFrame")
