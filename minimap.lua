-- Setup minimap button using LibDataBroker and LibDBIcon
local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
if ldb then
    local dataObject = ldb:NewDataObject("PSK", {
        type = "launcher",
        text = "PSK",
        icon = "Interface\\AddOns\\PSK\\media\\icon.tga",
        OnClick = function()
            if PSKMainFrame:IsShown() then
                PSKMainFrame:Hide()
            else
                PSKMainFrame:Show()
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine("PSK - Perchance Some Loot?")
            tt:AddLine("Click to open or close PSK.")
        end,
    })
    local icon = LibStub("LibDBIcon-1.0", true)
    if icon then
        icon:Register("PSK", dataObject, PSKMinimapDB)
    end
end
