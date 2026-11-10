local addonName, FJ = ...

FJ.UI = {}

local Theme =
    FJ.Theme

local Colors =
    Theme.Colors

local Textures =
    Theme.Textures

local Layout =
    Theme.Window

local Header =
    Theme.Header

local Portrait =
    Theme.Portrait

local mainFrame = nil
local memoryRows = {}
local historyProfessionRows = {}

--
-- Timeline geometry
--
-- Row starts at X = 76
-- Marker LEFT is -48
-- Marker width = 46
--
-- Marker center:
-- 76 - 48 + 23 = 51
--
-- Timeline line width = 2.
-- Because SetPoint uses the LEFT edge of the line,
-- it must begin at 50 to have its center at 51.
--

local TIMELINE_MARKER_CENTER_X = 51
local TIMELINE_LINE_WIDTH = 2
local TIMELINE_LINE_X =
    TIMELINE_MARKER_CENTER_X
    - (TIMELINE_LINE_WIDTH / 2)

local PROFESSION_ICON_BY_NAME = {
    -- ruRU
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

    ["Первая помощь"] =
        "Interface\\Icons\\Spell_Holy_SealOfSacrifice",

    -- enUS
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

    ["First Aid"] =
        "Interface\\Icons\\Spell_Holy_SealOfSacrifice"
}

local function L(key)
    return FJ.Locale.Get(key)
end

local function CreateText(
    parent,
    fontObject,
    anchorPoint,
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
        anchorPoint,
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

local function RefreshPlayerPortrait(
    texture
)
    if type(SetPortraitTexture)
        ~= "function" then

        return
    end

    SetPortraitTexture(
        texture,
        "player"
    )

    texture:SetTexCoord(
        0.09,
        0.91,
        0.09,
        0.91
    )
end

local function GetMemoryTypeLabel(
    memory
)
    if memory.source == "RECOVERED" then
        return L(
            "MEMORY_TYPE_RECOVERED"
        )
    end

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
        keys[memory.type]

    if not key then
        return memory.type
            or L("UNKNOWN")
    end

    return L(key)
end

local function GetProfessionIconTexture(
    profession
)
    if not profession then
        return Textures.iconStarted
    end

    if profession.icon
        and profession.icon ~= "" then

        return profession.icon
    end

    if profession.texture
        and profession.texture ~= "" then

        return profession.texture
    end

    local name =
        profession.name

    if name then
        local mappedIcon =
            PROFESSION_ICON_BY_NAME[name]

        if mappedIcon then
            return mappedIcon
        end
    end

    return Textures.iconStarted
end

local function CreateStatRow(
    parent,
    iconTexture,
    label,
    y
)
    local icon =
        CreateTexture(
            parent,
            iconTexture,
            "ARTWORK"
        )

    icon:SetSize(
        22,
        22
    )

    icon:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        34,
        y + 4
    )

    local labelText =
        CreateText(
            parent,
            "GameFontNormalSmall",
            "TOPLEFT",
            parent,
            "TOPLEFT",
            66,
            y
        )

    labelText:SetText(
        label
    )

    Theme.ApplyTextColor(
        labelText,
        Colors.inkMuted
    )

    local valueText =
        CreateText(
            parent,
            "GameFontHighlight",
            "TOPRIGHT",
            parent,
            "TOPRIGHT",
            -26,
            y
        )

    valueText:SetJustifyH(
        "RIGHT"
    )

    Theme.ApplyTextColor(
        valueText,
        Colors.ink
    )

    return valueText
end

local function CreateDivider(
    parent,
    y
)
    local divider =
        CreateTexture(
            parent,
            Textures.dividerHorizontal
        )

    divider:SetSize(
        278,
        12
    )

    divider:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        28,
        y
    )

    return divider
end

