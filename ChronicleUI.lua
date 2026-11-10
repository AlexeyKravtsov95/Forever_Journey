local addonName, FJ = ...

FJ.ChronicleUI = {}

local Theme = FJ.Theme
local Colors = Theme.Colors
local Textures = Theme.Textures
local Layout = Theme.Window

local dateRows = {}
local memoryRows = {}

local DEFAULT_MARKER_SIZE = 42
local PROFESSION_MARKER_SIZE = 34

local OpenMemoryEditor
local OpenDeleteDialog
local HideMemoryEditor
local HideDeleteDialog
local OpenMemoryReader
local HideMemoryReader

local function L(key)
    return FJ.Locale.Get(key)
end

local function GetReadEntryHint()
    if GetLocale and GetLocale() == "ruRU" then
        return "Нажмите, чтобы прочитать запись"
    end

    return "Click to read entry"
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

local function CreateTextButton(
    parent,
    width,
    height,
    text,
    fontObject
)
    local button =
        CreateFrame(
            "Button",
            nil,
            parent
        )

    button:SetSize(
        width,
        height
    )

    button.label =
        button:CreateFontString(
            nil,
            "OVERLAY",
            fontObject
                or "GameFontNormalSmall"
        )

    button.label:SetAllPoints(
        button
    )

    button.label:SetJustifyH(
        "CENTER"
    )

    button.label:SetText(
        text or ""
    )

    Theme.ApplyTextColor(
        button.label,
        Colors.goldMuted
    )

    button:SetScript(
        "OnEnter",
        function(self)
            Theme.ApplyTextColor(
                self.label,
                Colors.gold
            )
        end
    )

    button:SetScript(
        "OnLeave",
        function(self)
            Theme.ApplyTextColor(
                self.label,
                Colors.goldMuted
            )
        end
    )

    return button
end

local function AddSimpleBorder(
    frame,
    color,
    alpha
)
    local borderColor =
        color
        or Colors.goldMuted

    local borderAlpha =
        alpha
        or 0.70

    local function CreateEdge()
        local edge =
            frame:CreateTexture(
                nil,
                "OVERLAY"
            )

        edge:SetColorTexture(
            borderColor.r,
            borderColor.g,
            borderColor.b,
            borderAlpha
        )

        return edge
    end

    local top =
        CreateEdge()

    top:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        0,
        0
    )

    top:SetPoint(
        "TOPRIGHT",
        frame,
        "TOPRIGHT",
        0,
        0
    )

    top:SetHeight(
        1
    )

    local bottom =
        CreateEdge()

    bottom:SetPoint(
        "BOTTOMLEFT",
        frame,
        "BOTTOMLEFT",
        0,
        0
    )

    bottom:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        0,
        0
    )

    bottom:SetHeight(
        1
    )

    local left =
        CreateEdge()

    left:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        0,
        0
    )

    left:SetPoint(
        "BOTTOMLEFT",
        frame,
        "BOTTOMLEFT",
        0,
        0
    )

    left:SetWidth(
        1
    )

    local right =
        CreateEdge()

    right:SetPoint(
        "TOPRIGHT",
        frame,
        "TOPRIGHT",
        0,
        0
    )

    right:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        0,
        0
    )

    right:SetWidth(
        1
    )
end

local function AddInputBackground(
    editBox
)
    local background =
        editBox:CreateTexture(
            nil,
            "BACKGROUND"
        )

    background:SetAllPoints(
        editBox
    )

    background:SetColorTexture(
        0.30,
        0.20,
        0.10,
        0.055
    )

    AddSimpleBorder(
        editBox,
        Colors.goldMuted,
        0.32
    )
end

local function ApplyParchmentPanelBackground(
    panel
)
    if not panel then
        return nil
    end

    local background =
        panel:CreateTexture(
            nil,
            "BACKGROUND"
        )

    background:SetAllPoints(
        panel
    )

    background:SetTexture(
        Textures.parchment
    )

    if type(background.SetTexCoord) == "function" then
        background:SetTexCoord(
            0.006,
            0.994,
            0.006,
            0.994
        )
    end

    return background
end

local function SetFavoriteIcon(
    button,
    favorite
)
    if not button
        or not button.icon then

        return
    end

    local atlas =
        favorite
        and "auctionhouse-icon-favorite"
        or "auctionhouse-icon-favorite-off"

    if type(
        button.icon.SetAtlas
    ) == "function" then

        button.icon:SetAtlas(
            atlas
        )
    end

    button.icon:SetSize(
        18,
        18
    )
end

local function ApplyMarkerLayout(
    row,
    memory
)
    if not row
        or not row.marker then

        return
    end

    local isProfession =
        memory
        and memory.semanticType
            == "PROFESSION_MILESTONE"

    local size =
        isProfession
        and PROFESSION_MARKER_SIZE
        or DEFAULT_MARKER_SIZE

    local inset =
        (
            DEFAULT_MARKER_SIZE
            - size
        ) / 2

    row.marker:ClearAllPoints()

    row.marker:SetSize(
        size,
        size
    )

    row.marker:SetPoint(
        "TOPLEFT",
        row,
        "TOPLEFT",
        18 + inset,
        -8 - inset
    )
end

local function ShowTooltip(
    owner,
    text
)
    if not GameTooltip
        or not text then

        return
    end

    GameTooltip:SetOwner(
        owner,
        "ANCHOR_RIGHT"
    )

    GameTooltip:SetText(
        text
    )

    GameTooltip:Show()
end

local function GetMemoryTypeLabel(
    memory
)
    if memory.source
        == "RECOVERED" then

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
        keys[
            memory.type
        ]

    if not key then
        return memory.type
            or L("UNKNOWN")
    end

    return L(
        key
    )
