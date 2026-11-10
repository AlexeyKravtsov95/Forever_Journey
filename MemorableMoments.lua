local addonName, FJ = ...

FJ.MemorableMoments = {}

local Theme =
    FJ.Theme

local Colors =
    Theme.Colors

local locale =
    GetLocale()

local MAX_VISIBLE_MOMENTS = 5
local ROW_HEIGHT = 78

local strings = {
    enUS = {
        TITLE =
            "MEMORABLE MOMENTS",

        SUBTITLE =
            "The moments you chose to keep close.",

        EMPTY =
            "Mark a moment with a star in the Chronicle and it will appear here.",

        MORE =
            "+ %d more memorable moments in the Chronicle",

        UNKNOWN =
            "Unknown"
    },

    ruRU = {
        TITLE =
            "ПАМЯТНЫЕ МОМЕНТЫ",

        SUBTITLE =
            "События, которые ты решил сохранить особенно близко.",

        EMPTY =
            "Отметь событие звездой в Хронике — и оно появится здесь.",

        MORE =
            "+ ещё %d памятных моментов в Хронике",

        UNKNOWN =
            "Неизвестно"
    }
}

local currentStrings =
    strings[locale]
    or strings.enUS

local rows = {}

local function T(
    key,
    ...
)
    local value =
        currentStrings[key]
        or strings.enUS[key]
        or key

    if select(
        "#",
        ...
    ) == 0 then

        return value
    end

    local success,
        result = pcall(
            string.format,
            value,
            ...
        )

    if success then
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

local function ShiftDown(
    region,
    amount
)
    if not region then
        return
    end

    local point,
        relativeTo,
        relativePoint,
        x,
        y =
            region:GetPoint(
                1
            )

    if not point then
        return
    end

    region:ClearAllPoints()

    region:SetPoint(
        point,
        relativeTo,
        relativePoint,
        x or 0,
        (y or 0) - amount
    )
end

local function ShiftSummary(
    frame,
    amount
)
    ShiftDown(
        frame.historyV2Divider2,
        amount
    )

    ShiftDown(
        frame.historyV2SummaryTitle,
        amount
    )

    ShiftDown(
        frame.historyV2Summary,
        amount
    )

    ShiftDown(
        frame.historyV2Footnote,
        amount
    )

    local child =
        frame.historyV2ScrollChild

    if child then
        child:SetHeight(
            child:GetHeight()
                + amount
        )
    end
end

local function GetFavoriteMemories()
    local result = {}

    local memories =
        FJ.ViewModel.GetAllMemories
        and FJ.ViewModel.GetAllMemories()
        or {}

    for _, memory in ipairs(
        memories
    ) do
        if type(memory) == "table"
            and memory.favorite == true then

            table.insert(
                result,
                memory
            )
        end
    end

    table.sort(
        result,
        function(a, b)
            local aTime =
                a.timestamp
                or 0

            local bTime =
                b.timestamp
                or 0

            if aTime == bTime then
                return tostring(
                    a.id
                    or ""
                ) < tostring(
                    b.id
                    or ""
                )
            end

            return aTime < bTime
        end
    )

    return result
end

local function GetTypeLabel(
    memory
)
    if not memory then
        return T(
            "UNKNOWN"
        )
    end

    if memory.source == "RECOVERED" then
        return FJ.Locale.Get(
            "MEMORY_TYPE_RECOVERED"
        )
    end

    local semanticType =
        memory.semanticType
        or memory.type

    local keys = {
        LEVEL =
            "MEMORY_TYPE_LEVEL",

        ZONE =
            "MEMORY_TYPE_ZONE",

        INSTANCE =
            "MEMORY_TYPE_INSTANCE",

        DEATH =
            "MEMORY_TYPE_DEATH"
    }

    local key =
        keys[semanticType]

    if key then
        return FJ.Locale.Get(
            key
        )
    end

    return memory.type
        or semanticType
        or T(
            "UNKNOWN"
        )
end

