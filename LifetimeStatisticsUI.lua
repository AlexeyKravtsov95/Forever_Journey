local addonName, FJ = ...

FJ.LifetimeStatisticsUI = {}

local Theme = FJ.Theme
local Colors = Theme.Colors
local Textures = Theme.Textures

local strings = {
    enUS = {
        BUTTON = "STATISTICS",
        BACK = "< OVERVIEW",
        TITLE = "JOURNEY STATISTICS",
        SUBTITLE = "Lifetime character totals stored by the game.",
        JOURNEY = "JOURNEY",
        COMBAT = "COMBAT",
        DANGERS = "DANGERS",
        TOTAL_DEATHS = "Total deaths",
        COMPLETED_QUESTS = "Quests completed",
        TOTAL_KILLS = "Enemies defeated",
        FLIGHTS_TAKEN = "Flights taken",
        HONORABLE_KILLS = "Honorable kills",
        HEARTHSTONE_USES = "Hearthstone uses",
        FALLING_DEATHS = "Deaths from falling",
        PVP_DEATHS = "Deaths to players",
        FOOTNOTE_TITLE = "ABOUT THESE NUMBERS",
        FOOTNOTE = "Lifetime totals come from the game statistics API. Chronicle keeps the detailed Forever Journey events with time and location."
    },

    ruRU = {
        BUTTON = "СТАТИСТИКА",
        BACK = "< ОБЗОР",
        TITLE = "СТАТИСТИКА ПУТЕШЕСТВИЯ",
        SUBTITLE = "Общие показатели персонажа, сохранённые самой игрой.",
        JOURNEY = "ПУТЕШЕСТВИЕ",
        COMBAT = "БОЙ",
        DANGERS = "ОПАСНОСТИ",
        TOTAL_DEATHS = "Всего смертей",
        COMPLETED_QUESTS = "Выполнено заданий",
        TOTAL_KILLS = "Побеждено врагов",
        FLIGHTS_TAKEN = "Совершено полётов",
        HONORABLE_KILLS = "Почётные победы",
        HEARTHSTONE_USES = "Камень возвращения",
        FALLING_DEATHS = "Смерти от падения",
        PVP_DEATHS = "Смерти от игроков",
        FOOTNOTE_TITLE = "ОБ ЭТИХ ДАННЫХ",
        FOOTNOTE = "Общие значения берутся из игровой статистики. Хроника Forever Journey хранит подробные события с местом и временем."
    }
}

local S =
    strings[GetLocale()]
    or strings.enUS

local function T(key)
    return S[key]
        or strings.enUS[key]
        or key
end

local function SetColor(
    fontString,
    color
)
    fontString:SetTextColor(
        color.r,
        color.g,
        color.b,
        color.a
    )
end

local function FormatValue(
    value
)
    if value == nil then
        return "-"
    end

    if type(value) == "number"
        and type(BreakUpLargeNumbers)
            == "function" then

        local success,
            formatted =
                pcall(
                    BreakUpLargeNumbers,
                    value
                )

        if success
            and formatted then

            return formatted
        end
    end

    return tostring(value)
end

local function CreateRule(
    parent,
    x,
    y,
    width
)
    local rule =
        parent:CreateTexture(
            nil,
            "ARTWORK"
        )

    rule:SetSize(
        width,
        1
    )

    rule:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        x,
        y
    )

    rule:SetColorTexture(
        Colors.goldMuted.r,
        Colors.goldMuted.g,
        Colors.goldMuted.b,
        0.28
    )

    return rule
end

local function CreateSectionTitle(
    parent,
    text,
    x,
    y,
    width
)
    local title =
        parent:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )

    title:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        x,
        y
    )

    title:SetWidth(
        width
    )

    title:SetJustifyH(
        "LEFT"
    )

    title:SetText(
        text
    )

    SetColor(
        title,
        Colors.goldMuted
    )

    CreateRule(
        parent,
        x,
        y - 18,
        width
    )

    return title
end

local function CreateStatRow(
    parent,
    key,
    label,
    x,
    y,
    width,
    emphasize
)
    local labelText =
        parent:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlightSmall"
        )

    labelText:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        x,
        y
    )

    labelText:SetWidth(
        width - 78
    )

    labelText:SetJustifyH(
        "LEFT"
    )

    labelText:SetText(
        label
    )

    SetColor(
        labelText,
        Colors.inkMuted
    )

    local valueText =
        parent:CreateFontString(
            nil,
            "OVERLAY",
            emphasize
            and "GameFontNormalLarge"
            or "GameFontNormal"
        )

    valueText:SetPoint(
        "TOPRIGHT",
        parent,
        "TOPLEFT",
        x + width,
        y + (
            emphasize
            and 3
            or 0
        )
    )

    valueText:SetWidth(
        72
    )

    valueText:SetJustifyH(
        "RIGHT"
    )

    SetColor(
        valueText,
        emphasize
        and Colors.goldMuted
        or Colors.ink
    )

    local separator =
        parent:CreateTexture(
            nil,
            "ARTWORK"
        )

    separator:SetSize(
        width,
        1
    )

    separator:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        x,
        y - 23
    )

    separator:SetColorTexture(
        Colors.inkMuted.r,
        Colors.inkMuted.g,
        Colors.inkMuted.b,
        0.10
    )

    parent.fjLifetimeValueTexts[key] =
        valueText
