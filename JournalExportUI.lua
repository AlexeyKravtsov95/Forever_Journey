local addonName, FJ = ...

FJ.JournalExportUI = {}
local ExportUI = FJ.JournalExportUI
local Theme = FJ.Theme
local Colors = Theme.Colors
local Textures = Theme.Textures
local isRussian = GetLocale() == "ruRU"

local T = isRussian and {
    open = "ЭКСПОРТ КНИГИ",
    title = "КНИГА ПРИКЛЮЧЕНИЙ",
    subtitleSingle = "Один код для всего журнала — без переключения страниц.",
    subtitleMulti = "Очень большой журнал: скопируй части по порядку для Book Creator.",
    select = "ВЫДЕЛИТЬ КОД",
    regenerate = "ОБНОВИТЬ",
    previous = "< НАЗАД",
    next = "ДАЛЕЕ >",
    close = "ЗАКРЫТЬ",
    partSingle = "%d записей - %.1f КБ - один код",
    partMulti = "Часть %d из %d - %d записей - %.1f КБ",
    readySingle = "Нажми «Выделить код» и Ctrl+C. Вставь код на сайте ниже.",
    readyMulti = "Скопируй каждую часть (Ctrl+C), затем вставь все части на сайте ниже.",
    website = "Создай PDF в браузере: journal.mythweld.com",
    truncated = "ОШИБКА: WoW обрезал текст. Попробуй повторить экспорт.",
    changed = "Код изменён. Нажми «Обновить», чтобы восстановить экспорт.",
    error = "Не удалось создать журнал: %s"
} or {
    open = "EXPORT BOOK",
    title = "ADVENTURE JOURNAL",
    subtitleSingle = "One code for your entire journal — no pages to switch.",
    subtitleMulti = "Large journal: copy the parts in order for Book Creator.",
    select = "SELECT CODE",
    regenerate = "REFRESH",
    previous = "< PREV",
    next = "NEXT >",
    close = "CLOSE",
    partSingle = "%d entries - %.1f KB - one code",
    partMulti = "Part %d of %d - %d entries - %.1f KB",
    readySingle = "Select the code, press Ctrl+C, and paste it on the site below.",
    readyMulti = "Copy each part (Ctrl+C), then paste all parts on the site below.",
    website = "Create your PDF in browser: journal.mythweld.com",
    truncated = "ERROR: WoW truncated the code. Please retry the export.",
    changed = "Code was modified. Press Refresh to restore the export.",
    error = "Could not create journal: %s"
}

local function Paint(text, color)
    Theme.ApplyTextColor(text, color)
end

local function MakeButton(parent, label, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)

    local caption = button:CreateFontString(
        nil, "OVERLAY", "GameFontNormalSmall"
    )
    caption:SetAllPoints(button)
    caption:SetJustifyH("CENTER")
    caption:SetText(label)

    Paint(caption, Colors.goldMuted)
    button.caption = caption

    button:SetScript("OnEnter", function(self)
        Paint(self.caption, Colors.gold)
    end)

    button:SetScript("OnLeave", function(self)
        Paint(self.caption, Colors.goldMuted)
    end)

    return button
end

local function AddBorder(panel)
    local function Edge()
        local texture = panel:CreateTexture(nil, "OVERLAY")
        texture:SetColorTexture(
            Colors.goldMuted.r,
            Colors.goldMuted.g,
            Colors.goldMuted.b,
            0.85
        )
        return texture
    end

    local top = Edge()
    top:SetHeight(1)
    top:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)

    local bottom = Edge()
    bottom:SetHeight(1)
    bottom:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)

    local left = Edge()
    left:SetWidth(1)
    left:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)

    local right = Edge()
    right:SetWidth(1)
    right:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
end

local function Close(frame)
    if frame.fjBookOverlay then
        frame.fjBookOverlay:Hide()
    end

    if frame.fjBookEditor then
        frame.fjBookEditor:ClearFocus()
    end
