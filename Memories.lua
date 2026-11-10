
local addonName, FJ = ...

local JourneyState = FJ.State

FJ.Memories = {}

local MEMORY_SCHEMA_VERSION = 3

local ENVIRONMENT_TITLE_KEYS = {
    FALLING =
        "MEMORY_TITLE_DEATH_FALLING",

    DROWNING =
        "MEMORY_TITLE_DEATH_DROWNING",

    FATIGUE =
        "MEMORY_TITLE_DEATH_FATIGUE",

    FIRE =
        "MEMORY_TITLE_DEATH_FIRE",

    LAVA =
        "MEMORY_TITLE_DEATH_LAVA",

    SLIME =
        "MEMORY_TITLE_DEATH_SLIME"
}

FJ.MemoryTypes =
    FJ.MemoryTypes
    or {}

local memoryTypeHandlers =
    FJ.MemoryTypes.handlers
    or {}

FJ.MemoryTypes.handlers =
    memoryTypeHandlers

function FJ.MemoryTypes.Register(
    memoryType,
    handler
)
    if type(memoryType) ~= "string"
        or memoryType == ""
        or type(handler) ~= "table" then

        return false
    end

    memoryTypeHandlers[memoryType] =
        handler

    return true
end

function FJ.MemoryTypes.Get(
    memoryType
)
    if type(memoryType) ~= "string"
        or memoryType == "" then

        return nil
    end

    return memoryTypeHandlers[
        memoryType
    ]
end

function FJ.MemoryTypes.GetSemanticType(
    memory
)
    if type(memory) ~= "table" then
        return nil
    end

    if type(memory.raw) == "table"
        and type(memory.raw.type) == "string" then

        return memory.raw.type
    end

    if type(memory.semanticType) == "string"
        and memory.semanticType ~= "" then

        return memory.semanticType
    end

    if type(memory.type) == "string"
        and memory.type ~= "" then

        return memory.type
    end

    return nil
end

function FJ.MemoryTypes.GetRawMemory(
    memory
)
    if type(memory) ~= "table" then
        return nil
    end

    if type(memory.raw) == "table" then
        return memory.raw
    end

    return memory
end

function FJ.MemoryTypes.GetTypeLabel(
    memory
)
    local semanticType =
        FJ.MemoryTypes.GetSemanticType(
            memory
        )

    if not semanticType then
        return nil
    end

    local handler =
        FJ.MemoryTypes.Get(
            semanticType
        )

    if handler
        and type(handler.getTypeLabel)
            == "function" then

        local label =
            handler.getTypeLabel(
                FJ.MemoryTypes.GetRawMemory(
                    memory
                )
            )

        if label ~= nil then
            return label
        end
    end

    return semanticType
end

local function GetRecordingMetadata()
    local metadata = {}

    if type(GetLocale)
        == "function" then

        local success,
            locale = pcall(
                GetLocale
            )

        if success
            and type(locale) == "string"
            and locale ~= "" then

            metadata.locale =
                locale
        end
    end

    if type(GetBuildInfo)
        == "function" then

        local success,
            clientVersion,
            clientBuild = pcall(
                GetBuildInfo
            )

        if success then
            if type(clientVersion) == "string"
                and clientVersion ~= "" then

                metadata.clientVersion =
                    clientVersion
            end

            if clientBuild ~= nil
                and tostring(clientBuild) ~= "" then

                metadata.clientBuild =
                    tostring(clientBuild)
            end
        end
    end

    if type(FJ.Version) == "string"
        and FJ.Version ~= "" then

        metadata.addonVersion =
            FJ.Version
    end

    return metadata
end

local function GetLocationName(
    memory
)
    if type(memory) ~= "table" then
        return nil
    end

    local data =
        type(memory.data) == "table"
        and memory.data
        or {}

    local location =
        type(memory.location) == "table"
        and memory.location
        or {}

    --
    -- Prefer stable IDs over names stored
    -- in SavedVariables.
    --
    -- Stored names may belong to a different
    -- client locale.
    --

    if memory.type == "INSTANCE" then
        local instanceLocation = {
            kind =
                location.kind
                or "INSTANCE",

            instanceID =
                data.instanceID
                or location.instanceID,

            mapID =
                location.mapID,

            name =
                data.instanceName
                or location.name,

            type =
                data.instanceType
                or location.type
        }

        return FJ.Utils
            .GetLocalizedLocationName(
                instanceLocation
            )
    end

    if memory.type == "ZONE" then
        local zoneLocation = {
            kind =
                location.kind
                or "ZONE",

            mapID =
                data.mapID
                or location.mapID,

            instanceID =
                location.instanceID,

            name =
                data.zoneName
                or location.name,

            type =
                location.type
        }

        return FJ.Utils
            .GetLocalizedLocationName(
                zoneLocation
            )
    end

    return FJ.Utils
        .GetLocalizedLocationName(
            location
        )
end

local function ParseLegacyLevel(
    title
)
    if type(title) ~= "string" then
        return nil
    end

    local level =
        string.match(
            title,
            "Reached Level (%d+)"
        )

    return tonumber(level)
end