end

local function RefreshPage(
    frame
)
    if not frame
        or not frame.fjLifetimeStatisticsPage then

        return
    end

    local snapshot = {}

    if FJ.ServerStatistics
        and type(
            FJ.ServerStatistics.GetSnapshot
        ) == "function" then

        snapshot =
            FJ.ServerStatistics.GetSnapshot()
            or {}
    end

    local values =
        frame.fjLifetimeStatisticsPage
            .fjLifetimeValueTexts
        or {}

    for key,
        valueText in pairs(
            values
        ) do

        valueText:SetText(
            FormatValue(
                snapshot[key]
            )
        )
    end
end

local function ShowOverview(
    frame
)
    if not frame then
        return
    end

    frame.fjLifetimeStatisticsActive =
        false

    if frame.fjLifetimeStatisticsPage then
        frame.fjLifetimeStatisticsPage:Hide()
    end

    if frame.leftPanel then
        frame.leftPanel:Show()
    end

    if frame.rightPanel then
        frame.rightPanel:Show()
    end
end

local function ShowStatistics(
    frame
)
    if not frame
        or not frame.fjLifetimeStatisticsPage then

        return
    end

    frame.fjLifetimeStatisticsActive =
        true

    if frame.leftPanel then
        frame.leftPanel:Hide()
    end

    if frame.rightPanel then
        frame.rightPanel:Hide()
    end

    RefreshPage(
        frame
    )

    frame.fjLifetimeStatisticsPage:Show()
end

local function CreateBackButton(
    page,
    frame
)
    local button =
        CreateFrame(
            "Button",
            nil,
            page
        )

    button:SetSize(
        110,
        24
    )

    button:SetPoint(
        "TOPLEFT",
        page,
        "TOPLEFT",
        24,
        -8
    )

    local text =
        button:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )

    text:SetPoint(
        "LEFT",
        button,
        "LEFT",
        0,
        0
    )

    text:SetText(
        T("BACK")
    )

    SetColor(
        text,
        Colors.goldMuted
    )

    button:SetScript(
        "OnEnter",
        function()
            SetColor(
                text,
                Colors.gold
            )
        end
    )

    button:SetScript(
        "OnLeave",
        function()
            SetColor(
                text,
                Colors.goldMuted
            )
        end
    )

    button:SetScript(
        "OnClick",
        function()
            ShowOverview(
                frame
            )
        end
    )

    return button
end

local function EnsurePage(
    frame
)
    if not frame
        or frame.fjLifetimeStatisticsPage
        or not frame.content then

        return
    end

    local page =
        CreateFrame(
            "Frame",
            nil,
            frame.content
        )

    page:SetAllPoints(
        frame.content
    )

    page:SetFrameLevel(
        frame.content:GetFrameLevel()
        + 2
    )

    page.fjLifetimeValueTexts = {}

    CreateBackButton(
        page,
        frame
    )

    local compass =
        page:CreateTexture(
            nil,
            "ARTWORK"
        )

    compass:SetTexture(
        Textures.compass
    )

    compass:SetSize(
        74,
        37
    )

    compass:SetPoint(
        "TOP",
        page,
        "TOP",
        0,
        1
    )

    compass:SetAlpha(
        0.78
    )

    local title =
        page:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalLarge"
        )

    title:SetPoint(
        "TOP",
        page,
        "TOP",
        0,
        -39
    )

    title:SetText(
        T("TITLE")
    )

    SetColor(
        title,
        Colors.ink
    )

    local subtitle =
        page:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlightSmall"
        )

    subtitle:SetPoint(
        "TOP",
        title,
        "BOTTOM",
        0,
        -4
    )

    subtitle:SetWidth(
        560
    )

    subtitle:SetJustifyH(
        "CENTER"
    )

    subtitle:SetText(
        T("SUBTITLE")
    )

    SetColor(
        subtitle,
        Colors.inkMuted
    )

    local ornament =
        page:CreateTexture(
            nil,
            "ARTWORK"
        )

    ornament:SetTexture(
        Textures.ornamentLine
    )

    ornament:SetSize(
        300,
        14
    )

    ornament:SetPoint(
        "TOP",
        subtitle,
        "BOTTOM",
        0,
        -8
    )

    local leftX = 66
    local rightX = 430
    local columnWidth = 292

    CreateSectionTitle(
        page,
        T("JOURNEY"),
        leftX,
        -119,
        columnWidth
    )

    CreateStatRow(
        page,
        "completedQuests",
        T("COMPLETED_QUESTS"),
        leftX,
        -151,
        columnWidth,
        true
    )

    CreateStatRow(
        page,
        "flightsTaken",
        T("FLIGHTS_TAKEN"),
        leftX,
        -186,
        columnWidth,
        false
    )

    CreateStatRow(
        page,
        "hearthstoneUses",
        T("HEARTHSTONE_USES"),
        leftX,
        -221,
        columnWidth,
        false
    )

    CreateSectionTitle(
        page,
        T("COMBAT"),
        leftX,
        -270,
        columnWidth
    )

    CreateStatRow(
        page,
        "totalKills",
        T("TOTAL_KILLS"),
        leftX,
        -302,
        columnWidth,
        true
    )

    CreateStatRow(
        page,
        "honorableKills",
        T("HONORABLE_KILLS"),
        leftX,
        -337,
        columnWidth,
        false
    )

    CreateSectionTitle(
        page,
        T("DANGERS"),
        rightX,
        -119,
        columnWidth
    )

    CreateStatRow(
        page,
        "totalDeaths",
        T("TOTAL_DEATHS"),
        rightX,
        -151,
        columnWidth,
        true
    )

    CreateStatRow(
        page,
        "fallingDeaths",
        T("FALLING_DEATHS"),
        rightX,
        -186,
        columnWidth,
        false
    )

    CreateStatRow(
        page,
        "pvpDeaths",
        T("PVP_DEATHS"),
        rightX,
        -221,
        columnWidth,
        false
    )

    CreateSectionTitle(
        page,
        T("FOOTNOTE_TITLE"),
        rightX,
        -270,
        columnWidth
    )

    local footer =
        page:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlightSmall"
        )

    footer:SetPoint(
        "TOPLEFT",
        page,
        "TOPLEFT",
        rightX,
        -302
    )

    footer:SetWidth(
        columnWidth
    )

    footer:SetJustifyH(
        "LEFT"
    )

    footer:SetJustifyV(
        "TOP"
    )

    footer:SetText(
        T("FOOTNOTE")
    )

    SetColor(
        footer,
        Colors.inkMuted
    )

    frame.fjLifetimeStatisticsPage =
        page

    page:Hide()
