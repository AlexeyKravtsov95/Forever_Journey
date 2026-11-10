local addonName, FJ = ...

FJ.ChronicleFilters = {}

local Theme = FJ.Theme
local Colors = Theme.Colors
local Textures = Theme.Textures
local locale = GetLocale()

local FILTER_ALL = "ALL"

local strings = {
    enUS = {
        FILTER = "FILTER: %s",
        FILTERS_COUNT = "FILTERS: %d",
        FAVORITES = "FAVORITES",
        ALL = "ALL",
        MANUAL = "MY MEMORIES",
        LEVEL = "LEVELS",
        ZONE = "DISCOVERIES",
        INSTANCE = "INSTANCES",
        VICTORY = "VICTORIES",
        REPUTATION = "REPUTATION",
        QUEST = "QUESTS",
        PROFESSION = "PROFESSIONS",
        DEATH = "DEATHS",
        EMPTY_FILTERED = "No moments match the selected filters."
    },

    ruRU = {
        FILTER = "ФИЛЬТР: %s",
        FILTERS_COUNT = "ФИЛЬТРЫ: %d",
        FAVORITES = "ИЗБРАННОЕ",
        ALL = "ВСЕ",
        MANUAL = "МОИ ЗАПИСИ",
        LEVEL = "УРОВНИ",
        ZONE = "ЛОКАЦИИ",
        INSTANCE = "ПОДЗЕМЕЛЬЯ",
        VICTORY = "ПОБЕДЫ",
        REPUTATION = "РЕПУТАЦИЯ",
        QUEST = "ЗАДАНИЯ",
        PROFESSION = "ПРОФЕССИИ",
        DEATH = "СМЕРТИ",
        EMPTY_FILTERED = "Нет событий, подходящих под выбранные фильтры."
    }
}

local currentStrings =
    strings[locale]
    or strings.enUS

local filterOptions = {
    {
        value = FILTER_ALL,
        labelKey = "ALL"
    },
    {
        value = "MANUAL_MEMORY",
        labelKey = "MANUAL"
    },
    {
        value = "LEVEL",
        labelKey = "LEVEL"
    },
    {
        value = "ZONE",
        labelKey = "ZONE"
    },
    {
        value = "INSTANCE",
        labelKey = "INSTANCE"
    },
    {
        value = "BOSS_VICTORY",
        labelKey = "VICTORY"
    },
    {
        value = "REPUTATION_MILESTONE",
        labelKey = "REPUTATION"
    },
    {
        value = "QUEST_MILESTONE",
        labelKey = "QUEST"
    },
    {
        value = "PROFESSION_MILESTONE",
        labelKey = "PROFESSION"
    },
    {
        value = "DEATH",
        labelKey = "DEATH"
    }
}

local function T(
    key,
    ...
)
    local value =
        currentStrings[key]
        or strings.enUS[key]
        or key

    if select(
        "#",
        ...
    ) == 0 then

        return value
    end

    local success,
        result = pcall(
            string.format,
            value,
            ...
        )

    if success then
        return result
    end

    return value
end

