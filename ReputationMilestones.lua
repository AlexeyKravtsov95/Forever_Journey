local addonName, FJ = ...

FJ.ReputationMilestones = {}

local JourneyState = FJ.State

local MEMORY_TYPE =
    "REPUTATION_MILESTONE"

local DUPLICATE_WINDOW_SECONDS =
    10

local POLL_DELAYS = {
    0.05,
    0.25,
    0.75,
    1.50,
    3.00
}

local locale =
    GetLocale()

local strings = {
    enUS = {
        TYPE =
            "REPUTATION",

        UNKNOWN_FACTION =
            "Unknown faction",

        TITLE =
            "%s — %s",

        DESCRIPTION =
            "Standing improved: %s -> %s.",
    },

    ruRU = {
        TYPE =
            "РЕПУТАЦИЯ",

        UNKNOWN_FACTION =
            "Неизвестная фракция",

        TITLE =
            "%s — %s",

        DESCRIPTION =
            "Отношения улучшились: %s -> %s.",
    }
}

local currentStrings =
    strings[locale]
    or strings.enUS

local baselineSnapshot = nil
local watchActive = false
local watchGeneration = 0

local recentMilestones = {}

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
        result =
            pcall(
                string.format,
                value,
                ...
            )

    if success then
        return result
    end

    return value
end

local function Schedule(
    delay,
    callback
)
    if C_Timer
        and type(
            C_Timer.After
        ) == "function" then

        C_Timer.After(
            delay,
            callback
        )

        return
    end

    callback()
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

local function StandingLabel(
    standingID
)
    if standingID == nil then
        return FJ.Locale.Get(
            "UNKNOWN"
        )
    end

    local label =
        _G[
            "FACTION_STANDING_LABEL"
            .. tostring(
                standingID
            )
        ]

    return label
        or tostring(
            standingID
        )
end

local function GetFactionCount()
    if not C_Reputation
        or type(
            C_Reputation.GetNumFactions
        ) ~= "function" then

        return 0
    end

    local success,
        count =
            pcall(
                C_Reputation.GetNumFactions
            )

    if not success
        or type(count)
            ~= "number" then

        return 0
    end

    return count
end

local function NormalizeFaction(
    index,
    data
)
    if type(data) ~= "table"
        or type(data.name) ~= "string"
        or data.name == "" then

        return nil
    end

    local factionID =
        tonumber(
            data.factionID
        )

    local key

    if factionID
        and factionID > 0 then

        key =
            "id:"
            .. tostring(
                factionID
            )
    else
        key =
            "name:"
            .. data.name
            .. ":"
            .. tostring(
                index
                or 0
            )
    end

    return {
        key =
            key,

        index =
            index,

        factionID =
            factionID,

        name =
            data.name,

        standingID =
            tonumber(
                data.standingID
                or data.reaction
            ),

        barMin =
            tonumber(
                data.barMin
                or data.currentReactionThreshold
            ),

        barMax =
            tonumber(
                data.barMax
                or data.nextReactionThreshold
            ),

        barValue =
            tonumber(
                data.barValue
                or data.currentStanding
            ),

        isHeader =
            data.isHeader == true,

        hasRep =
            data.hasRep == true
            or data.isHeaderWithRep == true
    }
end

local function ReadFaction(
    index
)
    if not C_Reputation
        or type(
            C_Reputation.GetFactionDataByIndex
        ) ~= "function" then

        return nil
    end

    local success,
        data =
            pcall(
                C_Reputation.GetFactionDataByIndex,
                index
            )

    if not success then
        return nil
    end

    return NormalizeFaction(
        index,
        data
    )
end

local function CaptureSnapshot()
    local snapshot = {}

    local count =
        GetFactionCount()

    for index = 1,
        count do

        local faction =
            ReadFaction(
                index
            )

        if faction then
            snapshot[
                faction.key
            ] =
                faction
        end
    end

    return snapshot
end

local function BuildDuplicateKey(
    factionID,
    factionName,
    newStandingID
)
    local factionPart =
        factionID
        or factionName
        or "unknown"

    return tostring(
        factionPart
    )
        .. ":"
        .. tostring(
            newStandingID
            or "unknown"
        )
end

