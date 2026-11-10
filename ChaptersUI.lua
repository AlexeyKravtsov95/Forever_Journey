
local addonName, FJ = ...

FJ.ChaptersUI = {}
local UI = FJ.ChaptersUI
local Chapters = FJ.Chapters
local Theme = FJ.Theme
local Colors = Theme.Colors
local isRussian = GetLocale() == "ruRU"

local T = isRussian and {
    open = "ГЛАВЫ",
    title = "ГЛАВЫ ПУТЕШЕСТВИЯ",
    subtitle = "Назови важные этапы истории своего персонажа.",
    create = "НОВАЯ ГЛАВА",
    save = "СОХРАНИТЬ",
    finish = "ЗАВЕРШИТЬ ГЛАВУ",
    previous = "< НАЗАД",
    next = "ДАЛЕЕ >",
    titleLabel = "Название главы",
    descriptionLabel = "Описание (необязательно)",
    empty = "Пока нет глав. Создай первую!",
    newHint = "Новая глава начнётся с текущего момента.",
    active = "АКТИВНАЯ",
    finished = "ЗАКРЫТА",
    draft = "НОВАЯ ГЛАВА",
    page = "Страница %d из %d",
    saved = "Глава сохранена.",
    created = "Глава создана.",
    closed = "Глава завершена.",
    confirmFinish = "Нажми «Завершить главу» ещё раз для подтверждения.",
    noCharacter = "Данные персонажа ещё не загружены.",
    titleRequired = "Укажи название главы.",
    titleTooLong = "Название: не более 160 байт UTF-8.",
    descriptionTooLong = "Описание: не более 1200 байт UTF-8.",
    limit = "Достигнут предел глав (512).",
    notFound = "Глава не найдена.",
    otherError = "Не удалось сохранить главу: %s"
} or {
    open = "CHAPTERS",
    title = "CHAPTERS OF YOUR JOURNEY",
    subtitle = "Give the important stages of your story a name.",
    create = "NEW CHAPTER",
    save = "SAVE",
    finish = "FINISH CHAPTER",
    previous = "< PREV",
    next = "NEXT >",
    titleLabel = "Chapter title",
    descriptionLabel = "Description (optional)",
    empty = "No chapters yet. Create your first one!",
    newHint = "A new chapter begins at the current moment.",
    active = "ACTIVE",
    finished = "CLOSED",
    draft = "NEW CHAPTER",
    page = "Page %d of %d",
    saved = "Chapter saved.",
    created = "Chapter created.",
    closed = "Chapter finished.",
    confirmFinish = "Press Finish Chapter again to confirm.",
    noCharacter = "Character data is not loaded yet.",
    titleRequired = "Enter a chapter title.",
    titleTooLong = "Title: maximum 160 UTF-8 bytes.",
    descriptionTooLong = "Description: maximum 1200 UTF-8 bytes.",
    limit = "Maximum number of chapters reached (512).",
    notFound = "Chapter was not found.",
    otherError = "Could not save chapter: %s"
}

local PAGE_SIZE = 8

local function Paint(object, color)
    Theme.ApplyTextColor(object, color)
end

local function Text(parent, font, label, width)
    local object = parent:CreateFontString(nil, "OVERLAY", font)
    if width then object:SetWidth(width) end
    object:SetText(label or "")
    return object
end

local function Border(parent)
    local color = Colors.goldMuted

    local function Edge()
        local texture = parent:CreateTexture(nil, "OVERLAY")
        texture:SetColorTexture(color.r, color.g, color.b, 0.75)
        return texture
    end

    local top = Edge()
    top:SetPoint("TOPLEFT", parent)
    top:SetPoint("TOPRIGHT", parent)
    top:SetHeight(1)

    local bottom = Edge()
    bottom:SetPoint("BOTTOMLEFT", parent)
    bottom:SetPoint("BOTTOMRIGHT", parent)
    bottom:SetHeight(1)

    local left = Edge()
    left:SetPoint("TOPLEFT", parent)
    left:SetPoint("BOTTOMLEFT", parent)
    left:SetWidth(1)

    local right = Edge()
    right:SetPoint("TOPRIGHT", parent)
    right:SetPoint("BOTTOMRIGHT", parent)
    right:SetWidth(1)