local function CreateTextButton(
    parent,
    width,
    height,
    text
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
            "GameFontNormalSmall"
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
                self.isActive
                    and Colors.gold
                    or Colors.goldMuted
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

local function GetSemanticType(
    memory
)
    if type(memory) ~= "table" then
        return nil
    end

    if type(
        memory.semanticType
    ) == "string"
        and memory.semanticType ~= "" then

        return memory.semanticType
    end

    if FJ.MemoryTypes
        and type(
            FJ.MemoryTypes.GetSemanticType
        ) == "function" then

        return FJ.MemoryTypes
            .GetSemanticType(
                memory
            )
    end

    return memory.type
end

local function GetFilterLabel(
    value
)
    for _, option in ipairs(
        filterOptions
    ) do
        if option.value == value then
            return T(
                option.labelKey
            )
        end
    end

    return T(
        "ALL"
    )
end

local function EnsureState(
    frame
)
    if type(
        frame.chronicleTypeFilters
    ) ~= "table" then

        frame.chronicleTypeFilters =
            {}

        if type(
            frame.chronicleTypeFilter
        ) == "string"
            and frame.chronicleTypeFilter
                ~= ""
            and frame.chronicleTypeFilter
                ~= FILTER_ALL then

            frame.chronicleTypeFilters[
                frame.chronicleTypeFilter
            ] = true
        end

        frame.chronicleTypeFilter =
            nil
    end

    if frame.chronicleFavoritesOnly
        == nil then

        frame.chronicleFavoritesOnly =
            false
    end
end

local function CountSelectedTypes(
    frame
)
    EnsureState(
        frame
    )

    local count = 0

    for _, selected in pairs(
        frame.chronicleTypeFilters
    ) do
        if selected == true then
            count =
                count + 1
        end
    end

    return count
end

local function GetSingleSelectedType(
    frame
)
    EnsureState(
        frame
    )

    local found =
        nil

    local count =
        0

    for value, selected in pairs(
        frame.chronicleTypeFilters
    ) do
        if selected == true then
            found =
                value

            count =
                count + 1

            if count > 1 then
                return nil
            end
        end
    end

    if count == 1 then
        return found
    end

    return nil
end

local function IsTypeSelected(
    frame,
    value
)
    EnsureState(
        frame
    )

    if value == FILTER_ALL then
        return CountSelectedTypes(
            frame
        ) == 0
    end

    return frame.chronicleTypeFilters[
        value
    ] == true
end

local function ClearTypeFilters(
    frame
)
    EnsureState(
        frame
    )

    wipe(
        frame.chronicleTypeFilters
    )
end

local function ToggleTypeFilter(
    frame,
    value
)
    EnsureState(
        frame
    )

    if value == FILTER_ALL then
        ClearTypeFilters(
            frame
        )

        return
    end

    if frame.chronicleTypeFilters[
        value
    ] then

        frame.chronicleTypeFilters[
            value
        ] = nil
    else
        frame.chronicleTypeFilters[
            value
        ] = true
    end
end

local function MatchesTypeFilters(
    frame,
    memory
)
    if CountSelectedTypes(
        frame
    ) == 0 then

        return true
    end

    local semanticType =
        GetSemanticType(
            memory
        )

    return semanticType ~= nil
        and frame.chronicleTypeFilters[
            semanticType
        ] == true
end

local function ApplyFilters(
    frame,
    memories
)
    EnsureState(
        frame
    )

    local result = {}

    for _, memory in ipairs(
        memories
        or {}
    ) do
        local matchesType =
            MatchesTypeFilters(
                frame,
                memory
            )

        local matchesFavorite =
            not frame.chronicleFavoritesOnly
            or memory.favorite == true

        if matchesType
            and matchesFavorite then

            table.insert(
                result,
                memory
            )
        end
    end

    return result
end

local function SetFavoriteIcon(
    button,
    active
)
    if not button
        or not button.icon then

        return
    end

    local atlas =
        active
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
        16,
        16
    )
end

local function GetFilterButtonText(
    frame
)
    local count =
        CountSelectedTypes(
            frame
        )

    if count == 0 then
        return T(
            "FILTER",
            T(
                "ALL"
            )
        )
    end

    if count == 1 then
        return T(
            "FILTER",
            GetFilterLabel(
                GetSingleSelectedType(
                    frame
                )
            )
        )
    end

    return T(
        "FILTERS_COUNT",
        count
    )
end

local function UpdatePopupOptions(
    frame
)
    if not frame
        .chronicleFilterOptionButtons then

        return
    end

    for _, button in ipairs(
        frame.chronicleFilterOptionButtons
    ) do
        local active =
            IsTypeSelected(
                frame,
                button.filterValue
            )

        button.isActive =
            active

        if active then
            button.selectionBar:Show()
            button.selectionBackground:Show()

            Theme.ApplyTextColor(
                button.label,
                Colors.gold
            )
        else
            button.selectionBar:Hide()
            button.selectionBackground:Hide()

            Theme.ApplyTextColor(
                button.label,
                Colors.inkMuted
            )
        end
    end
end

