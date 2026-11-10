local addonName, FJ = ...

FJ.HistoryUI = {}

local Theme = FJ.Theme
local Colors = Theme.Colors
local Textures = Theme.Textures
local Layout = Theme.Window

local locale = GetLocale()

local strings = {
    enUS = {
        TITLE = "JOURNEY HISTORY",
        SUBTITLE = "The milestones and chapters that shaped your adventure.",

        BEFORE = "BEFORE THE CHRONICLE",
        ARCHIVE = "ARCHIVAL ENTRY",
        ARCHIVE_META = "Recovered from character data - %s",

        FROM_BEGINNING = "FROM THE VERY BEGINNING",
        FROM_BEGINNING_TEXT =
            "Forever Journey has been here since the beginning of this adventure.",

        CHRONICLE_STARTED =
            "Chronicle began %s - Level %d",

        LEVEL = "LEVEL",
        QUESTS = "QUESTS",
        PLAYED = "TIME PLAYED",
        MONEY = "MONEY",

        PROFESSIONS_AT_THAT_TIME =
            "PROFESSIONS AT THAT MOMENT",

        FIRST_STEPS =
            "FIRST STEPS",

        FIRST_DISCOVERY =
            "FIRST DISCOVERY",

        FIRST_INSTANCE =
            "FIRST DUNGEON",

        FIRST_DEATH =
            "FIRST DEATH",

        FIRST_LEVEL =
            "FIRST LEVEL-UP",

        FIRST_RECORDED_DISCOVERY =
            "FIRST RECORDED DISCOVERY",

        FIRST_RECORDED_INSTANCE =
            "FIRST RECORDED DUNGEON",

        FIRST_RECORDED_DEATH =
            "FIRST RECORDED DEATH",

        FIRST_RECORDED_LEVEL =
            "FIRST RECORDED LEVEL-UP",

        NO_FIRST_STEPS =
            "The first chapters are still waiting to be written.",

        LEVEL_MILESTONES =
            "LEVEL MILESTONES",

        MORE_LEVELS =
            "+ %d more level milestones in the Chronicle",

        SO_FAR =
            "THE JOURNEY SO FAR",

        ZONES =
            "ZONES",

        INSTANCES =
            "DUNGEONS",

        DEATHS =
            "DEATHS",

        EVENTS =
            "EVENTS",

        RECORDED_TIME =
            "RECORDED TIME",

        FOOTNOTE =
            "Every recorded event remains available in the Chronicle.",

        UNKNOWN =
            "Unknown"
    },

    ruRU = {
        TITLE =
            "ИСТОРИЯ ПУТЕШЕСТВИЯ",

        SUBTITLE =
            "Главные этапы и главы, из которых сложился твой путь.",

        BEFORE =
            "ДО НАЧАЛА ХРОНИКИ",

        ARCHIVE =
            "АРХИВНАЯ ЗАПИСЬ",

        ARCHIVE_META =
            "Восстановлено по данным персонажа - %s",

        FROM_BEGINNING =
            "С САМОГО НАЧАЛА",

        FROM_BEGINNING_TEXT =
            "Forever Journey был рядом с самого начала этого путешествия.",

        CHRONICLE_STARTED =
            "Хроника началась %s - уровень %d",

        LEVEL =
            "УРОВЕНЬ",

        QUESTS =
            "ЗАДАНИЯ",

        PLAYED =
            "ВРЕМЯ В ИГРЕ",

        MONEY =
            "МОНЕТЫ",

        PROFESSIONS_AT_THAT_TIME =
            "ПРОФЕССИИ НА ТОТ МОМЕНТ",

        FIRST_STEPS =
            "ПЕРВЫЕ ШАГИ",

        FIRST_DISCOVERY =
            "ПЕРВОЕ ОТКРЫТИЕ",

        FIRST_INSTANCE =
            "ПЕРВОЕ ПОДЗЕМЕЛЬЕ",

        FIRST_DEATH =
            "ПЕРВАЯ СМЕРТЬ",

        FIRST_LEVEL =
            "ПЕРВОЕ ПОВЫШЕНИЕ УРОВНЯ",

        FIRST_RECORDED_DISCOVERY =
            "ПЕРВОЕ ЗАПИСАННОЕ ОТКРЫТИЕ",

        FIRST_RECORDED_INSTANCE =
            "ПЕРВОЕ ЗАПИСАННОЕ ПОДЗЕМЕЛЬЕ",

        FIRST_RECORDED_DEATH =
            "ПЕРВАЯ ЗАПИСАННАЯ СМЕРТЬ",

        FIRST_RECORDED_LEVEL =
            "ПЕРВОЕ ЗАПИСАННОЕ ПОВЫШЕНИЕ УРОВНЯ",

        NO_FIRST_STEPS =
            "Первые главы этого путешествия ещё ждут своей записи.",

        LEVEL_MILESTONES =
            "УРОВНЕВЫЕ ВЕХИ",

        MORE_LEVELS =
            "+ ещё %d уровневых вех в Хронике",

        SO_FAR =
            "ПУТЬ К ЭТОМУ МОМЕНТУ",

        ZONES =
            "ЛОКАЦИИ",

        INSTANCES =
            "ПОДЗЕМЕЛЬЯ",

        DEATHS =
            "СМЕРТИ",

        EVENTS =
            "СОБЫТИЯ",

        RECORDED_TIME =
            "ВРЕМЯ В ХРОНИКЕ",

        FOOTNOTE =
            "Подробности каждого записанного события всегда доступны во вкладке «Хроника».",

        UNKNOWN =
            "Неизвестно"
    }
}

