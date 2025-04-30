-- utils.lua
-- Helper functions for PSK
local PSK = select(2, ...)

-- Award selected player (move them to bottom, remove from bid list)
function AwardPlayer(index)
    local playerEntry = PSK.BidEntries and PSK.BidEntries[index]
    local playerName = playerEntry and playerEntry.name
    if not playerName then
        print("AwardPlayer: No playerName found at index", index)
        return
    end

    -- Step 1: Confirm with the user first
    StaticPopupDialogs["PSK_CONFIRM_AWARD"] = {
        text = "Are you sure you want to award loot to |cffffff00%s|r?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            -- Award confirmed
            PerformAward(index)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopup_Show("PSK_CONFIRM_AWARD", playerName)
end

function PerformAward(index)
    local playerEntry = PSK.BidEntries and PSK.BidEntries[index]
    local playerName = playerEntry and playerEntry.name
    local list = (PSK.CurrentList == "Main") and PSKDB.MainList or PSKDB.TierList

    table.remove(PSK.BidEntries, index)

    local found = false
    for i = #list, 1, -1 do
        if list[i]:lower() == playerName:lower() then
            table.remove(list, i)
            found = true
            break
        end
    end

    table.insert(list, playerName)

    Announce("[PSK] Awarded loot to " .. playerName .. "!")
		
    PSK:RefreshGuildList()
    PSK:RefreshBidList()
    PlaySound(12867)
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

function Announce(message)
	if IsInRaid() then
		SendChatMessage(message, "RAID")
	else
		print(message)
	end
end

local DEFAULT_COLUMN_WIDTH = 220

local COLUMN_HEIGHT = 355

-- Helper to create bordered scroll frames with header
-- utils.lua
-- Helper to create bordered scroll frames with header

local DEFAULT_COLUMN_WIDTH = 220
local COLUMN_HEIGHT = 355

function CreateBorderedScrollFrame(name, parent, x, y, titleText, customWidth)
    local COLUMN_WIDTH = customWidth or DEFAULT_COLUMN_WIDTH

    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetSize(COLUMN_WIDTH, COLUMN_HEIGHT + 20)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    container:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    container:SetBackdropColor(0.1, 0.1, 0.1, 0.85)

    -- Header text
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("BOTTOMLEFT", container, "TOPLEFT", 5, 10)
    header:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    header:SetTextColor(1, 0.85, 0.1)
    header:SetText(titleText)

    -- ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", name, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(COLUMN_WIDTH - 26, COLUMN_HEIGHT)
    scrollFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 5, -5)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(COLUMN_WIDTH - 40, COLUMN_HEIGHT)
    scrollFrame:SetScrollChild(scrollChild)

    return scrollFrame, scrollChild, container, header
end
