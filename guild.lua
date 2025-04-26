-- Draws level-60 guildies with class icon + name, plus a hover outline.

-- SaveGuildMembers: keep only level-60 entries in PSKDB
function SaveGuildMembers()
    if not IsInGuild() then return end

    wipe(PSKDB)  -- clear out old entries

    local total = GetNumGuildMembers()
    for i = 1, total do
        local name, _, _, level, classFileName, _, _, _, online = GetGuildRosterInfo(i)
        if name then
            name = Ambiguate(name, "short")
            local token = CLASS_TRANSLATIONS[classFileName] or "UNKNOWN"
            if level == 60 then
                PSKDB[name] = {
                    class  = token,
                    online = online,
                    seen   = date("%Y-%m-%d %H:%M"),
                }
            end
        end
    end
end


-- UpdateNameList: draw icon + name, with hover outline
function UpdateNameList()
    -- Layout constants
    local ROW_HEIGHT  = 20
    local ROW_PADDING = 4
    local ROW_SPACING = ROW_HEIGHT + ROW_PADDING

    -- Make sure our list frame is above the scroll-frame artwork
    playerFrame:SetFrameLevel(scrollFrame:GetFrameLevel() + 1)

    -- Wipe old rows completely
    for _, child in ipairs({ playerFrame:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Build & sort entries
    local entries = {}
    for name, data in pairs(PSKDB) do
        table.insert(entries, {
            name   = name,
            class  = data.class,
            seen   = data.seen,
            online = data.online,
        })
    end
    table.sort(entries, function(a, b)
        if a.online == b.online then
            return a.name < b.name
        end
        return a.online and not b.online
    end)

    -- Draw each row
    local yOffset = -5
    for _, entry in ipairs(entries) do
        local name     = entry.name
        local token    = entry.class
        local seen     = entry.seen
        local isOnline = entry.online
        local inRaid   = IsInRaidWith(name)
        local color    = RAID_CLASS_COLORS[token] or { r=1, g=1, b=1 }

        -- Hover-outline (full-width)
        local highlight = CreateFrame("Frame", nil, playerFrame, "BackdropTemplate")
        highlight:SetFrameLevel(playerFrame:GetFrameLevel() + 1)
        highlight:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 2,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        highlight:SetBackdropBorderColor(color.r, color.g, color.b, 0.8)
        highlight:SetPoint("TOPLEFT",     playerFrame, "TOPLEFT",   -2, yOffset + 2)
        highlight:SetPoint("BOTTOMRIGHT", playerFrame, "TOPRIGHT",   2, yOffset - ROW_HEIGHT - 2)
        highlight:Hide()

        -- Class icon
        local icon = playerFrame:CreateTexture(nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("TOPLEFT", playerFrame, "TOPLEFT", 5, yOffset)
        local coords = CLASS_ICON_TCOORDS[token]
        if coords then
            icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
            icon:SetTexCoord(unpack(coords))
        else
            icon:SetColorTexture(0.2, 0.2, 0.2)
        end
        icon:Show()

        -- Player name
        local fs = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        fs:SetText(name)
        if isOnline then
            fs:SetTextColor(inRaid and 0 or 1, 1, inRaid and 0 or 0)
        else
            fs:SetTextColor(0.5, 0.5, 0.5)
        end
        fs:Show()

        -- Hover & tooltip handlers
        local function onEnter()
            highlight:Show()
            GameTooltip:SetOwner(fs, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(name, 1, 1, 1)
            GameTooltip:AddLine("Class: " .. (token or "Unknown"))
            GameTooltip:AddLine("Level: 60")
            GameTooltip:AddLine("Last Seen: " .. (seen or "Unknown"))
            GameTooltip:Show()
        end
        local function onLeave()
            highlight:Hide()
            GameTooltip_Hide()
        end

        icon:EnableMouse(true)
        icon:SetScript("OnEnter", onEnter)
        icon:SetScript("OnLeave", onLeave)
        fs:EnableMouse(true)
        fs:SetScript("OnEnter", onEnter)
        fs:SetScript("OnLeave", onLeave)

        -- Move down for next row
        yOffset = yOffset - ROW_SPACING
    end

    -- Show & size the scroll‐child
    playerFrame:Show()
    playerFrame:SetSize(260, math.max(#entries * ROW_SPACING, 400))
end


-- RefreshRoster: request a fresh roster
function RefreshRoster()
    if not IsInGuild() then return end

    PlayRandomPeonSound()
    PSKRequestedRoster = true
    GuildRoster()  -- triggers GUILD_ROSTER_UPDATE → Save + UpdateNameList
end