local currentStrings =
    strings[locale]
    or strings.enUS

local function T(key, ...)
    local value =
        currentStrings[key]
        or strings.enUS[key]
        or key

    if select("#", ...) == 0 then
        return value
    end

    local ok,
        result = pcall(
            string.format,
            value,
            ...
        )

    if ok then
        return result
    end

    return value
end

local function CreateText(
    parent,
    fontObject,
    point,
    relativeTo,
    relativePoint,
    x,
    y
)
    local text =
        parent:CreateFontString(
            nil,
            "OVERLAY",
            fontObject
        )

    text:SetPoint(
        point,
        relativeTo,
        relativePoint,
        x,
        y
    )

    return text
end

local function CreateTexture(
    parent,
    texturePath,
    layer
)
    local texture =
        parent:CreateTexture(
            nil,
            layer or "ARTWORK"
        )

    texture:SetTexture(
        texturePath
    )

    return texture
end

local function SetTabActive(
    button,
    active
)
    if not button
        or not button.background
        or not button.label then

        return
    end

    button.background:SetTexture(
        active
            and Textures.tabActive
            or Textures.tabInactive
    )

    if active then
        Theme.ApplyTextColor(
            button.label,
            Colors.gold
        )
    else
        button.label:SetTextColor(
            0.78,
            0.69,
            0.55,
            1
        )
    end
end

local function FormatShortDate(
    timestamp
)
    if not timestamp then
        return T(
            "UNKNOWN"
        )
    end

    return date(
        "%d.%m.%Y",
        timestamp
    )
end

local function GetRecoveredHistory()
    if FJ.ViewModel.GetRecoveredHistory then
        return FJ.ViewModel.GetRecoveredHistory()
    end

    local recovered =
        FJ.State.recoveredHistory
        or {}

    return {
        initialized =
            recovered.initialized
            == true,

        capturedAt =
            recovered.capturedAt,

        level =
            recovered.level
            or 0,

        completedQuests =
            recovered.completedQuests
            and recovered.completedQuests.count
            or 0,

        totalPlayed =
            recovered.played
            and recovered.played.total
            or 0,

        money =
            recovered.money
            and recovered.money.current
            or 0,

        professions =
            recovered.professions
            or {}
    }
end

local function HasMeaningfulRecoveredHistory(
    history
)
    if not history
        or not history.initialized then

        return false
    end

    if (history.level or 0) > 1 then
        return true
    end

    if (history.completedQuests or 0) > 0 then
        return true
    end

    if (history.totalPlayed or 0)
        >= 1800 then

        return true
    end

    for _, profession in ipairs(
        history.professions or {}
    ) do
        if (profession.skillLevel or 0)
            > 1 then

            return true
        end
    end

    return false
end

local function GetViewMemory(
    rawMemory
)
    if FJ.ViewModel.GetMemory then
        local view =
            FJ.ViewModel.GetMemory(
                rawMemory
            )

        if view then
            return view
        end
    end

    return rawMemory
end

local function GetRecordedMemories()
    local result = {}

    for _, rawMemory in ipairs(
        FJ.State.memories
        or {}
    ) do
        if type(rawMemory)
                == "table"
            and rawMemory.source
                ~= "RECOVERED" then

            table.insert(
                result,
                {
                    raw =
                        rawMemory,

                    view =
                        GetViewMemory(
                            rawMemory
                        )
                }
            )
        end
    end

    table.sort(
        result,
        function(a, b)
            local aTime =
                a.raw.timestamp
                or 0

            local bTime =
                b.raw.timestamp
                or 0

            if aTime == bTime then
                return tostring(
                    a.raw.id
                    or ""
                )
                    < tostring(
                        b.raw.id
                        or ""
                    )
            end

            return aTime < bTime
        end
    )

    return result
end

local function FindFirstMemory(
    memories,
    memoryType
)
    for _, item in ipairs(
        memories
    ) do
        if item.raw.type
            == memoryType then

            return item
        end
    end

    return nil
end

local function GetLocationName(
    item
)
    if not item then
        return nil
    end

    local view =
        item.view
        or {}

    local location =
        view.location
        or item.raw.location

    if location
        and location.name
        and location.name ~= "" then

        return location.name
    end

    return nil
end

local function GetMemoryTitle(
    item
)
    if not item then
        return T(
            "UNKNOWN"
        )
    end

    local view =
        item.view
        or {}

    return view.title
        or item.raw.title
        or T("UNKNOWN")
end

local function GetMemoryMeta(
    item
)
    if not item then
        return ""
    end

    local result =
        FormatShortDate(
            item.raw.timestamp
        )

    local locationName =
        GetLocationName(
            item
        )

    if locationName then
        result =
            result
            .. " - "
            .. locationName
    end

    return result
