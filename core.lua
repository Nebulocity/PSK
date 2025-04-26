-- core.lua
print("PSK addon loaded!")

-- SavedVariables
PSKDB = PSKDB or {}
PSKRequestedRoster = false

-- Default starting view
PSKCurrentList = "MainList"

-- Slash command to open UI
SLASH_PSK1 = "/psk"
SlashCmdList["PSK"] = function()
    if PSKMainFrame then
        PSKMainFrame:Show()
        UpdateNameList()
    else
        print("PSK: Frame not ready yet. Try again shortly.")
    end
end

-- Escape key closes frame
tinsert(UISpecialFrames, "PSKMainFrame")