local function CleanupExpiredGuards(
    now
)
    for key,
        recordedAt in pairs(
            recentMilestones
        ) do

        local elapsed =
            now
            - recordedAt

        if elapsed < 0
            or elapsed
                > DUPLICATE_WINDOW_SECONDS then

            recentMilestones[key] =
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
        recentMilestones[
            duplicateKey
        ]

    if recordedAt == nil then
        return false
    end

    local elapsed =
        now
        - recordedAt

    return elapsed >= 0
        and elapsed
            <= DUPLICATE_WINDOW_SECONDS
end

local function RememberMilestone(
    duplicateKey
)
    recentMilestones[
        duplicateKey
    ] =
        GetNow()
end

local function ShouldCreateMilestone(
    oldFaction,
    newFaction
)
    if type(oldFaction) ~= "table"
        or type(newFaction) ~= "table" then

        return false
    end

    local oldStandingID =
        tonumber(
            oldFaction.standingID
        )

    local newStandingID =
        tonumber(
            newFaction.standingID
        )

    if oldStandingID == nil
        or newStandingID == nil then

        return false
    end

    return newStandingID
        > oldStandingID
end

local function RecordMilestone(
    oldFaction,
    newFaction
)
    if not ShouldCreateMilestone(
        oldFaction,
        newFaction
    ) then

        return false,
            "NOT_MILESTONE"
    end

    local factionName =
        newFaction.name
        or oldFaction.name
        or T(
            "UNKNOWN_FACTION"
        )

    local factionID =
        tonumber(
            newFaction.factionID
        )
        or tonumber(
            oldFaction.factionID
        )

    local oldStandingID =
        tonumber(
            oldFaction.standingID
        )

    local newStandingID =
        tonumber(
            newFaction.standingID
        )

    local duplicateKey =
        BuildDuplicateKey(
            factionID,
            factionName,
            newStandingID
        )

    if IsDuplicate(
        duplicateKey
    ) then

        return false,
            "DUPLICATE"
    end

    local oldValue =
        tonumber(
            oldFaction.barValue
        )

    local newValue =
        tonumber(
            newFaction.barValue
        )

    local delta = nil

    if oldValue ~= nil
        and newValue ~= nil then

        delta =
            newValue
            - oldValue
    end

    local memory =
        FJ.Memories.Add(
            MEMORY_TYPE,
            {
                factionID =
                    factionID,

                factionName =
                    factionName,

                oldStandingID =
                    oldStandingID,

                oldStandingName =
                    StandingLabel(
                        oldStandingID
                    ),

                newStandingID =
                    newStandingID,

                newStandingName =
                    StandingLabel(
                        newStandingID
                    ),

                oldValue =
                    oldValue,

                newValue =
                    newValue,

                delta =
                    delta,

                oldBarMin =
                    tonumber(
                        oldFaction.barMin
                    ),

                oldBarMax =
                    tonumber(
                        oldFaction.barMax
                    ),

                newBarMin =
                    tonumber(
                        newFaction.barMin
                    ),

                newBarMax =
                    tonumber(
                        newFaction.barMax
                    )
            },
            nil,
            "RECORDED"
        )

    if not memory then
        return false,
            "STORAGE_UNAVAILABLE"
    end

    RememberMilestone(
        duplicateKey
    )

    RefreshUI()

    return true,
        memory
end

local function ProcessSnapshotChanges(
    oldSnapshot,
    newSnapshot
)
    if type(oldSnapshot) ~= "table"
        or type(newSnapshot) ~= "table" then

        return 0
    end

    local changes = 0

    for key,
        newFaction in pairs(
            newSnapshot
        ) do

        local oldFaction =
            oldSnapshot[key]

        if oldFaction then
            local valueChanged =
                oldFaction.barValue
                ~= newFaction.barValue

            local standingChanged =
                oldFaction.standingID
                ~= newFaction.standingID

            local thresholdsChanged =
                oldFaction.barMin
                    ~= newFaction.barMin
                or oldFaction.barMax
                    ~= newFaction.barMax

            if valueChanged
                or standingChanged
                or thresholdsChanged then

                changes =
                    changes + 1

                RecordMilestone(
                    oldFaction,
                    newFaction
                )
            end
        end
    end

    return changes
end