end

local function CountVisitedZones()
    local count = 0

    for _ in pairs(
        FJ.State.visitedZones
        or {}
    ) do
        count =
            count + 1
    end

    return count
end

local function CountUniqueInstances(
    memories
)
    local unique = {}

    for _, item in ipairs(
        memories
    ) do
        if item.raw.type
            == "INSTANCE" then

            local data =
                item.raw.data
                or {}

            local location =
                item.raw.location
                or {}

            local key =
                data.instanceID
                or location.instanceID
                or location.name
                or GetMemoryTitle(
                    item
                )

            unique[
                tostring(key)
            ] = true
        end
    end

    local count = 0

    for _ in pairs(
        unique
    ) do
        count =
            count + 1
    end

    return count
end

local function CountDeaths(
    memories
)
    local count = 0

    for _, item in ipairs(
        memories
    ) do
        if item.raw.type
            == "DEATH" then

            count =
                count + 1
        end
    end

    return count
end

local function GetLevelMemories(
    memories
)
    local result = {}

    for _, item in ipairs(
        memories
    ) do
        if item.raw.type
            == "LEVEL" then

            table.insert(
                result,
                item
            )
        end
    end

    return result
end

local function CreateSectionTitle(
    parent
)
    local text =
        CreateText(
            parent,
            "GameFontNormal",
            "TOPLEFT",
            parent,
            "TOPLEFT",
            0,
            0
        )

    Theme.ApplyTextColor(
        text,
        Colors.ink
    )

    return text
end

local function CreateMilestoneRow(
    parent
)
    local row =
        CreateFrame(
            "Frame",
            nil,
            parent
        )

    row:SetSize(
        660,
        58
    )

    row.marker =
        CreateTexture(
            row,
            Textures.markerGeneric,
            "ARTWORK"
        )

    row.marker:SetSize(
        38,
        38
    )

    row.marker:SetPoint(
        "TOPLEFT",
        row,
        "TOPLEFT",
        8,
        -6
    )

    row.typeLabel =
        CreateText(
            row,
            "GameFontNormalSmall",
            "TOPLEFT",
            row,
            "TOPLEFT",
            60,
            -1
        )

    Theme.ApplyTextColor(
        row.typeLabel,
        Colors.goldMuted
    )

    row.title =
        CreateText(
            row,
            "GameFontHighlight",
            "TOPLEFT",
            row,
            "TOPLEFT",
            60,
            -20
        )

    row.title:SetWidth(
        570
    )

    row.title:SetJustifyH(
        "LEFT"
    )

    Theme.ApplyTextColor(
        row.title,
        Colors.ink
    )

    row.meta =
        CreateText(
            row,
            "GameFontHighlightSmall",
            "TOPLEFT",
            row,
            "TOPLEFT",
            60,
            -40
        )

    row.meta:SetWidth(
        570
    )

    row.meta:SetJustifyH(
        "LEFT"
    )

    Theme.ApplyTextColor(
        row.meta,
        Colors.inkMuted
    )

    return row
end

local function CreateSummaryCard(
    parent
)
    local card =
        CreateFrame(
            "Frame",
            nil,
            parent
        )

    card:SetSize(
        126,
        58
    )

    card.value =
        CreateText(
            card,
            "GameFontNormalLarge",
            "TOP",
            card,
            "TOP",
            0,
            0
        )

    card.value:SetWidth(
        126
    )

    card.value:SetJustifyH(
        "CENTER"
    )

    Theme.ApplyTextColor(
        card.value,
        Colors.ink
    )

    card.label =
        CreateText(
            card,
            "GameFontHighlightSmall",
            "TOP",
            card.value,
            "BOTTOM",
            0,
            -5
        )

    card.label:SetWidth(
        126
    )

    card.label:SetJustifyH(
        "CENTER"
    )

    Theme.ApplyTextColor(
        card.label,
        Colors.inkMuted
    )

    return card
end

local function CreateProfessionRow(
    parent
)
    local row =
        CreateFrame(
            "Frame",
            nil,
            parent
        )

    row:SetSize(
        300,
        20
    )

    row.name =
        CreateText(
            row,
            "GameFontHighlightSmall",
            "LEFT",
            row,
            "LEFT",
            0,
            0
        )

    row.name:SetWidth(
        220
    )

    row.name:SetJustifyH(
        "LEFT"
    )

    Theme.ApplyTextColor(
        row.name,
        Colors.ink
    )

    row.value =
        CreateText(
            row,
            "GameFontHighlightSmall",
            "RIGHT",
            row,
            "RIGHT",
            0,
            0
        )

    row.value:SetJustifyH(
        "RIGHT"
    )

    Theme.ApplyTextColor(
        row.value,
        Colors.inkMuted
    )

    return row
end

local function UpdateScrollThumb(
    frame
)
    local scroll =
        frame.historyV2Scroll

    local track =
        frame.historyV2ScrollTrack

    local thumb =
        frame.historyV2ScrollThumb

    if not scroll
        or not track
        or not thumb then

        return
    end

    local maximum =
        scroll:GetVerticalScrollRange()
        or 0

    if maximum <= 0 then
        track:Hide()
        thumb:Hide()

        return
    end

    track:Show()
    thumb:Show()

    local current =
        scroll:GetVerticalScroll()

    local ratio =
        current / maximum

    local travel =
        math.max(
            track:GetHeight()
                - thumb:GetHeight(),
            0
        )

    thumb:ClearAllPoints()

    thumb:SetPoint(
        "TOP",
        track,
        "TOP",
        0,
        -(travel * ratio)
    )