local function CreateMemoryRow(
    parent,
    index
)
    local row =
        CreateFrame(
            "Frame",
            nil,
            parent
        )

    row:SetSize(
        350,
        66
    )

    row:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        76,
        -78
            - (
                (index - 1)
                * Layout.timelineRowHeight
            )
    )

    row.marker =
        CreateTexture(
            row,
            Textures.markerGeneric,
            "ARTWORK"
        )

    row.marker:SetSize(
        46,
        46
    )

    row.marker:SetPoint(
        "LEFT",
        row,
        "LEFT",
        -48,
        3
    )

    row.typeLabel =
        CreateText(
            row,
            "GameFontNormalSmall",
            "TOPLEFT",
            row,
            "TOPLEFT",
            4,
            0
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
            4,
            -19
        )

    row.title:SetWidth(
        330
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
            4,
            -42
        )

    row.meta:SetWidth(
        330
    )

    row.meta:SetJustifyH(
        "LEFT"
    )

    Theme.ApplyTextColor(
        row.meta,
        Colors.inkMuted
    )

    -- A manual diary entry can be opened directly from Recent Journey.
    -- Reuse the reader owned by ChronicleUI; no second modal is needed.
    row.readButton =
        CreateFrame(
            "Button",
            nil,
            row
        )

    row.readButton:SetAllPoints(
        row
    )

    row.readButton:SetScript(
        "OnClick",
        function()
            local memory = row.memoryView

            if not memory
                or not FJ.ChronicleUI
                or type(FJ.ChronicleUI.OpenMemoryReader) ~= "function" then

                return
            end

            FJ.ChronicleUI.OpenMemoryReader(
                mainFrame,
                memory
            )
        end
    )

    row.readButton:SetScript(
        "OnEnter",
        function(self)
            if not row.memoryView then
                return
            end

            Theme.ApplyTextColor(
                row.title,
                Colors.gold
            )

            if GameTooltip then
                GameTooltip:SetOwner(
                    self,
                    "ANCHOR_RIGHT"
                )

                GameTooltip:SetText(
                    (GetLocale and GetLocale() == "ruRU")
                        and "Нажмите, чтобы прочитать запись"
                        or "Click to read entry"
                )

                GameTooltip:Show()
            end
        end
    )

    row.readButton:SetScript(
        "OnLeave",
        function()
            Theme.ApplyTextColor(
                row.title,
                Colors.ink
            )

            if GameTooltip then
                GameTooltip:Hide()
            end
        end
    )

    row.readButton:Hide()

    memoryRows[index] =
        row

    return row
end

local function CreateTab(
    parent,
    label,
    iconTexture,
    iconSize,
    x,
    active
)
    local button =
        CreateFrame(
            "Button",
            nil,
            parent
        )

    button:SetSize(
        240,
        64
    )

    button:SetPoint(
        "BOTTOMLEFT",
        parent,
        "BOTTOMLEFT",
        x,
        17
    )

    button.background =
        CreateTexture(
            button,
            active
                and Textures.tabActive
                or Textures.tabInactive,
            "BACKGROUND"
        )

    button.background:SetAllPoints()

    button.icon =
        CreateTexture(
            button,
            iconTexture,
            "ARTWORK"
        )

    button.icon:SetSize(
        iconSize,
        iconSize
    )

    button.icon:SetPoint(
        "CENTER",
        button,
        "CENTER",
        -47,
        0
    )

    button.label =
        button:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormal"
        )

    button.label:SetPoint(
        "LEFT",
        button.icon,
        "RIGHT",
        12,
        0
    )

    button.label:SetText(
        label
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

    return button
end

local function SetTabActive(
    button,
    active
)
    if not button then
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

local function ShowPage(
    frame,
    page
)
    frame.currentPage =
        page

    if page == "HISTORY" then
        frame.content:Hide()
        frame.historyPage:Show()

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
    else
        frame.historyPage:Hide()
        frame.content:Show()

        SetTabActive(
            frame.overviewButton,
            true
        )

        SetTabActive(
            frame.timelineButton,
            false
        )

        SetTabActive(
            frame.historyButton,
            false
        )
    end
end

local function CreatePortrait(
    parent,
    ownerFrame
)
    local container =
        CreateFrame(
            "Frame",
            nil,
            parent
        )

    container:SetSize(
        108,
        108
    )

    container:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        23,
        -18
    )

    ownerFrame.portraitContainer =
        container

    local portrait =
        container:CreateTexture(
            nil,
            "ARTWORK"
        )

    portrait:SetSize(
        86,
        86
    )

    portrait:SetPoint(
        "CENTER",
        container,
        "CENTER",
        0,
        0
    )

    RefreshPlayerPortrait(
        portrait
    )

    ownerFrame.characterPortrait =
        portrait

    local border =
        CreateTexture(
            container,
            Textures.portraitFrame,
            "OVERLAY"
        )

    border:SetSize(
        108,
        108
    )

    border:SetPoint(
        "CENTER",
        container,
        "CENTER",
        0,
        0
    )

    ownerFrame.portraitFrame =
        border
end

local function CreateHistoryDivider(
    parent,
    y,
    width
)
    local divider =
        CreateTexture(
            parent,
            Textures.dividerHorizontal,
            "ARTWORK"
        )

    divider:SetSize(
        width or 600,
        12
    )

    divider:SetPoint(
        "TOP",
        parent,
        "TOP",
        0,
        y
    )

    return divider