end

-- Pagination is needed only when the export has multiple blocks.
-- Single-block export keeps the main actions centered.
-- Multi-block export restores navigation and right-aligned actions.
local function UpdateNavigation(overlay)
    local hasPages = overlay.export and overlay.export.total > 1

    if hasPages then
        overlay.previousButton:Show()
        overlay.nextButton:Show()

        overlay.previousButton:SetEnabled(
            (overlay.index or 1) > 1
        )

        overlay.nextButton:SetEnabled(
            (overlay.index or 1) < overlay.export.total
        )
    else
        overlay.previousButton:Hide()
        overlay.nextButton:Hide()
    end

    local selectButton = overlay.selectButton
    local refreshButton = overlay.refreshButton

    selectButton:ClearAllPoints()
    refreshButton:ClearAllPoints()

    if hasPages then
        selectButton:SetPoint(
            "BOTTOMRIGHT",
            overlay.panel,
            "BOTTOMRIGHT",
            -27,
            53
        )

        refreshButton:SetPoint(
            "RIGHT",
            selectButton,
            "LEFT",
            -10,
            0
        )
    else
        refreshButton:SetPoint(
            "BOTTOM",
            overlay.panel,
            "BOTTOM",
            -85,
            53
        )

        selectButton:SetPoint(
            "LEFT",
            refreshButton,
            "RIGHT",
            10,
            0
        )
    end
end

local function UpdatePart(frame)
    local overlay = frame.fjBookOverlay
    local export = overlay and overlay.export

    if not export then
        return
    end

    local index = overlay.index or 1
    local part = export.parts[index] or ""

    overlay.ignoreTextChange = true
    frame.fjBookEditor:SetText(part)
    overlay.ignoreTextChange = false

    overlay.currentPart = part
    overlay.valid = frame.fjBookEditor:GetText() == part

    -- If this WoW client cannot display the full 30k-character
    -- code, automatically use smaller chunks.
    -- The FJBOOK1 format is not changed.
    if not overlay.valid and export.chunkSize > 12000 then
        local fallback, err = FJ.JournalExport.Build(12000)

        if fallback then
            overlay.export = fallback
            overlay.index = 1
            return UpdatePart(frame)
        end

        overlay.status:SetText(
            string.format(T.error, tostring(err))
        )
        overlay.selectButton:SetEnabled(false)
        return
    end

    frame.fjBookEditor:SetCursorPosition(0)
    frame.fjBookScroll:SetVerticalScroll(0)

    if export.total == 1 then
        overlay.subtitle:SetText(T.subtitleSingle)

        overlay.partLabel:SetText(string.format(
            T.partSingle,
            export.count,
            export.jsonBytes / 1024
        ))
    else
        overlay.subtitle:SetText(T.subtitleMulti)

        overlay.partLabel:SetText(string.format(
            T.partMulti,
            index,
            export.total,
            export.count,
            export.jsonBytes / 1024
        ))
    end

    UpdateNavigation(overlay)

    overlay.status:SetText(
        not overlay.valid and T.truncated
        or export.total == 1 and T.readySingle
        or T.readyMulti
    )

    overlay.selectButton:SetEnabled(overlay.valid)
end

local function RefreshExport(frame)
    local overlay = frame.fjBookOverlay
    local result, err = FJ.JournalExport.Build()

    if not result then
        overlay.export = nil

        overlay.status:SetText(
            string.format(T.error, tostring(err))
        )

        overlay.partLabel:SetText("")
        overlay.subtitle:SetText(T.subtitleSingle)

        overlay.ignoreTextChange = true
        frame.fjBookEditor:SetText("")
        overlay.ignoreTextChange = false

        overlay.selectButton:SetEnabled(false)
        UpdateNavigation(overlay)
        return
    end

    overlay.export = result
    overlay.index = 1

    UpdatePart(frame)
end

