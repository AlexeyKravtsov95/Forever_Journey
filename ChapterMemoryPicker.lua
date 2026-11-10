
local addonName, FJ = ...

-- Forever Journey 0.8.0
-- Chapter selection inside the existing memory reader.
-- Selected chapter uses parchment highlighting instead of
-- unsupported Unicode symbols.
FJ.ChapterMemoryPicker = {}

local Chapters = FJ.Chapters
local Theme = FJ.Theme
local Colors = Theme.Colors

local PAGE_SIZE = 8
local ru = type(GetLocale) == "function"
    and GetLocale() == "ruRU"

local T = ru and {
    heading = "ВЫБРАТЬ ГЛАВУ",
    change = "ИЗМЕНИТЬ ГЛАВУ",
    current = "Сейчас: ",
    auto = "ПО ВРЕМЕНИ",
    outside = "ВНЕ ГЛАВ",
    back = "НАЗАД",
    previous = "< НАЗАД",
    nextPage = "ДАЛЕЕ >",
    active = "АКТИВНАЯ",
    closed = "ЗАКРЫТА",
    noChapters = "Глав пока нет",
    automatic = "По времени",
    excluded = "Вне всех глав",
    missing = "Глава не найдена",
    page = "%d / %d",
    failed = "Не удалось изменить главу: %s"
} or {
    heading = "CHOOSE A CHAPTER",
    change = "CHANGE CHAPTER",
    current = "Current: ",
    auto = "BY DATE",
    outside = "OUTSIDE CHAPTERS",
    back = "BACK",
    previous = "< PREV",
    nextPage = "NEXT >",
    active = "ACTIVE",
    closed = "CLOSED",
    noChapters = "No chapters yet",
    automatic = "By date",
    excluded = "Outside all chapters",
    missing = "Chapter not found",
    page = "%d / %d",
    failed = "Could not change chapter: %s"
}

local function Paint(label, color)
    Theme.ApplyTextColor(label, color)
end

local function Text(parent, font, width, align)
    local label = parent:CreateFontString(
        nil, "OVERLAY", font
    )

    label:SetWidth(width)
    label:SetJustifyH(align or "LEFT")

    return label
end

local function Shorten(value, maxBytes)
    if type(value) ~= "string" then
        return ""
    end

    if #value <= maxBytes then
        return value
    end

    local limit = maxBytes

    while limit > 0 do
        local nextByte = value:byte(limit + 1)

        if not nextByte
            or nextByte < 128
            or nextByte >= 192 then
            break
        end

        limit = limit - 1
    end

    return value:sub(1, limit) .. "..."
end

local function Button(
    parent,
    title,
    width,
    height,
    align
)
    local button = CreateFrame(
        "Button", nil, parent
    )

    button:SetSize(width, height)

    -- Larger WoW-native font for readable controls.
    button.label = Text(
        button,
        "GameFontNormal",
        width - 12,
        align or "CENTER"
    )

    button.label:SetPoint(
        "CENTER", button, "CENTER"
    )

    button.label:SetText(title)
    button.baseColor = Colors.goldMuted

    Paint(
        button.label,
        button.baseColor
    )

    button:SetScript("OnEnter", function(self)
        Paint(self.label, Colors.gold)
    end)

    button:SetScript("OnLeave", function(self)
        Paint(
            self.label,
            self.baseColor or Colors.goldMuted
        )
    end)

    return button
end

local function GetRawMemory(panel)
    local view = panel and panel.memoryView

    if type(view) ~= "table" then
        return nil
    end

    return type(view.raw) == "table"
        and view.raw or view
end

local function GetResolvedChapter(memory)
    if not memory then
        return nil
    end

    if type(Chapters.ResolveForMemory)
        == "function" then

        return Chapters.ResolveForMemory(memory)
    end

    return nil
end

local function CurrentLabel(memory)
    if not memory then
        return T.missing
    end

    if memory.chapterId == false then
        return T.excluded
    end

    if type(memory.chapterId) == "string" then
        local chapter = Chapters.FindByID(
            memory.chapterId
        )

        return chapter
            and chapter.title or T.missing
    end

    local chapter = GetResolvedChapter(memory)

    return chapter
        and (T.automatic .. ": " .. chapter.title)
        or T.automatic
end

local function SelectedChapterID(memory)
    if not memory
        or memory.chapterId == false then

        return nil
    end

    if type(memory.chapterId) == "string" then
        return memory.chapterId
    end

    local chapter = GetResolvedChapter(memory)

    return chapter and chapter.id or nil