local function UpdateControls(
    frame
)
    if not frame
        or not frame.chronicleFilterButton then

        return
    end

    EnsureState(
        frame
    )

    local selectedCount =
        CountSelectedTypes(
            frame
        )

    frame.chronicleFilterButton
        .label:SetText(
            GetFilterButtonText(
                frame
            )
        )

    frame.chronicleFilterButton
        .isActive =
        selectedCount > 0

    Theme.ApplyTextColor(
        frame.chronicleFilterButton.label,
        frame.chronicleFilterButton
            .isActive
            and Colors.gold
            or Colors.goldMuted
    )

    local favoriteButton =
        frame.chronicleFavoritesFilterButton

    favoriteButton.isActive =
        frame.chronicleFavoritesOnly
            == true

    SetFavoriteIcon(
        favoriteButton,
        favoriteButton.isActive
    )

    Theme.ApplyTextColor(
        favoriteButton.label,
        favoriteButton.isActive
            and Colors.gold
            or Colors.goldMuted
    )

    UpdatePopupOptions(
        frame
    )
end

local function CreateFilterPopup(
    frame
)
    if frame.chronicleFilterPopup then
        return
    end

    local page =
        frame.chroniclePage

    local popup =
        CreateFrame(
            "Frame",
            nil,
            page
        )

    popup:SetSize(
        196,
        16 + (#filterOptions * 23)
    )

    popup:SetPoint(
        "TOPRIGHT",
        frame.chronicleFilterButton,
        "BOTTOMRIGHT",
        0,
        -4
    )

    popup:SetFrameLevel(
        page:GetFrameLevel()
            + 50
    )

    popup:EnableMouse(
        true
    )

    -- Opaque paper base prevents Chronicle content
    -- from showing through the dropdown.
    popup.paper =
        popup:CreateTexture(
            nil,
            "BACKGROUND"
        )

    popup.paper:SetAllPoints(
        popup
    )

    popup.paper:SetColorTexture(
        0.88,
        0.82,
        0.69,
        1
    )

    popup.background =
        popup:CreateTexture(
            nil,
            "BACKGROUND"
        )

    popup.background:SetAllPoints(
        popup
    )

    popup.background:SetTexture(
        Textures.parchment
    )

    popup.background:SetAlpha(
        0.94
    )

    AddSimpleBorder(
        popup,
        Colors.goldMuted,
        0.72
    )

    frame.chronicleFilterOptionButtons =
        {}

    for index, option in ipairs(
        filterOptions
    ) do
        local button =
            CreateFrame(
                "Button",
                nil,
                popup
            )

        button:SetSize(
            180,
            22
        )

        button:SetPoint(
            "TOPLEFT",
            popup,
            "TOPLEFT",
            8,
            -8 - ((index - 1) * 23)
        )

        button.filterValue =
            option.value

        button.labelKey =
            option.labelKey

        button.selectionBackground =
            button:CreateTexture(
                nil,
                "BACKGROUND"
            )

        button.selectionBackground
            :SetAllPoints(
                button
            )

        button.selectionBackground
            :SetColorTexture(
                Colors.goldMuted.r,
                Colors.goldMuted.g,
                Colors.goldMuted.b,
                0.10
            )

        button.selectionBackground:Hide()

        button.selectionBar =
            button:CreateTexture(
                nil,
                "ARTWORK"
            )

        button.selectionBar:SetSize(
            3,
            16
        )

        button.selectionBar:SetPoint(
            "LEFT",
            button,
            "LEFT",
            3,
            0
        )

        button.selectionBar:SetColorTexture(
            Colors.gold.r,
            Colors.gold.g,
            Colors.gold.b,
            0.92
        )

        button.selectionBar:Hide()

        button.label =
            button:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontNormalSmall"
            )

        button.label:SetPoint(
            "LEFT",
            button,
            "LEFT",
            14,
            0
        )

        button.label:SetPoint(
            "RIGHT",
            button,
            "RIGHT",
            -8,
            0
        )

        button.label:SetJustifyH(
            "LEFT"
        )

        button.label:SetText(
            T(
                option.labelKey
            )
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
                    self.isActive
                        and Colors.gold
                        or Colors.inkMuted
                )
            end
        )

        button:SetScript(
            "OnClick",
            function(self)
                ToggleTypeFilter(
                    frame,
                    self.filterValue
                )

                UpdateControls(
                    frame
                )

                FJ.ChronicleUI.Refresh(
                    frame
                )

                -- Keep open so several types can
                -- be selected consecutively.
                if frame.chronicleFilterPopup then
                    frame.chronicleFilterPopup:Show()

                    UpdateControls(
                        frame
                    )
                end
            end
        )

        table.insert(
            frame.chronicleFilterOptionButtons,
            button
        )
    end

    frame.chronicleFilterPopup =
        popup

    UpdatePopupOptions(
        frame
    )

    popup:Hide()