local function FormatMeta(
    memory
)
    local result

    if memory.timestamp then
        result =
            date(
                "%d.%m.%Y, %H:%M",
                memory.timestamp
            )
    else
        result =
            FJ.Locale.Get(
                "UNKNOWN_TIME"
            )
    end

    local location =
        memory.location

    if location
        and location.name
        and location.name ~= ""
        and location.name
            ~= FJ.Locale.Get(
                "UNKNOWN"
            ) then

        result =
            result
            .. " - "
            .. location.name
    end

    return result
end

local function ApplyMarkerLayout(
    row,
    memory
)
    local semanticType =
        memory
        and (
            memory.semanticType
            or memory.type
        )

    local size = 38

    if semanticType
        == "PROFESSION_MILESTONE" then

        size = 32

    elseif semanticType
        == "MANUAL_MEMORY" then

        size = 34
    end

    local inset =
        (38 - size) / 2

    row.marker:ClearAllPoints()

    row.marker:SetSize(
        size,
        size
    )

    row.marker:SetPoint(
        "TOPLEFT",
        row,
        "TOPLEFT",
        8 + inset,
        -7 - inset
    )
end

local function CreateRow(
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
        ROW_HEIGHT
    )

    row.marker =
        row:CreateTexture(
            nil,
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
        -7
    )

    row.favoriteIcon =
        row:CreateTexture(
            nil,
            "ARTWORK"
        )

    if type(
        row.favoriteIcon.SetAtlas
    ) == "function" then

        row.favoriteIcon:SetAtlas(
            "auctionhouse-icon-favorite"
        )
    end

    row.favoriteIcon:SetSize(
        18,
        18
    )

    row.favoriteIcon:SetPoint(
        "TOPRIGHT",
        row,
        "TOPRIGHT",
        -12,
        -2
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
        540
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
        540
    )

    row.meta:SetJustifyH(
        "LEFT"
    )

    Theme.ApplyTextColor(
        row.meta,
        Colors.inkMuted
    )

    row.description =
        CreateText(
            row,
            "GameFontHighlightSmall",
            "TOPLEFT",
            row,
            "TOPLEFT",
            60,
            -58
        )

    row.description:SetWidth(
        540
    )

    row.description:SetJustifyH(
        "LEFT"
    )

    row.description:SetWordWrap(
        false
    )

    Theme.ApplyTextColor(
        row.description,
        Colors.inkMuted
    )

    return row
end

local function EnsureSection(
    frame
)
    if frame.historyMemorableMomentsTitle then
        return
    end

    local child =
        frame.historyV2ScrollChild

    if not child then
        return
    end

    frame.historyMemorableMomentsTitle =
        CreateText(
            child,
            "GameFontNormal",
            "TOPLEFT",
            child,
            "TOPLEFT",
            0,
            0
        )

    Theme.ApplyTextColor(
        frame.historyMemorableMomentsTitle,
        Colors.ink
    )

    frame.historyMemorableMomentsSubtitle =
        CreateText(
            child,
            "GameFontHighlightSmall",
            "TOPLEFT",
            child,
            "TOPLEFT",
            0,
            0
        )

    frame.historyMemorableMomentsSubtitle:SetWidth(
        620
    )

    Theme.ApplyTextColor(
        frame.historyMemorableMomentsSubtitle,
        Colors.inkMuted
    )

    for index = 1,
        MAX_VISIBLE_MOMENTS do

        rows[index] =
            CreateRow(
                child
            )
    end

    frame.historyMemorableMomentsEmpty =
        CreateText(
            child,
            "GameFontHighlightSmall",
            "TOPLEFT",
            child,
            "TOPLEFT",
            8,
            0
        )

    frame.historyMemorableMomentsEmpty:SetWidth(
        620
    )

    Theme.ApplyTextColor(
        frame.historyMemorableMomentsEmpty,
        Colors.inkMuted
    )

    frame.historyMemorableMomentsMore =
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
        frame.historyMemorableMomentsMore,
        Colors.inkMuted
    )
end