end

local function ScrollBy(
    frame,
    amount
)
    local scroll =
        frame.historyV2Scroll

    if not scroll then
        return
    end

    local maximum =
        scroll:GetVerticalScrollRange()
        or 0

    local target =
        scroll:GetVerticalScroll()
        + amount

    if target < 0 then
        target = 0

    elseif target > maximum then
        target = maximum
    end

    scroll:SetVerticalScroll(
        target
    )

    UpdateScrollThumb(
        frame
    )
end

local function CreatePage(
    frame
)
    local page =
        CreateFrame(
            "Frame",
            nil,
            frame
        )

    page:SetSize(
        Layout.contentWidth,
        Layout.contentHeight
    )

    page:SetPoint(
        "TOP",
        frame,
        "TOP",
        0,
        -106
    )

    frame.historyV2Page =
        page

    frame.historyV2Title =
        CreateText(
            page,
            "GameFontNormalLarge",
            "TOPLEFT",
            page,
            "TOPLEFT",
            38,
            -8
        )

    frame.historyV2Title:SetText(
        T("TITLE")
    )

    Theme.ApplyTextColor(
        frame.historyV2Title,
        Colors.ink
    )

    frame.historyV2Subtitle =
        CreateText(
            page,
            "GameFontHighlightSmall",
            "TOPLEFT",
            frame.historyV2Title,
            "BOTTOMLEFT",
            0,
            -6
        )

    frame.historyV2Subtitle:SetText(
        T("SUBTITLE")
    )

    Theme.ApplyTextColor(
        frame.historyV2Subtitle,
        Colors.inkMuted
    )

    local scroll =
        CreateFrame(
            "ScrollFrame",
            nil,
            page
        )

    scroll:SetPoint(
        "TOPLEFT",
        page,
        "TOPLEFT",
        38,
        -58
    )

    scroll:SetPoint(
        "BOTTOMRIGHT",
        page,
        "BOTTOMRIGHT",
        -36,
        8
    )

    scroll:EnableMouseWheel(
        true
    )

    frame.historyV2Scroll =
        scroll

    local child =
        CreateFrame(
            "Frame",
            nil,
            scroll
        )

    child:SetSize(
        670,
        1
    )

    scroll:SetScrollChild(
        child
    )

    frame.historyV2ScrollChild =
        child

    scroll:SetScript(
        "OnMouseWheel",
        function(self, delta)
            ScrollBy(
                frame,
                -delta * 72
            )
        end
    )

    scroll:SetScript(
        "OnVerticalScroll",
        function()
            UpdateScrollThumb(
                frame
            )
        end
    )

    --
    -- Recovered archive
    --

    frame.historyV2Archive =
        CreateFrame(
            "Frame",
            nil,
            child
        )

    frame.historyV2Archive:SetSize(
        660,
        204
    )

    frame.historyV2ArchiveTitle =
        CreateSectionTitle(
            frame.historyV2Archive
        )

    frame.historyV2ArchiveMarker =
        CreateTexture(
            frame.historyV2Archive,
            Textures.markerRecovered,
            "ARTWORK"
        )

    frame.historyV2ArchiveMarker:SetSize(
        44,
        44
    )

    frame.historyV2ArchiveMarker:SetPoint(
        "TOPLEFT",
        frame.historyV2Archive,
        "TOPLEFT",
        8,
        -28
    )

    frame.historyV2ArchiveName =
        CreateText(
            frame.historyV2Archive,
            "GameFontNormal",
            "TOPLEFT",
            frame.historyV2Archive,
            "TOPLEFT",
            66,
            -28
        )

    Theme.ApplyTextColor(
        frame.historyV2ArchiveName,
        Colors.recovered
    )

    frame.historyV2ArchiveMeta =
        CreateText(
            frame.historyV2Archive,
            "GameFontHighlightSmall",
            "TOPLEFT",
            frame.historyV2Archive,
            "TOPLEFT",
            66,
            -50
        )

    Theme.ApplyTextColor(
        frame.historyV2ArchiveMeta,
        Colors.inkMuted
    )

    frame.historyV2ArchiveStats = {}

    local archiveLabels = {
        T("LEVEL"),
        T("QUESTS"),
        T("PLAYED"),
        T("MONEY")
    }

    for index = 1, 4 do
        local card =
            CreateSummaryCard(
                frame.historyV2Archive
            )

        card:SetPoint(
            "TOPLEFT",
            frame.historyV2Archive,
            "TOPLEFT",
            8
                + (
                    (index - 1)
                    * 160
                ),
            -76
        )

        card.label:SetText(
            archiveLabels[index]
        )

        frame.historyV2ArchiveStats[index] =
            card
    end

    frame.historyV2ArchiveProfessionTitle =
        CreateText(
            frame.historyV2Archive,
            "GameFontNormalSmall",
            "TOPLEFT",
            frame.historyV2Archive,
            "TOPLEFT",
            8,
            -137
        )

    frame.historyV2ArchiveProfessionTitle:SetText(
        T(
            "PROFESSIONS_AT_THAT_TIME"
        )
    )

    Theme.ApplyTextColor(
        frame.historyV2ArchiveProfessionTitle,
        Colors.inkMuted
    )

    frame.historyV2ProfessionRows = {}

    for index = 1, 5 do
        local row =
            CreateProfessionRow(
                frame.historyV2Archive
            )

        local column =
            index <= 3
            and 0
            or 1

        local rowIndex =
            index <= 3
            and index
            or index - 3

        row:SetPoint(
            "TOPLEFT",
            frame.historyV2Archive,
            "TOPLEFT",
            8 + (column * 332),
            -154
                - (
                    (rowIndex - 1)
                    * 22
                )
        )

        frame.historyV2ProfessionRows[index] =
            row
    end

    --
    -- Fresh-character intro
    --

    frame.historyV2Fresh =
        CreateFrame(
            "Frame",
            nil,
            child
        )

    frame.historyV2Fresh:SetSize(
        660,
        102
    )

    frame.historyV2FreshTitle =
        CreateSectionTitle(
            frame.historyV2Fresh
        )

    frame.historyV2FreshMarker =
        CreateTexture(
            frame.historyV2Fresh,
            Textures.iconStarted,
            "ARTWORK"
        )

    frame.historyV2FreshMarker:SetSize(
        38,
        38
    )

    frame.historyV2FreshMarker:SetPoint(
        "TOPLEFT",
        frame.historyV2Fresh,
        "TOPLEFT",
        10,
        -30
    )

    frame.historyV2FreshText =
        CreateText(
            frame.historyV2Fresh,
            "GameFontHighlight",
            "TOPLEFT",
            frame.historyV2Fresh,
            "TOPLEFT",
            64,
            -28
        )

    frame.historyV2FreshText:SetWidth(
        570
    )

    Theme.ApplyTextColor(
        frame.historyV2FreshText,
        Colors.ink
    )

    frame.historyV2FreshMeta =
        CreateText(
            frame.historyV2Fresh,
            "GameFontHighlightSmall",
            "TOPLEFT",
            frame.historyV2Fresh,
            "TOPLEFT",
            64,
            -54
        )

    Theme.ApplyTextColor(
        frame.historyV2FreshMeta,
        Colors.inkMuted
    )

    --
    -- First divider
    --

    frame.historyV2Divider1 =
        CreateTexture(
            child,
            Textures.dividerHorizontal,
            "ARTWORK"
        )

    frame.historyV2Divider1:SetSize(
        600,
        12
    )

    --
    -- First steps
    --

    frame.historyV2FirstStepsTitle =
        CreateSectionTitle(
            child
        )

    frame.historyV2Milestones = {}

    for index = 1, 4 do
        frame.historyV2Milestones[index] =
            CreateMilestoneRow(
                child
            )
    end

    frame.historyV2FirstStepsEmpty =
        CreateText(
            child,
            "GameFontHighlightSmall",
            "TOPLEFT",
            child,
            "TOPLEFT",
            8,
            0
        )

    frame.historyV2FirstStepsEmpty:SetWidth(
        630
    )

    Theme.ApplyTextColor(
        frame.historyV2FirstStepsEmpty,
        Colors.inkMuted
    )

    --
    -- Level milestones
    --

    frame.historyV2LevelTitle =
        CreateSectionTitle(
            child
        )

    frame.historyV2LevelRows = {}

    for index = 1, 6 do
        frame.historyV2LevelRows[index] =
            CreateMilestoneRow(
                child
            )
    end

    frame.historyV2MoreLevels =
        CreateText(
            child,
            "GameFontHighlightSmall",
            "TOPLEFT",
            child,
            "TOPLEFT",
            60,
            0
        )

    Theme.ApplyTextColor(
        frame.historyV2MoreLevels,
        Colors.inkMuted
    )

    --
    -- Summary divider
    --

    frame.historyV2Divider2 =
        CreateTexture(
            child,
            Textures.dividerHorizontal,
            "ARTWORK"
        )

    frame.historyV2Divider2:SetSize(
        600,
        12
    )

    --
    -- Summary
    --

    frame.historyV2SummaryTitle =
        CreateSectionTitle(
            child
        )

    frame.historyV2Summary =
        CreateFrame(
            "Frame",
            nil,
            child
        )

    frame.historyV2Summary:SetSize(
        660,
        64
    )

    frame.historyV2SummaryCards = {}

    local summaryLabels = {
        T("ZONES"),
        T("INSTANCES"),
        T("DEATHS"),
        T("EVENTS"),
        T("RECORDED_TIME")
    }

    for index = 1, 5 do
        local card =
            CreateSummaryCard(
                frame.historyV2Summary
            )

        card:SetPoint(
            "TOPLEFT",
            frame.historyV2Summary,
            "TOPLEFT",
            (index - 1)
                * 132,
            0
        )

        card.label:SetText(
            summaryLabels[index]
        )

        frame.historyV2SummaryCards[index] =
            card
    end

    frame.historyV2Footnote =
        CreateText(
            child,
            "GameFontHighlightSmall",
            "TOP",
            child,
            "TOP",
            0,
            0
        )

    frame.historyV2Footnote:SetWidth(
        640
    )

    frame.historyV2Footnote:SetJustifyH(
        "CENTER"
    )

    frame.historyV2Footnote:SetText(
        T("FOOTNOTE")
    )

    Theme.ApplyTextColor(
        frame.historyV2Footnote,
        Colors.recovered
    )

    --
    -- Minimal scrollbar.
    -- Only the track and thumb remain.
    -- Scrolling is handled with the mouse wheel.
    --

    local track =
        page:CreateTexture(
            nil,
            "ARTWORK"
        )

    track:SetSize(
        2,
        324
    )

    track:SetPoint(
        "TOPRIGHT",
        page,
        "TOPRIGHT",
        -17,
        -72
    )

    track:SetColorTexture(
        Colors.timeline.r,
        Colors.timeline.g,
        Colors.timeline.b,
        0.35
    )

    frame.historyV2ScrollTrack =
        track

    local thumb =
        page:CreateTexture(
            nil,
            "OVERLAY"
        )

    thumb:SetSize(
        8,
        46
    )

    thumb:SetColorTexture(
        Colors.goldMuted.r,
        Colors.goldMuted.g,
        Colors.goldMuted.b,
        0.85
    )

    thumb:SetPoint(
        "TOP",
        track,
        "TOP",
        0,
        0
    )

    frame.historyV2ScrollThumb =
        thumb

    page:Hide()
