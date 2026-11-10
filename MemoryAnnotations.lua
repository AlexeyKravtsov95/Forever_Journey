
local addonName, FJ = ...

FJ.MemoryAnnotations = {}

local Notes = FJ.MemoryAnnotations
local Theme = FJ.Theme
local Colors = Theme.Colors
local Textures = Theme.Textures
local isRussian = GetLocale() == "ruRU"
local MAX_NOTE_BYTES = 2400

local TEXT = {
    buttonEmpty = isRussian and "+ ЗАМЕТКА" or "+ NOTE",
    buttonFilled = isRussian and "МОЯ ЗАМЕТКА" or "MY NOTE",
    title = isRussian and "ЛИЧНАЯ ЗАМЕТКА" or "PERSONAL NOTE",
    subtitle = isRussian and "К этому моменту путешествия" or "About this journey moment",
    help = isRussian
        and "Название, время, место и детали события останутся неизменными."
        or "The original title, time, location and event details stay unchanged.",
    prompt = isRussian and "ЧТО ХОЧЕТСЯ ЗАПОМНИТЬ?" or "WHAT WOULD YOU LIKE TO REMEMBER?",
    save = isRussian and "СОХРАНИТЬ" or "SAVE",
    cancel = isRussian and "ОТМЕНА" or "CANCEL",
    empty = isRussian and "Нажми, чтобы добавить личную заметку." or "Click to add a personal note.",
    tooLong = isRussian and "Заметка слишком длинная." or "The note is too long.",
    failed = isRussian and "Не удалось сохранить заметку." or "Could not save the note."
}

local function Trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function IsAutomatic(memory)
    return type(memory) == "table"
        and type(memory.id) == "string"
        and memory.id ~= ""
        and not (FJ.Memories.IsManual and FJ.Memories.IsManual(memory))
end

function Notes.Get(memoryID)
    local memory = FJ.Memories.FindByID(memoryID)
    if not IsAutomatic(memory) then
        return nil
    end
    return type(memory.personalNote) == "string"
        and memory.personalNote or nil
end

function Notes.Save(memoryID, value)
    local memory = FJ.Memories.FindByID(memoryID)
    if not IsAutomatic(memory) then
        return false, "NOT_AUTOMATIC_MEMORY"
    end
    if type(value) ~= "string" then
        return false, "INVALID_NOTE"
    end
    if #value > MAX_NOTE_BYTES then
        return false, "NOTE_TOO_LONG"
    end

    local note = Trim(value)
    if note == "" then note = nil end
    if memory.personalNote == note then
        return true, memory
    end

    -- Preserve the original event's fields and metadata.
    memory.personalNote = note
    memory.personalNoteUpdatedAt = note and time() or nil

    if FJ.UI and type(FJ.UI.RefreshIfVisible) == "function" then
        FJ.UI.RefreshIfVisible()
    end
    return true, memory
end

local function Paint(text, color)
    Theme.ApplyTextColor(text, color)
end

local function MakeButton(parent, label, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)

    local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetAllPoints(button)
    text:SetJustifyH("CENTER")
    text:SetText(label)
    Paint(text, Colors.goldMuted)
    button.label = text

    button:SetScript("OnEnter", function(self)
        Paint(self.label, Colors.gold)
    end)
    button:SetScript("OnLeave", function(self)
        Paint(self.label, Colors.goldMuted)
    end)
    return button
end

local function AddBorder(panel)
    local function Edge()
        local line = panel:CreateTexture(nil, "OVERLAY")
        line:SetColorTexture(
            Colors.goldMuted.r, Colors.goldMuted.g, Colors.goldMuted.b, 0.75
        )
        return line
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
    local panel = frame.chronicleNotePanel
    if panel then
        panel.edit:ClearFocus()
        panel.memoryID = nil
        panel.error:SetText("")
    end
    if frame.chronicleNoteOverlay then
        frame.chronicleNoteOverlay:Hide()
    end