end

local function EnsureButton(
    frame
)
    if not frame
        or frame.fjLifetimeStatisticsButton
        or not frame.leftPanel then

        return
    end

    local button =
        CreateFrame(
            "Button",
            nil,
            frame.leftPanel
        )

    button:SetSize(
        110,
        22
    )

    button:SetPoint(
        "TOPRIGHT",
        frame.leftPanel,
        "TOPRIGHT",
        -27,
        -158
    )

    local background =
        button:CreateTexture(
            nil,
            "BACKGROUND"
        )

    background:SetAllPoints(
        button
    )

    background:SetColorTexture(
        Colors.goldMuted.r,
        Colors.goldMuted.g,
        Colors.goldMuted.b,
        0.10
    )

    local text =
        button:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )

    text:SetPoint(
        "CENTER"
    )

    text:SetText(
        T("BUTTON")
    )

    SetColor(
        text,
        Colors.goldMuted
    )

    button:SetScript(
        "OnEnter",
        function()
            background:SetColorTexture(
                Colors.goldMuted.r,
                Colors.goldMuted.g,
                Colors.goldMuted.b,
                0.20
            )

            SetColor(
                text,
                Colors.gold
            )
        end
    )

    button:SetScript(
        "OnLeave",
        function()
            background:SetColorTexture(
                Colors.goldMuted.r,
                Colors.goldMuted.g,
                Colors.goldMuted.b,
                0.10
            )

            SetColor(
                text,
                Colors.goldMuted
            )
        end
    )

    button:SetScript(
        "OnClick",
        function()
            ShowStatistics(
                frame
            )
        end
    )

    frame.fjLifetimeStatisticsButton =
        button
end

local function EnsureNavigationHooks(
    frame
)
    if not frame
        or frame.fjLifetimeStatisticsHooksInstalled then

        return
    end

    if frame.overviewButton then
        frame.overviewButton:HookScript(
            "OnClick",
            function()
                ShowOverview(
                    frame
                )
            end
        )
    end

    frame.fjLifetimeStatisticsHooksInstalled =
        true
end

local function EnsureUI()
    local frame =
        _G.ForeverJourneyMainFrame

    if not frame then
        return
    end

    EnsurePage(
        frame
    )

    EnsureButton(
        frame
    )

    EnsureNavigationHooks(
        frame
    )

    RefreshPage(
        frame
    )
end

function FJ.LifetimeStatisticsUI.Refresh()
    EnsureUI()
end

function FJ.LifetimeStatisticsUI.Show()
    EnsureUI()

    local frame =
        _G.ForeverJourneyMainFrame

    if frame then
        ShowStatistics(
            frame
        )
    end
end

function FJ.LifetimeStatisticsUI.Hide()
    local frame =
        _G.ForeverJourneyMainFrame

    if frame then
        ShowOverview(
            frame
        )
    end
end

if FJ.UI
    and type(
        FJ.UI.Refresh
    ) == "function" then

    local originalRefresh =
        FJ.UI.Refresh

    FJ.UI.Refresh =
        function(...)
            originalRefresh(...)
            EnsureUI()
        end
end