local addonName, FJ = ...

local JourneyState = FJ.State

FJ.Storage = {}

local SCHEMA_VERSION = 3

local function GetCharacterKey()
    local name =
        UnitName("player")

    if not name then
        return nil
    end

    local realm =
        GetNormalizedRealmName()

    if not realm
        or realm == "" then

        realm = GetRealmName()
    end

    if not realm then
        return nil
    end

    return realm
        .. ":"
        .. name
end

local function EnsureRecoveredHistory(
    recoveredHistory
)
    if type(recoveredHistory)
        ~= "table" then

        recoveredHistory = {}
    end

    if recoveredHistory.initialized
        == nil then

        recoveredHistory.initialized =
            false
    end

    recoveredHistory.completedQuests =
        recoveredHistory.completedQuests
        or {}

    recoveredHistory
        .completedQuests
        .count =
            recoveredHistory
                .completedQuests
                .count
            or 0

    recoveredHistory
        .completedQuests
        .questIDs =
            recoveredHistory
                .completedQuests
                .questIDs
            or {}

    recoveredHistory.played =
        recoveredHistory.played
        or {
            total = nil,
            currentLevel = nil
        }

    recoveredHistory.professions =
        recoveredHistory.professions
        or {}

    recoveredHistory.money =
        recoveredHistory.money
        or {
            current = nil
        }

    return recoveredHistory
end

local function NormalizeMemorySequence(
    value
)
    local sequence =
        tonumber(value)
        or 0

    if sequence < 0 then
        sequence = 0
    end

    return math.floor(
        sequence
    )
end

local function NormalizeTimestampForID(
    value
)
    local timestamp =
        tonumber(value)
        or 0

    if timestamp < 0 then
        timestamp = 0
    end

    return math.floor(
        timestamp
    )
end

local function ParseMemorySequenceFromID(
    memoryID
)
    if type(memoryID)
        ~= "string" then

        return nil
    end

    local sequence =
        string.match(
            memoryID,
            "^m:[^:]+:(%d+)$"
        )

    if not sequence then
        return nil
    end

    return NormalizeMemorySequence(
        sequence
    )
end

local function BuildMemoryID(
    timestamp,
    sequence
)
    return string.format(
        "m:%d:%d",
        NormalizeTimestampForID(
            timestamp
        ),
        NormalizeMemorySequence(
            sequence
        )
    )
end

local function IndexExistingMemoryIDs(
    character
)
    local usedMemoryIDs = {}

    character.memorySequence =
        NormalizeMemorySequence(
            character.memorySequence
        )

    for _, memory in ipairs(
        character.memories
    ) do
        if type(memory) == "table" then
            local memoryID =
                memory.id

            local hasValidID =
                type(memoryID) == "string"
                and memoryID ~= ""

            if hasValidID
                and not usedMemoryIDs[
                    memoryID
                ] then

                usedMemoryIDs[
                    memoryID
                ] = true

                local sequence =
                    ParseMemorySequenceFromID(
                        memoryID
                    )

                if sequence
                    and sequence
                        > character.memorySequence then

                    character.memorySequence =
                        sequence
                end
            else
                memory.id = nil
            end
        end
    end

    return usedMemoryIDs
end

local function AllocateMemoryID(
    character,
    memory,
    usedMemoryIDs
)
    local memoryID = nil

    repeat
        character.memorySequence =
            character.memorySequence
            + 1

        memoryID =
            BuildMemoryID(
                memory.timestamp,
                character.memorySequence
            )
    until not usedMemoryIDs[
        memoryID
    ]

    memory.id =
        memoryID

    usedMemoryIDs[
        memoryID
    ] = true

    return memoryID
end

local function MigrateCharacter(
    character
)
    character.memories =
        character.memories
        or {}

    character.visitedZones =
        character.visitedZones
        or {}

    character.stats =
        character.stats
        or {}

    character.stats.deaths =
        character.stats.deaths
        or 0

    character.money =
        character.money
        or {}

    if character.money.earned == nil then
        character.money.earned = 0
    end

    if character.money.spent == nil then
        character.money.spent = 0
    end

    character.recoveredHistory =
        EnsureRecoveredHistory(
            character.recoveredHistory
        )

    local usedMemoryIDs =
        IndexExistingMemoryIDs(
            character
        )

    for _, memory in ipairs(
        character.memories
    ) do
        if type(memory) == "table" then
            if not memory.id then
                AllocateMemoryID(
                    character,
                    memory,
                    usedMemoryIDs
                )
            end

            FJ.Memories.MigrateLegacyMemory(
                memory
            )
        end
    end

    character.schemaVersion =
        SCHEMA_VERSION

    return usedMemoryIDs
end

function FJ.Storage.Initialize()
    if type(ForeverJourneyDB)
        ~= "table" then

        ForeverJourneyDB = {}
    end

    ForeverJourneyDB.characters =
        ForeverJourneyDB.characters
        or {}

    for _, character in pairs(
        ForeverJourneyDB.characters
    ) do
        if type(character) == "table" then
            MigrateCharacter(
                character
            )
        end
    end

    ForeverJourneyDB.schemaVersion =
        SCHEMA_VERSION
end

function FJ.Storage.AttachCharacter()
    local characterKey =
        GetCharacterKey()

    if not characterKey then
        print(
            "Forever Journey: unable to determine character key."
        )

        return false
    end

    local characters =
        ForeverJourneyDB.characters

    local character =
        characters[characterKey]

    if not character then
        character = {
            schemaVersion =
                SCHEMA_VERSION,

            createdAt = time(),

            memorySequence = 0,

            memories = {},

            visitedZones = {},

            stats = {
                deaths = 0
            },

            money = {
                current = nil,
                earned = 0,
                spent = 0
            },

            recoveredHistory =
                JourneyState.recoveredHistory
        }

        characters[characterKey] =
            character
    end

    local usedMemoryIDs =
        MigrateCharacter(
            character
        )

    JourneyState.memories =
        character.memories

    JourneyState.visitedZones =
        character.visitedZones

    JourneyState.stats =
        character.stats

    JourneyState.money =
        character.money

    JourneyState.recoveredHistory =
        character.recoveredHistory

    -- Текущие деньги — runtime baseline.
    -- Не считаем разницу между сессиями доходом.
    JourneyState.money.current =
        GetMoney()

    FJ.Storage.characterKey =
        characterKey

    FJ.Storage.character =
        character

    FJ.Storage.memoryIDs =
        usedMemoryIDs

    return true
end

function FJ.Storage.CreateMemoryID(
    timestamp
)
    local character =
        FJ.Storage.character

    if type(character)
        ~= "table" then

        return nil
    end

    character.memorySequence =
        NormalizeMemorySequence(
            character.memorySequence
        )

    local usedMemoryIDs =
        FJ.Storage.memoryIDs

    if type(usedMemoryIDs)
        ~= "table" then

        usedMemoryIDs =
            IndexExistingMemoryIDs(
                character
            )

        FJ.Storage.memoryIDs =
            usedMemoryIDs
    end

    local memoryID = nil

    repeat
        character.memorySequence =
            character.memorySequence
            + 1

        memoryID =
            BuildMemoryID(
                timestamp,
                character.memorySequence
            )
    until not usedMemoryIDs[
        memoryID
    ]

    usedMemoryIDs[
        memoryID
    ] = true

    return memoryID
end