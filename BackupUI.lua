
local addonName, FJ = ...

FJ.BackupUI = {}

local Colors = FJ.Theme.Colors
local Textures = FJ.Theme.Textures
local ERROR_COLOR = { r = 0.58, g = 0.18, b = 0.12, a = 1 }

local translations = {
    ruRU = {
        DATA = "ДАННЫЕ",
        BACK = "< ОБЗОР",
        TITLE = "РЕЗЕРВНАЯ КОПИЯ",
        SUBTITLE = "Сохрани хронику вне папки World of Warcraft.",
        EXPORT_TAB = "ЭКСПОРТ",
        IMPORT_TAB = "ИМПОРТ",
        EXPORT_STEPS = "1. Выдели текст  2. Ctrl+C  3. Сохрани в .txt вне папки игры",
        IMPORT_STEPS = "Вставь старую резервную копию из .txt через Ctrl+V.",
        SELECT = "ВЫДЕЛИТЬ ТЕКСТ",
        REGENERATE = "ОБНОВИТЬ КОПИЮ",
        VALIDATE = "ПРОВЕРИТЬ КОПИЮ",
        RESTORE = "ВОССТАНОВИТЬ ДАННЫЕ",
        CONFIRM = "ПОДТВЕРДИТЬ ВОССТАНОВЛЕНИЕ",
        EXPORT_READY = "Копия: %d записей, %d избранных, %.1f КБ. Скопируй текст в файл вне WoW.",
        EXPORT_ERROR = "Не удалось создать копию: %s",
        EXPORT_CHANGED = "Текст копии изменён. Нажми «Обновить копию» перед сохранением.",
        EXPORT_TRUNCATED = "Редактор обрезал копию. Сохранять её нельзя!",
        SELECTED = "Текст выделен. Нажми Ctrl+C, затем сохрани в .txt вне папки WoW.",
        IMPORT_HINT = "Это текущая копия. Для восстановления старой вставь её текст из .txt, затем проверь.",
        IMPORT_EMPTY = "Вставь текст резервной копии из .txt.",
        INVALID = "Копия не прошла проверку: %s",
        WRONG_CHARACTER = "Копия принадлежит другому персонажу: %s",
        PLAN = "Проверено: новых записей %d, дублей %d, без ID %d. Для импорта нажми «Восстановить данные».",
        CHANGED_INPUT = "Текст изменился. Проверь копию ещё раз.",
        CONFIRM_HINT = "Последний шаг: нажми «Подтвердить восстановление». Текущие записи не удаляются.",
        RESTORE_OK = "Готово: добавлено %d записей, пропущено %d дублей. Выполни /reload для сохранения.",
        RESTORE_ERROR = "Ошибка восстановления: %s"
    },
    enUS = {
        DATA = "DATA",
        BACK = "< OVERVIEW",
        TITLE = "JOURNEY BACKUP",
        SUBTITLE = "Save your Chronicle outside the World of Warcraft folder.",
        EXPORT_TAB = "EXPORT",
        IMPORT_TAB = "IMPORT",
        EXPORT_STEPS = "1. Select text  2. Ctrl+C  3. Save to .txt outside the game folder",
        IMPORT_STEPS = "Paste an older saved backup from your .txt with Ctrl+V.",
        SELECT = "SELECT TEXT",
        REGENERATE = "REFRESH BACKUP",
        VALIDATE = "VALIDATE BACKUP",
        RESTORE = "RESTORE DATA",
        CONFIRM = "CONFIRM RESTORE",
        EXPORT_READY = "Backup: %d memories, %d favorites, %.1f KB. Save the text outside WoW.",
        EXPORT_ERROR = "Could not export backup: %s",
        EXPORT_CHANGED = "Backup text was edited. Refresh the backup before saving it.",
        EXPORT_TRUNCATED = "The editor truncated the backup. Do not save it!",
        SELECTED = "Text selected. Press Ctrl+C and save in a .txt outside WoW.",
        IMPORT_HINT = "Current backup is prefilled. To restore an older one, paste it from .txt and validate.",
        IMPORT_EMPTY = "Paste a saved backup from .txt.",
        INVALID = "Invalid backup: %s",
        WRONG_CHARACTER = "Backup belongs to a different character: %s",
        PLAN = "Validated: %d new, %d duplicates, %d without ID. Click Restore Data to proceed.",
        CHANGED_INPUT = "Text changed. Validate it again.",
        CONFIRM_HINT = "Final step: click Confirm Restore. Existing memories will not be deleted.",
        RESTORE_OK = "Done: %d memories added, %d duplicates skipped. Use /reload to save.",
        RESTORE_ERROR = "Restore failed: %s"
    }
}