end

local function PositionMilestoneRow(
    row,
    child,
    y,
    item,
    label
)
    row:ClearAllPoints()

    row:SetPoint(
        "TOPLEFT",
        child,
        "TOPLEFT",
        0,
        -y
    )

    row.marker:SetTexture(
        Theme.GetMarkerTexture(
            item.raw
        )
    )

    row.typeLabel:SetText(
        label
    )

    row.title:SetText(
        GetMemoryTitle(
            item
        )
    )

    row.meta:SetText(
        GetMemoryMeta(
            item
        )
    )

    row:Show()
end

local function HidePage(
    frame
)
    if frame
        and frame.historyV2Page then

        frame.historyV2Page:Hide()
    end
end

local function ShowPage(
    frame
)
    if not frame
        or not frame.historyV2Page then

        return
    end

    if frame.content then
        frame.content:Hide()
    end

    if frame.historyPage then
        frame.historyPage:Hide()
    end

    if frame.chroniclePage then
        frame.chroniclePage:Hide()
    end

    frame.historyV2Page:Show()

    frame.currentPage =
        "HISTORY_V2"

    SetTabActive(
        frame.overviewButton,
        false
    )

    SetTabActive(
        frame.timelineButton,
        false
    )

    SetTabActive(
        frame.historyButton,
        true
    )

    FJ.HistoryUI.Refresh(
        frame
    )

    frame.historyV2Scroll:SetVerticalScroll(
        0
    )

    UpdateScrollThumb(
        frame
    )
