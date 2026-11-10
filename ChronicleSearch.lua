local addonName, FJ = ...

FJ.ChronicleSearch = {}

local Search = FJ.ChronicleSearch
local Colors = FJ.Theme.Colors
local isRussian = GetLocale() == "ruRU"

local TEXT = {
    placeholder = isRussian
        and "ПОИСК ПО ХРОНИКЕ..."
        or "SEARCH CHRONICLE...",

    empty = isRussian
        and "По вашему запросу ничего не найдено."
        or "No memories match your search."
}

-- Lua 5.1 does not reliably lowercase Russian UTF-8.
-- Normalize Cyrillic uppercase letters manually.
-- Treat е and ё as equivalent.

local function Normalize(value)
    if type(value) ~= "string" then
        return ""
    end

    local parts = {}
    local index = 1
    local length = #value

    while index <= length do
        local first = string.byte(value, index)
        local second =
            index < length
            and string.byte(value, index + 1)
            or nil

        if first == 208 and second then
            if second >= 144 and second <= 159 then
                -- А-П -> а-п
                parts[#parts + 1] =
                    string.char(208, second + 32)

                index = index + 2

            elseif second >= 160 and second <= 175 then
                -- Р-Я -> р-я
                parts[#parts + 1] =
                    string.char(209, second - 32)

                index = index + 2

            elseif second == 129 then
                -- Ё -> е
                parts[#parts + 1] =
                    string.char(208, 181)

                index = index + 2
            else
                parts[#parts + 1] =
                    string.char(first)

                index = index + 1
            end

        elseif first == 209 and second == 145 then
            -- ё -> е
            parts[#parts + 1] =
                string.char(208, 181)

            index = index + 2

        elseif first < 128 then
            parts[#parts + 1] =
                string.char(first):lower()

            index = index + 1
        else
            parts[#parts + 1] =
                string.char(first)

            index = index + 1
        end
    end

    return table.concat(parts)
        :gsub("%s+", " ")
        :match("^%s*(.-)%s*$")
end

local function Matches(memory, words)
    if type(memory) ~= "table" then
        return false
    end

    local location = memory.location

    local locationName =
        type(location) == "table"
        and location.name
        or location

    local text = Normalize(
        table.concat({
            tostring(memory.title or ""),
            tostring(memory.description or ""),
            tostring(locationName or "")
        }, " ")
    )

    for _, word in ipairs(words) do
        if not string.find(
            text,
            word,
            1,
            true
        ) then
            return false
        end
    end

    return true
end

function Search.Filter(memories, query)
    local normalized = Normalize(query)

    if normalized == "" then
        return memories or {}
    end

    local words = {}

    for word in string.gmatch(
        normalized,
        "%S+"
    ) do
        words[#words + 1] = word
    end

    local results = {}

    for _, memory in ipairs(
        memories or {}
    ) do
        if Matches(memory, words) then
            results[#results + 1] = memory
        end
    end

    return results
end

local function RefreshSearch(frame)
    if frame and frame.chroniclePage then
        FJ.ChronicleUI.Refresh(frame)
    end
end

local function ScheduleRefresh(frame)
    frame.chronicleSearchRevision =
        (frame.chronicleSearchRevision or 0) + 1

    local revision =
        frame.chronicleSearchRevision

    if C_Timer
        and type(C_Timer.After) == "function" then

        C_Timer.After(
            0.18,
            function()
                if frame.chronicleSearchRevision
                    == revision then

                    RefreshSearch(frame)
                end
            end
        )
    else
        RefreshSearch(frame)
    end
end

local function UpdatePlaceholder(frame)
    if not frame.chronicleSearchPlaceholder
        or not frame.chronicleSearchEditBox then

        return
    end

    local editBox =
        frame.chronicleSearchEditBox

    local isEmpty =
        (editBox:GetText() or "") == ""

    if isEmpty and not editBox:HasFocus() then
        frame.chronicleSearchPlaceholder:Show()
    else
        frame.chronicleSearchPlaceholder:Hide()
    end

    if frame.chronicleSearchClearButton then
        if isEmpty then
            frame.chronicleSearchClearButton:Hide()
        else
            frame.chronicleSearchClearButton:Show()
        end
    end
end

local function CreateControls(frame)
    if frame.chronicleSearchEditBox
        or not frame.chroniclePage then

        return
    end

    local parent = frame.chroniclePage

    local container =
        CreateFrame("Frame", nil, parent)

    container:SetSize(386, 22)

    container:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        36,
        -40
    )

    local line =
        container:CreateTexture(
            nil,
            "BACKGROUND"
        )

    line:SetPoint(
        "BOTTOMLEFT",
        container,
        "BOTTOMLEFT",
        0,
        0
    )

    line:SetPoint(
        "BOTTOMRIGHT",
        container,
        "BOTTOMRIGHT",
        0,
        0
    )

    line:SetHeight(1)

    line:SetColorTexture(
        Colors.goldMuted.r,
        Colors.goldMuted.g,
        Colors.goldMuted.b,
        0.40
    )

    local editBox =
        CreateFrame(
            "EditBox",
            nil,
            container
        )

    editBox:SetAutoFocus(false)
    editBox:SetMultiLine(false)

    editBox:SetFontObject(
        "GameFontHighlightSmall"
    )

    editBox:SetSize(345, 20)

    editBox:SetPoint(
        "LEFT",
        container,
        "LEFT",
        8,
        0
    )

    editBox:SetMaxLetters(120)

    editBox:SetTextColor(
        Colors.ink.r,
        Colors.ink.g,
        Colors.ink.b
    )

    local placeholder =
        container:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlightSmall"
        )

    placeholder:SetPoint(
        "LEFT",
        editBox,
        "LEFT",
        0,
        0
    )

    placeholder:SetText(
        TEXT.placeholder
    )

    FJ.Theme.ApplyTextColor(
        placeholder,
        Colors.inkMuted
    )

    local clear =
        CreateFrame(
            "Button",
            nil,
            container
        )

    clear:SetSize(24, 20)

    clear:SetPoint(
        "RIGHT",
        container,
        "RIGHT",
        -3,
        0
    )

    local clearLabel =
        clear:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormal"
        )

    clearLabel:SetPoint(
        "CENTER",
        clear,
        "CENTER",
        0,
        0
    )

    clearLabel:SetText("X")

    FJ.Theme.ApplyTextColor(
        clearLabel,
        Colors.goldMuted
    )

    clear:SetScript(
        "OnClick",
        function()
            editBox:SetText("")
            editBox:ClearFocus()
        end
    )

    editBox:SetScript(
        "OnEscapePressed",
        function(self)
            if self:GetText() ~= "" then
                self:SetText("")
            else
                self:ClearFocus()
            end
        end
    )

    editBox:SetScript(
        "OnEnterPressed",
        function(self)
            self:ClearFocus()
        end
    )

    editBox:SetScript(
        "OnEditFocusGained",
        function()
            UpdatePlaceholder(frame)
        end
    )

    editBox:SetScript(
        "OnEditFocusLost",
        function()
            UpdatePlaceholder(frame)
        end
    )

    editBox:SetScript(
        "OnTextChanged",
        function(self)
            local newQuery =
                Normalize(self:GetText())

            UpdatePlaceholder(frame)

            if newQuery ==
                (frame.chronicleSearchQuery or "") then

                return
            end

            frame.chronicleSearchQuery = newQuery

            ScheduleRefresh(frame)
        end
    )

    frame.chronicleSearchEditBox = editBox
    frame.chronicleSearchPlaceholder = placeholder
    frame.chronicleSearchClearButton = clear
    frame.chronicleSearchQuery = ""

    local emptyText =
        parent:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlight"
        )

    emptyText:SetPoint(
        "CENTER",
        parent,
        "CENTER",
        0,
        -10
    )

    emptyText:SetText(TEXT.empty)

    FJ.Theme.ApplyTextColor(
        emptyText,
        Colors.inkMuted
    )

    emptyText:Hide()

    frame.chronicleSearchEmptyText =
        emptyText

    UpdatePlaceholder(frame)
end

-- ChronicleFilters wraps this refresh afterward.
-- It supplies the type/favorites-filtered memories.
-- Search is applied to that result.

local baseRefresh =
    FJ.ChronicleUI.Refresh

FJ.ChronicleUI.Refresh =
    function(frame)
        frame =
            frame
            or ForeverJourneyMainFrame

        if not frame
            or not frame.chroniclePage then

            return baseRefresh(frame)
        end

        CreateControls(frame)

        local query =
            frame.chronicleSearchQuery or ""

        if query == "" then
            frame.chronicleSearchFound = nil

            if frame.chronicleSearchEmptyText then
                frame.chronicleSearchEmptyText:Hide()
            end

            if frame.chronicleEmptyText then
                frame.chronicleEmptyText:SetAlpha(1)
            end

            return baseRefresh(frame)
        end

        local originalGetter =
            FJ.ViewModel.GetAllMemories

        local filtered =
            Search.Filter(
                originalGetter(),
                query
            )

        frame.chronicleSearchFound =
            #filtered

        FJ.ViewModel.GetAllMemories =
            function()
                return filtered
            end

        local ok, result =
            pcall(
                baseRefresh,
                frame
            )

        FJ.ViewModel.GetAllMemories =
            originalGetter

        if not ok then
            error(result, 0)
        end

        if frame.chronicleSearchEmptyText then
            if #filtered == 0 then
                frame.chronicleSearchEmptyText:Show()

                if frame.chronicleEmptyText then
                    frame.chronicleEmptyText:SetAlpha(0)
                end
            else
                frame.chronicleSearchEmptyText:Hide()

                if frame.chronicleEmptyText then
                    frame.chronicleEmptyText:SetAlpha(1)
                end
            end
        end

        return result
    end