end

local function UpdateChangeButton(panel)
    local button = panel and panel.fjChapterButton

    if not button then
        return
    end

    local memory = GetRawMemory(panel)

    button:SetShown(
        memory ~= nil
        and type(memory.id) == "string"
        and memory.id ~= ""
    )
end

local function ShowReaderMode(panel)
    if not panel then
        return
    end

    if panel.fjChapterSelection then
        panel.fjChapterSelection:Hide()
    end

    panel.title:Show()
    panel.meta:Show()
    panel.scroll:Show()
    panel.closeButton:Show()

    if panel.editButton then
        if panel.memoryView
            and panel.memoryView.canEdit == true then

            panel.editButton:Show()
        else
            panel.editButton:Hide()
        end
    end

    UpdateChangeButton(panel)
end

local RenderSelection

local function Assign(frame, chapterID)
    local panel = frame
        and frame.chronicleMemoryReaderPanel

    local memory = GetRawMemory(panel)

    if not memory
        or type(memory.id) ~= "string" then

        return
    end

    local ok, result = Chapters.SetMemoryChapter(
        memory.id,
        chapterID
    )

    if not ok then
        print(
            "Forever Journey: "
            .. string.format(
                T.failed,
                tostring(result)
            )
        )

        return
    end

    -- Keep the reader open after changing the chapter.
    ShowReaderMode(panel)

    if FJ.ChronicleUI
        and type(FJ.ChronicleUI.Refresh)
            == "function" then

        FJ.ChronicleUI.Refresh(frame)
    end
end

local function CreateSelection(frame, panel)
    if panel.fjChapterSelection then
        return panel.fjChapterSelection
    end

    local selection = CreateFrame(
        "Frame", nil, panel
    )

    -- Reuse the original parchment reader panel.
    selection:SetAllPoints(panel)

    selection:SetFrameLevel(
        panel:GetFrameLevel() + 5
    )

    selection:EnableMouse(true)
    selection.page = 1

    selection.heading = Text(
        selection,
        "GameFontNormalLarge",
        460,
        "CENTER"
    )

    selection.heading:SetPoint(
        "TOP", selection, "TOP", 0, -21
    )

    selection.heading:SetText(T.heading)
    Paint(selection.heading, Colors.ink)

    -- Use a readable font for current chapter.
    selection.current = Text(
        selection,
        "GameFontHighlight",
        460,
        "CENTER"
    )

    selection.current:SetPoint(
        "TOP", selection, "TOP", 0, -51
    )

    Paint(
        selection.current,
        Colors.inkMuted
    )

    selection.rows = {}

    for i = 1, PAGE_SIZE do
        local row = Button(
            selection,
            "",
            466,
            22,
            "LEFT"
        )

        row:SetPoint(
            "TOPLEFT",
            selection,
            "TOPLEFT",
            37,
            -78 - (i - 1) * 22
        )

        row.label:ClearAllPoints()

        row.label:SetPoint(
            "LEFT",
            row,
            "LEFT",
            16,
            0
        )

        row.label:SetWidth(308)
        row.label:SetJustifyH("LEFT")

        -- Full-size text for ACTIVE / CLOSED.
        row.status = Text(
            row,
            "GameFontNormal",
            125,
            "RIGHT"
        )

        row.status:SetPoint(
            "RIGHT",
            row,
            "RIGHT",
            -7,
            0
        )

        Paint(
            row.status,
            Colors.inkMuted
        )

        -- Subtle parchment tint for the assigned chapter.
        row.selectedBackground = row:CreateTexture(
            nil, "BACKGROUND"
        )

        row.selectedBackground:SetAllPoints(row)

        row.selectedBackground:SetColorTexture(
            Colors.goldMuted.r,
            Colors.goldMuted.g,
            Colors.goldMuted.b,
            0.12
        )

        row.selectedBackground:Hide()

        -- Selected state is indicated by a gold line.
        -- No Unicode checkmark is used.
        row.selectionMark = row:CreateTexture(
            nil, "OVERLAY"
        )

        row.selectionMark:SetColorTexture(
            Colors.goldMuted.r,
            Colors.goldMuted.g,
            Colors.goldMuted.b,
            1
        )

        row.selectionMark:SetSize(3, 17)

        row.selectionMark:SetPoint(
            "LEFT",
            row,
            "LEFT",
            2,
            0
        )

        row.selectionMark:Hide()

        row:SetScript("OnClick", function(self)
            if self.chapterID then
                Assign(frame, self.chapterID)
            end
        end)

        selection.rows[i] = row
    end

    selection.empty = Text(
        selection,
        "GameFontHighlight",
        450,
        "CENTER"
    )

    selection.empty:SetPoint(
        "TOP",
        selection,
        "TOP",
        0,
        -123
    )

    selection.empty:SetText(T.noChapters)

    Paint(
        selection.empty,
        Colors.inkMuted
    )

    -- Page navigation below the eighth row.
    selection.previous = Button(
        selection,
        T.previous,
        108,
        22
    )

    selection.previous:SetPoint(
        "BOTTOMLEFT",
        selection,
        "BOTTOMLEFT",
        38,
        47
    )

    selection.previous:SetScript(
        "OnClick",
        function()
            selection.page = math.max(
                1,
                selection.page - 1
            )

            RenderSelection(frame)
        end
    )

    selection.pageLabel = Text(
        selection,
        "GameFontNormal",
        100,
        "CENTER"
    )

    selection.pageLabel:SetPoint(
        "BOTTOM",
        selection,
        "BOTTOM",
        0,
        51
    )

    Paint(
        selection.pageLabel,
        Colors.ink
    )

    selection.nextPage = Button(
        selection,
        T.nextPage,
        108,
        22
    )

    selection.nextPage:SetPoint(
        "BOTTOMRIGHT",
        selection,
        "BOTTOMRIGHT",
        -38,
        47
    )

    selection.nextPage:SetScript(
        "OnClick",
        function()
            selection.page = selection.page + 1
            RenderSelection(frame)
        end
    )

    -- Footer actions.
    selection.auto = Button(
        selection,
        T.auto,
        136,
        27
    )

    selection.auto:SetPoint(
        "BOTTOMLEFT",
        selection,
        "BOTTOMLEFT",
        32,
        14
    )

    selection.auto:SetScript(
        "OnClick",
        function()
            Assign(frame, nil)
        end
    )

    selection.outside = Button(
        selection,
        T.outside,
        148,
        27
    )

    selection.outside:SetPoint(
        "BOTTOM",
        selection,
        "BOTTOM",
        0,
        14
    )

    selection.outside:SetScript(
        "OnClick",
        function()
            Assign(frame, false)
        end
    )

    selection.back = Button(
        selection,
        T.back,
        107,
        27
    )

    selection.back:SetPoint(
        "BOTTOMRIGHT",
        selection,
        "BOTTOMRIGHT",
        -32,
        14
    )

    selection.back:SetScript(
        "OnClick",
        function()
            ShowReaderMode(panel)
        end
    )

    selection:Hide()

    panel.fjChapterSelection = selection

    return selection
