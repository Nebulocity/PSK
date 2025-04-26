-- Setup minimap button using LibDataBroker and LibDBIcon
local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
if ldb then
    local dataObject = ldb:NewDataObject("PSK", {
        type = "launcher",
        text = "PSK",
        icon = "Interface\\AddOns\\PSK\\media\\icon.tga",
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
        icon:Register("PSK", dataObject, PSKMinimapDB)
    end
end