local function RefreshSection(
    frame
)
    EnsureSection(
        frame
    )

    if not frame.historyMemorableMomentsTitle then
        return
    end

    local divider =
        frame.historyV2Divider2

    if not divider then
        return
    end

    local point,
        relativeTo,
        relativePoint,
        x,
        dividerY =
            divider:GetPoint(
                1
            )

    if not point then
        return
    end

    local child =
        frame.historyV2ScrollChild

    if not child then
        return
    end

    local baseY =
        -(dividerY or 0)

    local favorites =
        GetFavoriteMemories()

    frame.historyMemorableMomentsTitle:ClearAllPoints()

    frame.historyMemorableMomentsTitle:SetPoint(
        "TOPLEFT",
        child,
        "TOPLEFT",
        0,
        -baseY
    )

    frame.historyMemorableMomentsTitle:SetText(
        T(
            "TITLE"
        )
    )

    frame.historyMemorableMomentsTitle:Show()

    local y =
        baseY + 25

    frame.historyMemorableMomentsSubtitle:ClearAllPoints()

    frame.historyMemorableMomentsSubtitle:SetPoint(
        "TOPLEFT",
        child,
        "TOPLEFT",
        0,
        -y
    )

    frame.historyMemorableMomentsSubtitle:SetText(
        T(
            "SUBTITLE"
        )
    )

    frame.historyMemorableMomentsSubtitle:Show()

    y =
        y + 26

    for index = 1,
        MAX_VISIBLE_MOMENTS do

        rows[index]:Hide()
    end

    frame.historyMemorableMomentsEmpty:Hide()
    frame.historyMemorableMomentsMore:Hide()

    if #favorites == 0 then
        frame.historyMemorableMomentsEmpty:ClearAllPoints()

        frame.historyMemorableMomentsEmpty:SetPoint(
            "TOPLEFT",
            child,
            "TOPLEFT",
            8,
            -y
        )

        frame.historyMemorableMomentsEmpty:SetText(
            T(
                "EMPTY"
            )
        )

        frame.historyMemorableMomentsEmpty:Show()

        y =
            y + 32

    else
        local visibleCount =
            math.min(
                #favorites,
                MAX_VISIBLE_MOMENTS
            )

        local firstIndex =
            math.max(
                #favorites
                    - visibleCount
                    + 1,
                1
            )

        local rowIndex = 1

        for index = firstIndex,
            #favorites do

            local memory =
                favorites[index]

            local row =
                rows[rowIndex]

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
                    memory
                )
            )

            ApplyMarkerLayout(
                row,
                memory
            )

            row.typeLabel:SetText(
                GetTypeLabel(
                    memory
                )
            )

            row.title:SetText(
                memory.title
                or T(
                    "UNKNOWN"
                )
            )

            row.meta:SetText(
                FormatMeta(
                    memory
                )
            )

            row.description:SetText(
                memory.description
                or ""
            )

            row:Show()

            y =
                y + ROW_HEIGHT

            rowIndex =
                rowIndex + 1
        end

        local hiddenCount =
            #favorites
            - visibleCount

        if hiddenCount > 0 then
            frame.historyMemorableMomentsMore:ClearAllPoints()

            frame.historyMemorableMomentsMore:SetPoint(
                "TOPLEFT",
                child,
                "TOPLEFT",
                60,
                -y
            )

            frame.historyMemorableMomentsMore:SetText(
                T(
                    "MORE",
                    hiddenCount
                )
            )

            frame.historyMemorableMomentsMore:Show()

            y =
                y + 27
        end
    end

    local insertionHeight =
        (
            y
            - baseY
        )
        + 10

    ShiftSummary(
        frame,
        insertionHeight
    )
end

local originalRefresh =
    FJ.HistoryUI.Refresh

FJ.HistoryUI.Refresh =
    function(frame)
        originalRefresh(
            frame
        )

        frame =
            frame
            or ForeverJourneyMainFrame

        if not frame
            or not frame.historyV2Page then

            return
        end

        RefreshSection(
            frame
        )
    end