local locale = translations[GetLocale()] or translations.enUS

local function T(key, ...)
    local value = locale[key] or translations.enUS[key] or key
    if select("#", ...) == 0 then return value end
    return string.format(value, ...)
end

local function SetColor(fontString, color)
    fontString:SetTextColor(color.r, color.g, color.b, color.a or 1)
end

local function MakeButton(parent, label, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(button)
    bg:SetColorTexture(
        Colors.goldMuted.r,
        Colors.goldMuted.g,
        Colors.goldMuted.b,
        0.10
    )

    local text = button:CreateFontString(
        nil, "OVERLAY", "GameFontNormalSmall"
    )
    text:SetPoint("CENTER")
    text:SetText(label)
    SetColor(text, Colors.goldMuted)

    button.fjText = text
    button.fjBackground = bg

    button:SetScript("OnEnter", function(self)
        self.fjBackground:SetAlpha(0.75)
    end)

    button:SetScript("OnLeave", function(self)
        self.fjBackground:SetAlpha(1)
    end)

    return button
end

local function SetStatus(page, message, isError)
    page.status:SetText(message or "")
    SetColor(
        page.status,
        isError and ERROR_COLOR or Colors.inkMuted
    )
end

local function ResizeEditor(page)
    if not page.editor or not page.scroll then return end

    local editor = page.editor
    local height

    if type(editor.GetTextHeight) == "function" then
        local ok, value = pcall(
            editor.GetTextHeight, editor
        )

        if ok and type(value) == "number" and value > 0 then
            height = value + 24
        end
    end

    if not height then
        local text = editor:GetText() or ""
        local _, lineBreaks = text:gsub("\n", "")

        height = (
            math.ceil(#text / 78) + lineBreaks + 1
        ) * 15 + 24
    end

    editor:SetHeight(
        math.max(
            page.scroll:GetHeight() or 196,
            math.min(height, 32000)
        )
    )
end

local function ClearPlan(page)
    page.plan = nil
    page.validatedText = nil
    page.confirming = false

    if page.restoreButton then
        page.restoreButton:Hide()
        page.restoreButton.fjText:SetText(T("RESTORE"))
    end
end

local function SetEditor(page, text)
    page.internalTextChange = true
    page.editor:SetText(text or "")
    page.internalTextChange = false

    ResizeEditor(page)
end

local function FreshExport(page)
    local text, err, summary =
        FJ.Backup.ExportCurrentCharacter()

    if not text then
        page.exportText = ""
        page.exportValid = false

        SetEditor(page, "")

        page.primaryButton:Hide()
        page.secondaryButton:Hide()

        SetStatus(
            page,
            T("EXPORT_ERROR", tostring(err)),
            true
        )

        return
    end

    page.exportText = text
    page.exportValid = true

    SetEditor(page, text)

    if page.editor:GetText() ~= text then
        page.exportValid = false

        page.primaryButton:Hide()
        page.secondaryButton:Hide()

        SetStatus(
            page,
            T("EXPORT_TRUNCATED"),
            true
        )

        return
    end

    page.primaryButton:Show()
    page.secondaryButton:Show()

    page.editor:SetFocus()
    page.editor:HighlightText()

    SetStatus(
        page,
        T(
            "EXPORT_READY",
            summary.memoryCount or 0,
            summary.favoriteCount or 0,
            (summary.encodedSize or 0) / 1024
        ),
        false
    )
end

local function SelectExport(page)
    if page.mode == "IMPORT" then
        page.importText = page.editor:GetText() or ""
    end

    page.mode = "EXPORT"
    ClearPlan(page)

    page.instructions:SetText(T("EXPORT_STEPS"))
    page.primaryButton.fjText:SetText(T("SELECT"))
    page.secondaryButton.fjText:SetText(T("REGENERATE"))

    page.primaryButton:ClearAllPoints()
    page.primaryButton:SetPoint(
        "BOTTOM", page, "BOTTOM", -108, 10
    )

    page.secondaryButton:Show()

    page.exportTab.fjBackground:SetAlpha(1)
    page.importTab.fjBackground:SetAlpha(0.35)

    SetEditor(page, page.exportText or "")

    if not page.exportText then
        FreshExport(page)
    else
        page.primaryButton:Show()
        page.editor:ClearFocus()

        SetStatus(
            page,
            page.exportValid
                and T("SELECTED")
                or T("EXPORT_CHANGED"),
            not page.exportValid
        )
    end
end

local function SelectImport(page)
    if page.mode == "EXPORT" then
        page.exportText = page.editor:GetText() or ""

        if page.importText == nil then
            page.importText = page.exportText
        end
    end

    page.mode = "IMPORT"
    ClearPlan(page)

    page.instructions:SetText(T("IMPORT_STEPS"))
    page.primaryButton.fjText:SetText(T("VALIDATE"))

    page.primaryButton:ClearAllPoints()
    page.primaryButton:SetPoint(
        "BOTTOM", page, "BOTTOM", 0, 10
    )

    page.primaryButton:Show()
    page.secondaryButton:Hide()

    page.exportTab.fjBackground:SetAlpha(0.35)
    page.importTab.fjBackground:SetAlpha(1)

    SetEditor(page, page.importText or "")

    page.editor:SetFocus()
    page.editor:HighlightText()

    SetStatus(page, T("IMPORT_HINT"), false)
end

local function Validate(page)
    local text = page.editor:GetText() or ""

    ClearPlan(page)

    if text == "" then
        SetStatus(page, T("IMPORT_EMPTY"), true)
        return
    end

    local plan, err =
        FJ.Backup.BuildImportPlan(text)

    if not plan then
        SetStatus(
            page,
            T("INVALID", tostring(err)),
            true
        )
        return
    end

    if not plan.sameCharacter then
        SetStatus(
            page,
            T(
                "WRONG_CHARACTER",
                tostring(
                    plan.summary
                    and plan.summary.characterKey
                    or "?"
                )
            ),
            true
        )
        return
    end

    -- Keep an immutable copy of the exact validated payload.
    page.plan = plan
    page.validatedText = text
    page.confirming = false

    page.restoreButton.fjText:SetText(T("RESTORE"))
    page.restoreButton:Show()

    SetStatus(
        page,
        T(
            "PLAN",
            plan.newMemories or 0,
            plan.duplicateMemories or 0,
            plan.memoriesWithoutID or 0
        ),
        false
    )
end

local function Restore(page)
    if page.mode ~= "IMPORT"
        or not page.plan then
        return
    end

    -- The validated snapshot, not the live EditBox text,
    -- is the source for this restore operation.
    local text = page.validatedText

    if type(text) ~= "string" or text == "" then
        ClearPlan(page)
        SetStatus(page, T("IMPORT_EMPTY"), true)
        return
    end

    if not page.confirming then
        page.confirming = true
        page.restoreButton.fjText:SetText(T("CONFIRM"))

        SetStatus(page, T("CONFIRM_HINT"), false)
        return
    end

    -- ImportMerge verifies the checksum and character again.
    local ok, success, err, result =
        pcall(FJ.Backup.ImportMerge, text)

    ClearPlan(page)

    if not ok then
        SetStatus(
            page,
            T("RESTORE_ERROR", tostring(success)),
            true
        )
        return
    end

    if not success then
        SetStatus(
            page,
            T("RESTORE_ERROR", tostring(err)),
            true
        )
        return
    end

    page.primaryButton:Hide()

    SetStatus(
        page,
        T(
            "RESTORE_OK",
            result.addedMemories or 0,
            result.duplicateMemories or 0
        ),
        false
    )
end

local function HidePage(frame)
    frame.fjBackupActive = false

    if frame.fjBackupPage then
        frame.fjBackupPage:Hide()
    end
end

local function BackToOverview(frame)
    HidePage(frame)

    if frame.leftPanel then frame.leftPanel:Show() end
    if frame.rightPanel then frame.rightPanel:Show() end
end

local function ShowPage(frame)
    if FJ.LifetimeStatisticsUI
        and type(FJ.LifetimeStatisticsUI.Hide) == "function" then
        FJ.LifetimeStatisticsUI.Hide()
    end

    if frame.leftPanel then frame.leftPanel:Hide() end
    if frame.rightPanel then frame.rightPanel:Hide() end

    frame.fjBackupActive = true
    frame.fjBackupPage:Show()

    SelectExport(frame.fjBackupPage)
end

local function CreatePage(frame)
    if frame.fjBackupPage or not frame.content then
        return
    end

    local page =
        CreateFrame("Frame", nil, frame.content)

    page:SetAllPoints(frame.content)
    page:SetFrameLevel(
        frame.content:GetFrameLevel() + 3
    )

    local back =
        MakeButton(page, T("BACK"), 108, 22)

    back:SetPoint(
        "TOPLEFT", page, "TOPLEFT", 24, -8
    )

    back:SetScript("OnClick", function()
        BackToOverview(frame)
    end)

    local compass =
        page:CreateTexture(nil, "ARTWORK")

    compass:SetTexture(Textures.compass)
    compass:SetSize(74, 37)
    compass:SetPoint("TOP", page, "TOP", 0, 1)
    compass:SetAlpha(0.78)

    local title =
        page:CreateFontString(
            nil, "OVERLAY", "GameFontNormalLarge"
        )

    title:SetPoint(
        "TOP", page, "TOP", 0, -39
    )

    title:SetText(T("TITLE"))
    SetColor(title, Colors.ink)

    local subtitle =
        page:CreateFontString(
            nil, "OVERLAY", "GameFontHighlightSmall"
        )

    subtitle:SetPoint(
        "TOP", title, "BOTTOM", 0, -5
    )

    subtitle:SetWidth(610)
    subtitle:SetText(T("SUBTITLE"))
    SetColor(subtitle, Colors.inkMuted)

    local ornament =
        page:CreateTexture(nil, "ARTWORK")

    ornament:SetTexture(Textures.ornamentLine)
    ornament:SetSize(300, 14)

    ornament:SetPoint(
        "TOP", subtitle, "BOTTOM", 0, -8
    )

    page.exportTab =
        MakeButton(page, T("EXPORT_TAB"), 160, 24)

    page.exportTab:SetPoint(
        "TOP", page, "TOP", -89, -103
    )

    page.importTab =
        MakeButton(page, T("IMPORT_TAB"), 160, 24)

    page.importTab:SetPoint(
        "LEFT", page.exportTab, "RIGHT", 16, 0
    )

    page.instructions =
        page:CreateFontString(
            nil, "OVERLAY", "GameFontHighlightSmall"
        )

    page.instructions:SetPoint(
        "TOP", page, "TOP", 0, -137
    )

    page.instructions:SetWidth(700)
    page.instructions:SetJustifyH("CENTER")
    SetColor(page.instructions, Colors.inkMuted)

    local border =
        CreateFrame("Frame", nil, page)

    border:SetSize(714, 212)
    border:SetPoint(
        "TOP", page, "TOP", 0, -163
    )

    local sides = {
        {"TOPLEFT", "TOPLEFT", 714, 1},
        {"BOTTOMLEFT", "BOTTOMLEFT", 714, 1},
        {"TOPLEFT", "TOPLEFT", 1, 212},
        {"TOPRIGHT", "TOPRIGHT", 1, 212}
    }

    for _, side in ipairs(sides) do
        local rule =
            border:CreateTexture(nil, "ARTWORK")

        rule:SetSize(side[3], side[4])
        rule:SetPoint(
            side[1], border, side[2], 0, 0
        )

        rule:SetColorTexture(
            Colors.goldMuted.r,
            Colors.goldMuted.g,
            Colors.goldMuted.b,
            0.35
        )
    end

    local scroll = CreateFrame(
        "ScrollFrame",
        nil,
        border,
        "UIPanelScrollFrameTemplate"
    )

    scroll:SetPoint(
        "TOPLEFT", border, "TOPLEFT", 10, -10
    )

    scroll:SetPoint(
        "BOTTOMRIGHT", border, "BOTTOMRIGHT", -28, 10
    )

    local editor =
        CreateFrame("EditBox", nil, scroll)

    editor:SetMultiLine(true)
    editor:SetAutoFocus(false)
    editor:SetFontObject("GameFontHighlightSmall")
    editor:SetWidth(660)
    editor:SetHeight(196)
    editor:SetMaxLetters(0)

    if type(editor.SetMaxBytes) == "function" then
        editor:SetMaxBytes(0)
    end

    editor:SetTextInsets(4, 4, 4, 4)

    editor:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    editor:SetScript(
        "OnTextChanged",
        function(self, isUserInput)
            if page.internalTextChange then
                return
            end

            ResizeEditor(page)

            local currentText = self:GetText() or ""

            if page.mode == "IMPORT" then
                page.importText = currentText

                -- Ignore spurious events caused by layout or focus.
                -- Only genuine user edits to different content
                -- invalidate the previously verified backup.
                if isUserInput
                    and page.plan
                    and currentText ~= page.validatedText then

                    ClearPlan(page)
                    SetStatus(
                        page,
                        T("CHANGED_INPUT"),
                        true
                    )
                end

            elseif page.mode == "EXPORT" then
                page.exportValid = (
                    currentText == page.exportText
                )

                if not page.exportValid then
                    SetStatus(
                        page,
                        T("EXPORT_CHANGED"),
                        true
                    )
                end
            end
        end
    )

    scroll:SetScrollChild(editor)

    page.editor = editor
    page.scroll = scroll

    page.status =
        page:CreateFontString(
            nil, "OVERLAY", "GameFontHighlightSmall"
        )

    page.status:SetPoint(
        "TOP", border, "BOTTOM", 0, -10
    )

    page.status:SetWidth(690)
    page.status:SetJustifyH("CENTER")
    page.status:SetJustifyV("TOP")
    SetColor(page.status, Colors.inkMuted)

    page.primaryButton =
        MakeButton(page, T("SELECT"), 180, 26)

    page.primaryButton:SetPoint(
        "BOTTOM", page, "BOTTOM", -108, 10
    )

    page.secondaryButton =
        MakeButton(page, T("REGENERATE"), 180, 26)

    page.secondaryButton:SetPoint(
        "LEFT",
        page.primaryButton,
        "RIGHT",
        18,
        0
    )

    page.restoreButton =
        MakeButton(page, T("RESTORE"), 230, 26)

    page.restoreButton:SetPoint(
        "LEFT",
        page.primaryButton,
        "RIGHT",
        16,
        0
    )

    page.restoreButton:Hide()

    page.primaryButton:SetScript("OnClick", function()
        if page.mode == "IMPORT" then
            Validate(page)

        elseif page.exportValid then
            page.editor:SetFocus()
            page.editor:HighlightText()

            SetStatus(
                page,
                T("SELECTED"),
                false
            )
        end
    end)

    page.secondaryButton:SetScript("OnClick", function()
        if page.mode == "EXPORT" then
            FreshExport(page)
        end
    end)

    page.restoreButton:SetScript("OnClick", function()
        Restore(page)
    end)

    page.exportTab:SetScript("OnClick", function()
        SelectExport(page)
    end)

    page.importTab:SetScript("OnClick", function()
        SelectImport(page)
    end)

    frame.fjBackupPage = page
    page:Hide()
end

local function CreateActionButtons(frame)
    local left = frame.leftPanel
    if not left then return end

    if not frame.fjBackupButton then
        local button =
            MakeButton(left, T("DATA"), 60, 20)

        button:SetScript("OnClick", function()
            ShowPage(frame)
        end)

        frame.fjBackupButton = button
    end

    local dataButton = frame.fjBackupButton

    if dataButton:GetParent() ~= left then
        dataButton:SetParent(left)
    end

    dataButton:ClearAllPoints()
    dataButton:SetSize(60, 20)

    -- User-adjusted positioning, unchanged.
    dataButton:SetPoint(
        "TOPRIGHT",
        left,
        "TOPRIGHT",
        0,
        -158
    )

    local statistics =
        frame.fjLifetimeStatisticsButton

    if statistics then
        if statistics:GetParent() ~= left then
            statistics:SetParent(left)
        end

        statistics:ClearAllPoints()
        statistics:SetSize(88, 20)

        statistics:SetPoint(
            "RIGHT",
            dataButton,
            "LEFT",
            -4,
            0
        )
    end
end

local function InstallNavigation(frame)
    if frame.fjBackupNavigationHooks then
        return
    end

    for _, button in ipairs({
        frame.overviewButton,
        frame.timelineButton,
        frame.historyButton
    }) do
        if button then
            button:HookScript("OnClick", function()
                HidePage(frame)
            end)
        end
    end

    frame.fjBackupNavigationHooks = true
end

local function EnsureUI()
    local frame = _G.ForeverJourneyMainFrame
    if not frame then return end

    CreatePage(frame)
    CreateActionButtons(frame)
    InstallNavigation(frame)
end

function FJ.BackupUI.Refresh()
    EnsureUI()
end

function FJ.BackupUI.Show()
    EnsureUI()

    local frame = _G.ForeverJourneyMainFrame

    if frame and frame.fjBackupPage then
        ShowPage(frame)
    end
end

function FJ.BackupUI.Hide()
    local frame = _G.ForeverJourneyMainFrame
    if frame then HidePage(frame) end
end

if FJ.UI and type(FJ.UI.Refresh) == "function" then
    local originalRefresh = FJ.UI.Refresh

    FJ.UI.Refresh = function(...)
        originalRefresh(...)
        EnsureUI()
    end
end