end

local function SetTabActive(
    button,
    active
)
    if not button
        or not button.background
        or not button.label then

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

local function GetDateKey(
    timestamp
)
    if not timestamp then
        return "unknown"
    end

    return date(
        "%Y-%m-%d",
        timestamp
    )
end

local function GetDateLabel(
    timestamp
)
    if not timestamp then
        return L(
            "CHRONICLE_UNKNOWN_DATE"
        )
    end

    return date(
        "%d.%m.%Y",
        timestamp
    )
end

local function GetAllMemories()
    if FJ.ViewModel.GetAllMemories then
        return FJ.ViewModel
            .GetAllMemories()
    end

    local recent =
        FJ.ViewModel.GetRecentMemories(
            999999
        )

    local result = {}

    for index =
        #recent,
        1,
        -1 do

        table.insert(
            result,
            recent[index]
        )
    end

    return result
end

local function CreateDateRow(
    parent
)
    local row =
        CreateFrame(
            "Frame",
            nil,
            parent
        )

    row:SetSize(
        670,
        34
    )

    row.title =
        CreateText(
            row,
            "GameFontNormal",
            "LEFT",
            row,
            "LEFT",
            18,
            0
        )

    Theme.ApplyTextColor(
        row.title,
        Colors.goldMuted
    )

    row.divider =
        CreateTexture(
            row,
            Textures.dividerHorizontal,
            "ARTWORK"
        )

    row.divider:SetSize(
        470,
        10
    )

    row.divider:SetPoint(
        "LEFT",
        row,
        "LEFT",
        178,
        0
    )

    return row
end

local function CreateMemoryRow(
    parent
)
    local row =
        CreateFrame(
            "Frame",
            nil,
            parent
        )

    row:SetSize(
        670,
        82
    )

    row.marker =
        CreateTexture(
            row,
            Textures.markerGeneric,
            "ARTWORK"
        )

    row.marker:SetSize(
        DEFAULT_MARKER_SIZE,
        DEFAULT_MARKER_SIZE
    )

    row.marker:SetPoint(
        "TOPLEFT",
        row,
        "TOPLEFT",
        18,
        -8
    )

    row.line =
        row:CreateTexture(
            nil,
            "ARTWORK"
        )

    row.line:SetWidth(
        2
    )

    row.line:SetColorTexture(
        Colors.timeline.r,
        Colors.timeline.g,
        Colors.timeline.b,
        Colors.timeline.a
    )

    row.line:SetPoint(
        "TOPLEFT",
        row,
        "TOPLEFT",
        38,
        -50
    )

    row.line:SetHeight(
        32
    )

    row.typeLabel =
        CreateText(
            row,
            "GameFontNormalSmall",
            "TOPLEFT",
            row,
            "TOPLEFT",
            78,
            -3
        )

    row.typeLabel:SetWidth(
        370
    )

    row.typeLabel:SetJustifyH(
        "LEFT"
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
            78,
            -22
        )

    row.title:SetWidth(
        470
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
            78,
            -43
        )

    row.meta:SetWidth(
        470
    )

    row.meta:SetJustifyH(
        "LEFT"
    )

    Theme.ApplyTextColor(
        row.meta,
        Colors.inkMuted
    )

    row.description =
        CreateText(
            row,
            "GameFontHighlightSmall",
            "TOPLEFT",
            row,
            "TOPLEFT",
            78,
            -61
        )

    row.description:SetWidth(
        470
    )

    row.description:SetJustifyH(
        "LEFT"
    )

    Theme.ApplyTextColor(
        row.description,
        Colors.inkMuted
    )

    -- The diary entry is opened by clicking its heading/body area.
    -- Keep this hit area clear of Edit/Delete/Favorite buttons.
    row.readButton =
        CreateFrame(
            "Button",
            nil,
            row
        )

    row.readButton:SetSize(
        360,
        66
    )

    row.readButton:SetPoint(
        "TOPLEFT",
        row,
        "TOPLEFT",
        76,
        -14
    )

    row.readButton:SetScript(
        "OnClick",
        function()
            if row.ownerFrame and row.memoryView then
                OpenMemoryReader(
                    row.ownerFrame,
                    row.memoryView
                )
            end
        end
    )

    row.readButton:SetScript(
        "OnEnter",
        function(self)
            Theme.ApplyTextColor(
                row.title,
                Colors.gold
            )
        end
    )

    row.readButton:SetScript(
        "OnLeave",
        function(self)
            Theme.ApplyTextColor(
                row.title,
                Colors.ink
            )
        end
    )

    row.favoriteButton =
        CreateFrame(
            "Button",
            nil,
            row
        )

    row.favoriteButton:SetSize(
        26,
        26
    )

    row.favoriteButton:SetPoint(
        "TOPRIGHT",
        row,
        "TOPRIGHT",
        -14,
        -3
    )

    row.favoriteButton.icon =
        row.favoriteButton:CreateTexture(
            nil,
            "ARTWORK"
        )

    row.favoriteButton.icon:SetPoint(
        "CENTER",
        row.favoriteButton,
        "CENTER",
        0,
        0
    )

    SetFavoriteIcon(
        row.favoriteButton,
        false
    )

    row.favoriteButton:SetScript(
        "OnClick",
        function()
            if not row.memoryID then
                return
            end

            FJ.Memories.ToggleFavorite(
                row.memoryID
            )
        end
    )

    row.favoriteButton:SetScript(
        "OnEnter",
        function(self)
            ShowTooltip(
                self,
                row.favorite
                    and L(
                        "MEMORY_UNFAVORITE"
                    )
                    or L(
                        "MEMORY_FAVORITE"
                    )
            )
        end
    )

    row.favoriteButton:SetScript(
        "OnLeave",
        function()
            if GameTooltip then
                GameTooltip:Hide()
            end
        end
    )

    row.deleteButton =
        CreateTextButton(
            row,
            74,
            20,
            L(
                "MANUAL_MEMORY_DELETE"
            ),
            "GameFontNormalSmall"
        )

    row.deleteButton:SetPoint(
        "RIGHT",
        row.favoriteButton,
        "LEFT",
        -2,
        0
    )

    row.deleteButton:SetScript(
        "OnClick",
        function()
            if row.ownerFrame
                and row.memoryView then

                OpenDeleteDialog(
                    row.ownerFrame,
                    row.memoryView
                )
            end
        end
    )

    row.editButton =
        CreateTextButton(
            row,
            74,
            20,
            L(
                "MANUAL_MEMORY_EDIT"
            ),
            "GameFontNormalSmall"
        )

    row.editButton:SetPoint(
        "RIGHT",
        row.deleteButton,
        "LEFT",
        -2,
        0
    )

    row.editButton:SetScript(
        "OnClick",
        function()
            if row.ownerFrame
                and row.memoryView then

                OpenMemoryEditor(
                    row.ownerFrame,
                    row.memoryView
                )
            end
        end
    )

    return row
