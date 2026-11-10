local addonName, FJ = ...

FJ.Launcher = {}

local BUTTON_SIZE = 32
local ICON_SIZE = 26
local EDGE_OFFSET = 5
local DEFAULT_ANGLE = 315
local LAYOUT_VERSION = 2

local launcherButton = nil

local function L(key)
    return FJ.Locale.Get(key)
end

local function NormalizeAngle(angle)
    while angle < 0 do
        angle = angle + 360
    end

    while angle >= 360 do
        angle = angle - 360
    end

    return angle
end

local function GetSettings()
    ForeverJourneyDB.minimap =
        ForeverJourneyDB.minimap or {}

    local settings =
        ForeverJourneyDB.minimap

    if settings.layoutVersion ~= LAYOUT_VERSION then
        settings.angle = DEFAULT_ANGLE
        settings.layoutVersion = LAYOUT_VERSION
    end

    if settings.angle == nil then
        settings.angle = DEFAULT_ANGLE
    end

    return settings
end

local function GetMinimapRadii()
    local width =
        Minimap:GetWidth()

    local height =
        Minimap:GetHeight()

    if not width or width <= 0 then
        width = 200
    end

    if not height or height <= 0 then
        height = width
    end

    local radiusX =
        width / 2 + EDGE_OFFSET

    local radiusY =
        height / 2 + EDGE_OFFSET

    return radiusX, radiusY
end

local function PositionButton(button, angle)
    angle =
        NormalizeAngle(angle)

    local radians =
        math.rad(angle)

    local radiusX, radiusY =
        GetMinimapRadii()

    local x =
        math.cos(radians) * radiusX

    local y =
        math.sin(radians) * radiusY

    button:ClearAllPoints()
    button:SetPoint(
        "CENTER",
        Minimap,
        "CENTER",
        x,
        y
    )
end

local function UpdatePositionFromCursor(button)
    local minimapX, minimapY =
        Minimap:GetCenter()

    if not minimapX or not minimapY then
        return
    end

    local scale =
        Minimap:GetEffectiveScale()

    if not scale or scale == 0 then
        return
    end

    local cursorX, cursorY =
        GetCursorPosition()

    cursorX = cursorX / scale
    cursorY = cursorY / scale

    local deltaX =
        cursorX - minimapX

    local deltaY =
        cursorY - minimapY

    local radiusX, radiusY =
        GetMinimapRadii()

    local normalizedX =
        deltaX / radiusX

    local normalizedY =
        deltaY / radiusY

    local angle =
        math.deg(
            math.atan2(
                normalizedY,
                normalizedX
            )
        )

    angle =
        NormalizeAngle(angle)

    local settings =
        GetSettings()

    settings.angle = angle

    PositionButton(
        button,
        angle
    )
end

local function ShowTooltip(button)
    GameTooltip:SetOwner(
        button,
        "ANCHOR_LEFT"
    )

    GameTooltip:SetText(
        "Forever Journey",
        0.90,
        0.70,
        0.36,
        1
    )

    GameTooltip:AddLine(
        L("MINIMAP_TOOLTIP_OPEN"),
        1,
        1,
        1,
        true
    )

    GameTooltip:AddLine(
        L("MINIMAP_TOOLTIP_CLICK"),
        0.75,
        0.75,
        0.75,
        true
    )

    GameTooltip:AddLine(
        L("MINIMAP_TOOLTIP_DRAG"),
        0.55,
        0.55,
        0.55,
        true
    )

    GameTooltip:Show()
end

local function HideTooltip()
    GameTooltip:Hide()
end

local function CreateLauncherButton()
    if launcherButton then
        return launcherButton
    end

    local button =
        CreateFrame(
            "Button",
            "ForeverJourneyMinimapButton",
            Minimap
        )

    button:SetSize(
        BUTTON_SIZE,
        BUTTON_SIZE
    )

    button:SetFrameStrata(
        "MEDIUM"
    )

    button:SetFrameLevel(
        Minimap:GetFrameLevel() + 8
    )

    button:SetClampedToScreen(true)

    button:RegisterForClicks(
        "LeftButtonUp"
    )

    button:RegisterForDrag(
        "LeftButton"
    )

    local background =
        button:CreateTexture(
            nil,
            "BACKGROUND"
        )

    background:SetSize(
        30,
        30
    )

    background:SetPoint(
        "CENTER",
        button,
        "CENTER",
        0,
        0
    )

    background:SetTexture(
        "Interface\\Minimap\\UI-Minimap-Background"
    )

    button.background =
        background

    local icon =
        button:CreateTexture(
            nil,
            "ARTWORK"
        )

    icon:SetSize(
        ICON_SIZE,
        ICON_SIZE
    )

    icon:SetPoint(
        "CENTER",
        button,
        "CENTER",
        0,
        0
    )

    icon:SetTexture(
        FJ.Theme.Textures.compass
    )

    icon:SetTexCoord(
        0.25,
        0.75,
        0,
        1
    )

    button.icon = icon

    local border =
        button:CreateTexture(
            nil,
            "OVERLAY"
        )

    border:SetSize(
        60,
        60
    )

    border:SetPoint(
        "CENTER",
        button,
        "CENTER",
        11,
        -12
    )

    border:SetTexture(
        "Interface\\Minimap\\MiniMap-TrackingBorder"
    )

    button.border = border

    local highlight =
        button:CreateTexture(
            nil,
            "HIGHLIGHT"
        )

    highlight:SetSize(
        46,
        46
    )

    highlight:SetPoint(
        "CENTER",
        button,
        "CENTER",
        -1,
        1
    )

    highlight:SetTexture(
        "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
    )

    highlight:SetBlendMode("ADD")

    button:SetScript(
        "OnClick",
        function(self, mouseButton)
            if self.isDragging then
                return
            end

            if mouseButton == "LeftButton" then
                FJ.UI.Toggle()
            end
        end
    )

    button:SetScript(
        "OnDragStart",
        function(self)
            self.isDragging = true
            GameTooltip:Hide()

            self:SetScript(
                "OnUpdate",
                function()
                    UpdatePositionFromCursor(self)
                end
            )
        end
    )

    button:SetScript(
        "OnDragStop",
        function(self)
            self:SetScript(
                "OnUpdate",
                nil
            )

            UpdatePositionFromCursor(self)

            C_Timer.After(
                0,
                function()
                    self.isDragging = false
                end
            )
        end
    )

    button:SetScript(
        "OnEnter",
        function(self)
            if not self.isDragging then
                ShowTooltip(self)
            end
        end
    )

    button:SetScript(
        "OnLeave",
        function()
            HideTooltip()
        end
    )

    launcherButton = button

    return button
end

function FJ.Launcher.Initialize()
    local button =
        CreateLauncherButton()

    local settings =
        GetSettings()

    PositionButton(
        button,
        settings.angle
    )

    button:Show()
end

function FJ.Launcher.GetButton()
    return launcherButton
end