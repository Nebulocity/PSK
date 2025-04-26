-- Loading 
print("PSK addon loaded!")


-- Persistent database setup
if not PSKDB then
    PSKDB = {}
end


-- Cleanup: remove invalid entries that may have numeric class values
for k, v in pairs(PSKDB) do
    if type(v.class) ~= "string" then
        print("Removing invalid class entry for", k)
        PSKDB[k] = nil
    end
end


-- Try to map localize class names to CLASS_ICON_TCOORDS keys since classFileName isn't returned in Classic Era by GetGuildRosterInfo()
local CLASS_TRANSLATIONS = {
    ["Warrior"] = "WARRIOR",
    ["Paladin"] = "PALADIN",
    ["Hunter"] = "HUNTER",
    ["Rogue"] = "ROGUE",
    ["Priest"] = "PRIEST",
    ["Death Knight"] = "DEATHKNIGHT",
    ["Shaman"] = "SHAMAN",
    ["Mage"] = "MAGE",
    ["Warlock"] = "WARLOCK",
    ["Monk"] = "MONK",
    ["Druid"] = "DRUID",
    ["Demon Hunter"] = "DEMONHUNTER",
}


-- Main UI Frame
local pskFrame = CreateFrame("Frame", "PSKMainFrame", UIParent, "BasicFrameTemplateWithInset")
pskFrame:SetSize(800, 600)
pskFrame:SetPoint("CENTER")
pskFrame:SetFrameStrata("HIGH")
pskFrame:SetMovable(true)
pskFrame:EnableMouse(true)
pskFrame:RegisterForDrag("LeftButton")
pskFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
pskFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

pskFrame.TitleBg:SetHeight(30)
pskFrame.title = pskFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
pskFrame.title:SetPoint("TOPLEFT", pskFrame.TitleBg, "TOPLEFT", 5, -3)
pskFrame.title:SetText("Perchance PSK - Perchance You Want Some Loot?")
pskFrame.statusText = pskFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
pskFrame.statusText:SetPoint("TOPLEFT", pskFrame.title, "BOTTOMLEFT", 25, -10)
pskFrame.statusText:SetText("Last updated: never")
pskFrame.statusText:SetTextColor(0.7, 0.7, 0.7)


-- Refresh Button
local refreshButton = CreateFrame("Button", nil, pskFrame, "UIPanelButtonTemplate")
refreshButton:SetSize(80, 24)
refreshButton:SetPoint("TOPRIGHT", pskFrame, "TOPRIGHT", -30, -30)
refreshButton:SetText("Refresh")


-- Tooltip for Refresh Button
refreshButton:EnableMouse(true)
refreshButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(refreshButton, "ANCHOR_RIGHT")
    GameTooltip:SetText("Click to update the guild list!", 1, 1, 1)
    GameTooltip:Show()
end)
refreshButton:SetScript("OnLeave", GameTooltip_Hide)


-- Scroll Frame
local scrollFrame = CreateFrame("ScrollFrame", nil, pskFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 25, -60)
scrollFrame:SetSize(260, 500)

local playerFrame = CreateFrame("Frame", nil, scrollFrame)
playerFrame:SetSize(260, 500)
scrollFrame:SetScrollChild(playerFrame)