end

local function EnsureControls(
    frame
)
    if not frame
        or not frame.chroniclePage
        or frame.chronicleFilterButton then

        return
    end

    EnsureState(
        frame
    )

    local page =
        frame.chroniclePage

    local filterButton =
        CreateTextButton(
            page,
            166,
            22,
            ""
        )

    filterButton:SetPoint(
        "TOPRIGHT",
        page,
        "TOPRIGHT",
        -38,
        -34
    )

    filterButton:SetScript(
        "OnClick",
        function()
            CreateFilterPopup(
                frame
            )

            if frame.chronicleFilterPopup
                :IsShown() then

                frame.chronicleFilterPopup
                    :Hide()
            else
                UpdateControls(
                    frame
                )

                frame.chronicleFilterPopup
                    :Show()
            end
        end
    )

    frame.chronicleFilterButton =
        filterButton

    local favoritesButton =
        CreateFrame(
            "Button",
            nil,
            page
        )

    favoritesButton:SetSize(
        116,
        22
    )

    favoritesButton:SetPoint(
        "RIGHT",
        filterButton,
        "LEFT",
        -6,
        0
    )

    favoritesButton.icon =
        favoritesButton:CreateTexture(
            nil,
            "ARTWORK"
        )

    favoritesButton.icon:SetPoint(
        "LEFT",
        favoritesButton,
        "LEFT",
        2,
        0
    )

    favoritesButton.label =
        favoritesButton:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )

    favoritesButton.label:SetPoint(
        "LEFT",
        favoritesButton.icon,
        "RIGHT",
        4,
        0
    )

    favoritesButton.label:SetPoint(
        "RIGHT",
        favoritesButton,
        "RIGHT",
        0,
        0
    )

    favoritesButton.label:SetJustifyH(
        "LEFT"
    )

    favoritesButton.label:SetText(
        T(
            "FAVORITES"
        )
    )

    favoritesButton:SetScript(
        "OnEnter",
        function(self)
            Theme.ApplyTextColor(
                self.label,
                Colors.gold
            )
        end
    )

    favoritesButton:SetScript(
        "OnLeave",
        function(self)
            Theme.ApplyTextColor(
                self.label,
                self.isActive
                    and Colors.gold
                    or Colors.goldMuted
            )
        end
    )

    favoritesButton:SetScript(
        "OnClick",
        function()
            if frame.chronicleFilterPopup then
                frame.chronicleFilterPopup
                    :Hide()
            end

            frame.chronicleFavoritesOnly =
                not frame.chronicleFavoritesOnly

            FJ.ChronicleUI.Refresh(
                frame
            )
        end
    )

    frame.chronicleFavoritesFilterButton =
        favoritesButton

    UpdateControls(
        frame
    )
end

local originalGetAllMemories =
    FJ.ViewModel.GetAllMemories

local originalRefresh =
    FJ.ChronicleUI.Refresh

FJ.ChronicleUI.Refresh =
    function(
        frame
    )
        frame =
            frame
            or ForeverJourneyMainFrame

        if not frame
            or not frame.chroniclePage then

            return originalRefresh(
                frame
            )
        end

        EnsureControls(
            frame
        )

        if frame.chronicleFilterPopup then
            frame.chronicleFilterPopup
                :Hide()
        end

        local allMemories =
            originalGetAllMemories()

        local filteredMemories =
            ApplyFilters(
                frame,
                allMemories
            )

        local previousGetAllMemories =
            FJ.ViewModel.GetAllMemories

        FJ.ViewModel.GetAllMemories =
            function()
                return filteredMemories
            end

        local success,
            result = pcall(
                originalRefresh,
                frame
            )

        FJ.ViewModel.GetAllMemories =
            previousGetAllMemories

        if not success then
            error(
                result,
                0
            )
        end

        if frame.chronicleEmptyText then
            if #allMemories > 0
                and #filteredMemories == 0 then

                frame.chronicleEmptyText
                    :SetText(
                        T(
                            "EMPTY_FILTERED"
                        )
                    )
            else
                frame.chronicleEmptyText
                    :SetText(
                        FJ.Locale.Get(
                            "CHRONICLE_EMPTY"
                        )
                    )
            end
        end

        UpdateControls(
            frame
        )

        return result
    end