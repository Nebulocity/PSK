-- Class translations (localized to token names)
CLASS_TRANSLATIONS = {
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

-- Check if a player is in your raid group
function IsInRaidWith(name)
    name = name:lower()
    for i = 1, GetNumGroupMembers() do
        local unit = "raid" .. i
        if UnitExists(unit) and UnitName(unit):lower() == name then
            return true
        end
    end
    return false
end