end

local function GetEditorMetaText(
    memory
)
    local timestamp =
        memory
        and memory.timestamp
        or time()

    local location =
        memory
        and memory.location
        or FJ.Memories
            .GetCurrentLocation()

    local timeText =
        timestamp
        and date(
            "%d.%m.%Y, %H:%M",
            timestamp
        )
        or L(
            "UNKNOWN_TIME"
        )

    local locationText =
        FJ.Utils
            .GetLocalizedLocationName(
                location
            )

    return timeText
        .. "   -   "
        .. locationText
end

-- Full, scrollable text is available on click instead of being placed
-- directly inside the compact Chronicle timeline row.
local function CreateMemoryReader(frame)
    if frame.chronicleMemoryReader then
        return
    end

    -- Parent to the main window, so the reader can also open from
    -- Recent Journey without forcing a navigation to Chronicle.
    local overlay =
        CreateFrame(
            "Frame",
            nil,
            frame
        )

    overlay:SetAllPoints(frame)
    overlay:SetFrameLevel(frame:GetFrameLevel() + 55)
    overlay:EnableMouse(true)

    local panel =
        CreateFrame(
            "Frame",
            nil,
            overlay
        )

    panel:SetSize(540, 326)
    panel:SetPoint("CENTER", overlay, "CENTER", 0, 2)
    panel:SetFrameLevel(overlay:GetFrameLevel() + 1)
    panel:EnableMouse(true)

    panel.background =
        ApplyParchmentPanelBackground(
            panel
        )

    AddSimpleBorder(panel, Colors.goldMuted, 0.85)

    panel.title =
        CreateText(
            panel,
            "GameFontNormalLarge",
            "TOPLEFT",
            panel,
            "TOPLEFT",
            34,
            -24
        )

    panel.title:SetWidth(472)
    panel.title:SetJustifyH("LEFT")
    Theme.ApplyTextColor(panel.title, Colors.ink)

    panel.meta =
        CreateText(
            panel,
            "GameFontHighlightSmall",
            "TOPLEFT",
            panel,
            "TOPLEFT",
            34,
            -61
        )

    panel.meta:SetWidth(472)
    panel.meta:SetJustifyH("LEFT")
    Theme.ApplyTextColor(panel.meta, Colors.goldMuted)

    local scroll = CreateFrame("ScrollFrame", nil, panel)
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 34, -92)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -34, 57)
    scroll:EnableMouseWheel(true)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(472, 1)
    scroll:SetScrollChild(child)

    panel.body =
        CreateText(
            child,
            "GameFontHighlightSmall",
            "TOPLEFT",
            child,
            "TOPLEFT",
            0,
            0
        )

    panel.body:SetWidth(460)
    panel.body:SetJustifyH("LEFT")
    panel.body:SetJustifyV("TOP")
    Theme.ApplyTextColor(panel.body, Colors.ink)

    scroll:SetScript(
        "OnMouseWheel",
        function(self, delta)
            local maxScroll = self:GetVerticalScrollRange() or 0
            local target = self:GetVerticalScroll() - delta * 40
            self:SetVerticalScroll(math.max(0, math.min(target, maxScroll)))
        end
    )

    panel.scroll = scroll
    panel.scrollChild = child

    panel.closeButton =
        CreateTextButton(
            panel,
            96,
            26,
            (GetLocale and GetLocale() == "ruRU") and "Закрыть" or "Close",
            "GameFontNormal"
        )

    panel.closeButton:SetPoint(
        "BOTTOMRIGHT",
        panel,
        "BOTTOMRIGHT",
        -32,
        19
    )

    panel.closeButton:SetScript(
        "OnClick",
        function()
            HideMemoryReader(frame)
        end
    )

    panel.editButton =
        CreateTextButton(
            panel,
            96,
            26,
            L("MANUAL_MEMORY_EDIT"),
            "GameFontNormal"
        )

    panel.editButton:SetPoint(
        "RIGHT",
        panel.closeButton,
        "LEFT",
        -8,
        0
    )

    panel.editButton:SetScript(
        "OnClick",
        function()
            if panel.memoryView and panel.memoryView.canEdit == true then
                local memory = panel.memoryView
                HideMemoryReader(frame)

                -- The editor lives on the Chronicle page. If the
                -- reader was opened from Overview, navigate first.
                if frame.chroniclePage
                    and not frame.chroniclePage:IsShown()
                    and frame.timelineButton then
                    frame.timelineButton:Click()
                end

                OpenMemoryEditor(frame, memory)
            end
        end
    )

    frame.chronicleMemoryReader = overlay
    frame.chronicleMemoryReaderPanel = panel
    overlay:Hide()
