
local addonName, FJ = ...

-- Forever Journey 0.8.0 - Chapter Timeline
-- Clickable headings open the existing chapter editor.
-- Explicit memory assignments take priority over timestamps.
FJ.ChapterTimeline = {}

local Timeline = FJ.ChapterTimeline
local Chapters = FJ.Chapters
local Theme = FJ.Theme
local Colors = Theme.Colors
local Textures = Theme.Textures
local isRussian = GetLocale() == "ruRU"

local T = isRussian and {
    chapter = "ГЛАВА %s",
    untitled = "Без названия",
    edit = "Нажми, чтобы изменить главу"
} or {
    chapter = "CHAPTER %s",
    untitled = "Untitled",
    edit = "Click to edit this chapter"
}

local ROW_WIDTH = 670
local HEIGHT_SIMPLE = 60
local HEIGHT_WITH_DESCRIPTION = 84

local function Roman(value)
    value = math.floor(tonumber(value) or 1)
    if value < 1 then return tostring(value) end

    local result = {}
    local symbols = {
        {1000, "M"}, {900, "CM"}, {500, "D"},
        {400, "CD"}, {100, "C"}, {90, "XC"},
        {50, "L"}, {40, "XL"}, {10, "X"},
        {9, "IX"}, {5, "V"}, {4, "IV"}, {1, "I"}
    }

    for _, item in ipairs(symbols) do
        while value >= item[1] do
            result[#result + 1] = item[2]
            value = value - item[1]
        end
    end

    return table.concat(result)
end

local function Preview(value, maxBytes)
    if type(value) ~= "string" then return "" end

    local text = value:gsub("[%c]+", " "):gsub("%s+", " ")
    text = text:match("^%s*(.-)%s*$") or ""

    if #text <= maxBytes then return text end

    local last = maxBytes

    while last > 0 do
        local nextByte = text:byte(last + 1)

        if not nextByte
            or nextByte < 128
            or nextByte >= 192 then
            break
        end

        last = last - 1
    end

    return text:sub(1, last) .. "…"
end

local function Label(parent, font, x, y, width, height, color)
    local text = parent:CreateFontString(nil, "OVERLAY", font)

    text:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    text:SetSize(width, height)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")

    Theme.ApplyTextColor(text, color)
    return text
end

local function CloseTooltip(row)
    if GameTooltip and GameTooltip:IsOwned(row) then
        GameTooltip:Hide()
    end
end

local function CreateHeading(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(ROW_WIDTH, HEIGHT_SIMPLE)
    row:RegisterForClicks("LeftButtonUp")
    row.fjChapterHeading = true

    row.marker = row:CreateTexture(nil, "ARTWORK")
    row.marker:SetTexture(Textures.markerGeneric)
    row.marker:SetSize(38, 38)
    row.marker:SetPoint("TOPLEFT", row, "TOPLEFT", 21, -7)
    row.marker:SetAlpha(0.85)

    row.line = row:CreateTexture(nil, "ARTWORK")
    row.line:SetWidth(2)
    row.line:SetPoint("TOPLEFT", row, "TOPLEFT", 38, -45)
    row.line:SetColorTexture(
        Colors.timeline.r,
        Colors.timeline.g,
        Colors.timeline.b,
        Colors.timeline.a or 1
    )

    row.number = Label(
        row,
        "GameFontNormalSmall",
        78, -4, 250, 17,
        Colors.goldMuted
    )

    row.title = Label(
        row,
        "GameFontNormalLarge",
        78, -22, 548, 24,
        Colors.ink
    )

    row.description = Label(
        row,
        "GameFontHighlightSmall",
        78, -48, 535, 31,
        Colors.inkMuted
    )

    if type(row.description.SetMaxLines) == "function" then
        row.description:SetMaxLines(2)
    end

    row:SetScript("OnEnter", function(self)
        Theme.ApplyTextColor(self.title, Colors.goldMuted)
        self.marker:SetAlpha(1)

        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(T.edit)
            GameTooltip:Show()
        end
    end)

    row:SetScript("OnLeave", function(self)
        Theme.ApplyTextColor(self.title, Colors.ink)
        self.marker:SetAlpha(0.85)
        CloseTooltip(self)
    end)

    row:SetScript("OnHide", CloseTooltip)

    row:SetScript("OnClick", function(self)
        if type(self.chapterID) ~= "string" then
            return
        end

        local editor = FJ.ChaptersUI

        if editor and type(editor.OpenChapter) == "function" then
            CloseTooltip(self)

            editor.OpenChapter(
                _G.ForeverJourneyMainFrame,
                self.chapterID
            )
        end
    end)

    return row
end

local function UpdateHeading(row, chapter, number)
    local name = Preview(chapter.title, 180)
    local description = Preview(chapter.description, 124)

    local height = description ~= ""
        and HEIGHT_WITH_DESCRIPTION
        or HEIGHT_SIMPLE

    row.chapterID = chapter.id
    row:SetHeight(height)

    row.number:SetText(
        string.format(T.chapter, Roman(number))
    )

    row.title:SetText(
        name ~= "" and name or T.untitled
    )

    row.description:SetText(description)
    row.description:SetShown(description ~= "")
    row.line:SetHeight(height - 47)

    Theme.ApplyTextColor(row.title, Colors.ink)
    row.marker:SetAlpha(0.85)

    return height
end

-- Collect already rendered rows from Chronicle.
-- Preserve its original search, filtering and rendering pipeline.
local function CollectRows(child)
    local rows = {}
    local sequence = 0

    local function Add(row)
        if not row:IsShown() or row.fjChapterHeading then
            return
        end

        local kind

        if row.memoryView and row.favoriteButton then
            kind = "memory"
        elseif row.divider and row.title and not row.memoryView then
            kind = "date"
        else
            return
        end

        local point, relative, relativePoint, x, y = row:GetPoint(1)

        if point ~= "TOPLEFT"
            or relative ~= child
            or relativePoint ~= "TOPLEFT"
            or type(y) ~= "number" then
            return
        end

        sequence = sequence + 1

        rows[#rows + 1] = {
            frame = row,
            kind = kind,
            x = x or 0,
            y = y,
            sequence = sequence
        }
    end

    if type(child.EnumerateChildren) == "function" then
        local previous

        while true do
            local row = child:EnumerateChildren(previous)

            if not row then break end

            Add(row)
            previous = row
        end
    else
        for _, row in ipairs({child:GetChildren()}) do
            Add(row)
        end
    end

    table.sort(rows, function(a, b)
        if a.y == b.y then
            return a.sequence < b.sequence
        end

        return a.y > b.y
    end)

    return rows
end

-- Explicit chapterId is stored on memory.raw, not on the
-- displayed ViewModel wrapper.
--
-- Two memories with the same timestamp can belong to
-- different chapters after a manual reassignment.
-- Therefore chapter resolution must never be cached by time.
local function ResolveChapter(memoryView)
    if type(memoryView) ~= "table" then
        return nil
    end

    if type(Chapters.ResolveForMemory) == "function" then
        return Chapters.ResolveForMemory(memoryView)
    end

    -- Compatibility with older versions of Chapters.lua.
    local raw = type(memoryView.raw) == "table"
        and memoryView.raw or memoryView

    if raw.chapterId == false then
        return nil
    end

    if type(raw.chapterId) == "string" then
        if type(Chapters.FindByID) == "function" then
            return Chapters.FindByID(raw.chapterId)
        end

        return nil
    end

    local timestamp = raw.timestamp or memoryView.timestamp

    if type(Chapters.FindForTimestamp) == "function" then
        return Chapters.FindForTimestamp(timestamp)
    end

    return nil
end

local function UpdateScrollbar(frame)
    local scroll = frame.chronicleScroll
    local track = frame.chronicleScrollTrack
    local thumb = frame.chronicleScrollThumb

    if not scroll or not track or not thumb then
        return
    end

    local maximum = scroll:GetVerticalScrollRange() or 0

    if maximum <= 0 then
        track:Hide()
        thumb:Hide()
        return
    end

    track:Show()
    thumb:Show()

    local current = math.min(
        scroll:GetVerticalScroll(),
        maximum
    )

    local travel = math.max(
        track:GetHeight() - thumb:GetHeight(),
        0
    )

    thumb:ClearAllPoints()

    thumb:SetPoint(
        "TOP",
        track,
        "TOP",
        0,
        -travel * current / maximum
    )
end

function Timeline.Apply(frame)
    if not frame
        or not frame.chronicleScrollChild
        or not frame.chronicleScroll
        or not Chapters then
        return
    end

    local child = frame.chronicleScrollChild
    local headings = frame.fjChapterTimelineRows

    if not headings then
        headings = {}
        frame.fjChapterTimelineRows = headings
    end

    for _, heading in ipairs(headings) do
        heading:Hide()
    end

    if not frame.chronicleScroll:IsShown() then
        return
    end

    local chapters = Chapters.GetAll() or {}

    if #chapters == 0 then
        return
    end

    local rows = CollectRows(child)
    local chapterNumbers = {}

    for number, chapter in ipairs(chapters) do
        if type(chapter) == "table"
            and type(chapter.id) == "string" then

            chapterNumbers[chapter.id] = number
        end
    end

    local previousChapterID
    local previousMemoryRow

    local extraHeight = 0
    local usedHeadings = 0

    for _, item in ipairs(rows) do
        if item.kind == "memory" then
            local chapter = ResolveChapter(item.frame.memoryView)
            local chapterID = chapter and chapter.id or nil

            if chapterID ~= previousChapterID
                and previousMemoryRow
                and previousMemoryRow.line then

                previousMemoryRow.line:Hide()
            end

            if chapterID and chapterID ~= previousChapterID then
                usedHeadings = usedHeadings + 1

                local heading = headings[usedHeadings]

                if not heading then
                    heading = CreateHeading(child)
                    headings[usedHeadings] = heading
                end

                local height = UpdateHeading(
                    heading,
                    chapter,
                    chapterNumbers[chapterID] or 1
                )

                heading:ClearAllPoints()

                heading:SetPoint(
                    "TOPLEFT",
                    child,
                    "TOPLEFT",
                    0,
                    item.y - extraHeight
                )

                heading:Show()
                extraHeight = extraHeight + height
            end

            previousChapterID = chapterID
            previousMemoryRow = item.frame
        end

        item.frame:ClearAllPoints()

        item.frame:SetPoint(
            "TOPLEFT",
            child,
            "TOPLEFT",
            item.x,
            item.y - extraHeight
        )
    end

    if extraHeight > 0 then
        child:SetHeight(child:GetHeight() + extraHeight)

        local scroll = frame.chronicleScroll
        local maximum = scroll:GetVerticalScrollRange() or 0

        if scroll:GetVerticalScroll() > maximum then
            scroll:SetVerticalScroll(maximum)
        end

        UpdateScrollbar(frame)
    end
end

-- Preserve Chronicle's original Refresh function.
local originalRefresh = FJ.ChronicleUI.Refresh

FJ.ChronicleUI.Refresh = function(frame)
    local result = originalRefresh(frame)

    Timeline.Apply(
        frame or _G.ForeverJourneyMainFrame
    )

    return result
end

-- Update headings when chapter metadata changes.
local function RefreshAfterMutation(method)
    local original = Chapters[method]

    if type(original) ~= "function" then
        return
    end

    Chapters[method] = function(...)
        local chapter, err = original(...)

        if chapter then
            local frame = _G.ForeverJourneyMainFrame

            if frame
                and frame.chroniclePage
                and frame.chroniclePage:IsShown() then

                FJ.ChronicleUI.Refresh(frame)
            end
        end

        return chapter, err
    end
end

RefreshAfterMutation("Create")
RefreshAfterMutation("Rename")
RefreshAfterMutation("SetDescription")
RefreshAfterMutation("Close")
