local addonName, FJ = ...

-- Shared parchment input styling for manual memories and personal notes.
-- The stock EditBox caret is difficult to see on light parchment.
FJ.InputVisuals = {}

local InputVisuals = FJ.InputVisuals

function InputVisuals.Attach(edit, options)
    if not edit or edit.fjParchmentInputReady then
        return
    end

    options = options or {}

    local insetX = options.insetX or 8
    local insetY = options.insetY or 7
    local defaultHeight = options.cursorHeight or 16
    local scroll = options.scrollFrame

    edit:SetTextColor(0.18, 0.11, 0.07, 1)
    edit:SetHighlightColor(0.88, 0.58, 0.18, 0.80)

    local caret = edit:CreateTexture(nil, "OVERLAY")
    caret:SetColorTexture(0.19, 0.11, 0.06, 1)
    caret:SetSize(2, defaultHeight)
    caret:Hide()

    local focusLine = edit:CreateTexture(nil, "OVERLAY")
    focusLine:SetPoint("BOTTOMLEFT", edit, "BOTTOMLEFT", 1, 1)
    focusLine:SetPoint("BOTTOMRIGHT", edit, "BOTTOMRIGHT", -1, 1)
    focusLine:SetHeight(1)
    focusLine:SetColorTexture(0.66, 0.39, 0.12, 0.78)
    focusLine:Hide()

    edit.fjParchmentInputReady = true
    edit.fjParchmentCaret = caret
    edit.fjParchmentBlink = 0
    edit.fjParchmentCursorKnown = false

    local function PlaceCaret(self, x, y, height)
        caret:ClearAllPoints()
        caret:SetPoint(
            "TOPLEFT", self, "TOPLEFT",
            x + insetX, y - insetY
        )
        caret:SetSize(2, height)
        self.fjParchmentCursorKnown = true
        self.fjParchmentBlink = 0

        if self:HasFocus() then
            caret:Show()
        end
    end

    edit:SetScript("OnCursorChanged", function(self, x, y, width, height)
        if type(x) ~= "number" or type(y) ~= "number" then
            return
        end

        local cursorHeight =
            type(height) == "number" and height > 0
            and height or defaultHeight

        PlaceCaret(self, x, y, cursorHeight)

        if not scroll or not self:HasFocus() then
            return
        end

        local viewportHeight = scroll:GetHeight()
        if not viewportHeight or viewportHeight <= 0 then
            return
        end

        local offset = scroll:GetVerticalScroll() or 0
        local cursorTop = math.max(0, -y)

        if cursorTop < offset then
            scroll:SetVerticalScroll(cursorTop)
        elseif cursorTop + cursorHeight > offset + viewportHeight then
            scroll:SetVerticalScroll(
                math.max(0, cursorTop + cursorHeight - viewportHeight)
            )
        end
    end)

    edit:SetScript("OnEditFocusGained", function(self)
        self.fjParchmentBlink = 0
        focusLine:Show()

        -- An empty EditBox need not fire OnCursorChanged on initial focus.
        -- Show a caret at the beginning even before the first keystroke.
        if not self.fjParchmentCursorKnown then
            PlaceCaret(self, 0, 0, defaultHeight)
        else
            caret:Show()
        end
    end)

    edit:SetScript("OnEditFocusLost", function()
        caret:Hide()
        focusLine:Hide()
    end)

    edit:SetScript("OnUpdate", function(self, elapsed)
        if not self:HasFocus() then
            caret:Hide()
            return
        end

        self.fjParchmentBlink =
            ((self.fjParchmentBlink or 0) + elapsed) % 1.0

        if self.fjParchmentBlink < 0.58 then
            caret:Show()
        else
            caret:Hide()
        end
    end)
end