end

HideMemoryReader =
    function(frame)
        if not frame or not frame.chronicleMemoryReader then
            return
        end

        if frame.chronicleMemoryReaderPanel then
            frame.chronicleMemoryReaderPanel.memoryView = nil
        end

        frame.chronicleMemoryReader:Hide()
    end

OpenMemoryReader =
    function(frame, memory)
        if not frame or not memory then
            return
        end

        CreateMemoryReader(frame)
        HideMemoryEditor(frame)
        HideDeleteDialog(frame)

        local panel = frame.chronicleMemoryReaderPanel
        local overlay = frame.chronicleMemoryReader
        if not panel or not overlay then
            return
        end

        panel.memoryView = memory
        panel.title:SetText(memory.title or L("UNKNOWN"))
        panel.meta:SetText(GetEditorMetaText(memory))

        local description = memory.description or memory.note or ""
        panel.body:SetText(description)

        local bodyHeight = panel.body:GetStringHeight() or 0
        panel.scrollChild:SetHeight(math.max(bodyHeight + 18, 1))
        panel.scroll:SetVerticalScroll(0)

        if memory.canEdit == true then
            panel.editButton:Show()
        else
            panel.editButton:Hide()
        end

        overlay:Show()
    end

local function CreateMemoryEditor(
    frame
)
    if frame.chronicleMemoryEditor
        or not frame.chroniclePage then

        return
    end

    local page =
        frame.chroniclePage

    local overlay =
        CreateFrame(
            "Frame",
            nil,
            page
        )

    overlay:SetAllPoints(
        page
    )

    overlay:SetFrameLevel(
        page:GetFrameLevel()
            + 30
    )

    overlay:EnableMouse(
        true
    )

    overlay.shade =
        overlay:CreateTexture(
            nil,
            "BACKGROUND"
        )

    overlay.shade:SetAllPoints(
        overlay
    )

    overlay.shade:SetColorTexture(
        0,
        0,
        0,
        0
    )

    local panel =
        CreateFrame(
            "Frame",
            nil,
            overlay
        )

    panel:SetSize(
        540,
        326
    )

    panel:SetPoint(
        "CENTER",
        overlay,
        "CENTER",
        0,
        2
    )

    panel:SetFrameLevel(
        overlay:GetFrameLevel()
            + 1
    )

    panel:EnableMouse(
        true
    )

    panel.background =
        ApplyParchmentPanelBackground(
            panel
        )

    AddSimpleBorder(
        panel,
        Colors.goldMuted,
        0.85
    )

    panel.title =
        CreateText(
            panel,
            "GameFontNormalLarge",
            "TOP",
            panel,
            "TOP",
            0,
            -24
        )

    Theme.ApplyTextColor(
        panel.title,
        Colors.ink
    )

    panel.captureHint =
        CreateText(
            panel,
            "GameFontHighlightSmall",
            "TOP",
            panel.title,
            "BOTTOM",
            0,
            -6
        )

    panel.captureHint:SetText(
        L(
            "MANUAL_MEMORY_AUTO_CAPTURE"
        )
    )

    Theme.ApplyTextColor(
        panel.captureHint,
        Colors.inkMuted
    )

    panel.meta =
        CreateText(
            panel,
            "GameFontHighlightSmall",
            "TOP",
            panel.captureHint,
            "BOTTOM",
            0,
            -5
        )

    Theme.ApplyTextColor(
        panel.meta,
        Colors.goldMuted
    )

    panel.titleLabel =
        CreateText(
            panel,
            "GameFontNormalSmall",
            "TOPLEFT",
            panel,
            "TOPLEFT",
            34,
            -88
        )

    panel.titleLabel:SetText(
        L(
            "MANUAL_MEMORY_TITLE_LABEL"
        )
    )

    Theme.ApplyTextColor(
        panel.titleLabel,
        Colors.goldMuted
    )

    panel.titleBox =
        CreateFrame(
            "EditBox",
            nil,
            panel
        )

    panel.titleBox:SetSize(
        472,
        30
    )

    panel.titleBox:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        34,
        -106
    )

    panel.titleBox:SetAutoFocus(
        false
    )

    if GameFontNormal then
        panel.titleBox:SetFontObject(
            GameFontNormal
        )
    end

    Theme.ApplyTextColor(
        panel.titleBox,
        Colors.ink
    )

    panel.titleBox:SetHighlightColor(
        Colors.goldMuted.r,
        Colors.goldMuted.g,
        Colors.goldMuted.b,
        0.35
    )

    panel.titleBox:SetTextInsets(
        8,
        8,
        0,
        0
    )

    panel.titleBox:SetMaxLetters(
        100
    )

    AddInputBackground(
        panel.titleBox
    )

    FJ.InputVisuals.Attach(
        panel.titleBox,
        { insetX = 8, insetY = 8, cursorHeight = 16 }
    )

    panel.noteLabel =
        CreateText(
            panel,
            "GameFontNormalSmall",
            "TOPLEFT",
            panel,
            "TOPLEFT",
            34,
            -151
        )

    panel.noteLabel:SetText(
        L(
            "MANUAL_MEMORY_NOTE_LABEL"
        )
    )

    Theme.ApplyTextColor(
        panel.noteLabel,
        Colors.goldMuted
    )

    panel.noteBox =
        CreateFrame(
            "EditBox",
            nil,
            panel
        )

    panel.noteBox:SetSize(
        472,
        84
    )

    panel.noteBox:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        34,
        -169
    )

    panel.noteBox:SetAutoFocus(
        false
    )

    panel.noteBox:SetMultiLine(
        true
    )

    if GameFontNormalSmall then
        panel.noteBox:SetFontObject(
            GameFontNormalSmall
        )
    end

    Theme.ApplyTextColor(
        panel.noteBox,
        Colors.ink
    )

    panel.noteBox:SetHighlightColor(
        Colors.goldMuted.r,
        Colors.goldMuted.g,
        Colors.goldMuted.b,
        0.35
    )

    panel.noteBox:SetTextInsets(
        8,
        8,
        7,
        7
    )

    panel.noteBox:SetJustifyH(
        "LEFT"
    )

    panel.noteBox:SetJustifyV(
        "TOP"
    )

    panel.noteBox:SetMaxLetters(
        600
    )

    AddInputBackground(
        panel.noteBox
    )

    FJ.InputVisuals.Attach(
        panel.noteBox,
        { insetX = 8, insetY = 7, cursorHeight = 15 }
    )

    panel.error =
        CreateText(
            panel,
            "GameFontHighlightSmall",
            "BOTTOMLEFT",
            panel,
            "BOTTOMLEFT",
            34,
            24
        )

    panel.error:SetWidth(
        260
    )

    panel.error:SetJustifyH(
        "LEFT"
    )

    panel.error:SetTextColor(
        0.55,
        0.12,
        0.08,
        1
    )

    panel.saveButton =
        CreateTextButton(
            panel,
            96,
            26,
            L(
                "MANUAL_MEMORY_SAVE"
            ),
            "GameFontNormal"
        )

    panel.saveButton:SetPoint(
        "BOTTOMRIGHT",
        panel,
        "BOTTOMRIGHT",
        -32,
        19
    )

    panel.cancelButton =
        CreateTextButton(
            panel,
            96,
            26,
            L(
                "MANUAL_MEMORY_CANCEL"
            ),
            "GameFontNormal"
        )

    panel.cancelButton:SetPoint(
        "RIGHT",
        panel.saveButton,
        "LEFT",
        -8,
        0
    )

    panel.cancelButton:SetScript(
        "OnClick",
        function()
            HideMemoryEditor(
                frame
            )
        end
    )

    panel.titleBox:SetScript(
        "OnEnterPressed",
        function(self)
            self:ClearFocus()

            panel.noteBox:SetFocus()
        end
    )

    panel.titleBox:SetScript(
        "OnEscapePressed",
        function(self)
            self:ClearFocus()

            HideMemoryEditor(
                frame
            )
        end
    )

    panel.noteBox:SetScript(
        "OnEscapePressed",
        function(self)
            self:ClearFocus()

            HideMemoryEditor(
                frame
            )
        end
    )

    panel.saveButton:SetScript(
        "OnClick",
        function()
            local title =
                panel.titleBox:GetText()
                or ""

            if not string.find(
                title,
                "%S"
            ) then

                panel.error:SetText(
                    L(
                        "MANUAL_MEMORY_TITLE_REQUIRED"
                    )
                )

                panel.titleBox:SetFocus()

                return
            end

            local note =
                panel.noteBox:GetText()
                or ""

            local success =
                false

            if panel.mode
                    == "EDIT"
                and panel.memoryID then

                success =
                    FJ.Memories.UpdateManual(
                        panel.memoryID,
                        title,
                        note
                    ) == true
            else
                local memory =
                    FJ.Memories.AddManual(
                        title,
                        note
                    )

                success =
                    memory ~= nil
            end

            if not success then
                panel.error:SetText(
                    L(
                        "MANUAL_MEMORY_SAVE_FAILED"
                    )
                )

                return
            end

            HideMemoryEditor(
                frame
            )
        end
    )

    frame.chronicleMemoryEditor =
        overlay

    frame.chronicleMemoryEditorPanel =
        panel

    overlay:Hide()
