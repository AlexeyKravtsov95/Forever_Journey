local addonName, FJ = ...

FJ.ProfessionHistoryExtensions = {}

local Theme =
    FJ.Theme

local Colors =
    Theme.Colors

local locale =
    GetLocale()

local strings = {
    enUS = {
        TITLE =
            "PROFESSION MILESTONES",

        TYPE =
            "PROFESSION",

        MORE =
            "+ %d more profession milestones in the Chronicle"
    },

    ruRU = {
        TITLE =
            "ВЕХИ ПРОФЕССИЙ",

        TYPE =
            "ПРОФЕССИЯ",

        MORE =
            "+ ещё %d профессиональных вех в Хронике"
    }
}

local currentStrings =
    strings[locale]
    or strings.enUS

local function T(
    key,
    ...
)
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

local rows = {}

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

local function GetProfessionMilestones()
    local result = {}

    for _, rawMemory in ipairs(
        FJ.State.memories
        or {}
    ) do
        if type(rawMemory)
                == "table"
            and rawMemory.type
                == "PROFESSION_MILESTONE"
            and rawMemory.source
                ~= "RECOVERED" then

            table.insert(
                result,
                {
                    raw =
                        rawMemory,

                    view =
                        FJ.ViewModel.GetMemory(
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
                local aSkill =
                    a.raw.data
                    and a.raw.data.milestone
                    or 0

                local bSkill =
                    b.raw.data
                    and b.raw.data.milestone
                    or 0

                return (
                    tonumber(aSkill)
                    or 0
                ) < (
                    tonumber(bSkill)
                    or 0
                )
            end

            return aTime < bTime
        end
    )

    return result
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
        58
    )

    row.marker =
        row:CreateTexture(
            nil,
            "ARTWORK"
        )

    row.marker:SetSize(
        32,
        32
    )

    row.marker:SetPoint(
        "TOPLEFT",
        row,
        "TOPLEFT",
        11,
        -9
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

local function EnsureSection(
    frame
)
    local child =
        frame.historyV2ScrollChild

    if not child then
        return
    end

    if not frame
        .historyProfessionMilestoneTitle then

        frame
            .historyProfessionMilestoneTitle =
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
            frame
                .historyProfessionMilestoneTitle,
            Colors.ink
        )
    end

    if not frame
        .historyProfessionMilestoneMore then

        frame
            .historyProfessionMilestoneMore =
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
            frame
                .historyProfessionMilestoneMore,
            Colors.inkMuted
        )
    end

    for index = 1, 6 do
        if not rows[index] then
            rows[index] =
                CreateRow(
                    child
                )
        end
    end
end

local function FormatMemoryMeta(
    item
)
    local result

    if item.raw.timestamp then
        result =
            date(
                "%d.%m.%Y",
                item.raw.timestamp
            )
    else
        result =
            FJ.Locale.Get(
                "UNKNOWN_TIME"
            )
    end

    local location =
        item.view
        and item.view.location

    if location
        and location.name
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

local function RefreshSection(
    frame
)
    EnsureSection(
        frame
    )

    local milestones =
        GetProfessionMilestones()

    frame
        .historyProfessionMilestoneTitle
        :Hide()

    frame
        .historyProfessionMilestoneMore
        :Hide()

    for index = 1, 6 do
        rows[index]:Hide()
    end

    if #milestones == 0 then
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

    local baseY =
        -(dividerY or 0)

    frame
        .historyProfessionMilestoneTitle
        :ClearAllPoints()

    frame
        .historyProfessionMilestoneTitle
        :SetPoint(
            "TOPLEFT",
            child,
            "TOPLEFT",
            0,
            -baseY
        )

    frame
        .historyProfessionMilestoneTitle
        :SetText(
            T("TITLE")
        )

    frame
        .historyProfessionMilestoneTitle
        :Show()

    local visibleCount =
        math.min(
            #milestones,
            6
        )

    local firstIndex =
        math.max(
            #milestones
                - visibleCount
                + 1,
            1
        )

    local y =
        baseY + 27

    local rowIndex =
        1

    for index =
        firstIndex,
        #milestones do

        local item =
            milestones[index]

        local row =
            rows[rowIndex]

        local data =
            item.raw.data
            or {}

        row:ClearAllPoints()

        row:SetPoint(
            "TOPLEFT",
            child,
            "TOPLEFT",
            0,
            -y
        )

        row.marker:SetTexture(
            FJ.ProfessionMilestones
                .GetIcon(
                    data.skillLine,
                    data.professionName
                )
        )

        row.typeLabel:SetText(
            T("TYPE")
        )

        row.title:SetText(
            item.view
            and item.view.title
            or ""
        )

        row.meta:SetText(
            FormatMemoryMeta(
                item
            )
        )

        row:Show()

        y =
            y + 58

        rowIndex =
            rowIndex + 1
    end

    local hiddenCount =
        #milestones
        - visibleCount

    if hiddenCount > 0 then
        frame
            .historyProfessionMilestoneMore
            :ClearAllPoints()

        frame
            .historyProfessionMilestoneMore
            :SetPoint(
                "TOPLEFT",
                child,
                "TOPLEFT",
                60,
                -y
            )

        frame
            .historyProfessionMilestoneMore
            :SetText(
                T(
                    "MORE",
                    hiddenCount
                )
            )

        frame
            .historyProfessionMilestoneMore
            :Show()

        y =
            y + 27
    end

    local insertionHeight =
        (
            y
            - baseY
        )
        + 8

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