end

local function ResizeInput(panel)
    if not panel.edit or not panel.scroll then return end
    local height
    if type(panel.edit.GetTextHeight) == "function" then
        local ok, measured = pcall(panel.edit.GetTextHeight, panel.edit)
        if ok and type(measured) == "number" and measured > 0 then
            height = measured + 25
        end
    end
    if not height then
        local content = panel.edit:GetText() or ""
        local _, breaks = content:gsub("\n", "")
        height = (math.ceil(#content / 65) + breaks + 1) * 16 + 25
    end
    panel.edit:SetHeight(math.max(112, math.min(height, 1200)))
end

local function EnsureEditor(frame)
    if frame.chronicleNoteOverlay or not frame.chroniclePage then return end

    local overlay = CreateFrame("Frame", nil, frame.chroniclePage)
    overlay:SetAllPoints(frame.chroniclePage)
    overlay:SetFrameLevel(frame.chroniclePage:GetFrameLevel() + 40)
    overlay:EnableMouse(true)

    local shade = overlay:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints(overlay)
    shade:SetColorTexture(0, 0, 0, 0)

    local panel = CreateFrame("Frame", nil, overlay)
    panel:SetSize(560, 335)
    panel:SetPoint("CENTER", overlay, "CENTER", 0, 0)
    panel:SetFrameLevel(overlay:GetFrameLevel() + 1)
    panel:EnableMouse(true)

    local background = panel:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(panel)
    background:SetTexture(Textures.parchment)
    AddBorder(panel)

    local heading = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOP", panel, "TOP", 0, -22)
    heading:SetText(TEXT.title)
    Paint(heading, Colors.ink)

    local subtitle = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOP", heading, "BOTTOM", 0, -5)
    subtitle:SetText(TEXT.subtitle)
    Paint(subtitle, Colors.inkMuted)

    local eventTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    eventTitle:SetPoint("TOP", panel, "TOP", 0, -73)
    eventTitle:SetWidth(490)
    eventTitle:SetJustifyH("CENTER")
    Paint(eventTitle, Colors.ink)
    panel.eventTitle = eventTitle

    local meta = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    meta:SetPoint("TOP", eventTitle, "BOTTOM", 0, -6)
    meta:SetWidth(490)
    meta:SetJustifyH("CENTER")
    Paint(meta, Colors.inkMuted)
    panel.meta = meta

    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", panel, "TOPLEFT", 30, -129)
    label:SetText(TEXT.prompt)
    Paint(label, Colors.goldMuted)

    local border = CreateFrame("Frame", nil, panel)
    border:SetPoint("TOPLEFT", panel, "TOPLEFT", 30, -149)
    border:SetSize(500, 110)
    AddBorder(border)

    local scroll = CreateFrame("ScrollFrame", nil, border, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", border, "TOPLEFT", 8, -5)
    scroll:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -26, 5)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetAutoFocus(false)
    edit:SetMultiLine(true)
    edit:SetFontObject("GameFontNormalSmall")
    edit:SetWidth(452)
    edit:SetHeight(112)
    edit:SetMaxLetters(800)
    edit:SetTextInsets(5, 5, 4, 4)

    edit:SetScript("OnEscapePressed", function()
        Close(frame)
    end)

    edit:SetScript("OnTextChanged", function()
        ResizeInput(panel)
        panel.error:SetText("")
    end)

    scroll:SetScrollChild(edit)
    panel.scroll = scroll
    panel.edit = edit

    FJ.InputVisuals.Attach(
        edit,
        { insetX = 5, insetY = 4, cursorHeight = 15, scrollFrame = scroll }
    )

    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOP", border, "BOTTOM", 0, -8)
    hint:SetWidth(500)
    hint:SetText(TEXT.help)
    Paint(hint, Colors.inkMuted)

    local errorText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    errorText:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 30, 22)
    errorText:SetWidth(280)
    errorText:SetJustifyH("LEFT")
    errorText:SetTextColor(0.58, 0.18, 0.12)
    panel.error = errorText

    local save = MakeButton(panel, TEXT.save, 95, 26)
    save:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 15)
    save:SetScript("OnClick", function()
        if not panel.memoryID then return end
        local note = panel.edit:GetText() or ""
        if #note > MAX_NOTE_BYTES then
            panel.error:SetText(TEXT.tooLong)
            return
        end

        local success = Notes.Save(panel.memoryID, note)
        if not success then
            panel.error:SetText(TEXT.failed)
            return
        end
        Close(frame)
    end)

    local cancel = MakeButton(panel, TEXT.cancel, 95, 26)
    cancel:SetPoint("RIGHT", save, "LEFT", -8, 0)
    cancel:SetScript("OnClick", function()
        Close(frame)
    end)

    frame.chronicleNoteOverlay = overlay
    frame.chronicleNotePanel = panel
    overlay:Hide()
