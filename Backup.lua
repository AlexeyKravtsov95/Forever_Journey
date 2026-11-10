local addonName, FJ = ...

FJ.Backup = {}

local Backup = FJ.Backup

local FORMAT_VERSION = 1
local PREFIX = "FJBACKUP1:"

local MAX_INPUT_SIZE =
    2 * 1024 * 1024

local MAX_DEPTH = 32
local MAX_TABLE_ENTRIES = 100000

local function GetCurrentSchemaVersion()
    if type(ForeverJourneyDB)
        == "table" then

        return tonumber(
            ForeverJourneyDB.schemaVersion
        ) or 0
    end

    return 0
end

local function CountTableEntries(
    value
)
    if type(value) ~= "table" then
        return 0
    end

    local count = 0

    for _ in pairs(value) do
        count =
            count + 1
    end

    return count
end

local function CountFavorites(
    memories
)
    local count = 0

    for _, memory in ipairs(
        memories
        or {}
    ) do
        if type(memory)
                == "table"
            and memory.favorite
                == true then

            count =
                count + 1
        end
    end

    return count
end

local function KeyTypeRank(
    value
)
    local valueType =
        type(value)

    if valueType
        == "number" then

        return 1
    end

    if valueType
        == "string" then

        return 2
    end

    if valueType
        == "boolean" then

        return 3
    end

    return nil
end

local function SortKeys(
    keys
)
    table.sort(
        keys,
        function(
            left,
            right
        )
            local leftType =
                type(left)

            local rightType =
                type(right)

            if leftType
                ~= rightType then

                return KeyTypeRank(
                    left
                ) < KeyTypeRank(
                    right
                )
            end

            if leftType == "number"
                or leftType
                    == "string" then

                return left < right
            end

            if leftType
                == "boolean" then

                return left == false
                    and right == true
            end

            return tostring(left)
                < tostring(right)
        end
    )
end

