-- Class translations for Classic Era
CLASS_TRANSLATIONS = {
    ["Warrior"] = "WARRIOR",
    ["Paladin"] = "PALADIN",
    ["Hunter"] = "HUNTER",
    ["Rogue"] = "ROGUE",
    ["Priest"] = "PRIEST",
    ["Shaman"] = "SHAMAN",
    ["Mage"] = "MAGE",
    ["Warlock"] = "WARLOCK",
    ["Druid"] = "DRUID",
}

-- Check if a player is in your current raid group
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