end

local function CreateHistorySummaryColumn(
    parent,
    x,
    valueY,
    label
)
    local column =
        CreateFrame(
            "Frame",
            nil,
            parent
        )

    column:SetSize(
        190,
        54
    )

    column:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        x,
        valueY
    )

    column.value =
        CreateText(
            column,
            "GameFontNormalLarge",
            "TOP",
            column,
            "TOP",
            0,
            0
        )

    column.value:SetWidth(
        190
    )

    column.value:SetJustifyH(
        "CENTER"
    )

    Theme.ApplyTextColor(
        column.value,
        Colors.ink
    )

    column.label =
        CreateText(
            column,
            "GameFontHighlightSmall",
            "TOP",
            column.value,
            "BOTTOM",
            0,
            -6
        )

    column.label:SetWidth(
        190
    )

    column.label:SetJustifyH(
        "CENTER"
    )

    column.label:SetText(
        label
    )

    Theme.ApplyTextColor(
        column.label,
        Colors.inkMuted
    )

    return column.value
end

local function CreateHistoryStatRow(
    parent,
    iconTexture,
    label,
    y
)
    local icon =
        CreateTexture(
            parent,
            iconTexture,
            "ARTWORK"
        )

    icon:SetSize(
        24,
        24
    )

    icon:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        42,
        y + 4
    )

    local labelText =
        CreateText(
            parent,
            "GameFontNormalSmall",
            "TOPLEFT",
            parent,
            "TOPLEFT",
            78,
            y
        )

    labelText:SetText(
        label
    )

    Theme.ApplyTextColor(
        labelText,
        Colors.inkMuted
    )

    local valueText =
        CreateText(
            parent,
            "GameFontHighlight",
            "TOPRIGHT",
            parent,
            "TOPLEFT",
            350,
            y
        )

    valueText:SetJustifyH(
        "RIGHT"
    )

    Theme.ApplyTextColor(
        valueText,
        Colors.ink
    )

    return valueText
end