end

local function RefreshButtonVisual(button)
    if not button.caption then return end

    local enabled = button:IsEnabled()
    local hovered = button.__fjHovered

    if button.__fjFilled and button.background then
        local alpha = not enabled and 0.055 or hovered and 0.24 or 0.14

        button.background:SetColorTexture(
            Colors.goldMuted.r,
            Colors.goldMuted.g,
            Colors.goldMuted.b,
            alpha
        )
    end

    if not enabled then
        Paint(button.caption, Colors.inkMuted)
    elseif button.__fjFilled then
        Paint(button.caption, Colors.ink)
    elseif hovered then
        Paint(button.caption, Colors.goldMuted)
    else
        Paint(button.caption, Colors.ink)
    end
end

local function Button(parent, label, width, height, filled)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)
    button.__fjFilled = filled == true
    button.__fjHovered = false

    if filled then
        button.background = button:CreateTexture(nil, "BACKGROUND")
        button.background:SetAllPoints(button)
    end

    button.caption = Text(button, "GameFontNormalSmall", label)
    button.caption:SetAllPoints(button)
    button.caption:SetJustifyH("CENTER")

    button:SetScript("OnEnter", function(self)
        self.__fjHovered = true
        RefreshButtonVisual(self)
    end)

    button:SetScript("OnLeave", function(self)
        self.__fjHovered = false
        RefreshButtonVisual(self)
    end)

    button:SetScript("OnEnable", RefreshButtonVisual)
    button:SetScript("OnDisable", RefreshButtonVisual)

    RefreshButtonVisual(button)
    return button
end

local function ErrorText(code)
    local messages = {
        CHARACTER_NOT_ATTACHED = T.noCharacter,
        TITLE_REQUIRED = T.titleRequired,
        TITLE_TOO_LONG = T.titleTooLong,
        DESCRIPTION_TOO_LONG = T.descriptionTooLong,
        CHAPTER_LIMIT = T.limit,
        NOT_FOUND = T.notFound
    }

    return messages[code]
        or string.format(T.otherError, tostring(code))
end

local function Status(overlay, message, isError)
    overlay.message:SetText(message or "")

    if isError then
        overlay.message:SetTextColor(0.56, 0.14, 0.09, 1)
    else
        Paint(overlay.message, Colors.inkMuted)
    end
end

local function SelectChapter(overlay, chapter)
    overlay.confirmCloseID = nil
    overlay.selectedID = chapter and chapter.id or nil
    overlay.newMode = chapter == nil

    overlay.titleBox:SetText(chapter and chapter.title or "")
    overlay.descriptionBox:SetText(chapter and chapter.description or "")

    overlay.titleBox:ClearFocus()
    overlay.descriptionBox:ClearFocus()

    Status(overlay, chapter and "" or T.newHint)
end

local function Render(overlay)
    local chapters = Chapters.GetAll()

    if not chapters then
        chapters = {}
        Status(overlay, T.noCharacter, true)
    end

    local total = #chapters
    local pages = math.max(1, math.ceil(total / PAGE_SIZE))

    overlay.pageIndex = math.max(
        1,
        math.min(overlay.pageIndex or 1, pages)
    )

    overlay.pageLabel:SetText(
        string.format(T.page, overlay.pageIndex, pages)
    )

    overlay.previousButton:SetEnabled(overlay.pageIndex > 1)
    overlay.nextButton:SetEnabled(overlay.pageIndex < pages)
    overlay.emptyLabel:SetShown(total == 0)

    for rowIndex, row in ipairs(overlay.rows) do
        local index =
            total - ((overlay.pageIndex - 1) * PAGE_SIZE + rowIndex - 1)

        local chapter = chapters[index]

        if chapter then
            row.chapterID = chapter.id

            row.caption:SetText(
                string.format("%d. %s", index, chapter.title or "")
            )

            local selected =
                not overlay.newMode
                and chapter.id == overlay.selectedID

            if selected then
                row.background:SetColorTexture(
                    Colors.goldMuted.r,
                    Colors.goldMuted.g,
                    Colors.goldMuted.b,
                    0.22
                )
                Paint(row.caption, Colors.ink)
            else
                row.background:SetColorTexture(
                    Colors.ink.r,
                    Colors.ink.g,
                    Colors.ink.b,
                    0.04
                )
                Paint(row.caption, Colors.inkMuted)
            end

            row:Show()
        else
            row.chapterID = nil
            row:Hide()
        end
    end

    if overlay.newMode then
        overlay.modeLabel:SetText(T.draft)
        overlay.finishButton:SetEnabled(false)
    else
        local selected = Chapters.FindByID(overlay.selectedID)

        if not selected then
            SelectChapter(overlay, nil)
            overlay.modeLabel:SetText(T.draft)
            overlay.finishButton:SetEnabled(false)
        else
            local active = Chapters.GetActive()
            local isActive = active and active.id == selected.id

            overlay.modeLabel:SetText(
                isActive and T.active or T.finished
            )

            overlay.finishButton:SetEnabled(not not isActive)
        end
    end
