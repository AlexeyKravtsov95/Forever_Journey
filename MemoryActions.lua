local addonName, FJ = ...

local JourneyState = FJ.State

FJ.MemoryActions = {}

local MANUAL_MEMORY_TYPE = "MANUAL_MEMORY"

local MANUAL_TYPE_LABELS = {
    enUS = "MEMORY",
    ruRU = "ВОСПОМИНАНИЕ"
}

local function NormalizeUserText(
    value
)
    if type(value) ~= "string" then
        return nil
    end

    local normalized =
        string.gsub(
            value,
            "^%s+",
            ""
        )

    normalized =
        string.gsub(
            normalized,
            "%s+$",
            ""
        )

    if normalized == "" then
        return nil
    end

    return normalized
end

local function NotifyMemoryChanged()
    if FJ.UI
        and type(
            FJ.UI.RefreshIfVisible
        ) == "function" then

        FJ.UI.RefreshIfVisible()
    end
end

local function GetManualTypeLabel()
    local locale =
        FJ.Locale.GetLocale()

    return MANUAL_TYPE_LABELS[locale]
        or MANUAL_TYPE_LABELS.enUS
end

function FJ.Memories.FindByID(
    memoryID
)
    if type(memoryID) ~= "string"
        or memoryID == "" then

        return nil, nil
    end

    for index, memory in ipairs(
        JourneyState.memories
        or {}
    ) do
        if type(memory) == "table"
            and memory.id == memoryID then

            return memory, index
        end
    end

    return nil, nil
end

function FJ.Memories.IsManual(
    memory
)
    return type(memory) == "table"
        and memory.type == MANUAL_MEMORY_TYPE
        and memory.source == "USER"
end

function FJ.Memories.CanEdit(
    memory
)
    return FJ.Memories.IsManual(
        memory
    )
end

function FJ.Memories.CanDelete(
    memory
)
    return FJ.Memories.IsManual(
        memory
    )
end

function FJ.Memories.SetFavorite(
    memoryID,
    favorite
)
    if type(favorite) ~= "boolean" then
        return false,
            "INVALID_FAVORITE_VALUE"
    end

    local memory =
        FJ.Memories.FindByID(
            memoryID
        )

    if not memory then
        return false,
            "NOT_FOUND"
    end

    if memory.favorite == favorite then
        return true,
            memory
    end

    memory.favorite =
        favorite

    NotifyMemoryChanged()

    return true,
        memory
end

function FJ.Memories.ToggleFavorite(
    memoryID
)
    local memory =
        FJ.Memories.FindByID(
            memoryID
        )

    if not memory then
        return false,
            "NOT_FOUND"
    end

    memory.favorite =
        not memory.favorite

    NotifyMemoryChanged()

    return true,
        memory
end

function FJ.Memories.GetFavoriteMemories()
    local result = {}

    for _, memory in ipairs(
        JourneyState.memories
        or {}
    ) do
        if type(memory) == "table"
            and memory.favorite == true then

            table.insert(
                result,
                memory
            )
        end
    end

    return result
end

function FJ.Memories.AddManual(
    title,
    note
)
    local normalizedTitle =
        NormalizeUserText(
            title
        )

    if not normalizedTitle then
        return nil,
            "INVALID_TITLE"
    end

    local normalizedNote =
        NormalizeUserText(
            note
        )

    local memory =
        FJ.Memories.Add(
            MANUAL_MEMORY_TYPE,
            {
                title =
                    normalizedTitle,

                note =
                    normalizedNote
            },
            nil,
            "USER"
        )

    if not memory then
        return nil,
            "STORAGE_UNAVAILABLE"
    end

    NotifyMemoryChanged()

    return memory,
        nil
end

function FJ.Memories.UpdateManual(
    memoryID,
    title,
    note
)
    local memory =
        FJ.Memories.FindByID(
            memoryID
        )

    if not memory then
        return false,
            "NOT_FOUND"
    end

    if not FJ.Memories.IsManual(
        memory
    ) then

        return false,
            "NOT_MANUAL"
    end

    local normalizedTitle =
        NormalizeUserText(
            title
        )

    if not normalizedTitle then
        return false,
            "INVALID_TITLE"
    end

    local normalizedNote =
        NormalizeUserText(
            note
        )

    memory.data =
        type(memory.data) == "table"
        and memory.data
        or {}

    local changed =
        memory.data.title ~= normalizedTitle
        or memory.data.note ~= normalizedNote

    if not changed then
        return true,
            memory
    end

    memory.data.title =
        normalizedTitle

    memory.data.note =
        normalizedNote

    memory.updatedAt =
        time()

    NotifyMemoryChanged()

    return true,
        memory
end

function FJ.Memories.DeleteManual(
    memoryID
)
    local memory, index =
        FJ.Memories.FindByID(
            memoryID
        )

    if not memory
        or not index then

        return false,
            "NOT_FOUND"
    end

    if not FJ.Memories.IsManual(
        memory
    ) then

        return false,
            "NOT_MANUAL"
    end

    table.remove(
        JourneyState.memories,
        index
    )

    NotifyMemoryChanged()

    return true,
        memory
end

FJ.MemoryTypes.Register(
    MANUAL_MEMORY_TYPE,
    {
        getTypeLabel = function()
            return GetManualTypeLabel()
        end,

        getTitle = function(memory)
            local data =
                type(memory.data) == "table"
                and memory.data
                or {}

            return data.title
                or FJ.Locale.Get(
                    "UNKNOWN"
                )
        end,

        getDescription = function(memory)
            local data =
                type(memory.data) == "table"
                and memory.data
                or {}

            return data.note
        end,

        getMarkerTexture = function()
            return FJ.Theme.Textures
                .iconMemories
        end
    }
)