local function EnsureUI(frame)
    if frame.fjBookOverlay then
        return
    end

    local overlay = CreateFrame("Frame", nil, frame)
    overlay:SetAllPoints(frame)
    overlay:SetFrameLevel(frame:GetFrameLevel() + 100)
    overlay:EnableMouse(true)

    local panel = CreateFrame("Frame", nil, overlay)
    panel:SetSize(710, 440)
    panel:SetPoint("CENTER", overlay, "CENTER", 0, 0)
    panel:SetFrameLevel(overlay:GetFrameLevel() + 1)
    panel:EnableMouse(true)

    overlay.panel = panel

    local background = panel:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(panel)
    background:SetTexture(Textures.parchment)

    if type(background.SetTexCoord) == "function" then
        background:SetTexCoord(
            0.006, 0.994, 0.006, 0.994
        )
    end

    AddBorder(panel)

    local title = panel:CreateFontString(
        nil, "OVERLAY", "GameFontNormalLarge"
    )
    title:SetPoint("TOP", panel, "TOP", 0, -22)
    title:SetText(T.title)
    Paint(title, Colors.ink)

    local subtitle = panel:CreateFontString(
        nil, "OVERLAY", "GameFontHighlightSmall"
    )
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -8)
    subtitle:SetText(T.subtitleSingle)
    Paint(subtitle, Colors.inkMuted)

    overlay.subtitle = subtitle

    local partLabel = panel:CreateFontString(
        nil, "OVERLAY", "GameFontNormalSmall"
    )
    partLabel:SetPoint("TOP", subtitle, "BOTTOM", 0, -14)
    partLabel:SetWidth(650)
    Paint(partLabel, Colors.goldMuted)

    overlay.partLabel = partLabel

    local textBorder = CreateFrame("Frame", nil, panel)
    textBorder:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        27,
        -106
    )
    textBorder:SetPoint(
        "BOTTOMRIGHT",
        panel,
        "BOTTOMRIGHT",
        -27,
        132
    )

    AddBorder(textBorder)

    local scroll = CreateFrame(
        "ScrollFrame",
        nil,
        textBorder,
        "UIPanelScrollFrameTemplate"
    )

    scroll:SetPoint(
        "TOPLEFT",
        textBorder,
        "TOPLEFT",
        8,
        -5
    )
    scroll:SetPoint(
        "BOTTOMRIGHT",
        textBorder,
        "BOTTOMRIGHT",
        -26,
        5
    )

    local editor = CreateFrame("EditBox", nil, scroll)
    editor:SetAutoFocus(false)
    editor:SetMultiLine(true)
    editor:SetFontObject("GameFontHighlightSmall")
    editor:SetSize(590, 240)
    editor:SetMaxLetters(0)

    if type(editor.SetMaxBytes) == "function" then
        editor:SetMaxBytes(0)
    end

    editor:SetTextInsets(4, 4, 4, 4)
    Paint(editor, Colors.ink)

    editor:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    editor:SetScript("OnTextChanged", function(self)
        if overlay.ignoreTextChange then
            return
        end

        local isValid =
            overlay.currentPart ~= nil
            and self:GetText() == overlay.currentPart

        overlay.valid = isValid

        if overlay.export then
            overlay.status:SetText(
                isValid
                    and (
                        overlay.export.total == 1
                        and T.readySingle
                        or T.readyMulti
                    )
                    or T.changed
            )

            overlay.selectButton:SetEnabled(isValid)
        end
    end)

    scroll:SetScrollChild(editor)

    frame.fjBookEditor = editor
    frame.fjBookScroll = scroll

    local status = panel:CreateFontString(
        nil, "OVERLAY", "GameFontHighlightSmall"
    )
    status:SetPoint(
        "TOP",
        textBorder,
        "BOTTOM",
        0,
        -12
    )
    status:SetWidth(645)
    status:SetJustifyH("CENTER")
    Paint(status, Colors.inkMuted)

    overlay.status = status

    -- Book Creator URL is kept outside the exported FJBOOK1 EditBox,
    -- so it cannot be copied together with the export payload.
    local website = panel:CreateFontString(
        nil, "OVERLAY", "GameFontNormalSmall"
    )
    website:SetPoint(
        "BOTTOM",
        panel,
        "BOTTOM",
        0,
        86
    )
    website:SetWidth(645)
    website:SetJustifyH("CENTER")
    website:SetText(T.website)
    Paint(website, Colors.goldMuted)

    local previous = MakeButton(
        panel,
        T.previous,
        88,
        25
    )

    previous:SetPoint(
        "BOTTOMLEFT",
        panel,
        "BOTTOMLEFT",
        27,
        53
    )

    previous:SetScript("OnClick", function()
        if overlay.index > 1 then
            overlay.index = overlay.index - 1
            UpdatePart(frame)
        end
    end)

    overlay.previousButton = previous

    local nextPart = MakeButton(
        panel,
        T.next,
        88,
        25
    )

    nextPart:SetPoint(
        "LEFT",
        previous,
        "RIGHT",
        8,
        0
    )

    nextPart:SetScript("OnClick", function()
        if overlay.export
            and overlay.index < overlay.export.total then
            overlay.index = overlay.index + 1
            UpdatePart(frame)
        end
    end)

    overlay.nextButton = nextPart

    local selectButton = MakeButton(
        panel,
        T.select,
        160,
        25
    )

    selectButton:SetPoint(
        "BOTTOMRIGHT",
        panel,
        "BOTTOMRIGHT",
        -27,
        53
    )

    selectButton:SetScript("OnClick", function()
        if overlay.valid then
            editor:SetFocus()
            editor:HighlightText()
        end
    end)

    overlay.selectButton = selectButton

    local refreshButton = MakeButton(
        panel,
        T.regenerate,
        110,
        25
    )

    refreshButton:SetPoint(
        "RIGHT",
        selectButton,
        "LEFT",
        -10,
        0
    )

    refreshButton:SetScript("OnClick", function()
        RefreshExport(frame)
    end)

    overlay.refreshButton = refreshButton

    local closeButton = MakeButton(
        panel,
        T.close,
        110,
        25
    )

    closeButton:SetPoint(
        "BOTTOM",
        panel,
        "BOTTOM",
        0,
        17
    )

    closeButton:SetScript("OnClick", function()
        Close(frame)
    end)

    frame.fjBookOverlay = overlay
    overlay:Hide()