end

local function Save(overlay)
    local title =
        (overlay.titleBox:GetText() or ""):match("^%s*(.-)%s*$") or ""

    local description =
        (overlay.descriptionBox:GetText() or ""):match("^%s*(.-)%s*$") or ""

    if title == "" then
        Status(overlay, T.titleRequired, true)
        return
    end

    if #title > 160 then
        Status(overlay, T.titleTooLong, true)
        return
    end

    if #description > 1200 then
        Status(overlay, T.descriptionTooLong, true)
        return
    end

    local chapter, err

    if overlay.newMode then
        chapter, err = Chapters.Create(title, description)
    else
        chapter, err = Chapters.Rename(overlay.selectedID, title)

        if chapter then
            chapter, err = Chapters.SetDescription(
                overlay.selectedID,
                description
            )
        end
    end

    if not chapter then
        Status(overlay, ErrorText(err), true)
        return
    end

    local wasNew = overlay.newMode

    SelectChapter(overlay, chapter)
    if wasNew then overlay.pageIndex = 1 end

    Render(overlay)
    Status(overlay, wasNew and T.created or T.saved)
end

local function FinishChapter(overlay)
    local active = Chapters.GetActive()

    if not active
        or overlay.newMode
        or active.id ~= overlay.selectedID then
        return
    end

    if overlay.confirmCloseID ~= active.id then
        overlay.confirmCloseID = active.id
        Status(overlay, T.confirmFinish)
        return
    end

    overlay.confirmCloseID = nil

    local chapter, err = Chapters.Close()

    if not chapter then
        Status(overlay, ErrorText(err), true)
        return
    end

    SelectChapter(overlay, chapter)
    Render(overlay)
    Status(overlay, T.closed)
end