end

HideMemoryEditor =
    function(
        frame
    )
        if not frame
            or not frame.chronicleMemoryEditor then

            return
        end

        local panel =
            frame.chronicleMemoryEditorPanel

        if panel then
            panel.titleBox:ClearFocus()
            panel.noteBox:ClearFocus()

            panel.memoryID =
                nil

            panel.mode =
                nil

            panel.error:SetText(
                ""
            )
        end

        frame.chronicleMemoryEditor
            :Hide()
    end

OpenMemoryEditor =
    function(
        frame,
        memory
    )
        if not frame
            or not frame.chroniclePage then

            return
        end

        CreateMemoryEditor(
            frame
        )

        HideMemoryReader(frame)
        HideDeleteDialog(
            frame
        )

        local overlay =
            frame.chronicleMemoryEditor

        local panel =
            frame.chronicleMemoryEditorPanel

        if not overlay
            or not panel then

            return
        end

        local isEdit =
            memory
            and memory.canEdit
                == true
            and memory.id
                ~= nil

        panel.mode =
            isEdit
            and "EDIT"
            or "CREATE"

        panel.memoryID =
            isEdit
            and memory.id
            or nil

        panel.title:SetText(
            isEdit
            and L(
                "MANUAL_MEMORY_EDIT_TITLE"
            )
            or L(
                "MANUAL_MEMORY_CREATE_TITLE"
            )
        )

        panel.titleBox:SetText(
            isEdit
            and (
                memory.title
                or ""
            )
            or ""
        )

        panel.noteBox:SetText(
            isEdit
            and (
                memory.description
                or ""
            )
            or ""
        )

        panel.meta:SetText(
            GetEditorMetaText(
                isEdit
                and memory
                or nil
            )
        )

        panel.error:SetText(
            ""
        )

        overlay:Show()

        panel.titleBox:SetFocus()
    end