end

local function HookButton(
    button,
    callback
)
    if not button then
        return
    end

    local original =
        button:GetScript(
            "OnClick"
        )

    button:SetScript(
        "OnClick",
        function(self, ...)
            callback(
                original,
                self,
                ...
            )
        end
    )
end

function FJ.HistoryUI.Attach(
    frame
)
    if not frame
        or frame.historyV2Attached then

        return
    end

    CreatePage(
        frame
    )

    HookButton(
        frame.overviewButton,
        function(
            original,
            self,
            ...
        )
            HidePage(
                frame
            )

            if original then
                original(
                    self,
                    ...
                )
            end
        end
    )

    HookButton(
        frame.timelineButton,
        function(
            original,
            self,
            ...
        )
            HidePage(
                frame
            )

            if original then
                original(
                    self,
                    ...
                )
            end
        end
    )

    frame.historyButton:SetScript(
        "OnClick",
        function()
            ShowPage(
                frame
            )
        end
    )

    frame.historyV2Attached =
        true

    FJ.HistoryUI.Refresh(
        frame
    )
end

function FJ.HistoryUI.Refresh(
    frame
)
    frame =
        frame
        or ForeverJourneyMainFrame

    if not frame
        or not frame.historyV2Page then

        return
    end

    local child =
        frame.historyV2ScrollChild

    local recovered =
        GetRecoveredHistory()

    local meaningfulRecovered =
        HasMeaningfulRecoveredHistory(
            recovered
        )

    local memories =
        GetRecordedMemories()

    local overview =
        FJ.ViewModel.GetOverview()

    local y = 0

    --
    -- Intro
    --

    if meaningfulRecovered then
        frame.historyV2Fresh:Hide()
        frame.historyV2Archive:Show()

        frame.historyV2Archive:ClearAllPoints()

        frame.historyV2Archive:SetPoint(
            "TOPLEFT",
            child,
            "TOPLEFT",
            0,
            -y
        )

        frame.historyV2ArchiveTitle:SetText(
            T("BEFORE")
        )

        frame.historyV2ArchiveName:SetText(
            T("ARCHIVE")
        )

        frame.historyV2ArchiveMeta:SetText(
            T(
                "ARCHIVE_META",
                FJ.Utils.FormatDate(
                    recovered.capturedAt
                )
            )
        )

        frame.historyV2ArchiveStats[1]
            .value:SetText(
                tostring(
                    recovered.level
                    or 0
                )
            )

        frame.historyV2ArchiveStats[2]
            .value:SetText(
                tostring(
                    recovered.completedQuests
                    or 0
                )
            )

        frame.historyV2ArchiveStats[3]
            .value:SetText(
                FJ.Utils.FormatPlayedTime(
                    recovered.totalPlayed
                    or 0
                )
            )

        frame.historyV2ArchiveStats[4]
            .value:SetText(
                FJ.Utils.FormatMoney(
                    recovered.money
                    or 0
                )
            )

        local professionCount =
            #(
                recovered.professions
                or {}
            )

        if professionCount > 0 then
            frame.historyV2ArchiveProfessionTitle:Show()

            for index = 1, 5 do
                local row =
                    frame.historyV2ProfessionRows[index]

                local profession =
                    recovered.professions[index]

                if profession then
                    row.name:SetText(
                        FJ.Utils.GetLocalizedProfessionName(profession)
                        or T("UNKNOWN")
                    )

                    row.value:SetText(
                        tostring(
                            profession.skillLevel
                            or 0
                        )
                            .. "/"
                            .. tostring(
                                profession.maxSkillLevel
                                or 0
                            )
                    )

                    row:Show()
                else
                    row:Hide()
                end
            end

            frame.historyV2Archive:SetHeight(
                204
            )

            y =
                y + 210
        else
            frame.historyV2ArchiveProfessionTitle:Hide()

            for index = 1, 5 do
                frame.historyV2ProfessionRows[index]:Hide()
            end

            frame.historyV2Archive:SetHeight(
                138
            )

            y =
                y + 146
        end
    else
        frame.historyV2Archive:Hide()
        frame.historyV2Fresh:Show()

        frame.historyV2Fresh:ClearAllPoints()

        frame.historyV2Fresh:SetPoint(
            "TOPLEFT",
            child,
            "TOPLEFT",
            0,
            -y
        )

        frame.historyV2FreshTitle:SetText(
            T(
                "FROM_BEGINNING"
            )
        )

        frame.historyV2FreshText:SetText(
            T(
                "FROM_BEGINNING_TEXT"
            )
        )

        frame.historyV2FreshMeta:SetText(
            T(
                "CHRONICLE_STARTED",
                FormatShortDate(
                    recovered.capturedAt
                        or overview.journey
                            .recordingStartedAt
                        or overview.journey
                            .startedAt
                ),
                recovered.level
                    or overview.character.level
                    or 1
            )
        )

        y =
            y + 108
    end

    --
    -- First steps
    --

    frame.historyV2Divider1:ClearAllPoints()

    frame.historyV2Divider1:SetPoint(
        "TOP",
        child,
        "TOP",
        0,
        -y
    )

    y =
        y + 24

    frame.historyV2FirstStepsTitle:ClearAllPoints()

    frame.historyV2FirstStepsTitle:SetPoint(
        "TOPLEFT",
        child,
        "TOPLEFT",
        0,
        -y
    )

    frame.historyV2FirstStepsTitle:SetText(
        T(
            "FIRST_STEPS"
        )
    )

    y =
        y + 27

    local firstLabels

    if meaningfulRecovered then
        firstLabels = {
            T(
                "FIRST_RECORDED_DISCOVERY"
            ),

            T(
                "FIRST_RECORDED_INSTANCE"
            ),

            T(
                "FIRST_RECORDED_DEATH"
            ),

            T(
                "FIRST_RECORDED_LEVEL"
            )
        }
    else
        firstLabels = {
            T(
                "FIRST_DISCOVERY"
            ),

            T(
                "FIRST_INSTANCE"
            ),

            T(
                "FIRST_DEATH"
            ),

            T(
                "FIRST_LEVEL"
            )
        }
    end

    local firstItems = {
        {
            item =
                FindFirstMemory(
                    memories,
                    "ZONE"
                ),

            label =
                firstLabels[1]
        },

        {
            item =
                FindFirstMemory(
                    memories,
                    "INSTANCE"
                ),

            label =
                firstLabels[2]
        },

        {
            item =
                FindFirstMemory(
                    memories,
                    "DEATH"
                ),

            label =
                firstLabels[3]
        },

        {
            item =
                FindFirstMemory(
                    memories,
                    "LEVEL"
                ),

            label =
                firstLabels[4]
        }
    }

    local visibleFirstSteps = 0

    for index = 1, 4 do
        local row =
            frame.historyV2Milestones[
                index
            ]

        local first =
            firstItems[index]

        if first.item then
            PositionMilestoneRow(
                row,
                child,
                y,
                first.item,
                first.label
            )

            y =
                y + 58

            visibleFirstSteps =
                visibleFirstSteps + 1
        else
            row:Hide()
        end
    end

    if visibleFirstSteps == 0 then
        frame.historyV2FirstStepsEmpty:ClearAllPoints()

        frame.historyV2FirstStepsEmpty:SetPoint(
            "TOPLEFT",
            child,
            "TOPLEFT",
            8,
            -y
        )

        frame.historyV2FirstStepsEmpty:SetText(
            T(
                "NO_FIRST_STEPS"
            )
        )

        frame.historyV2FirstStepsEmpty:Show()

        y =
            y + 34
    else
        frame.historyV2FirstStepsEmpty:Hide()
    end

    --
    -- Level milestones
    --

    local levelMemories =
        GetLevelMemories(
            memories
        )

    for index = 1, 6 do
        frame.historyV2LevelRows[
            index
        ]:Hide()
    end

    frame.historyV2MoreLevels:Hide()

    if #levelMemories > 1 then
        y =
            y + 12

        frame.historyV2LevelTitle:ClearAllPoints()

        frame.historyV2LevelTitle:SetPoint(
            "TOPLEFT",
            child,
            "TOPLEFT",
            0,
            -y
        )

        frame.historyV2LevelTitle:SetText(
            T(
                "LEVEL_MILESTONES"
            )
        )

        frame.historyV2LevelTitle:Show()

        y =
            y + 27

        local firstIndex =
            math.max(
                2,
                #levelMemories - 5
            )

        local rowIndex = 1

        for index = firstIndex,
            #levelMemories do

            local item =
                levelMemories[index]

            local row =
                frame.historyV2LevelRows[
                    rowIndex
                ]

            if row then
                PositionMilestoneRow(
                    row,
                    child,
                    y,
                    item,
                    T(
                        "LEVEL_MILESTONES"
                    )
                )

                y =
                    y + 58

                rowIndex =
                    rowIndex + 1
            end
        end

        local hiddenLevels =
            math.max(
                (
                    #levelMemories
                    - 1
                )
                    - 6,
                0
            )

        if hiddenLevels > 0 then
            frame.historyV2MoreLevels:ClearAllPoints()

            frame.historyV2MoreLevels:SetPoint(
                "TOPLEFT",
                child,
                "TOPLEFT",
                60,
                -y
            )

            frame.historyV2MoreLevels:SetText(
                T(
                    "MORE_LEVELS",
                    hiddenLevels
                )
            )

            frame.historyV2MoreLevels:Show()

            y =
                y + 28
        end
    else
        frame.historyV2LevelTitle:Hide()
    end

    --
    -- Summary
    --

    y =
        y + 8

    frame.historyV2Divider2:ClearAllPoints()

    frame.historyV2Divider2:SetPoint(
        "TOP",
        child,
        "TOP",
        0,
        -y
    )

    y =
        y + 24

    frame.historyV2SummaryTitle:ClearAllPoints()

    frame.historyV2SummaryTitle:SetPoint(
        "TOPLEFT",
        child,
        "TOPLEFT",
        0,
        -y
    )

    frame.historyV2SummaryTitle:SetText(
        T(
            "SO_FAR"
        )
    )

    y =
        y + 30

    frame.historyV2Summary:ClearAllPoints()

    frame.historyV2Summary:SetPoint(
        "TOPLEFT",
        child,
        "TOPLEFT",
        0,
        -y
    )

    local totalPlayed =
        overview.journey.totalPlayed
        or 0

    local beforePlayed =
        recovered.totalPlayed
        or 0

    local recordedPlayed =
        math.max(
            totalPlayed
                - beforePlayed,
            0
        )

    frame.historyV2SummaryCards[1]
        .value:SetText(
            tostring(
                CountVisitedZones()
            )
        )

    frame.historyV2SummaryCards[2]
        .value:SetText(
            tostring(
                CountUniqueInstances(
                    memories
                )
            )
        )

    frame.historyV2SummaryCards[3]
        .value:SetText(
            tostring(
                CountDeaths(
                    memories
                )
            )
        )

    frame.historyV2SummaryCards[4]
        .value:SetText(
            tostring(
                #memories
            )
        )

    frame.historyV2SummaryCards[5]
        .value:SetText(
            FJ.Utils.FormatPlayedTime(
                recordedPlayed
            )
        )

    y =
        y + 70

    frame.historyV2Footnote:ClearAllPoints()

    frame.historyV2Footnote:SetPoint(
        "TOP",
        child,
        "TOP",
        0,
        -y
    )

    y =
        y + 28

    child:SetHeight(
        math.max(
            y,
            frame.historyV2Scroll:GetHeight()
        )
    )

    local maximum =
        frame.historyV2Scroll
            :GetVerticalScrollRange()
        or 0

    local current =
        frame.historyV2Scroll
            :GetVerticalScroll()

    if current > maximum then
        frame.historyV2Scroll:SetVerticalScroll(
            maximum
        )
    end

    UpdateScrollThumb(
        frame
    )
end

local originalRefresh =
    FJ.UI.Refresh

FJ.UI.Refresh =
    function(...)
        local result =
            originalRefresh(...)

        local frame =
            ForeverJourneyMainFrame

        if frame then
            FJ.HistoryUI.Attach(
                frame
            )

            FJ.HistoryUI.Refresh(
                frame
            )
        end

        return result
    end