-- Play a random Peon voice line
local function PlayRandomPeonSound()
    local normalSounds = {
        "Sound\\Creature\\Peon\\PeonYes1.ogg", -- "Work work."
        "Sound\\Creature\\Peon\\PeonYes2.ogg", -- "Zug zug."
    }
    local rareSound = "Sound\\Creature\\Peon\\PeonWhat3.ogg" -- "Me not that kind of orc!"

    if math.random(1, 100) <= 5 then
        PlaySoundFile(rareSound)
        return true -- Rare triggered!
    else
        local randomIndex = math.random(1, #normalSounds)
        PlaySoundFile(normalSounds[randomIndex])
        return false
    end
end

-- Checks to see if you're in a raid
local function IsInRaidWith(name)
    name = name:lower()
    for i = 1, GetNumGroupMembers() do
        local unit = "raid" .. i
        if UnitExists(unit) and UnitName(unit):lower() == name then
            return true
        end
    end
    return false
end


-- Save all max-level members
local function SaveGuildMembers()
    if not IsInGuild() then return end
    local total = GetNumGuildMembers()
    for i = 1, total do
        local name, _, _, level, class, _, _, _, online = GetGuildRosterInfo(i)
        if name then
            name = Ambiguate(name, "short")
            local token = CLASS_TRANSLATIONS[class or ""] or "UNKNOWN"
            if level == 60 then
                PSKDB[name] = PSKDB[name] or {}
                PSKDB[name].class = token
                PSKDB[name].online = online
                PSKDB[name].seen = date("%Y-%m-%d %H:%M")
            end
        end
    end
end


-- Updates name list in playerFrame
local function UpdateNameList()
    for _, child in ipairs({ playerFrame:GetChildren() }) do child:Hide() end
    local yOffset = -5
    local entries = {}

    -- Build sortable table
    for name, data in pairs(PSKDB) do
        table.insert(entries, { name = name, class = data.class, seen = data.seen, online = data.online })
    end

    -- Sort online first, then by name A–Z
    table.sort(entries, function(a, b)
        if a.online == b.online then
            return a.name < b.name
        else
            return a.online and not b.online
        end
    end)

    for _, entry in ipairs(entries) do
        local name = entry.name
        local class = entry.class or "UNKNOWN"
        local seen = entry.seen or "UNKNOWN"
        local isOnline = entry.online
        local inRaid = IsInRaidWith(name)

        local icon = playerFrame:CreateTexture(nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("TOPLEFT", playerFrame, "TOPLEFT", 5, yOffset)

        local coords = CLASS_ICON_TCOORDS[class]
        if coords then
            icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
            icon:SetTexCoord(unpack(coords))
        else
            icon:SetColorTexture(0.2, 0.2, 0.2)
        end

        local fs = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetText(name)
        fs:SetPoint("LEFT", icon, "RIGHT", 5, 0)

        if isOnline then
            if inRaid then
                fs:SetTextColor(0, 1, 0) -- Green
            else
                fs:SetTextColor(1, 1, 0) -- Yellow
            end
        else
            fs:SetTextColor(0.5, 0.5, 0.5) -- Gray
        end

        fs:EnableMouse(true)
        fs:SetScript("OnEnter", function()
            GameTooltip:SetOwner(fs, "ANCHOR_RIGHT")
            GameTooltip:SetText(name .. "\nLast Seen: " .. seen, 1, 1, 1)
            GameTooltip:Show()
        end)
        fs:SetScript("OnLeave", GameTooltip_Hide)

        yOffset = yOffset - 20
    end

    playerFrame:SetSize(260, math.max(#entries * 20, 400))
end


-- Manual Refresh Handler
local function RefreshRoster()
    if not IsInGuild() then return end
	
    PlayRandomPeonSound()

    -- Flash
    if not refreshButton.flash then
        local flash = refreshButton:CreateAnimationGroup()
        local alphaOut = flash:CreateAnimation("Alpha")
        alphaOut:SetFromAlpha(1)
        alphaOut:SetToAlpha(0.5)
        alphaOut:SetDuration(0.1)
        alphaOut:SetOrder(1)

        local alphaIn = flash:CreateAnimation("Alpha")
        alphaIn:SetFromAlpha(0.5)
        alphaIn:SetToAlpha(1)
        alphaIn:SetDuration(0.2)
        alphaIn:SetOrder(2)

        refreshButton.flash = flash
    end
    refreshButton.flash:Play()

    -- Stop pulsing animation if active
    if refreshButton.pulse and refreshButton.pulse:IsPlaying() then
        refreshButton.pulse:Stop()
        refreshButton:SetAlpha(1)
    end

    -- Update
    C_GuildInfo.GuildRoster()
    C_Timer.After(1, function()
        SaveGuildMembers()
        UpdateNameList()
        pskFrame.statusText:SetText("Last updated: " .. date("%Y-%m-%d %H:%M"))
    end)
end


-- Click event for RefreshRoster
refreshButton:SetScript("OnClick", RefreshRoster)


-- Event listener
local hasRequestedRoster = false
local listener = CreateFrame("Frame")

listener:SetScript("OnEvent", function(self, event, message, sender, ...)

    if event == "PLAYER_ENTERING_WORLD" and not hasRequestedRoster then
        hasRequestedRoster = true

        -- Start gentle pulsing to show roster isn't loaded
        if not refreshButton.pulse then
            local pulse = refreshButton:CreateAnimationGroup()
            local fadeOut = pulse:CreateAnimation("Alpha")
            fadeOut:SetFromAlpha(1)
            fadeOut:SetToAlpha(0.7)
            fadeOut:SetDuration(1)
            fadeOut:SetSmoothing("IN_OUT")
            fadeOut:SetOrder(1)

            local fadeIn = pulse:CreateAnimation("Alpha")
            fadeIn:SetFromAlpha(0.7)
            fadeIn:SetToAlpha(1)
            fadeIn:SetDuration(1)
            fadeIn:SetSmoothing("IN_OUT")
            fadeIn:SetOrder(2)

            pulse:SetLooping("REPEAT")
            refreshButton.pulse = pulse
        end
        refreshButton.pulse:Play()
    end
	
	-- Check guild/raid chat for the word "bid", then handle
    if event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_WHISPER_INFORM" then
        if message:lower():find("bid") then
            print(sender .. " has listed their bid!")
        end
    end
	
end)


-- Slash Command
SLASH_PSK1 = "/psk"
SlashCmdList["PSK"] = function()
    pskFrame:Show()
end

-- Escape key closable
table.insert(UISpecialFrames, "PSKMainFrame")


-- Minimap Button
local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
if ldb then
    local dataObject = ldb:NewDataObject("PSK", {
        type = "launcher",
        text = "PSK",
        icon = "Interface\\AddOns\\PSK\\icon.tga",
        OnClick = function()
            if pskFrame:IsShown() then
                pskFrame:Hide()
            else
                pskFrame:Show()
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine("PSK - Anniversary Addon")
            tt:AddLine("Click to open or close the guild list.")
        end,
    })
    local icon = LibStub("LibDBIcon-1.0", true)
    if icon then
        icon:Register("PSK", dataObject, {})
    end
end


-- Register Events for the event listener
listener:RegisterEvent("CHAT_MSG_GUILD")
listener:RegisterEvent("CHAT_MSG_RAID")
listener:RegisterEvent("PLAYER_ENTERING_WORLD")
listener:RegisterEvent("GUILD_ROSTER_UPDATE")
listener:RegisterEvent("PLAYER_LOGIN")
-- Unused for now, will add back later.
-- listener:RegisterEvent("CHAT_MSG_WHISPER")
listener:RegisterEvent("CHAT_MSG_WHISPER_INFORM")