end

function ExportUI.Open(frame)
    frame = frame or ForeverJourneyMainFrame

    if not frame then
        return
    end

    EnsureUI(frame)
    RefreshExport(frame)
    frame.fjBookOverlay:Show()
end

local function AttachButton(frame)
    if not frame
        or frame.fjBookButton
        or not frame.chroniclePage
        or not frame.chronicleAddMemoryButton then
        return
    end

    local button = MakeButton(
        frame.chroniclePage,
        T.open,
        125,
        24
    )

    button:SetPoint(
        "RIGHT",
        frame.chronicleAddMemoryButton,
        "LEFT",
        -12,
        0
    )

    button:SetScript("OnClick", function()
        ExportUI.Open(frame)
    end)

    frame.fjBookButton = button
end

-- Chronicle attaches lazily during the main UI's first Refresh.
-- Extend its Attach hook without replacing the implementation.
local originalAttach = FJ.ChronicleUI.Attach

FJ.ChronicleUI.Attach = function(frame)
    originalAttach(frame)
    AttachButton(frame)
end

SLASH_FJBOOK1 = "/fjbook"

SlashCmdList["FJBOOK"] = function()
    if not ForeverJourneyMainFrame then
        if FJ.UI and type(FJ.UI.Refresh) == "function" then
            FJ.UI.Refresh()
        end
    end

    if ForeverJourneyMainFrame then
        ForeverJourneyMainFrame:Show()
        ExportUI.Open(ForeverJourneyMainFrame)
    end
end