local function ParseLegacyName(
    title,
    prefix
)
    if type(title) ~= "string" then
        return nil
    end

    local pattern =
        "^"
        .. prefix
        .. "(.+)$"

    return string.match(
        title,
        pattern
    )
end

local function GetKnownRealmNames()
    local realms = {}

    local function AddRealm(value)
        if type(value) ~= "string"
            or value == "" then

            return
        end

        for _, existing in ipairs(
            realms
        ) do
            if string.lower(existing)
                == string.lower(value) then

                return
            end
        end

        table.insert(
            realms,
            value
        )
    end

    if type(GetRealmName)
        == "function" then

        local success,
            realm = pcall(
                GetRealmName
            )

            if success then
                AddRealm(realm)
            end
        end

        if type(GetNormalizedRealmName)
            == "function" then

            local success,
                realm = pcall(
                    GetNormalizedRealmName
                )

            if success then
                AddRealm(realm)
            end
        end

        if type(SelectedRealmName)
            == "function" then

            local success,
                realm = pcall(
                    SelectedRealmName
                )

            if success then
                AddRealm(realm)
            end
        end

        return realms
end

local function StripKnownRealmSuffix(
    name
)
    if type(name) ~= "string"
        or name == "" then

        return name
    end

    local lowerName =
        string.lower(name)

    for _, realm in ipairs(
        GetKnownRealmNames()
    ) do
        local lowerRealm =
            string.lower(realm)

        local suffixes = {
            "-" .. lowerRealm,
            " " .. lowerRealm
        }

        for _, suffix in ipairs(
            suffixes
        ) do
            if #lowerName > #suffix
                and string.sub(
                    lowerName,
                    -#suffix
                ) == suffix then

                return string.sub(
                    name,
                    1,
                    #name - #suffix
                )
            end
        end
    end

    return name
end

local function GetEnvironmentalTitleKey(
    environmentalType
)
    if type(environmentalType)
        ~= "string" then

        return nil
    end

    return ENVIRONMENT_TITLE_KEYS[
        string.upper(
            environmentalType
        )
    ]
end

function FJ.Memories.GetSchemaVersion()
    return MEMORY_SCHEMA_VERSION
end

function FJ.Memories.GetCurrentLocation()
    local inInstance,
        instanceType =
            IsInInstance()

    if inInstance then
        local instanceName,
            currentInstanceType,
            difficultyID,
            difficultyName,
            maxPlayers,
            dynamicDifficulty,
            isDynamic,
            instanceID =
                GetInstanceInfo()

        return {
            kind = "INSTANCE",

            mapID = nil,

            instanceID =
                instanceID,

            name =
                instanceName
                or FJ.Locale.Get(
                    "UNKNOWN"
                ),

            type =
                currentInstanceType
                or instanceType
        }
    end

    local mapID =
        C_Map.GetBestMapForUnit(
            "player"
        )

    if not mapID then
        return {
            kind = "UNKNOWN",
            mapID = nil,
            instanceID = nil,
            name =
                FJ.Locale.Get(
                    "UNKNOWN"
                ),
            type = nil
        }
    end

    local mapInfo =
        C_Map.GetMapInfo(
            mapID
        )

    return {
        kind = "ZONE",

        mapID =
            mapID,

        instanceID =
            nil,

        name =
            mapInfo
            and mapInfo.name
            or FJ.Locale.Get(
                "UNKNOWN"
            ),

        type = nil
    }
end

function FJ.Memories.MigrateLegacyMemory(
    memory
)
    if type(memory) ~= "table" then
        return false
    end

    local changed = false

    if type(memory.data) ~= "table" then
        memory.data = {}
        changed = true
    end

    if not memory.source then
        memory.source = "RECORDED"
        changed = true
    end

    if type(memory.favorite)
        ~= "boolean" then

        memory.favorite = false
        changed = true
    end

    if type(memory.metadata)
        ~= "table" then

        memory.metadata = {}
        changed = true
    end

    local data =
        memory.data

    local location =
        type(memory.location)
            == "table"
        and memory.location
        or nil

    if memory.type == "ZONE" then
        if data.mapID == nil
            and location
            and location.mapID then

            data.mapID =
                location.mapID

            changed = true
        end

        if data.zoneName == nil then
            data.zoneName =
                location
                and location.name
                or ParseLegacyName(
                    memory.title,
                    "Discovered "
                )

            if data.zoneName then
                changed = true
            end
        end

    elseif memory.type == "LEVEL" then
        if data.level == nil then
            data.level =
                ParseLegacyLevel(
                    memory.title
                )

            if level then
                changed = true
            end
        end

    elseif memory.type == "INSTANCE" then
        if data.instanceID == nil
            and location
            and location.instanceID then

            data.instanceID =
                location.instanceID

            changed = true
        end

        if data.instanceName == nil then
            data.instanceName =
                location
                and location.name
                or ParseLegacyName(
                    memory.title,
                    "Entered "
                )

            if data.instanceName then
                changed = true
            end
        end

        if data.instanceType == nil
            and location
            and location.type then

            data.instanceType =
                location.type

            changed = true
        end
    end

    if memory.schemaVersion
        ~= MEMORY_SCHEMA_VERSION then

        memory.schemaVersion =
            MEMORY_SCHEMA_VERSION

        changed = true
    end

    return changed