end

local function OpenEditor(frame, memoryView)
    if not memoryView or not IsAutomatic(memoryView.raw) then return end
    EnsureEditor(frame)
    local panel = frame.chronicleNotePanel
    if not panel then return end

    panel.memoryID = memoryView.id
    panel.eventTitle:SetText(memoryView.title or "")

    local location = memoryView.location
    local locationName = type(location) == "table" and location.name or ""
    local dateText = memoryView.timestamp
        and date("%d.%m.%Y %H:%M", memoryView.timestamp) or ""

    panel.meta:SetText(dateText .. "  -  " .. (locationName or ""))
    panel.error:SetText("")
    panel.edit:SetText(Notes.Get(memoryView.id) or "")
    ResizeInput(panel)

    frame.chronicleNoteOverlay:Show()
    panel.edit:SetFocus()

    if type(panel.edit.SetCursorPosition) == "function" then
        local pos = 0
        if type(panel.edit.GetNumLetters) == "function" then
            pos = panel.edit:GetNumLetters()
        end
        panel.edit:SetCursorPosition(pos)
    end
end

local function EnsureRowButton(row)
    if row.personalNoteButton then return end

    local button = MakeButton(row, TEXT.buttonEmpty, 100, 20)
    button:SetPoint("RIGHT", row.favoriteButton, "LEFT", -4, 0)
    button:SetFrameLevel(row:GetFrameLevel() + 1)

    button:SetScript("OnClick", function()
        if row.ownerFrame and row.memoryView then
            OpenEditor(row.ownerFrame, row.memoryView)
        end
    end)

    button:SetScript("OnEnter", function(self)
        Paint(self.label, Colors.gold)
        if not GameTooltip then return end

        local note = row.memoryID and Notes.Get(row.memoryID)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(TEXT.title, 1, 0.82, 0.42)
        GameTooltip:AddLine(note or TEXT.empty, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function(self)
        Paint(self.label, Colors.goldMuted)
        if GameTooltip then GameTooltip:Hide() end
    end)

    row.personalNoteButton = button
end

local originalRefresh = FJ.ChronicleUI.Refresh

FJ.ChronicleUI.Refresh = function(frame)
    local result = originalRefresh(frame)
    frame = frame or _G.ForeverJourneyMainFrame

    if not frame or not frame.chronicleScrollChild then
        return result
    end

    for _, row in ipairs({ frame.chronicleScrollChild:GetChildren() }) do
        if row.memoryView and row.favoriteButton and row.editButton then
            EnsureRowButton(row)

            if row:IsShown() and IsAutomatic(row.memoryView.raw) then
                local note = Notes.Get(row.memoryID)
                row.personalNoteButton.label:SetText(
                    note and TEXT.buttonFilled or TEXT.buttonEmpty
                )
                row.personalNoteButton:Show()
            else
                row.personalNoteButton:Hide()
            end
        end
    end

    return result
end
