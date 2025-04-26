-- Save guild members
function SaveGuildMembers()
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

-- Update displayed list
function UpdateNameList()
    for _, child in ipairs({ playerFrame:GetChildren() }) do child:Hide() end
    local yOffset = -5
    local entries = {}

    for name, data in pairs(PSKDB) do
        table.insert(entries, { name = name, class = data.class, seen = data.seen, online = data.online })
    end

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
                fs:SetTextColor(0, 1, 0)
            else
                fs:SetTextColor(1, 1, 0)
            end
        else
            fs:SetTextColor(0.5, 0.5, 0.5)
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

-- Manual refresh function
function RefreshRoster()
    if not IsInGuild() then return end

    PlayRandomPeonSound()

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

    if refreshButton.pulse and refreshButton.pulse:IsPlaying() then
        refreshButton.pulse:Stop()
        refreshButton:SetAlpha(1)
    end

    C_GuildInfo.GuildRoster()
    C_Timer.After(1, function()
        SaveGuildMembers()
        UpdateNameList()
        pskFrame.statusText:SetText("Last updated: " .. date("%Y-%m-%d %H:%M"))
    end)
end