end

function FJ.Memories.GetDisplayTitle(
    memory
)
    if type(memory) ~= "table" then
        return FJ.Locale.Get(
            "UNKNOWN"
        )
    end

    local handler =
        FJ.MemoryTypes.Get(
            memory.type
        )

    if handler
        and type(handler.getTitle)
            == "function" then

        local title =
            handler.getTitle(
                memory
            )

        if title ~= nil then
            return title
        end
    end

    local data =
        type(memory.data) == "table"
        and memory.data
        or {}

    if memory.type == "ZONE" then
        local zoneName =
            GetLocationName(
                memory
            )

        if zoneName then
            return FJ.Locale.Format(
                "MEMORY_TITLE_ZONE",
                zoneName
            )
        end

    elseif memory.type == "LEVEL" then
        local level =
            tonumber(
                data.level
            )
            or ParseLegacyLevel(
                memory.title
            )

        if level then
            return FJ.Locale.Format(
                "MEMORY_TITLE_LEVEL",
                level
            )
        end

    elseif memory.type == "INSTANCE" then
        local instanceName =
            GetLocationName(
                memory
            )

        if instanceName then
            return FJ.Locale.Format(
                "MEMORY_TITLE_INSTANCE",
                instanceName
            )
        end

    elseif memory.type == "DEATH" then
        if data.cause
            == "ENVIRONMENTAL" then

            local environmentKey =
                GetEnvironmentalTitleKey(
                    data.environmentalType
                )

            if environmentKey then
                return FJ.Locale.Get(
                    environmentKey
                )
            end

            return FJ.Locale.Get(
                "MEMORY_TITLE_DEATH_ENVIRONMENT"
            )
        end

        local recordedKillerName =
            FJ.Utils.GetRecordedUnitName(
                data.killerNameRaw,
                data.killerName
            )

        if recordedKillerName then
            local killerName =
                StripKnownRealmSuffix(
                    recordedKillerName
                )

            return FJ.Locale.Format(
                "MEMORY_TITLE_DEATH_KILLER",
                killerName
            )
        end

        return FJ.Locale.Get(
            "MEMORY_TITLE_DEATH"
        )
    end

    return memory.title
        or FJ.Locale.Get(
            "UNKNOWN"
        )
end

function FJ.Memories.GetDisplayDescription(
    memory
)
    if type(memory) ~= "table" then
        return nil
    end

    local handler =
        FJ.MemoryTypes.Get(
            memory.type
        )

    if handler
        and type(handler.getDescription)
            == "function" then

        local description =
            handler.getDescription(
                memory
            )

        if description ~= nil then
            return description
        end
    end

    local data =
        type(memory.data) == "table"
        and memory.data
        or {}

    if memory.type == "DEATH" then
        local spellName =
            FJ.Utils.GetLocalizedSpellName(
                data.spellID,
                data.spellName
            )

        if spellName then
            return FJ.Locale.Format(
                "MEMORY_DESCRIPTION_DEATH_SPELL",
                spellName
            )
        end
    end

    local descriptionKeys = {
        LEVEL =
            "MEMORY_DESCRIPTION_LEVEL",

        ZONE =
            "MEMORY_DESCRIPTION_ZONE",

        INSTANCE =
            "MEMORY_DESCRIPTION_INSTANCE",

        DEATH =
            "MEMORY_DESCRIPTION_DEATH"
    }

    local key =
        descriptionKeys[
            memory.type
        ]

    if key then
        return FJ.Locale.Get(
            key
        )
    end

    return memory.description
end

function FJ.Memories.GetDisplayLocationName(
    memory
)
    return GetLocationName(
        memory
    )
    or FJ.Locale.Get(
        "UNKNOWN"
    )
end

function FJ.Memories.Add(
    memoryType,
    data,
    locationOverride,
    source
)
    local timestamp =
        time()

    local memoryID =
        FJ.Storage.CreateMemoryID(
            timestamp
        )

    if not memoryID then
        return nil
    end

    local location =
        locationOverride
        or FJ.Memories
            .GetCurrentLocation()

    local memory = {
        schemaVersion =
            MEMORY_SCHEMA_VERSION,

        id =
            memoryID,

        type =
            memoryType,

        timestamp =
            timestamp,

        location =
            location,

        source =
            source
            or "RECORDED",

        favorite = false,

        metadata =
            GetRecordingMetadata(),

        data =
            type(data) == "table"
            and data
            or {}
    }

    -- Bind a newly recorded event to the active chapter at creation time.
    -- This also handles events recorded in the same second a chapter closes:
    -- their explicit assignment remains stable if the chapter is edited.
    -- Older memories are not rewritten and continue using time lookup.
    local chapters = FJ.Chapters
    if chapters and type(chapters.GetActive) == "function" then
        local active = chapters.GetActive()
        if active and type(active.id) == "string" then
            memory.chapterId = active.id
        end
    end

    table.insert(
        JourneyState.memories,
        memory
    )

    return memory
end