local function CreateHistoryPage(
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

    frame.historyPage =
        page

    frame.historyTitle =
        CreateText(
            page,
            "GameFontNormalLarge",
            "TOPLEFT",
            page,
            "TOPLEFT",
            38,
            -8
        )

    frame.historyTitle:SetText(
        L("HISTORY_BEFORE_RECORDING")
    )

    Theme.ApplyTextColor(
        frame.historyTitle,
        Colors.ink
    )

    frame.historySubtitle =
        CreateText(
            page,
            "GameFontHighlightSmall",
            "TOPLEFT",
            frame.historyTitle,
            "BOTTOMLEFT",
            0,
            -6
        )

    frame.historySubtitle:SetWidth(
        710
    )

    frame.historySubtitle:SetJustifyH(
        "LEFT"
    )

    frame.historySubtitle:SetText(
        L(
            "HISTORY_BEFORE_RECORDING_SUBTITLE"
        )
    )

    Theme.ApplyTextColor(
        frame.historySubtitle,
        Colors.inkMuted
    )

    local details =
        CreateFrame(
            "Frame",
            nil,
            page
        )

    details:SetAllPoints(
        page
    )

    frame.historyDetails =
        details

    --
    -- Archival entry
    --

    frame.historyRecoveredMarker =
        CreateTexture(
            details,
            Textures.markerRecovered,
            "ARTWORK"
        )

    frame.historyRecoveredMarker:SetSize(
        48,
        48
    )

    frame.historyRecoveredMarker:SetPoint(
        "TOPLEFT",
        details,
        "TOPLEFT",
        40,
        -66
    )

    frame.historySnapshotTitle =
        CreateText(
            details,
            "GameFontNormal",
            "TOPLEFT",
            details,
            "TOPLEFT",
            102,
            -67
        )

    frame.historySnapshotTitle:SetText(
        L("RECOVERED_SNAPSHOT")
    )

    Theme.ApplyTextColor(
        frame.historySnapshotTitle,
        Colors.recovered
    )

    frame.historyCapturedAt =
        CreateText(
            details,
            "GameFontHighlightSmall",
            "TOPLEFT",
            details,
            "TOPLEFT",
            102,
            -91
        )

    Theme.ApplyTextColor(
        frame.historyCapturedAt,
        Colors.inkMuted
    )

    CreateHistoryDivider(
        details,
        -121,
        600
    )

    --
    -- Recovered data columns
    --

    frame.historyCharacterTitle =
        CreateText(
            details,
            "GameFontNormal",
            "TOPLEFT",
            details,
            "TOPLEFT",
            40,
            -143
        )

    frame.historyCharacterTitle:SetText(
        L("RECOVERED_CHARACTER")
    )

    Theme.ApplyTextColor(
        frame.historyCharacterTitle,
        Colors.ink
    )

    frame.historyLevelValue =
        CreateHistoryStatRow(
            details,
            Textures.markerLevel,
            L("RECOVERED_LEVEL"),
            -174
        )

    frame.historyPlayedValue =
        CreateHistoryStatRow(
            details,
            Textures.iconTime,
            L("RECOVERED_TIME_PLAYED"),
            -208
        )

    frame.historyQuestsValue =
        CreateHistoryStatRow(
            details,
            Textures.iconQuests,
            L("RECOVERED_QUESTS"),
            -242
        )

    frame.historyMoneyValue =
        CreateHistoryStatRow(
            details,
            Textures.iconMoney,
            L("RECOVERED_MONEY"),
            -276
        )

    frame.historyProfessionsTitle =
        CreateText(
            details,
            "GameFontNormal",
            "TOPLEFT",
            details,
            "TOPLEFT",
            425,
            -143
        )

    frame.historyProfessionsTitle:SetText(
        L("RECOVERED_PROFESSIONS")
    )

    Theme.ApplyTextColor(
        frame.historyProfessionsTitle,
        Colors.ink
    )

    historyProfessionRows = {}

    for index = 1, 5 do
        local row =
            CreateFrame(
                "Frame",
                nil,
                details
            )

        row:SetSize(
            320,
            24
        )

        row:SetPoint(
            "TOPLEFT",
            details,
            "TOPLEFT",
            425,
            -174
                - ((index - 1) * 28)
        )

        row.icon =
            CreateTexture(
                row,
                Textures.iconStarted,
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

        row.name =
            CreateText(
                row,
                "GameFontHighlightSmall",
                "LEFT",
                row,
                "LEFT",
                30,
                0
            )

        row.name:SetWidth(
            190
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

        historyProfessionRows[index] =
            row
    end

    frame.historyNoProfessions =
        CreateText(
            details,
            "GameFontHighlightSmall",
            "TOPLEFT",
            details,
            "TOPLEFT",
            425,
            -177
        )

    frame.historyNoProfessions:SetWidth(
        310
    )

    frame.historyNoProfessions:SetText(
        L("RECOVERED_NO_PROFESSIONS")
    )

    Theme.ApplyTextColor(
        frame.historyNoProfessions,
        Colors.inkMuted
    )

    --
    -- Summary of what can be stated with confidence.
    --

    CreateHistoryDivider(
        details,
        -316,
        600
    )

    frame.historyKnownPastTitle =
        CreateText(
            details,
            "GameFontNormal",
            "TOP",
            details,
            "TOP",
            0,
            -335
        )

    frame.historyKnownPastTitle:SetText(
        L("RECOVERED_KNOWN_PAST")
    )

    Theme.ApplyTextColor(
        frame.historyKnownPastTitle,
        Colors.ink
    )

    frame.historySummaryLevel =
        CreateHistorySummaryColumn(
            details,
            55,
            -357,
            L("RECOVERED_SUMMARY_LEVEL")
        )

    frame.historySummaryQuests =
        CreateHistorySummaryColumn(
            details,
            300,
            -357,
            L("RECOVERED_SUMMARY_QUESTS")
        )

    frame.historySummaryPlayed =
        CreateHistorySummaryColumn(
            details,
            545,
            -357,
            L("RECOVERED_SUMMARY_PLAYED")
        )

    frame.historyFootnote =
        CreateText(
            details,
            "GameFontHighlightSmall",
            "TOP",
            details,
            "TOP",
            0,
            -414
        )

    frame.historyFootnote:SetWidth(
        710
    )

    frame.historyFootnote:SetJustifyH(
        "CENTER"
    )

    frame.historyFootnote:SetText(
        L("RECOVERED_FOOTNOTE")
    )

    Theme.ApplyTextColor(
        frame.historyFootnote,
        Colors.recovered
    )

    frame.historyEmptyText =
        CreateText(
            page,
            "GameFontHighlight",
            "CENTER",
            page,
            "CENTER",
            0,
            -15
        )

    frame.historyEmptyText:SetText(
        L("RECOVERED_EMPTY")
    )

    Theme.ApplyTextColor(
        frame.historyEmptyText,
        Colors.inkMuted
    )

    page:Hide()
end

local function CreateMainFrame()
    if mainFrame then
        return mainFrame
    end

    local frame =
        CreateFrame(
            "Frame",
            "ForeverJourneyMainFrame",
            UIParent
        )

    frame:SetSize(
        Layout.width,
        Layout.height
    )

    frame:SetPoint(
        "CENTER"
    )

    frame:SetFrameStrata(
        "DIALOG"
    )

    frame:SetMovable(
        true
    )

    frame:EnableMouse(
        true
    )

    frame:RegisterForDrag(
        "LeftButton"
    )

    frame:SetScript(
        "OnDragStart",
        function(self)
            self:StartMoving()
        end
    )

    frame:SetScript(
        "OnDragStop",
        function(self)
            self:StopMovingOrSizing()
        end
    )

    frame:SetClampedToScreen(
        true
    )

    --
    -- Parchment backing
    --

    frame.parchmentBacking =
        frame:CreateTexture(
            nil,
            "BACKGROUND"
        )

    frame.parchmentBacking:SetSize(
        Layout.parchmentWidth + 10,
        Layout.parchmentHeight + 10
    )

    frame.parchmentBacking:SetPoint(
        "CENTER",
        frame,
        "CENTER",
        0,
        0
    )

    Theme.ApplyColor(
        frame.parchmentBacking,
        Colors.parchmentFallback
    )

    --
    -- Parchment
    --

    frame.parchment =
        CreateTexture(
            frame,
            Textures.parchment,
            "BACKGROUND"
        )

    frame.parchment:SetSize(
        Layout.parchmentWidth,
        Layout.parchmentHeight
    )

    frame.parchment:SetPoint(
        "CENTER",
        frame,
        "CENTER",
        0,
        0
    )

    --
    -- Main journal frame
    --

    frame.journalFrame =
        CreateTexture(
            frame,
            Textures.journalFrame,
            "BORDER"
        )

    frame.journalFrame:SetAllPoints(
        frame
    )

    --
    -- Compass is the only header branding.
    --

    frame.compass =
        CreateTexture(
            frame,
            Textures.compass,
            "OVERLAY"
        )

    frame.compass:SetSize(
        Header.compassWidth,
        Header.compassHeight
    )

    frame.compass:SetPoint(
        "TOP",
        frame,
        "TOP",
        0,
        -1
    )

    --
    -- Close
    --

    local closeButton =
        CreateFrame(
            "Button",
            nil,
            frame
        )

    closeButton:SetSize(
        32,
        32
    )

    closeButton:SetPoint(
        "TOPRIGHT",
        frame,
        "TOPRIGHT",
        -27,
        -24
    )

    local closeText =
        closeButton:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalLarge"
        )

    closeText:SetPoint(
        "CENTER"
    )

    closeText:SetText(
        "X"
    )

    closeText:SetTextColor(
        0.90,
        0.70,
        0.36,
        1
    )

    closeButton:SetScript(
        "OnClick",
        function()
            frame:Hide()
        end
    )

    --
    -- Content
    --

    local content =
        CreateFrame(
            "Frame",
            nil,
            frame
        )

    content:SetSize(
        Layout.contentWidth,
        Layout.contentHeight
    )

    content:SetPoint(
        "TOP",
        frame,
        "TOP",
        0,
        -106
    )

    frame.content =
        content

    --
    -- LEFT COLUMN
    --

    local leftPanel =
        CreateFrame(
            "Frame",
            nil,
            content
        )

    leftPanel:SetSize(
        Layout.leftColumnWidth,
        Layout.contentHeight
    )

    leftPanel:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        0,
        0
    )

    frame.leftPanel =
        leftPanel

    CreatePortrait(
        leftPanel,
        frame
    )

    --
    -- Character
    --

    frame.characterName =
        CreateText(
            leftPanel,
            "GameFontNormalLarge",
            "TOPLEFT",
            leftPanel,
            "TOPLEFT",
            148,
            -23
        )

    Theme.ApplyTextColor(
        frame.characterName,
        Colors.ink
    )

    frame.characterInfo =
        CreateText(
            leftPanel,
            "GameFontHighlightSmall",
            "TOPLEFT",
            frame.characterName,
            "BOTTOMLEFT",
            0,
            -5
        )

    Theme.ApplyTextColor(
        frame.characterInfo,
        Colors.inkMuted
    )

    --
    -- Level
    --

    frame.levelBadge =
        CreateTexture(
            leftPanel,
            Textures.levelBadge,
            "ARTWORK"
        )

    frame.levelBadge:SetSize(
        62,
        62
    )

    frame.levelBadge:SetPoint(
        "TOPLEFT",
        leftPanel,
        "TOPLEFT",
        146,
        -69
    )

    frame.levelValue =
        CreateText(
            leftPanel,
            "GameFontNormalLarge",
            "CENTER",
            frame.levelBadge,
            "CENTER",
            0,
            0
        )

    frame.levelValue:SetTextColor(
        1.00,
        0.84,
        0.48,
        1
    )

    frame.levelValue:SetShadowColor(
        0.08,
        0.04,
        0.01,
        1
    )

    frame.levelValue:SetShadowOffset(
        1,
        -1
    )

    frame.levelLabel =
        CreateText(
            leftPanel,
            "GameFontNormalSmall",
            "LEFT",
            frame.levelBadge,
            "RIGHT",
            12,
            0
        )

    frame.levelLabel:SetText(
        L("LEVEL")
    )

    Theme.ApplyTextColor(
        frame.levelLabel,
        Colors.ink
    )

    --
    -- Character divider
    --

    CreateDivider(
        leftPanel,
        -141
    )

    --
    -- Journey summary
    --

    frame.summaryTitle =
        CreateText(
            leftPanel,
            "GameFontNormal",
            "TOPLEFT",
            leftPanel,
            "TOPLEFT",
            28,
            -163
        )

    frame.summaryTitle:SetText(
        L("JOURNEY_SO_FAR")
    )

    Theme.ApplyTextColor(
        frame.summaryTitle,
        Colors.ink
    )

    --
    -- Stats
    --

    frame.playedValue =
        CreateStatRow(
            leftPanel,
            Textures.iconTime,
            L("TIME_PLAYED"),
            -200
        )

    frame.questsValue =
        CreateStatRow(
            leftPanel,
            Textures.iconQuests,
            L("QUESTS"),
            -237
        )

    frame.moneyValue =
        CreateStatRow(
            leftPanel,
            Textures.iconMoney,
            L("MONEY"),
            -274
        )

    frame.deathsValue =
        CreateStatRow(
            leftPanel,
            Textures.iconDeaths,
            L("DEATHS"),
            -311
        )

    frame.memoriesValue =
        CreateStatRow(
            leftPanel,
            Textures.iconMemories,
            L("MEMORIES"),
            -348
        )

        --
    -- Chronicle began
    --

    CreateDivider(
        leftPanel,
        -375
    )

    frame.startedRow =
        CreateFrame(
            "Frame",
            nil,
            leftPanel
        )

    frame.startedRow:SetSize(
        330,
        22
    )

    frame.startedRow:SetPoint(
        "TOPLEFT",
        leftPanel,
        "TOPLEFT",
        34,
        -408
    )

    frame.startedIcon =
        CreateTexture(
            frame.startedRow,
            Textures.iconStarted,
            "ARTWORK"
        )

    frame.startedIcon:SetSize(
        22,
        22
    )

    frame.startedIcon:SetPoint(
        "LEFT",
        frame.startedRow,
        "LEFT",
        0,
        0
    )

    frame.startedTitle =
        CreateText(
            frame.startedRow,
            "GameFontNormalSmall",
            "LEFT",
            frame.startedIcon,
            "RIGHT",
            10,
            0
        )

    frame.startedTitle:SetText(
        L("RECORDING_STARTED")
    )

    Theme.ApplyTextColor(
        frame.startedTitle,
        Colors.inkMuted
    )

    frame.startedValue =
        CreateText(
            frame.startedRow,
            "GameFontHighlightSmall",
            "RIGHT",
            frame.startedRow,
            "RIGHT",
            0,
            0
        )

    frame.startedValue:SetJustifyH(
        "RIGHT"
    )

    Theme.ApplyTextColor(
        frame.startedValue,
        Colors.ink
    )

    --
    -- RIGHT COLUMN
    --

    local rightPanel =
        CreateFrame(
            "Frame",
            nil,
            content
        )

    rightPanel:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        Layout.leftColumnWidth
            + Layout.columnGap,
        0
    )

    rightPanel:SetPoint(
        "BOTTOMRIGHT",
        content,
        "BOTTOMRIGHT",
        0,
        0
    )

    frame.rightPanel =
        rightPanel

    frame.recentTitle =
        CreateText(
            rightPanel,
            "GameFontNormal",
            "TOPLEFT",
            rightPanel,
            "TOPLEFT",
            20,
            -10
        )

    frame.recentTitle:SetText(
        L("RECENT_JOURNEY")
    )

    Theme.ApplyTextColor(
        frame.recentTitle,
        Colors.ink
    )

    frame.recentSubtitle =
        CreateText(
            rightPanel,
            "GameFontHighlightSmall",
            "TOPLEFT",
            frame.recentTitle,
            "BOTTOMLEFT",
            0,
            -5
        )

    frame.recentSubtitle:SetText(
        L("RECENT_JOURNEY_SUBTITLE")
    )

    Theme.ApplyTextColor(
        frame.recentSubtitle,
        Colors.inkMuted
    )

    --
    -- Timeline
    --

    frame.timelineLine =
        rightPanel:CreateTexture(
            nil,
            "ARTWORK"
        )

    frame.timelineLine:SetWidth(
        TIMELINE_LINE_WIDTH
    )

    frame.timelineLine:SetColorTexture(
        Colors.timeline.r,
        Colors.timeline.g,
        Colors.timeline.b,
        Colors.timeline.a
    )

    frame.timelineLine:SetPoint(
        "TOPLEFT",
        rightPanel,
        "TOPLEFT",
        TIMELINE_LINE_X,
        -101
    )

    for index = 1,
        Layout.maxOverviewMemories do

        CreateMemoryRow(
            rightPanel,
            index
        )
    end

    frame.emptyJourneyText =
        CreateText(
            rightPanel,
            "GameFontHighlight",
            "CENTER",
            rightPanel,
            "CENTER",
            15,
            -5
        )

    frame.emptyJourneyText:SetText(
        L("EMPTY_JOURNEY")
    )

    Theme.ApplyTextColor(
        frame.emptyJourneyText,
        Colors.inkMuted
    )

    CreateHistoryPage(
        frame
    )

    --
    -- Tabs
    --

    frame.overviewButton =
        CreateTab(
            frame,
            L("OVERVIEW"),
            Textures.iconMemories,
            22,
            86,
            true
        )

    frame.timelineButton =
        CreateTab(
            frame,
            L("TIMELINE"),
            Textures.iconQuests,
            22,
            340,
            false
        )

    frame.historyButton =
        CreateTab(
            frame,
            L("HISTORY"),
            Textures.markerRecovered,
            27,
            594,
            false
        )

    frame.overviewButton:SetScript(
        "OnClick",
        function()
            ShowPage(
                frame,
                "OVERVIEW"
            )
        end
    )

    frame.historyButton:SetScript(
        "OnClick",
        function()
            FJ.UI.Refresh()

            ShowPage(
                frame,
                "HISTORY"
            )
        end
    )

    ShowPage(
        frame,
        "OVERVIEW"
    )

    mainFrame =
        frame

    frame:Hide()

    return frame
