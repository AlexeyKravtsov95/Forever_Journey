local addonName, FJ = ...

FJ.ParchmentLayer = {}

local function ApplyParchmentLayers()
    local frame =
        ForeverJourneyMainFrame

    if not frame then
        return
    end

    if frame.parchmentBacking then
        frame.parchmentBacking:SetDrawLayer(
            "BACKGROUND",
            -8
        )
    end

    if frame.parchment then
        frame.parchment:SetDrawLayer(
            "BACKGROUND",
            -7
        )

        frame.parchment:ClearAllPoints()

        frame.parchment:SetSize(
            FJ.Theme.Window.parchmentWidth - 6,
            FJ.Theme.Window.parchmentHeight - 6
        )

        frame.parchment:SetPoint(
            "CENTER",
            frame,
            "CENTER",
            0,
            1
        )

        frame.parchment:SetVertexColor(
            1,
            1,
            1,
            1
        )

        frame.parchment:SetAlpha(
            1
        )

        frame.parchment:Show()
    end
end

function FJ.ParchmentLayer.Apply()
    ApplyParchmentLayers()
end

local originalRefresh =
    FJ.UI.Refresh

FJ.UI.Refresh =
    function(...)
        local result =
            originalRefresh(...)

        FJ.ParchmentLayer.Apply()

        return result
    end