local function EnsureOverlay(frame)
    if frame.fjChaptersOverlay then
        return frame.fjChaptersOverlay
    end

    local page = frame.chroniclePage
    if not page then return nil end

    local overlay = CreateFrame("Frame", nil, page)
    overlay:SetAllPoints(page)
    overlay:SetFrameLevel(page:GetFrameLevel() + 70)
    overlay:EnableMouse(true)

    overlay.rows = {}
    overlay.pageIndex = 1
    overlay.newMode = true

    local panel = CreateFrame("Frame", nil, overlay)
    panel:SetSize(740, 390)
    panel:SetPoint("CENTER", overlay, "CENTER", 0, 0)
    panel:SetFrameLevel(overlay:GetFrameLevel() + 1)
    panel:EnableMouse(true)

    local background = panel:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(panel)
    background:SetTexture(Theme.Textures.parchment)
    Border(panel)

    local heading = Text(panel, "GameFontNormalLarge", T.title)
    heading:SetPoint("TOP", panel, "TOP", 0, -19)
    Paint(heading, Colors.ink)

    local subtitle = Text(panel, "GameFontHighlightSmall", T.subtitle)
    subtitle:SetPoint("TOP", heading, "BOTTOM", 0, -7)
    Paint(subtitle, Colors.inkMuted)

    local closeButton = Button(panel, "X", 25, 25, false)
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -10)

    closeButton:SetScript("OnClick", function()
        overlay.titleBox:ClearFocus()
        overlay.descriptionBox:ClearFocus()
        overlay:Hide()
    end)

    local split = panel:CreateTexture(nil, "ARTWORK")
    split:SetColorTexture(
        Colors.goldMuted.r,
        Colors.goldMuted.g,
        Colors.goldMuted.b,
        0.42
    )
    split:SetWidth(1)
    split:SetPoint("TOPLEFT", panel, "TOPLEFT", 296, -65)
    split:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 296, 30)

    local newButton = Button(panel, T.create, 240, 25, true)
    newButton:SetPoint("TOPLEFT", panel, "TOPLEFT", 28, -62)

    newButton:SetScript("OnClick", function()
        SelectChapter(overlay, nil)
        Render(overlay)
        overlay.titleBox:SetFocus()
    end)

    overlay.emptyLabel = Text(
        panel, "GameFontHighlightSmall", T.empty, 240
    )
    overlay.emptyLabel:SetPoint(
        "TOPLEFT", panel, "TOPLEFT", 29, -107
    )
    Paint(overlay.emptyLabel, Colors.inkMuted)

    for i = 1, PAGE_SIZE do
        local row = Button(panel, "", 248, 27, false)

        row:SetPoint(
            "TOPLEFT",
            panel,
            "TOPLEFT",
            24,
            -96 - (i - 1) * 29
        )

        row.caption:ClearAllPoints()
        row.caption:SetPoint("LEFT", row, "LEFT", 8, 0)
        row.caption:SetWidth(231)
        row.caption:SetJustifyH("LEFT")

        row.background = row:CreateTexture(nil, "BACKGROUND")
        row.background:SetAllPoints(row)

        row:SetScript("OnClick", function(self)
            local chapter = Chapters.FindByID(self.chapterID)

            if chapter then
                SelectChapter(overlay, chapter)
                Render(overlay)
            end
        end)

        overlay.rows[i] = row
    end

    local previous = Button(panel, T.previous, 80, 24, true)
    previous:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 25, 43)

    previous:SetScript("OnClick", function()
        overlay.pageIndex = overlay.pageIndex - 1
        Render(overlay)
    end)

    overlay.previousButton = previous

    overlay.pageLabel = Text(
        panel, "GameFontHighlightSmall", "", 99
    )
    overlay.pageLabel:SetPoint("LEFT", previous, "RIGHT", 0, 0)
    overlay.pageLabel:SetJustifyH("CENTER")
    Paint(overlay.pageLabel, Colors.inkMuted)

    local nextButton = Button(panel, T.next, 80, 24, true)
    nextButton:SetPoint("LEFT", overlay.pageLabel, "RIGHT", 0, 0)

    nextButton:SetScript("OnClick", function()
        overlay.pageIndex = overlay.pageIndex + 1
        Render(overlay)
    end)

    overlay.nextButton = nextButton

    overlay.modeLabel = Text(
        panel, "GameFontNormalSmall", T.draft, 374
    )
    overlay.modeLabel:SetPoint(
        "TOPLEFT", panel, "TOPLEFT", 314, -67
    )
    Paint(overlay.modeLabel, Colors.goldMuted)

    local titleLabel = Text(
        panel, "GameFontHighlightSmall", T.titleLabel
    )
    titleLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 314, -99)
    Paint(titleLabel, Colors.ink)

    local titleBorder = CreateFrame("Frame", nil, panel)
    titleBorder:SetSize(390, 30)
    titleBorder:SetPoint(
        "TOPLEFT", panel, "TOPLEFT", 314, -119
    )
    Border(titleBorder)

    local titleBox = CreateFrame("EditBox", nil, titleBorder)
    titleBox:SetPoint(
        "TOPLEFT", titleBorder, "TOPLEFT", 8, -3
    )
    titleBox:SetPoint(
        "BOTTOMRIGHT", titleBorder, "BOTTOMRIGHT", -8, 3
    )
    titleBox:SetAutoFocus(false)
    titleBox:SetMultiLine(false)
    titleBox:SetFontObject("GameFontHighlightSmall")
    titleBox:SetTextInsets(0, 0, 0, 0)
    Paint(titleBox, Colors.ink)
    overlay.titleBox = titleBox

    local descriptionLabel = Text(
        panel, "GameFontHighlightSmall", T.descriptionLabel
    )
    descriptionLabel:SetPoint(
        "TOPLEFT", panel, "TOPLEFT", 314, -167
    )
    Paint(descriptionLabel, Colors.ink)

    local descriptionBorder = CreateFrame("Frame", nil, panel)
    descriptionBorder:SetSize(390, 111)
    descriptionBorder:SetPoint(
        "TOPLEFT", panel, "TOPLEFT", 314, -188
    )
    Border(descriptionBorder)

    local descriptionBox = CreateFrame(
        "EditBox", nil, descriptionBorder
    )
    descriptionBox:SetPoint(
        "TOPLEFT", descriptionBorder, "TOPLEFT", 8, -7
    )
    descriptionBox:SetPoint(
        "BOTTOMRIGHT", descriptionBorder, "BOTTOMRIGHT", -8, 7
    )
    descriptionBox:SetAutoFocus(false)
    descriptionBox:SetMultiLine(true)
    descriptionBox:SetFontObject("GameFontHighlightSmall")
    descriptionBox:SetTextInsets(0, 0, 0, 0)
    Paint(descriptionBox, Colors.ink)
    overlay.descriptionBox = descriptionBox

    titleBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    titleBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        descriptionBox:SetFocus()
    end)

    descriptionBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    overlay.message = Text(
        panel, "GameFontHighlightSmall", "", 392
    )
    overlay.message:SetPoint(
        "TOPLEFT", panel, "TOPLEFT", 314, -309
    )
    Paint(overlay.message, Colors.inkMuted)

    local saveButton = Button(panel, T.save, 110, 25, true)
    saveButton:SetPoint(
        "BOTTOMRIGHT", panel, "BOTTOMRIGHT", -27, 30
    )
    saveButton:SetScript("OnClick", function()
        Save(overlay)
    end)

    local finishButton = Button(
        panel, T.finish, 186, 25, true
    )
    finishButton:SetPoint(
        "RIGHT", saveButton, "LEFT", -10, 0
    )
    finishButton:SetScript("OnClick", function()
        FinishChapter(overlay)
    end)

    overlay.finishButton = finishButton

    frame.fjChaptersOverlay = overlay
    overlay:Hide()

    return overlay