end

local function RefreshMemoryRows()
    local memories =
        FJ.ViewModel.GetRecentMemories(
            Layout.maxOverviewMemories
        )

    local memoryCount =
        #memories

    if memoryCount == 0 then
        mainFrame.emptyJourneyText:Show()
        mainFrame.timelineLine:Hide()
    else
        mainFrame.emptyJourneyText:Hide()

        if memoryCount >= 2 then
            mainFrame.timelineLine:Show()

            mainFrame.timelineLine:SetHeight(
                (memoryCount - 1)
                    * Layout.timelineRowHeight
            )
        else
            mainFrame.timelineLine:Hide()
        end
    end

    for index = 1,
        Layout.maxOverviewMemories do

        local row =
            memoryRows[index]

        local memory =
            memories[index]

        if memory then
            row:Show()

                        row.marker:SetTexture(
                Theme.GetMarkerTexture(
                    memory
                )
            )

            row.marker:ClearAllPoints()

            if memory.semanticType
                == "PROFESSION_MILESTONE" then

                row.marker:SetSize(
                    32,
                    32
                )

                row.marker:SetPoint(
                    "CENTER",
                    row,
                    "LEFT",
                    -25,
                    3
                )
            else
                row.marker:SetSize(
                    46,
                    46
                )

                row.marker:SetPoint(
                    "CENTER",
                    row,
                    "LEFT",
                    -25,
                    3
                )
            end

            row.typeLabel:SetText(
                GetMemoryTypeLabel(
                    memory
                )
            )

            row.title:SetText(
                memory.title
            )

            -- The row is reused for newer memories on refresh.
            -- Never leave a clickable hit area on automatic events.
            Theme.ApplyTextColor(
                row.title,
                Colors.ink
            )

            if memory.semanticType == "MANUAL_MEMORY"
                and memory.source == "USER" then

                row.memoryView = memory
                row.readButton:Show()
            else
                row.memoryView = nil
                row.readButton:Hide()
            end

            local locationName =
                memory.location
                and FJ.Utils.GetLocalizedLocationName(memory.location)
                or L("UNKNOWN")

            local timestamp =
                memory.timestamp
                and date(
                    "%d.%m %H:%M",
                    memory.timestamp
                )
                or L("UNKNOWN_TIME")

            row.meta:SetText(
                timestamp
                    .. "   -   "
                    .. locationName
            )
        else
            row.memoryView = nil
            row.readButton:Hide()
            row:Hide()
        end
    end