local function EncodeValue(
    value,
    state,
    depth
)
    if depth > MAX_DEPTH then
        return nil,
            "MAX_DEPTH_EXCEEDED"
    end

    local valueType =
        type(value)

    if valueType == "nil" then
        return "N"
    end

    if valueType
        == "boolean" then

        return value
            and "B1"
            or "B0"
    end

    if valueType
        == "number" then

        if value ~= value
            or value
                == math.huge
            or value
                == -math.huge then

            return nil,
                "INVALID_NUMBER"
        end

        local text =
            tostring(value)

        return "D"
            .. tostring(
                #text
            )
            .. ":"
            .. text
    end

    if valueType
        == "string" then

        return "S"
            .. tostring(
                #value
            )
            .. ":"
            .. value
    end

    if valueType
        ~= "table" then

        return nil,
            "UNSUPPORTED_TYPE_"
                .. valueType
    end

    if state.active[value] then
        return nil,
            "CYCLIC_TABLE"
    end

    state.active[value] =
        true

    local keys = {}

    for key in pairs(
        value
    ) do
        if not KeyTypeRank(
            key
        ) then
            state.active[value] =
                nil

            return nil,
                "UNSUPPORTED_KEY_TYPE_"
                    .. type(key)
        end

        table.insert(
            keys,
            key
        )
    end

    SortKeys(
        keys
    )

    state.entryCount =
        state.entryCount
        + #keys

    if state.entryCount
        > MAX_TABLE_ENTRIES then

        state.active[value] =
            nil

        return nil,
            "MAX_ENTRIES_EXCEEDED"
    end

    local parts = {
        "T",
        tostring(#keys),
        ":"
    }

    for _, key in ipairs(
        keys
    ) do
        local encodedKey,
            keyError =
                EncodeValue(
                    key,
                    state,
                    depth + 1
                )

        if not encodedKey then
            state.active[value] =
                nil

            return nil,
                keyError
        end

        local encodedValue,
            valueError =
                EncodeValue(
                    value[key],
                    state,
                    depth + 1
                )

        if not encodedValue then
            state.active[value] =
                nil

            return nil,
                valueError
        end

        table.insert(
            parts,
            encodedKey
        )

        table.insert(
            parts,
            encodedValue
        )
    end

    state.active[value] =
        nil

    return table.concat(
        parts
    )
end

local function Serialize(
    value
)
    return EncodeValue(
        value,
        {
            active = {},
            entryCount = 0
        },
        0
    )
end

local function ReadLength(
    text,
    position
)
    local colon =
        string.find(
            text,
            ":",
            position,
            true
        )

    if not colon then
        return nil,
            nil,
            "MISSING_LENGTH_SEPARATOR"
    end

    local lengthText =
        string.sub(
            text,
            position,
            colon - 1
        )

    if lengthText == ""
        or string.find(
            lengthText,
            "[^0-9]"
        ) then

        return nil,
            nil,
            "INVALID_LENGTH"
    end

    local length =
        tonumber(
            lengthText
        )

    if not length
        or length < 0 then

        return nil,
            nil,
            "INVALID_LENGTH"
    end

    return length,
        colon + 1,
        nil
end

local function DecodeValue(
    text,
    position,
    state,
    depth
)
    if depth > MAX_DEPTH then
        return nil,
            position,
            "MAX_DEPTH_EXCEEDED"
    end

    if position > #text then
        return nil,
            position,
            "UNEXPECTED_END"
    end

    local tag =
        string.sub(
            text,
            position,
            position
        )

    position =
        position + 1

    if tag == "N" then
        return nil,
            position,
            nil
    end

    if tag == "B" then
        local bit =
            string.sub(
                text,
                position,
                position
            )

        if bit == "1" then
            return true,
                position + 1,
                nil
        end

        if bit == "0" then
            return false,
                position + 1,
                nil
        end

        return nil,
            position,
            "INVALID_BOOLEAN"
    end

    if tag == "D"
        or tag == "S" then

        local length,
            contentPosition,
            lengthError =
                ReadLength(
                    text,
                    position
                )

        if not length then
            return nil,
                position,
                lengthError
        end

        local contentEnd =
            contentPosition
            + length
            - 1

        if contentEnd
            > #text then

            return nil,
                position,
                "TRUNCATED_VALUE"
        end

        local raw =
            string.sub(
                text,
                contentPosition,
                contentEnd
            )

        if tag == "D" then
            local number =
                tonumber(raw)

            if not number then
                return nil,
                    position,
                    "INVALID_NUMBER"
            end

            return number,
                contentEnd + 1,
                nil
        end

        return raw,
            contentEnd + 1,
            nil
    end

    if tag == "T" then
        local count,
            contentPosition,
            countError =
                ReadLength(
                    text,
                    position
                )

        if not count then
            return nil,
                position,
                countError
        end

        state.entryCount =
            state.entryCount
            + count

        if state.entryCount
            > MAX_TABLE_ENTRIES then

            return nil,
                position,
                "MAX_ENTRIES_EXCEEDED"
        end

        local result = {}

        local nextPosition =
            contentPosition

        for _ = 1,
            count do

            local key,
                keyPosition,
                keyError =
                    DecodeValue(
                        text,
                        nextPosition,
                        state,
                        depth + 1
                    )

            if keyError then
                return nil,
                    nextPosition,
                    keyError
            end

            if key == nil
                or not KeyTypeRank(
                    key
                ) then

                return nil,
                    nextPosition,
                    "INVALID_TABLE_KEY"
            end

            local item,
                itemPosition,
                itemError =
                    DecodeValue(
                        text,
                        keyPosition,
                        state,
                        depth + 1
                    )

            if itemError then
                return nil,
                    keyPosition,
                    itemError
            end

            result[key] =
                item

            nextPosition =
                itemPosition
        end

        return result,
            nextPosition,
            nil
    end

    return nil,
        position,
        "UNKNOWN_TAG_"
            .. tostring(tag)
end

local function Deserialize(
    text
)
    local value,
        nextPosition,
        decodeError =
            DecodeValue(
                text,
                1,
                {
                    entryCount = 0
                },
                0
            )

    if decodeError then
        return nil,
            decodeError
    end

    if nextPosition
        ~= #text + 1 then

        return nil,
            "TRAILING_DATA"
    end

    return value,
        nil
end

local function Adler32(
    text
)
    local modulo = 65521
    local a = 1
    local b = 0

    for index = 1,
        #text do

        a =
            (
                a
                + string.byte(
                    text,
                    index
                )
            ) % modulo

        b =
            (
                b
                + a
            ) % modulo
    end

    return b * 65536
        + a
end

local function ToHex32(
    value
)
    local digits =
        "0123456789ABCDEF"

    local result = {}
    local remaining =
        value

    for index = 8,
        1,
        -1 do

        local digit =
            remaining % 16

        result[index] =
            string.sub(
                digits,
                digit + 1,
                digit + 1
            )

        remaining =
            math.floor(
                remaining / 16
            )
    end

    return table.concat(
        result
    )
end

local function BuildSummary(
    package,
    encodedSize,
    checksum
)
    local character =
        package.character
        or {}

    local memories =
        character.memories
        or {}

    return {
        formatVersion =
            package.formatVersion,

        addonVersion =
            package.addonVersion,

        sourceSchemaVersion =
            package.schemaVersion,

        currentSchemaVersion =
            GetCurrentSchemaVersion(),

        exportedAt =
            package.exportedAt,

        characterKey =
            package.characterKey,

        sameCharacter =
            package.characterKey
                == FJ.Storage
                    .characterKey,

        memoryCount =
            #memories,

        favoriteCount =
            CountFavorites(
                memories
            ),

        visitedZoneCount =
            CountTableEntries(
                character.visitedZones
            ),

        deaths =
            type(
                character.stats
            ) == "table"
            and tonumber(
                character.stats.deaths
            )
            or 0,

        encodedSize =
            encodedSize,

        checksum =
            checksum
    }
end

local function ValidatePackage(
    package
)
    if type(package)
        ~= "table" then

        return false,
            "PACKAGE_NOT_TABLE"
    end

    if tonumber(
        package.formatVersion
    ) ~= FORMAT_VERSION then

        return false,
            "UNSUPPORTED_FORMAT_VERSION"
    end

    if type(
        package.characterKey
    ) ~= "string"
        or package.characterKey
            == "" then

        return false,
            "MISSING_CHARACTER_KEY"
    end

    if type(
        package.character
    ) ~= "table" then

        return false,
            "MISSING_CHARACTER_DATA"
    end

    if type(
        package.character
            .memories
    ) ~= "table" then

        return false,
            "INVALID_MEMORIES"
    end

    if type(
        package.character
            .visitedZones
    ) ~= "table" then

        return false,
            "INVALID_VISITED_ZONES"
    end

    if type(
        package.character
            .stats
    ) ~= "table" then

        return false,
            "INVALID_STATS"
    end

    local sourceSchema =
        tonumber(
            package.schemaVersion
        )

    local currentSchema =
        GetCurrentSchemaVersion()

    if not sourceSchema then
        return false,
            "MISSING_SCHEMA_VERSION"
    end

    if currentSchema > 0
        and sourceSchema
            > currentSchema then

        return false,
            "BACKUP_FROM_NEWER_SCHEMA"
    end

    return true,
        nil
end

local function ParseExport(
    exportText
)
    if type(exportText)
        ~= "string" then

        return nil,
            nil,
            "EXPORT_NOT_STRING"
    end

    if #exportText == 0 then
        return nil,
            nil,
            "EXPORT_EMPTY"
    end

    if #exportText
        > MAX_INPUT_SIZE then

        return nil,
            nil,
            "EXPORT_TOO_LARGE"
    end

    if string.sub(
        exportText,
        1,
        #PREFIX
    ) ~= PREFIX then

        return nil,
            nil,
            "INVALID_PREFIX"
    end

    local checksumStart =
        #PREFIX + 1

    local checksumEnd =
        checksumStart + 7

    local checksum =
        string.sub(
            exportText,
            checksumStart,
            checksumEnd
        )

    if #checksum ~= 8
        or string.find(
            checksum,
            "[^0-9A-Fa-f]"
        ) then

        return nil,
            nil,
            "INVALID_CHECKSUM_HEADER"
    end

    local separatorPosition =
        checksumEnd + 1

    if string.sub(
        exportText,
        separatorPosition,
        separatorPosition
    ) ~= ":" then

        return nil,
            nil,
            "INVALID_HEADER"
    end

    local payload =
        string.sub(
            exportText,
            separatorPosition + 1
        )

    local calculatedChecksum =
        ToHex32(
            Adler32(
                payload
            )
        )

    if string.upper(
        checksum
    ) ~= calculatedChecksum then

        return nil,
            nil,
            "CHECKSUM_MISMATCH"
    end

    local package,
        deserializeError =
            Deserialize(
                payload
            )

    if not package then
        return nil,
            nil,
            deserializeError
    end

    local valid,
        validationError =
            ValidatePackage(
                package
            )

    if not valid then
        return nil,
            nil,
            validationError
    end

    return package,
        calculatedChecksum,
        nil
end

local function BuildMemoryIDSet(
    memories
)
    local ids = {}

    for _, memory in ipairs(
        memories
        or {}
    ) do
        if type(memory)
                == "table"
            and type(
                memory.id
            ) == "string"
            and memory.id
                ~= "" then

            ids[memory.id] =
                true
        end
    end

    return ids
end

local function DeepCopy(
    value,
    seen
)
    if type(value)
        ~= "table" then

        return value
    end

    seen =
        seen
        or {}

    if seen[value] then
        return seen[value]
    end

    local copy = {}

    seen[value] =
        copy

    for key,
        item in pairs(
            value
        ) do

        copy[
            DeepCopy(
                key,
                seen
            )
        ] =
            DeepCopy(
                item,
                seen
            )
    end

    return copy
end

local function MergeMissingKeys(
    target,
    source
)
    if type(target)
            ~= "table"
        or type(source)
            ~= "table" then

        return 0
    end

    local added = 0

    for key,
        value in pairs(
            source
        ) do

        if target[key] == nil then
            target[key] =
                DeepCopy(
                    value
                )

            added =
                added + 1
        end
    end

    return added
end

local function MergeMaximumNumbers(
    target,
    source
)
    if type(target)
            ~= "table"
        or type(source)
            ~= "table" then

        return 0
    end

    local changed = 0

    for key,
        importedValue in pairs(
            source
        ) do

        local currentValue =
            target[key]

        if type(importedValue)
                == "number"
            and type(currentValue)
                == "number" then

            if importedValue
                > currentValue then

                target[key] =
                    importedValue

                changed =
                    changed + 1
            end

        elseif currentValue
            == nil then

            target[key] =
                DeepCopy(
                    importedValue
                )

            changed =
                changed + 1
        end
    end

    return changed
end

local function SortMemories(
    memories
)
    table.sort(
        memories,
        function(
            left,
            right
        )
            local leftTimestamp =
                type(left) == "table"
                and tonumber(
                    left.timestamp
                )
                or 0

            local rightTimestamp =
                type(right) == "table"
                and tonumber(
                    right.timestamp
                )
                or 0

            if leftTimestamp
                ~= rightTimestamp then

                return leftTimestamp
                    < rightTimestamp
            end

            local leftID =
                type(left) == "table"
                and tostring(
                    left.id
                    or ""
                )
                or ""

            local rightID =
                type(right) == "table"
                and tostring(
                    right.id
                    or ""
                )
                or ""

            return leftID
                < rightID
        end
    )
end

local function ReplaceTableContents(
    target,
    source
)
    for key in pairs(
        target
    ) do
        target[key] =
            nil
    end

    for key,
        value in pairs(
            source
        ) do

        target[
            DeepCopy(
                key
            )
        ] =
            DeepCopy(
                value
            )
    end
end

local function MergeRecoveredHistory(
    target,
    source
)
    if type(target)
            ~= "table"
        or type(source)
            ~= "table" then

        return 0
    end

    if source.initialized
        ~= true then

        return 0
    end

    local sourceCapturedAt =
        tonumber(
            source.capturedAt
        )

    local targetCapturedAt =
        tonumber(
            target.capturedAt
        )

    local shouldRestore =
        target.initialized
            ~= true
        or (
            sourceCapturedAt
            and (
                not targetCapturedAt
                or sourceCapturedAt
                    < targetCapturedAt
            )
        )

    if not shouldRestore then
        return 0
    end

    ReplaceTableContents(
        target,
        source
    )

    return 1
end

function Backup.ExportCurrentCharacter()
    local character =
        FJ.Storage.character

    local characterKey =
        FJ.Storage.characterKey

    if type(character)
            ~= "table"
        or type(characterKey)
            ~= "string" then

        return nil,
            "CHARACTER_NOT_ATTACHED"
    end

    local package = {
        formatVersion =
            FORMAT_VERSION,

        addonVersion =
            FJ.Version
            or "unknown",

        schemaVersion =
            tonumber(
                character.schemaVersion
            )
            or GetCurrentSchemaVersion(),

        exportedAt =
            time(),

        characterKey =
            characterKey,

        character =
            character
    }

    local payload,
        serializeError =
            Serialize(
                package
            )

    if not payload then
        return nil,
            serializeError
    end

    local checksum =
        ToHex32(
            Adler32(
                payload
            )
        )

    local exportText =
        PREFIX
        .. checksum
        .. ":"
        .. payload

    return exportText,
        nil,
        BuildSummary(
            package,
            #exportText,
            checksum
        )
end

function Backup.ValidateExport(
    exportText
)
    local package,
        checksum,
        parseError =
            ParseExport(
                exportText
            )

    if not package then
        return false,
            parseError,
            nil
    end

    return true,
        nil,
        BuildSummary(
            package,
            #exportText,
            checksum
        )
end

function Backup.BuildImportPlan(
    exportText
)
    local package,
        checksum,
        parseError =
            ParseExport(
                exportText
            )

    if not package then
        return nil,
            parseError
    end

    local currentCharacter =
        FJ.Storage.character
        or {}

    local currentMemories =
        currentCharacter.memories
        or {}

    local importedMemories =
        package.character.memories
        or {}

    local currentIDs =
        BuildMemoryIDSet(
            currentMemories
        )

    local newMemories = 0
    local duplicateMemories = 0
    local memoriesWithoutID = 0

    for _, memory in ipairs(
        importedMemories
    ) do
        local memoryID =
            type(memory)
                == "table"
            and memory.id
            or nil

        if type(memoryID)
                ~= "string"
            or memoryID == "" then

            memoriesWithoutID =
                memoriesWithoutID + 1

        elseif currentIDs[
            memoryID
        ] then

            duplicateMemories =
                duplicateMemories + 1
        else
            newMemories =
                newMemories + 1

            currentIDs[
                memoryID
            ] = true
        end
    end

    local summary =
        BuildSummary(
            package,
            #exportText,
            checksum
        )

    return {
        summary =
            summary,

        sameCharacter =
            summary.sameCharacter,

        totalImportedMemories =
            #importedMemories,

        newMemories =
            newMemories,

        duplicateMemories =
            duplicateMemories,

        memoriesWithoutID =
            memoriesWithoutID
    },
        nil
end

function Backup.ImportMerge(
    exportText
)
    local package,
        checksum,
        parseError =
            ParseExport(
                exportText
            )

    if not package then
        return false,
            parseError,
            nil
    end

    if package.characterKey
        ~= FJ.Storage.characterKey then

        return false,
            "CHARACTER_MISMATCH",
            nil
    end

    local target =
        FJ.Storage.character

    if type(target)
        ~= "table" then

        return false,
            "CHARACTER_NOT_ATTACHED",
            nil
    end

    local source =
        package.character

    target.memories =
        target.memories
        or {}

    target.visitedZones =
        target.visitedZones
        or {}

    target.stats =
        target.stats
        or {}

    target.recoveredHistory =
        target.recoveredHistory
        or {}

    target.money =
        target.money
        or {}

    local currentIDs =
        BuildMemoryIDSet(
            target.memories
        )

    local addedMemories = 0
    local duplicateMemories = 0
    local skippedMemories = 0
    local restoredFavorites = 0

    for _, memory in ipairs(
        source.memories
        or {}
    ) do
        local memoryID =
            type(memory)
                == "table"
            and memory.id
            or nil

        if type(memoryID)
                ~= "string"
            or memoryID == "" then

            skippedMemories =
                skippedMemories + 1

        elseif currentIDs[
            memoryID
        ] then

            duplicateMemories =
                duplicateMemories + 1
        else
            local copiedMemory =
                DeepCopy(
                    memory
                )

            table.insert(
                target.memories,
                copiedMemory
            )

            currentIDs[
                memoryID
            ] = true

            addedMemories =
                addedMemories + 1

            if copiedMemory.favorite
                == true then

                restoredFavorites =
                    restoredFavorites + 1
            end
        end
    end

    SortMemories(
        target.memories
    )

    local restoredZones =
        MergeMissingKeys(
            target.visitedZones,
            source.visitedZones
        )

    local restoredStats =
        MergeMaximumNumbers(
            target.stats,
            source.stats
        )

    local recoveredChanges =
        MergeRecoveredHistory(
            target.recoveredHistory,
            source.recoveredHistory
        )

    if type(source.money)
        == "table" then

        if type(source.money.earned)
                == "number"
            and (
                type(target.money.earned)
                    ~= "number"
                or source.money.earned
                    > target.money.earned
            ) then

            target.money.earned =
                source.money.earned
        end

        if type(source.money.spent)
                == "number"
            and (
                type(target.money.spent)
                    ~= "number"
                or source.money.spent
                    > target.money.spent
            ) then

            target.money.spent =
                source.money.spent
        end
    end

    local importedCreatedAt =
        tonumber(
            source.createdAt
        )

    local currentCreatedAt =
        tonumber(
            target.createdAt
        )

    if importedCreatedAt
        and (
            not currentCreatedAt
            or importedCreatedAt
                < currentCreatedAt
        ) then

        target.createdAt =
            importedCreatedAt
    end

    local importedSequence =
        tonumber(
            source.memorySequence
        ) or 0

    local currentSequence =
        tonumber(
            target.memorySequence
        ) or 0

    target.memorySequence =
        math.max(
            currentSequence,
            importedSequence
        )

    FJ.State.memories =
        target.memories

    FJ.State.visitedZones =
        target.visitedZones

    FJ.State.stats =
        target.stats

    FJ.State.money =
        target.money

    FJ.State.recoveredHistory =
        target.recoveredHistory

    FJ.Storage.memoryIDs =
        BuildMemoryIDSet(
            target.memories
        )

    if FJ.UI
        and type(
            FJ.UI.RefreshIfVisible
        ) == "function" then

        FJ.UI.RefreshIfVisible()
    end

    return true,
        nil,
        {
            checksum =
                checksum,

            addedMemories =
                addedMemories,

            duplicateMemories =
                duplicateMemories,

            skippedMemories =
                skippedMemories,

            restoredFavorites =
                restoredFavorites,

            restoredZones =
                restoredZones,

            restoredStats =
                restoredStats,

            recoveredChanges =
                recoveredChanges,

            totalMemories =
                #target.memories
        }
end