local function CreateDeleteDialog(
    frame
)
    if frame.chronicleDeleteDialog
        or not frame.chroniclePage then

        return
    end

    local page =
        frame.chroniclePage

    local overlay =
        CreateFrame(
            "Frame",
            nil,
            page
        )

    overlay:SetAllPoints(
        page
    )

    overlay:SetFrameLevel(
        page:GetFrameLevel()
            + 40
    )

    overlay:EnableMouse(
        true
    )

    overlay.shade =
        overlay:CreateTexture(
            nil,
            "BACKGROUND"
        )

    overlay.shade:SetAllPoints(
        overlay
    )

    overlay.shade:SetColorTexture(
        0,
        0,
        0,
        0
    )

    local panel =
        CreateFrame(
            "Frame",
            nil,
            overlay
        )

    panel:SetSize(
        430,
        180
    )

    panel:SetPoint(
        "CENTER",
        overlay,
        "CENTER",
        0,
        10
    )

    panel:SetFrameLevel(
        overlay:GetFrameLevel()
            + 1
    )

    panel.background =
        ApplyParchmentPanelBackground(
            panel
        )

    AddSimpleBorder(
        panel,
        Colors.goldMuted,
        0.85
    )

    panel.title =
        CreateText(
            panel,
            "GameFontNormalLarge",
            "TOP",
            panel,
            "TOP",
            0,
            -25
        )

    panel.title:SetText(
        L(
            "MANUAL_MEMORY_DELETE_TITLE"
        )
    )

    Theme.ApplyTextColor(
        panel.title,
        Colors.ink
    )

    panel.message =
        CreateText(
            panel,
            "GameFontHighlight",
            "TOP",
            panel.title,
            "BOTTOM",
            0,
            -16
        )

    panel.message:SetWidth(
        350
    )

    panel.message:SetJustifyH(
        "CENTER"
    )

    Theme.ApplyTextColor(
        panel.message,
        Colors.inkMuted
    )

    panel.error =
        CreateText(
            panel,
            "GameFontHighlightSmall",
            "BOTTOMLEFT",
            panel,
            "BOTTOMLEFT",
            28,
            18
        )

    panel.error:SetWidth(
        180
    )

    panel.error:SetTextColor(
        0.55,
        0.12,
        0.08,
        1
    )

    panel.deleteButton =
        CreateTextButton(
            panel,
            88,
            26,
            L(
                "MANUAL_MEMORY_DELETE"
            ),
            "GameFontNormal"
        )

    panel.deleteButton:SetPoint(
        "BOTTOMRIGHT",
        panel,
        "BOTTOMRIGHT",
        -28,
        14
    )

    panel.cancelButton =
        CreateTextButton(
            panel,
            88,
            26,
            L(
                "MANUAL_MEMORY_CANCEL"
            ),
            "GameFontNormal"
        )

    panel.cancelButton:SetPoint(
        "RIGHT",
        panel.deleteButton,
        "LEFT",
        -8,
        0
    )

    panel.cancelButton:SetScript(
        "OnClick",
        function()
            HideDeleteDialog(
                frame
            )
        end
    )

    panel.deleteButton:SetScript(
        "OnClick",
        function()
            if not panel.memoryID then
                return
            end

            local success =
                FJ.Memories.DeleteManual(
                    panel.memoryID
                ) == true

            if not success then
                panel.error:SetText(
                    L(
                        "MANUAL_MEMORY_DELETE_FAILED"
                    )
                )

                return
            end

            HideDeleteDialog(
                frame
            )
        end
    )

    frame.chronicleDeleteDialog =
        overlay

    frame.chronicleDeleteDialogPanel =
        panel

    overlay:Hide()
end

HideDeleteDialog =
    function(
        frame
    )
        if not frame
            or not frame.chronicleDeleteDialog then

            return
        end

        local panel =
            frame.chronicleDeleteDialogPanel

        if panel then
            panel.memoryID =
                nil

            panel.error:SetText(
                ""
            )
        end

        frame.chronicleDeleteDialog
            :Hide()
    end

OpenDeleteDialog =
    function(
        frame,
        memory
    )
        if not frame
            or not memory
            or memory.canDelete
                ~= true
            or not memory.id then

            return
        end

        CreateDeleteDialog(
            frame
        )

        HideMemoryReader(frame)
        HideMemoryEditor(
            frame
        )

        local overlay =
            frame.chronicleDeleteDialog

        local panel =
            frame.chronicleDeleteDialogPanel

        if not overlay
            or not panel then

            return
        end

        panel.memoryID =
            memory.id

        panel.message:SetText(
            FJ.Locale.Format(
                "MANUAL_MEMORY_DELETE_CONFIRM",
                memory.title
                    or L(
                        "UNKNOWN"
                    )
            )
        )

        panel.error:SetText(
            ""
        )

        overlay:Show()
    end

local function UpdateScrollThumb(
    frame
)
    local scroll =
        frame.chronicleScroll

    local track =
        frame.chronicleScrollTrack

    local thumb =
        frame.chronicleScrollThumb

    if not scroll
        or not track
        or not thumb then

        return
    end

    local maximum =
        scroll:GetVerticalScrollRange()
        or 0

    if maximum <= 0 then
        track:Hide()
        thumb:Hide()

        return
    end

    track:Show()
    thumb:Show()

    local current =
        scroll:GetVerticalScroll()

    local ratio =
        current / maximum

    local trackHeight =
        track:GetHeight()

    local thumbHeight =
        thumb:GetHeight()

    local travel =
        math.max(
            trackHeight - thumbHeight,
            0
        )

    thumb:ClearAllPoints()

    thumb:SetPoint(
        "TOP",
        track,
        "TOP",
        0,
        -(travel * ratio)
    )