end

local function RefreshRecoveredHistory()
    local history =
        FJ.ViewModel.GetRecoveredHistory()

    if not history.initialized then
        mainFrame.historyDetails:Hide()
        mainFrame.historyEmptyText:Show()

        return
    end

    mainFrame.historyEmptyText:Hide()
    mainFrame.historyDetails:Show()

    mainFrame.historyCapturedAt:SetText(
        FJ.Locale.Format(
            "RECOVERED_CAPTURED_AT",
            FJ.Utils.FormatDate(
                history.capturedAt
            )
        )
    )

    local levelText =
        tostring(
            history.level
        )

    local playedText =
        FJ.Utils.FormatPlayedTime(
            history.totalPlayed
        )

    local questsText =
        tostring(
            history.completedQuests
        )

    mainFrame.historyLevelValue:SetText(
        levelText
    )

    mainFrame.historyPlayedValue:SetText(
        playedText
    )

    mainFrame.historyQuestsValue:SetText(
        questsText
    )

    mainFrame.historyMoneyValue:SetText(
        FJ.Utils.FormatMoney(
            history.money
        )
    )

    mainFrame.historySummaryLevel:SetText(
        levelText
    )

    mainFrame.historySummaryQuests:SetText(
        questsText
    )

    mainFrame.historySummaryPlayed:SetText(
        playedText
    )

    local professionCount =
        #history.professions

    if professionCount == 0 then
        mainFrame.historyNoProfessions:Show()
    else
        mainFrame.historyNoProfessions:Hide()
    end

    for index = 1, 5 do
        local row =
            historyProfessionRows[index]

        local profession =
            history.professions[index]

        if profession then
            row:Show()

            row.icon:SetTexture(
                GetProfessionIconTexture(
                    profession
                )
            )

            row.name:SetText(
                FJ.Utils.GetLocalizedProfessionName(
                    profession
                )
                or L("UNKNOWN")
            )

            row.value:SetText(
                tostring(
                    profession.skillLevel
                )
                    .. "/"
                    .. tostring(
                        profession.maxSkillLevel
                    )
            )
        else
            row:Hide()
        end
    end
