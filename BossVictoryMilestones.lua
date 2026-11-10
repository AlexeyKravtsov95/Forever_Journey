local addonName, FJ = ...

FJ.BossVictoryMilestones = {}

local MEMORY_TYPE =
    "BOSS_VICTORY"

local DUPLICATE_WINDOW_SECONDS =
    10

local locale =
    GetLocale()

local strings = {
    enUS = {
        TYPE =
            "VICTORY",

        UNKNOWN_BOSS =
            "Unknown boss",

        UNKNOWN_INSTANCE =
            "Unknown instance",

        DESCRIPTION =
            "The battle ended in victory."
    },

    ruRU = {
        TYPE =
            "ПОБЕДА",

        UNKNOWN_BOSS =
            "Неизвестный босс",

        UNKNOWN_INSTANCE =
            "Неизвестное подземелье",

        DESCRIPTION =
            "Сражение завершилось победой."
    }
}

local currentStrings =
    strings[locale]
    or strings.enUS

local recentVictories = {}

local function T(
    key
)
    return currentStrings[key]
        or strings.enUS[key]
        or key
end

local function GetNow()
    if type(GetTime)
        == "function" then

        return GetTime()
    end

    return time()
end

local function RefreshUI()
    if FJ.UI
        and type(
            FJ.UI.RefreshIfVisible
        ) == "function" then

        FJ.UI.RefreshIfVisible()
    end
end

local function GetCurrentInstance()
    local result = {
        inInstance = false,
        instanceName = nil,
        instanceType = nil,
        difficultyID = nil,
        difficultyName = nil,
        maxPlayers = nil,
        instanceID = nil
    }

    if type(IsInInstance)
        == "function" then

        local success,
            inInstance,
            instanceType = pcall(
                IsInInstance
            )

        if success then
            result.inInstance =
                inInstance == true

            result.instanceType =
                instanceType
        end
    end

    if type(GetInstanceInfo)
        ~= "function" then

        return result
    end

    local success,
        instanceName,
        instanceType,
        difficultyID,
        difficultyName,
        maxPlayers,
        dynamicDifficulty,
        isDynamic,
        instanceID = pcall(
            GetInstanceInfo
        )

    if not success then
        return result
    end

    result.instanceName =
        instanceName

    result.instanceType =
        instanceType
        or result.instanceType

    result.difficultyID =
        difficultyID

    result.difficultyName =
        difficultyName

    result.maxPlayers =
        maxPlayers

    result.instanceID =
        instanceID

    return result
end

local function BuildLocation(
    instance
)
    if instance.inInstance
        == true then

        return {
            kind =
                "INSTANCE",

            mapID =
                nil,

            instanceID =
                instance.instanceID,

            name =
                instance.instanceName
                or T(
                    "UNKNOWN_INSTANCE"
                ),

            type =
                instance.instanceType
        }
    end

    return FJ.Memories
        .GetCurrentLocation()
end

local function BuildDuplicateKey(
    encounterID,
    encounterName,
    instanceID
)
    local encounterPart =
        encounterID
        or encounterName
        or "unknown"

    return tostring(
        encounterPart
    )
        .. ":"
        .. tostring(
            instanceID
            or "unknown"
        )
end

local function CleanupExpiredGuards(
    now
)
    for key,
        recordedAt in pairs(
            recentVictories
        ) do

        local elapsed =
            now - recordedAt

        if elapsed < 0
            or elapsed
                > DUPLICATE_WINDOW_SECONDS then

            recentVictories[key] =
                nil
        end
    end
end

local function IsDuplicate(
    duplicateKey
)
    local now =
        GetNow()

    CleanupExpiredGuards(
        now
    )

    local recordedAt =
        recentVictories[
            duplicateKey
        ]

    if recordedAt == nil then
        return false
    end

    local elapsed =
        now - recordedAt

    return elapsed >= 0
        and elapsed
            <= DUPLICATE_WINDOW_SECONDS
end

local function RememberVictory(
    duplicateKey
)
    recentVictories[
        duplicateKey
    ] = GetNow()
end

local function RecordVictory(
    encounterID,
    encounterName,
    difficultyID,
    groupSize
)
    local instance =
        GetCurrentInstance()

    local normalizedEncounterID =
        tonumber(
            encounterID
        )

    local bossName =
        type(encounterName)
            == "string"
        and encounterName ~= ""
        and encounterName
        or T(
            "UNKNOWN_BOSS"
        )

    local duplicateKey =
        BuildDuplicateKey(
            normalizedEncounterID,
            bossName,
            instance.instanceID
        )

    if IsDuplicate(
        duplicateKey
    ) then

        return false,
            "DUPLICATE"
    end

    local memory =
        FJ.Memories.Add(
            MEMORY_TYPE,
            {
                encounterID =
                    normalizedEncounterID,

                encounterName =
                    bossName,

                instanceID =
                    instance.instanceID,

                instanceName =
                    instance.instanceName,

                instanceType =
                    instance.instanceType,

                difficultyID =
                    tonumber(
                        difficultyID
                    )
                    or instance.difficultyID,

                difficultyName =
                    instance.difficultyName,

                groupSize =
                    tonumber(
                        groupSize
                    ),

                maxPlayers =
                    instance.maxPlayers,

                success = true
            },
            BuildLocation(
                instance
            ),
            "RECORDED"
        )

    if not memory then
        return false,
            "STORAGE_UNAVAILABLE"
    end

    RememberVictory(
        duplicateKey
    )

    RefreshUI()

    return true,
        memory
end

function FJ.BossVictoryMilestones.Record(
    encounterID,
    encounterName,
    difficultyID,
    groupSize
)
    return RecordVictory(
        encounterID,
        encounterName,
        difficultyID,
        groupSize
    )
end

FJ.MemoryTypes.Register(
    MEMORY_TYPE,
    {
        getTypeLabel =
            function()
                return T(
                    "TYPE"
                )
            end,

        getTitle =
            function(
                memory
            )
                local data =
                    type(memory.data)
                        == "table"
                    and memory.data
                    or {}

                if type(
                    data.encounterName
                ) == "string"
                    and data.encounterName
                        ~= "" then

                    return data.encounterName
                end

                return T(
                    "UNKNOWN_BOSS"
                )
            end,

        getDescription =
            function()
                return T(
                    "DESCRIPTION"
                )
            end,

        getMarkerTexture =
            function()
                return FJ.Theme
                    .Textures
                    .markerInstance
            end
    }
)

local eventFrame =
    CreateFrame(
        "Frame"
    )

local registrationSuccess,
    registrationResult = pcall(
        eventFrame.RegisterEvent,
        eventFrame,
        "ENCOUNTER_END"
    )

FJ.BossVictoryMilestones.IsSupported =
    registrationSuccess == true
    and registrationResult ~= false

eventFrame:SetScript(
    "OnEvent",
    function(
        self,
        event,
        encounterID,
        encounterName,
        difficultyID,
        groupSize,
        success
    )
        if event ~= "ENCOUNTER_END" then
            return
        end

        if success ~= 1
            and success ~= true then

            return
        end

        RecordVictory(
            encounterID,
            encounterName,
            difficultyID,
            groupSize
        )
    end
)
