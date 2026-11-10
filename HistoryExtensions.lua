local addonName, FJ = ...

FJ.HistoryExtensions = {}

local Theme =
    FJ.Theme

local Colors =
    Theme.Colors

local Textures =
    Theme.Textures

local locale =
    GetLocale()

local ARCHIVE_BOTTOM_GAP =
    16

local strings = {
    enUS = {
        QUEST_MILESTONES =
            "QUEST MILESTONES",

        QUEST_MILESTONE =
            "QUEST MILESTONE",

        MORE_QUEST_MILESTONES =
            "+ %d more quest milestones in the Chronicle"
    },

    ruRU = {
        QUEST_MILESTONES =
            "ВЕХИ ЗАДАНИЙ",

        QUEST_MILESTONE =
            "ВЕХА ЗАДАНИЙ",

        MORE_QUEST_MILESTONES =
            "+ ещё %d вех заданий в Хронике"
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

local PROFESSION_ICON_BY_SKILL_LINE = {
    [164] =
        "Interface\\Icons\\Trade_BlackSmithing",

    [165] =
        "Interface\\Icons\\INV_Misc_ArmorKit_17",

    [171] =
        "Interface\\Icons\\Trade_Alchemy",

    [182] =
        "Interface\\Icons\\Trade_Herbalism",

    [185] =
        "Interface\\Icons\\INV_Misc_Food_15",

    [186] =
        "Interface\\Icons\\Trade_Mining",

    [197] =
        "Interface\\Icons\\Trade_Tailoring",

    [202] =
        "Interface\\Icons\\Trade_Engineering",

    [333] =
        "Interface\\Icons\\Trade_Engraving",

    [356] =
        "Interface\\Icons\\Trade_Fishing",

    [393] =
        "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",

    [755] =
        "Interface\\Icons\\INV_Misc_Gem_01",

    [773] =
        "Interface\\Icons\\INV_Inscription_Tradeskill01",

    [794] =
        "Interface\\Icons\\Trade_Archaeology"
}

local PROFESSION_ICON_BY_NAME = {
    ["Горное дело"] =
        "Interface\\Icons\\Trade_Mining",

    ["Инженерное дело"] =
        "Interface\\Icons\\Trade_Engineering",

    ["Кулинария"] =
        "Interface\\Icons\\INV_Misc_Food_15",

    ["Алхимия"] =
        "Interface\\Icons\\Trade_Alchemy",

    ["Травничество"] =
        "Interface\\Icons\\Trade_Herbalism",

    ["Кузнечное дело"] =
        "Interface\\Icons\\Trade_BlackSmithing",

    ["Кожевничество"] =
        "Interface\\Icons\\INV_Misc_ArmorKit_17",

    ["Наложение чар"] =
        "Interface\\Icons\\Trade_Engraving",

    ["Портняжное дело"] =
        "Interface\\Icons\\Trade_Tailoring",

    ["Снятие шкур"] =
        "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",

    ["Рыбная ловля"] =
        "Interface\\Icons\\Trade_Fishing",

    ["Археология"] =
        "Interface\\Icons\\Trade_Archaeology",

    ["Ювелирное дело"] =
        "Interface\\Icons\\INV_Misc_Gem_01",

    ["Начертание"] =
        "Interface\\Icons\\INV_Inscription_Tradeskill01",

    ["Mining"] =
        "Interface\\Icons\\Trade_Mining",

    ["Engineering"] =
        "Interface\\Icons\\Trade_Engineering",

    ["Cooking"] =
        "Interface\\Icons\\INV_Misc_Food_15",

    ["Alchemy"] =
        "Interface\\Icons\\Trade_Alchemy",

    ["Herbalism"] =
        "Interface\\Icons\\Trade_Herbalism",

    ["Blacksmithing"] =
        "Interface\\Icons\\Trade_BlackSmithing",

    ["Leatherworking"] =
        "Interface\\Icons\\INV_Misc_ArmorKit_17",

    ["Enchanting"] =
        "Interface\\Icons\\Trade_Engraving",

    ["Tailoring"] =
        "Interface\\Icons\\Trade_Tailoring",

    ["Skinning"] =
        "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",

    ["Fishing"] =
        "Interface\\Icons\\Trade_Fishing",

    ["Archaeology"] =
        "Interface\\Icons\\Trade_Archaeology",

    ["Jewelcrafting"] =
        "Interface\\Icons\\INV_Misc_Gem_01",

    ["Inscription"] =
        "Interface\\Icons\\INV_Inscription_Tradeskill01"
}

local questRows = {}

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

local function GetRecoveredHistory()
    if FJ.ViewModel.GetRecoveredHistory then
        return FJ.ViewModel
            .GetRecoveredHistory()
    end

    local recovered =
        FJ.State.recoveredHistory
        or {}

    return {
        initialized =
            recovered.initialized
            == true,

        level =
            recovered.level
            or 0,

        completedQuests =
            recovered.completedQuests
            and recovered
                .completedQuests
                .count
            or 0,

        totalPlayed =
            recovered.played
            and recovered.played.total
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

    if (history.level or 0)
        > 1 then

        return true
    end

    if (history.completedQuests or 0)
        > 0 then

        return true
    end

    if (history.totalPlayed or 0)
        >= 1800 then

        return true
    end

    for _, profession in ipairs(
        history.professions
        or {}
    ) do
        if (profession.skillLevel or 0)
            > 1 then

            return true
        end
    end

    return false
end

local function GetProfessionIcon(
    profession
)
    if not profession then
        return Textures.iconStarted
    end

    if profession.icon
        and profession.icon ~= "" then

        return profession.icon
    end

    local skillLine =
        tonumber(
            profession.skillLine
        )

    if skillLine
        and PROFESSION_ICON_BY_SKILL_LINE[
            skillLine
        ] then

        return PROFESSION_ICON_BY_SKILL_LINE[
            skillLine
        ]
    end

    if profession.name
        and PROFESSION_ICON_BY_NAME[
            profession.name
        ] then

        return PROFESSION_ICON_BY_NAME[
            profession.name
        ]
    end

    return Textures.iconStarted
end

local function EnsureProfessionIcons(
    frame
)
    if not frame.historyV2ProfessionRows then
        return
    end

    local recovered =
        GetRecoveredHistory()

    for index,
        row in ipairs(
            frame.historyV2ProfessionRows
        ) do

        if not row.icon then
            row.icon =
                row:CreateTexture(
                    nil,
                    "ARTWORK"
                )

            row.icon:SetSize(
                18,
                18
            )

            row.icon:SetPoint(
                "LEFT",
                row,
                "LEFT",
                0,
                0
            )

            row.name:ClearAllPoints()

            row.name:SetPoint(
                "LEFT",
                row,
                "LEFT",
                27,
                0
            )

            row.name:SetWidth(
                188
            )
        end

        local profession =
            recovered.professions
            and recovered
                .professions[index]

        if profession
            and row:IsShown() then

            row.icon:SetTexture(
                GetProfessionIcon(
                    profession
                )
            )

            row.icon:Show()
        else
            row.icon:Hide()
        end
    end
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

local function ShiftTableDown(
    regions,
    amount
)
    if not regions then
        return
    end

    for _, region in ipairs(
        regions
    ) do
        if region
            and region:IsShown() then

            ShiftDown(
                region,
                amount
            )
        end
    end
end

local function AddArchiveBottomSpacing(
    frame
)
    local recovered =
        GetRecoveredHistory()

    local meaningful =
        HasMeaningfulRecoveredHistory(
            recovered
        )

    local hasProfessions =
        recovered.professions
        and #recovered.professions
            > 0

    if not meaningful
        or not hasProfessions then

        return
    end

    if frame.historyV2Archive then
        frame.historyV2Archive:SetHeight(
            224
        )
    end

    ShiftDown(
        frame.historyV2Divider1,
        ARCHIVE_BOTTOM_GAP
    )

    ShiftDown(
        frame.historyV2FirstStepsTitle,
        ARCHIVE_BOTTOM_GAP
    )

    ShiftTableDown(
        frame.historyV2Milestones,
        ARCHIVE_BOTTOM_GAP
    )

    if frame.historyV2FirstStepsEmpty
        and frame.historyV2FirstStepsEmpty
            :IsShown() then

        ShiftDown(
            frame.historyV2FirstStepsEmpty,
            ARCHIVE_BOTTOM_GAP
        )
    end

    if frame.historyV2LevelTitle
        and frame.historyV2LevelTitle
            :IsShown() then

        ShiftDown(
            frame.historyV2LevelTitle,
            ARCHIVE_BOTTOM_GAP
        )
    end

    ShiftTableDown(
        frame.historyV2LevelRows,
        ARCHIVE_BOTTOM_GAP
    )

    if frame.historyV2MoreLevels
        and frame.historyV2MoreLevels
            :IsShown() then

        ShiftDown(
            frame.historyV2MoreLevels,
            ARCHIVE_BOTTOM_GAP
        )
    end

    ShiftDown(
        frame.historyV2Divider2,
        ARCHIVE_BOTTOM_GAP
    )

    ShiftDown(
        frame.historyV2SummaryTitle,
        ARCHIVE_BOTTOM_GAP
    )

    ShiftDown(
        frame.historyV2Summary,
        ARCHIVE_BOTTOM_GAP
    )

    ShiftDown(
        frame.historyV2Footnote,
        ARCHIVE_BOTTOM_GAP
    )

    local child =
        frame.historyV2ScrollChild

    if child then
        child:SetHeight(
            child:GetHeight()
                + ARCHIVE_BOTTOM_GAP
        )
    end
end

local function GetQuestMilestones()
    local result = {}

    for _, rawMemory in ipairs(
        FJ.State.memories
        or {}
    ) do
        if type(rawMemory)
                == "table"
            and rawMemory.type
                == "QUEST_MILESTONE"
            and rawMemory.source
                ~= "RECOVERED" then

            table.insert(
                result,
                {
                    raw =
                        rawMemory,

                    view =
                        FJ.ViewModel
                            .GetMemory(
                                rawMemory
                            )
                }
            )
        end
    end

    table.sort(
        result,
        function(a, b)
            local aCount =
                a.raw.data
                and tonumber(
                    a.raw.data.count
                )
                or 0

            local bCount =
                b.raw.data
                and tonumber(
                    b.raw.data.count
                )
                or 0

            if aCount == bCount then
                return (
                    a.raw.timestamp
                    or 0
                ) < (
                    b.raw.timestamp
                    or 0
                )
            end

            return aCount < bCount
        end
    )

    return result
end

local function CreateQuestMilestoneRow(
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

local function EnsureQuestSection(
    frame
)
    local child =
        frame.historyV2ScrollChild

    if not child then
        return
    end

    if not frame.historyQuestMilestoneTitle then
        frame.historyQuestMilestoneTitle =
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
            frame.historyQuestMilestoneTitle,
            Colors.ink
        )
    end

    if not frame.historyQuestMilestoneMore then
        frame.historyQuestMilestoneMore =
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
            frame.historyQuestMilestoneMore,
            Colors.inkMuted
        )
    end

    for index = 1, 6 do
        if not questRows[index] then
            questRows[index] =
                CreateQuestMilestoneRow(
                    child
                )
        end
    end
end

local function FormatMemoryMeta(
    item
)
    local timestamp =
        item.raw.timestamp

    local result

    if timestamp then
        result =
            date(
                "%d.%m.%Y",
                timestamp
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

local function ShiftSummaryForQuestSection(
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

local function RefreshQuestSection(
    frame
)
    EnsureQuestSection(
        frame
    )

    local milestones =
        GetQuestMilestones()

    frame.historyQuestMilestoneTitle:Hide()
    frame.historyQuestMilestoneMore:Hide()

    for index = 1, 6 do
        questRows[index]:Hide()
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

    frame.historyQuestMilestoneTitle:ClearAllPoints()

    frame.historyQuestMilestoneTitle:SetPoint(
        "TOPLEFT",
        child,
        "TOPLEFT",
        0,
        -baseY
    )

    frame.historyQuestMilestoneTitle:SetText(
        T(
            "QUEST_MILESTONES"
        )
    )

    frame.historyQuestMilestoneTitle:Show()

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

    for index = firstIndex,
        #milestones do

        local item =
            milestones[index]

        local row =
            questRows[rowIndex]

        row:ClearAllPoints()

        row:SetPoint(
            "TOPLEFT",
            child,
            "TOPLEFT",
            0,
            -y
        )

        row.marker:SetTexture(
            Textures.iconQuests
        )

        row.typeLabel:SetText(
            T(
                "QUEST_MILESTONE"
            )
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
        frame.historyQuestMilestoneMore:ClearAllPoints()

        frame.historyQuestMilestoneMore:SetPoint(
            "TOPLEFT",
            child,
            "TOPLEFT",
            60,
            -y
        )

        frame.historyQuestMilestoneMore:SetText(
            T(
                "MORE_QUEST_MILESTONES",
                hiddenCount
            )
        )

        frame.historyQuestMilestoneMore:Show()

        y =
            y + 27
    end

    local insertionHeight =
        (
            y
            - baseY
        )
        + 8

    ShiftSummaryForQuestSection(
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

        EnsureProfessionIcons(
            frame
        )

        AddArchiveBottomSpacing(
            frame
        )

        RefreshQuestSection(
            frame
        )
    end