end

local function ScrollBy(
    frame,
    amount
)
    local scroll =
        frame.chronicleScroll

    if not scroll then
        return
    end

    local current =
        scroll:GetVerticalScroll()

    local maximum =
        scroll:GetVerticalScrollRange()
        or 0

    local target =
        current + amount

    if target < 0 then
        target = 0
    elseif target > maximum then
        target = maximum
    end

    scroll:SetVerticalScroll(
        target
    )

    UpdateScrollThumb(
        frame
    )
end

local function CreatePage(
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

    frame.chroniclePage =
        page

    frame.chronicleTitle =
        CreateText(
            page,
            "GameFontNormalLarge",
            "TOPLEFT",
            page,
            "TOPLEFT",
            38,
            -8
        )

    frame.chronicleTitle:SetText(
        L(
            "CHRONICLE_TITLE"
        )
    )

    Theme.ApplyTextColor(
        frame.chronicleTitle,
        Colors.ink
    )

    frame.chronicleSubtitle =
        CreateText(
            page,
            "GameFontHighlightSmall",
            "TOPLEFT",
            frame.chronicleTitle,
            "BOTTOMLEFT",
            0,
            -6
        )

    frame.chronicleSubtitle:SetText(
        L(
            "CHRONICLE_SUBTITLE"
        )
    )

    Theme.ApplyTextColor(
        frame.chronicleSubtitle,
        Colors.inkMuted
    )

    frame.chronicleAddMemoryButton =
        CreateTextButton(
            page,
            122,
            24,
            L(
                "CHRONICLE_ADD_MEMORY"
            ),
            "GameFontNormalSmall"
        )

    frame.chronicleAddMemoryButton:SetPoint(
        "TOPRIGHT",
        page,
        "TOPRIGHT",
        -38,
        -7
    )

    frame.chronicleAddMemoryButton:SetScript(
        "OnClick",
        function()
            OpenMemoryEditor(
                frame,
                nil
            )
        end
    )

    local scroll =
        CreateFrame(
            "ScrollFrame",
            nil,
            page
        )

    scroll:SetPoint(
        "TOPLEFT",
        page,
        "TOPLEFT",
        36,
        -58
    )

    scroll:SetPoint(
        "BOTTOMRIGHT",
        page,
        "BOTTOMRIGHT",
        -45,
        8
    )

    scroll:EnableMouseWheel(
        true
    )

    frame.chronicleScroll =
        scroll

    local child =
        CreateFrame(
            "Frame",
            nil,
            scroll
        )

    child:SetSize(
        670,
        1
    )

    scroll:SetScrollChild(
        child
    )

    frame.chronicleScrollChild =
        child

    scroll:SetScript(
        "OnMouseWheel",
        function(self, delta)
            ScrollBy(
                frame,
                -delta * 72
            )
        end
    )

    local track =
        page:CreateTexture(
            nil,
            "ARTWORK"
        )

    track:SetSize(
        2,
        324
    )

    track:SetPoint(
        "TOPRIGHT",
        page,
        "TOPRIGHT",
        -17,
        -72
    )

    track:SetColorTexture(
        Colors.timeline.r,
        Colors.timeline.g,
        Colors.timeline.b,
        0.35
    )

    frame.chronicleScrollTrack =
        track

    local thumb =
        page:CreateTexture(
            nil,
            "OVERLAY"
        )

    thumb:SetSize(
        8,
        46
    )

    thumb:SetColorTexture(
        Colors.goldMuted.r,
        Colors.goldMuted.g,
        Colors.goldMuted.b,
        0.85
    )

    thumb:SetPoint(
        "TOP",
        track,
        "TOP",
        0,
        0
    )

    frame.chronicleScrollThumb =
        thumb

    frame.chronicleEmptyText =
        CreateText(
            page,
            "GameFontHighlight",
            "CENTER",
            page,
            "CENTER",
            0,
            -10
        )

    frame.chronicleEmptyText:SetText(
        L(
            "CHRONICLE_EMPTY"
        )
    )

    Theme.ApplyTextColor(
        frame.chronicleEmptyText,
        Colors.inkMuted
    )

    page:Hide()
end

local function HidePage(
    frame
)
    if not frame then
        return
    end

    HideMemoryEditor(
        frame
    )

    HideDeleteDialog(
        frame
    )

    HideMemoryReader(frame)

    if frame.chroniclePage then
        frame.chroniclePage:Hide()
    end
end

local function ShowPage(
    frame
)
    if not frame
        or not frame.chroniclePage then

        return
    end

    if frame.content then
        frame.content:Hide()
    end

    if frame.historyPage then
        frame.historyPage:Hide()
    end

    frame.chroniclePage:Show()

    frame.currentPage =
        "TIMELINE"

    SetTabActive(
        frame.overviewButton,
        false
    )

    SetTabActive(
        frame.timelineButton,
        true
    )

    SetTabActive(
        frame.historyButton,
        false
    )

    FJ.ChronicleUI.Refresh(
        frame
    )

    frame.chronicleScroll
        :SetVerticalScroll(
            0
        )

    UpdateScrollThumb(
        frame
    )
end

local function HookButton(
    button,
    callback
)
    if not button then
        return
    end

    local original =
        button:GetScript(
            "OnClick"
        )

    button:SetScript(
        "OnClick",
        function(self, ...)
            callback(
                original,
                self,
                ...
            )
        end
    )
end

function FJ.ChronicleUI.OpenMemoryReader(frame, memory)
    frame = frame or ForeverJourneyMainFrame
    if not frame then
        return
    end

    OpenMemoryReader(frame, memory)
end

function FJ.ChronicleUI.Attach(
    frame
)
    if not frame
        or frame.chronicleAttached then

        return
    end

    CreatePage(
        frame
    )

    HookButton(
        frame.overviewButton,
        function(original, self, ...)
            HidePage(
                frame
            )

            if original then
                original(
                    self,
                    ...
                )
            elseif frame.content then
                frame.content:Show()
            end
        end
    )

    HookButton(
        frame.historyButton,
        function(original, self, ...)
            HidePage(
                frame
            )

            if original then
                original(
                    self,
                    ...
                )
            end
        end
    )

    frame.timelineButton:SetScript(
        "OnClick",
        function()
            ShowPage(
                frame
            )
        end
    )

    frame.chronicleAttached =
        true

    FJ.ChronicleUI.Refresh(
        frame
    )
end

function FJ.ChronicleUI.Refresh(
    frame
)
    frame =
        frame
        or ForeverJourneyMainFrame

    if not frame
        or not frame.chroniclePage then

        return
    end

    local memories =
        GetAllMemories()

    for _, row in ipairs(
        dateRows
    ) do
        row:Hide()
    end

    for _, row in ipairs(
        memoryRows
    ) do
        row:Hide()
    end

    if #memories == 0 then
        frame.chronicleEmptyText:Show()
        frame.chronicleScroll:Hide()
        frame.chronicleScrollTrack:Hide()
        frame.chronicleScrollThumb:Hide()

        return
    end

    frame.chronicleEmptyText:Hide()
    frame.chronicleScroll:Show()

    local child =
        frame.chronicleScrollChild

    local yOffset =
        0

    local dateRowIndex =
        0

    local memoryRowIndex =
        0

    local previousDateKey =
        nil

    for index =
        #memories,
        1,
        -1 do

        local memory =
            memories[index]

        local dateKey =
            GetDateKey(
                memory.timestamp
            )

        if dateKey
            ~= previousDateKey then

            dateRowIndex =
                dateRowIndex + 1

            local dateRow =
                dateRows[
                    dateRowIndex
                ]

            if not dateRow then
                dateRow =
                    CreateDateRow(
                        child
                    )

                dateRows[
                    dateRowIndex
                ] =
                    dateRow
            end

            dateRow:ClearAllPoints()

            dateRow:SetPoint(
                "TOPLEFT",
                child,
                "TOPLEFT",
                0,
                -yOffset
            )

            dateRow.title:SetText(
                GetDateLabel(
                    memory.timestamp
                )
            )

            dateRow:Show()

            yOffset =
                yOffset + 34

            previousDateKey =
                dateKey
        end

        memoryRowIndex =
            memoryRowIndex + 1

        local row =
            memoryRows[
                memoryRowIndex
            ]

        if not row then
            row =
                CreateMemoryRow(
                    child
                )

            memoryRows[
                memoryRowIndex
            ] =
                row
        end

        row:ClearAllPoints()

        row:SetPoint(
            "TOPLEFT",
            child,
            "TOPLEFT",
            0,
            -yOffset
        )

        row.marker:SetTexture(
            Theme.GetMarkerTexture(
                memory
            )
        )

        ApplyMarkerLayout(
            row,
            memory
        )

        row.typeLabel:SetText(
            GetMemoryTypeLabel(
                memory
            )
        )

        row.title:SetText(
            memory.title
            or L(
                "UNKNOWN"
            )
        )

        local locationName =
            FJ.Utils
                .GetLocalizedLocationName(
                    memory.location
                )

        local timeText =
            memory.timestamp
            and date(
                "%H:%M",
                memory.timestamp
            )
            or L(
                "UNKNOWN_TIME"
            )

        row.meta:SetText(
            timeText
                .. "   -   "
                .. locationName
        )

        if memory.canEdit == true then
            -- A manual memory is a diary entry: don't show the body
            -- on the timeline, require opening it by clicking.
            row.description:SetText(GetReadEntryHint())
        else
            row.description:SetText(memory.description or "")
        end

        row.ownerFrame =
            frame

        row.memoryView =
            memory

        if memory.canEdit == true
            or (type(memory.description) == "string"
                and memory.description ~= "") then

            row.readButton:Show()
        else
            row.readButton:Hide()
        end

        row.memoryID =
            memory.id

        row.favorite =
            memory.favorite == true

        SetFavoriteIcon(
            row.favoriteButton,
            row.favorite
        )

        row.favoriteButton:Show()

        if memory.canEdit
            == true then

            row.editButton:Show()
        else
            row.editButton:Hide()
        end

        if memory.canDelete
            == true then

            row.deleteButton:Show()
        else
            row.deleteButton:Hide()
        end

        local nextOlder =
            memories[
                index - 1
            ]

        local continueLine =
            nextOlder
            and GetDateKey(
                nextOlder.timestamp
            ) == dateKey

        if continueLine then
            row.line:Show()
        else
            row.line:Hide()
        end

        row:Show()

        yOffset =
            yOffset + 82
    end

    child:SetHeight(
        math.max(
            yOffset + 12,
            frame.chronicleScroll
                :GetHeight()
        )
    )

    local maximum =
        frame.chronicleScroll
            :GetVerticalScrollRange()
        or 0

    local current =
        frame.chronicleScroll
            :GetVerticalScroll()

    if current > maximum then
        frame.chronicleScroll
            :SetVerticalScroll(
                maximum
            )
    end

    UpdateScrollThumb(
        frame
    )
end

local originalRefresh =
    FJ.UI.Refresh

FJ.UI.Refresh =
    function(...)
        local result =
            originalRefresh(...)

        local frame =
            ForeverJourneyMainFrame

        if frame then
            FJ.ChronicleUI.Attach(
                frame
            )

            FJ.ChronicleUI.Refresh(
                frame
            )
        end

        return result
    end