end

function FJ.UI.Refresh()
    local frame =
        CreateMainFrame()

    local overview =
        FJ.ViewModel.GetOverview()

    frame.characterName:SetText(
        overview.character.name
    )

    frame.characterInfo:SetText(
        overview.character.race
            .. " "
            .. overview.character.class
    )

    frame.levelValue:SetText(
        tostring(
            overview.character.level
        )
    )

    frame.playedValue:SetText(
        FJ.Utils.FormatPlayedTime(
            overview.journey.totalPlayed
        )
    )

    frame.questsValue:SetText(
        tostring(
            overview.journey.completedQuests
        )
    )

    frame.moneyValue:SetText(
        FJ.Utils.FormatMoney(
            overview.journey.currentMoney
        )
    )

    frame.deathsValue:SetText(
        tostring(
            overview.journey.deaths
        )
    )

    frame.memoriesValue:SetText(
        tostring(
            overview.journey.memories
        )
    )

    frame.startedValue:SetText(
        FJ.Utils.FormatDate(
            overview.journey
                .recordingStartedAt
        )
    )

    RefreshPlayerPortrait(
        frame.characterPortrait
    )

    RefreshMemoryRows()
    RefreshRecoveredHistory()
end

function FJ.UI.Show()
    local frame =
        CreateMainFrame()

    FJ.UI.Refresh()

    frame:Show()
end

function FJ.UI.Hide()
    if mainFrame then
        mainFrame:Hide()
    end
end

function FJ.UI.Toggle()
    local frame =
        CreateMainFrame()

    if frame:IsShown() then
        frame:Hide()
    else
        FJ.UI.Show()
    end
end

function FJ.UI.RefreshIfVisible()
    if mainFrame
        and mainFrame:IsShown() then

        FJ.UI.Refresh()
    end
end