local function FinishWatch(
    generation,
    snapshot
)
    if generation
        ~= watchGeneration then

        return
    end

    baselineSnapshot =
        snapshot

    watchActive =
        false
end

local function StartChangeWatch()
    if watchActive then
        return
    end

    if type(
        baselineSnapshot
    ) ~= "table" then

        baselineSnapshot =
            CaptureSnapshot()

        return
    end

    watchActive =
        true

    watchGeneration =
        watchGeneration
        + 1

    local generation =
        watchGeneration

    local originalBaseline =
        baselineSnapshot

    local lastSnapshot =
        originalBaseline

    for pollIndex,
        delay in ipairs(
            POLL_DELAYS
        ) do

        Schedule(
            delay,
            function()
                if generation
                        ~= watchGeneration
                    or not watchActive then

                    return
                end

                local snapshot =
                    CaptureSnapshot()

                lastSnapshot =
                    snapshot

                local changes =
                    ProcessSnapshotChanges(
                        originalBaseline,
                        snapshot
                    )

                if changes > 0 then
                    FinishWatch(
                        generation,
                        snapshot
                    )

                    return
                end

                if pollIndex
                    == #POLL_DELAYS then

                    FinishWatch(
                        generation,
                        lastSnapshot
                    )
                end
            end
        )
    end
end

local function CaptureBaseline()
    baselineSnapshot =
        CaptureSnapshot()
end

local function CleanupLegacySyntheticMilestones()
    local memories =
        JourneyState.memories
        or {}

    for index = #memories,
        1,
        -1 do

        local memory =
            memories[index]

        local data =
            type(memory) == "table"
            and type(memory.data) == "table"
            and memory.data
            or nil

        if type(memory) == "table"
            and memory.type == MEMORY_TYPE
            and data
            and data.syntheticTest == true then

            table.remove(
                memories,
                index
            )
        end
    end
end

CleanupLegacySyntheticMilestones()

function FJ.ReputationMilestones.Record(
    oldFaction,
    newFaction
)
    return RecordMilestone(
        oldFaction,
        newFaction
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

                local factionName =
                    data.factionName
                    or T(
                        "UNKNOWN_FACTION"
                    )

                local standingName =
                    data.newStandingName
                    or StandingLabel(
                        data.newStandingID
                    )

                return T(
                    "TITLE",
                    factionName,
                    standingName
                )
            end,

        getDescription =
            function(
                memory
            )
                local data =
                    type(memory.data)
                        == "table"
                    and memory.data
                    or {}

                local oldStandingName =
                    data.oldStandingName
                    or StandingLabel(
                        data.oldStandingID
                    )

                local newStandingName =
                    data.newStandingName
                    or StandingLabel(
                        data.newStandingID
                    )

                return T(
                    "DESCRIPTION",
                    oldStandingName,
                    newStandingName
                )
            end,

        getMarkerTexture =
            function()
                return FJ.Theme
                    .Textures
                    .markerReputation
            end
    }
)

local eventFrame =
    CreateFrame(
        "Frame"
    )

local updateRegistrationSuccess,
    updateRegistrationResult =
        pcall(
            eventFrame.RegisterEvent,
            eventFrame,
            "UPDATE_FACTION"
        )

local worldRegistrationSuccess,
    worldRegistrationResult =
        pcall(
            eventFrame.RegisterEvent,
            eventFrame,
            "PLAYER_ENTERING_WORLD"
        )

FJ.ReputationMilestones.IsSupported =
    type(C_Reputation)
        == "table"
    and type(
        C_Reputation.GetNumFactions
    ) == "function"
    and type(
        C_Reputation.GetFactionDataByIndex
    ) == "function"
    and updateRegistrationSuccess
        == true
    and updateRegistrationResult
        ~= false
    and worldRegistrationSuccess
        == true
    and worldRegistrationResult
        ~= false

eventFrame:SetScript(
    "OnEvent",
    function(
        self,
        event
    )
        if event
            == "PLAYER_ENTERING_WORLD" then

            Schedule(
                1.0,
                CaptureBaseline
            )

            return
        end

        if event
            == "UPDATE_FACTION" then

            StartChangeWatch()
        end
    end
)

Schedule(
    1.0,
    function()
        if type(
            baselineSnapshot
        ) ~= "table" then

            CaptureBaseline()
        end
    end
)