end

-- Without chapterID, open the active or most recent chapter.
-- With chapterID, open that exact chapter, even on later list pages.
function UI.Open(frame, chapterID)
    frame = frame or _G.ForeverJourneyMainFrame

    if not frame or not frame.chroniclePage then
        return false
    end

    local chapters = Chapters.GetAll() or {}
    local selected
    local pageIndex = 1

    if chapterID ~= nil then
        selected = Chapters.FindByID(chapterID)

        if not selected then
            return false
        end

        for index, chapter in ipairs(chapters) do
            if chapter.id == chapterID then
                pageIndex =
                    math.floor((#chapters - index) / PAGE_SIZE) + 1
                break
            end
        end
    else
        selected = Chapters.GetActive() or chapters[#chapters]
    end

    local overlay = EnsureOverlay(frame)
    if not overlay then return false end

    overlay.pageIndex = pageIndex
    SelectChapter(overlay, selected)
    Render(overlay)
    overlay:Show()

    return true
end

-- Public entry point for clicking chapter headings in Chronicle.
function UI.OpenChapter(frame, chapterID)
    if type(chapterID) ~= "string" then
        return false
    end

    return UI.Open(frame, chapterID)
end

local function AttachButton(frame)
    if not frame
        or not frame.chroniclePage
        or frame.fjChaptersButton then
        return
    end

    local anchor =
        frame.fjBookButton or frame.chronicleAddMemoryButton

    if not anchor then return end

    local button = Button(
        frame.chroniclePage,
        T.open,
        102,
        24,
        false
    )

    button:SetPoint("RIGHT", anchor, "LEFT", -10, 0)
    button:SetScript("OnClick", function()
        UI.Open(frame)
    end)

    frame.fjChaptersButton = button
end

-- Load after JournalExportUI.lua, as before.
local originalAttach = FJ.ChronicleUI.Attach

FJ.ChronicleUI.Attach = function(frame)
    originalAttach(frame)
    AttachButton(frame)
end