end

RenderSelection = function(frame)
    local panel = frame
        and frame.chronicleMemoryReaderPanel

    local selection = panel
        and panel.fjChapterSelection

    if not selection then
        return
    end

    local chapters = Chapters.GetAll() or {}
    local memory = GetRawMemory(panel)

    local selectedID = SelectedChapterID(memory)

    local pages = math.max(
        1,
        math.ceil(#chapters / PAGE_SIZE)
    )

    selection.page = math.max(
        1,
        math.min(selection.page or 1, pages)
    )

    selection.current:SetText(
        T.current .. Shorten(
            CurrentLabel(memory),
            100
        )
    )

    selection.pageLabel:SetText(
        string.format(
            T.page,
            selection.page,
            pages
        )
    )

    local offset = (
        selection.page - 1
    ) * PAGE_SIZE

    for index, row in ipairs(selection.rows) do
        local chapterIndex = offset + index
        local chapter = chapters[chapterIndex]

        if type(chapter) == "table"
            and type(chapter.id) == "string" then

            local selected = (
                selectedID == chapter.id
            )

            local chapterState = (
                chapter.closedAt
                and T.closed or T.active
            )

            row.chapterID = chapter.id

            -- Plain text only. Avoid unsupported glyphs.
            row.label:SetText(
                string.format(
                    "%d. %s",
                    chapterIndex,
                    Shorten(chapter.title, 65)
                )
            )

            row.status:SetText(chapterState)

            row.baseColor = selected
                and Colors.ink
                or Colors.goldMuted

            Paint(
                row.label,
                row.baseColor
            )

            -- Selected chapter gets the visual accent.
            row.selectionMark:SetShown(selected)

            row.selectedBackground:SetShown(
                selected
            )

            row:Show()
        else
            row.chapterID = nil
            row:Hide()
        end
    end

    selection.empty:SetShown(
        #chapters == 0
    )

    selection.previous:SetShown(
        pages > 1
    )

    selection.nextPage:SetShown(
        pages > 1
    )

    selection.pageLabel:SetShown(
        pages > 1
    )

    if selection.page > 1 then
        selection.previous:Enable()
    else
        selection.previous:Disable()
    end

    if selection.page < pages then
        selection.nextPage:Enable()
    else
        selection.nextPage:Disable()
    end

    selection.previous:SetAlpha(
        selection.page > 1 and 1 or 0.35
    )

    selection.nextPage:SetAlpha(
        selection.page < pages and 1 or 0.35
    )
end

local function ShowSelection(frame)
    local panel = frame
        and frame.chronicleMemoryReaderPanel

    local memory = GetRawMemory(panel)

    if not panel
        or not memory
        or type(memory.id) ~= "string" then

        return
    end

    local selection = CreateSelection(
        frame,
        panel
    )

    local chapters = Chapters.GetAll() or {}
    local selectedID = SelectedChapterID(memory)

    selection.page = 1

    if type(selectedID) == "string" then
        for index, chapter in ipairs(chapters) do
            if type(chapter) == "table"
                and chapter.id == selectedID then

                selection.page = math.floor(
                    (index - 1) / PAGE_SIZE
                ) + 1

                break
            end
        end
    end

    RenderSelection(frame)

    -- Hide the reader's content, not its parchment.
    panel.title:Hide()
    panel.meta:Hide()
    panel.scroll:Hide()
    panel.closeButton:Hide()

    if panel.editButton then
        panel.editButton:Hide()
    end

    panel.fjChapterButton:Hide()

    selection:Show()
end

local function AttachReader(frame)
    local panel = frame
        and frame.chronicleMemoryReaderPanel

    local overlay = frame
        and frame.chronicleMemoryReader

    if not panel or not overlay then
        return
    end

    if not panel.fjChapterButton then
        local button = Button(
            panel,
            T.change,
            183,
            27
        )

        button:SetPoint(
            "BOTTOMLEFT",
            panel,
            "BOTTOMLEFT",
            32,
            19
        )

        button:SetScript(
            "OnClick",
            function()
                ShowSelection(frame)
            end
        )

        button:SetScript(
            "OnEnter",
            function(self)
                Paint(
                    self.label,
                    Colors.gold
                )

                local memory = GetRawMemory(panel)

                if GameTooltip and memory then
                    GameTooltip:SetOwner(
                        self,
                        "ANCHOR_TOP"
                    )

                    GameTooltip:SetText(
                        T.current
                        .. CurrentLabel(memory)
                    )

                    GameTooltip:Show()
                end
            end
        )

        button:SetScript(
            "OnLeave",
            function(self)
                Paint(
                    self.label,
                    Colors.goldMuted
                )

                if GameTooltip then
                    GameTooltip:Hide()
                end
            end
        )

        panel.fjChapterButton = button
    end

    if not panel.fjChapterModeHooked then
        panel.fjChapterModeHooked = true

        overlay:HookScript(
            "OnShow",
            function()
                ShowReaderMode(panel)
            end
        )

        overlay:HookScript(
            "OnHide",
            function()
                if panel.fjChapterSelection then
                    panel.fjChapterSelection:Hide()
                end
            end
        )
    end

    ShowReaderMode(panel)
end

local function HookTimelineReaders(frame)
    local child = frame
        and frame.chronicleScrollChild

    if not child then
        return
    end

    for _, row in ipairs({
        child:GetChildren()
    }) do

        if row.readButton
            and not row.fjChapterModeHooked then

            row.fjChapterModeHooked = true

            row.readButton:HookScript(
                "OnClick",
                function()
                    AttachReader(
                        row.ownerFrame or frame
                    )
                end
            )
        end

        if row.readButton
            and row.memoryView
            and row:IsShown() then

            row.readButton:Show()
        end
    end
end

-- Extend Chronicle without replacing its reader.
local originalRefresh = FJ.ChronicleUI.Refresh

FJ.ChronicleUI.Refresh = function(frame)
    local result = originalRefresh(frame)

    HookTimelineReaders(
        frame or _G.ForeverJourneyMainFrame
    )

    return result
end

local originalOpenReader =
    FJ.ChronicleUI.OpenMemoryReader

FJ.ChronicleUI.OpenMemoryReader = function(
    frame,
    memory
)
    local result = originalOpenReader(
        frame,
        memory
    )

    AttachReader(
        frame or _G.ForeverJourneyMainFrame
    )

    return result
end
