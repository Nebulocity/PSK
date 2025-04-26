-- guild.lua
-- Draws level-60 guild members as class icon + name,
-- with a bright, pulsing full-width outline on hover.


-- SaveGuildMembers: keep only level-60 entries
function SaveGuildMembers()
    if not IsInGuild() then return end
    wipe(PSKDB)  -- clear out any old entries

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


-- UpdateNameList: draw icon + name with pulsing outline
function UpdateNameList()
    -- Layout constants
    local ROW_HEIGHT  = 20
    local ROW_PADDING = 4
    local ROW_SPACING = ROW_HEIGHT + ROW_PADDING
	local OUTLINE_THICKNESS = 2
	local OUTLINE_PADDING  = 8   -- ↑ make this bigger for a taller outline

    -- Make sure our scroll-child sits above the template art
    playerFrame:SetFrameLevel(scrollFrame:GetFrameLevel() + 1)

    -- Completely remove old rows
    for _, child in ipairs({ playerFrame:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Build & sort the list of level-60 members
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
            if inRaid then
                fs:SetTextColor(0, 1, 0)  -- green
            else
                fs:SetTextColor(1, 1, 0)  -- yellow
            end
        else
            fs:SetTextColor(0.5, 0.5, 0.5) -- gray
        end
        fs:Show()

        -- Hover-outline frame (2px thick, full-width, pulsing)
        local highlight = CreateFrame("Frame", nil, playerFrame, "BackdropTemplate")
		highlight:SetFrameLevel(playerFrame:GetFrameLevel() + 1)
		highlight:SetBackdrop({
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = OUTLINE_THICKNESS,
			insets   = {
				left   = OUTLINE_PADDING,
				right  = OUTLINE_PADDING,
				top    = OUTLINE_PADDING,
				bottom = OUTLINE_PADDING,
			},
		})
		highlight:SetBackdropBorderColor(color.r, color.g, color.b, 1.0)

		-- Anchor to icon + name, but with larger vertical padding
		highlight:SetPoint("TOPLEFT",     icon, "TOPLEFT",     -OUTLINE_PADDING,  OUTLINE_PADDING)
		highlight:SetPoint("BOTTOMRIGHT", fs,   "BOTTOMRIGHT",    OUTLINE_PADDING, -OUTLINE_PADDING)
		highlight:Hide()

        -- Build the pulse animation for the highlight
        do
            local pulse = highlight:CreateAnimationGroup()
            pulse:SetLooping("BOUNCE")
            local alphaAnim = pulse:CreateAnimation("Alpha")
            alphaAnim:SetFromAlpha(0.4)
            alphaAnim:SetToAlpha(1.0)
            alphaAnim:SetDuration(1.0)
            alphaAnim:SetSmoothing("IN_OUT")
            highlight.pulse = pulse
        end

        -- Hover & tooltip handlers
        local function onEnter()
            highlight:Show()
            highlight.pulse:Play()
            GameTooltip:SetOwner(fs, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(name, 1, 1, 1)
            GameTooltip:AddLine("Class: " .. (token or "Unknown"))
            GameTooltip:AddLine("Level: 60")
            GameTooltip:AddLine("Last Seen: " .. (seen or "Unknown"))
            GameTooltip:Show()
        end
        local function onLeave()
            highlight.pulse:Stop()
            highlight:Hide()
            GameTooltip_Hide()
        end

        icon:EnableMouse(true)
        icon:SetScript("OnEnter", onEnter)
        icon:SetScript("OnLeave", onLeave)
        fs:EnableMouse(true)
        fs:SetScript("OnEnter", onEnter)
        fs:SetScript("OnLeave", onLeave)

        -- Move down for the next row
        yOffset = yOffset - ROW_SPACING
    end

    -- Show & size the scroll-child frame
    playerFrame:Show()
    playerFrame:SetSize(260, math.max(#entries * ROW_SPACING, 400))
end


-- RefreshRoster: request a fresh roster when clicked
function RefreshRoster()
    if not IsInGuild() then return end
    PlayRandomPeonSound()
    PSKRequestedRoster = true
    GuildRoster()  -- will fire GUILD_ROSTER_UPDATE → Save + UpdateNameList
end
