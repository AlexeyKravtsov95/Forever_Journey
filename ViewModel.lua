local addonName, FJ = ...

local JourneyState = FJ.State

FJ.ViewModel = {}

local function BuildMemoryLocation(
    memory
)
    local sourceLocation =
        type(memory.location) == "table"
        and memory.location
        or {}

    return {
        kind = sourceLocation.kind,
        mapID = sourceLocation.mapID,
        instanceID = sourceLocation.instanceID,
        type = sourceLocation.type,
        name =
            FJ.Memories
                .GetDisplayLocationName(
                    memory
                )
    }
end

local function BuildMemoryView(
    memory
)
    local semanticType =
        memory.type

    local typeLabel =
        FJ.MemoryTypes
        and FJ.MemoryTypes.GetTypeLabel
        and FJ.MemoryTypes.GetTypeLabel(
            memory
        )
        or semanticType

    return {
        type =
            typeLabel
            or semanticType,

        semanticType =
            semanticType,

        id =
            memory.id,

        source =
            memory.source
            or "RECORDED",

        favorite =
            memory.favorite == true,

        canEdit =
            FJ.Memories.CanEdit
            and FJ.Memories.CanEdit(
                memory
            )
            or false,

        canDelete =
            FJ.Memories.CanDelete
            and FJ.Memories.CanDelete(
                memory
            )
            or false,

        timestamp =
            memory.timestamp,

        location =
            BuildMemoryLocation(
                memory
            ),

        title =
            FJ.Memories.GetDisplayTitle(
                memory
            ),

        description =
            FJ.Memories
                .GetDisplayDescription(
                    memory
                ),

        data =
            memory.data,

        raw =
            memory
    }
end

function FJ.ViewModel.GetOverview()
    local recovered =
        JourneyState.recoveredHistory

    local profile =
        JourneyState.profile

    local recordingStartedAt =
        recovered
        and recovered.capturedAt
        or nil

    local completedQuests =
        recovered
        and recovered.completedQuests.count
        or 0

    if FJ.QuestMilestones
        and type(
            FJ.QuestMilestones.GetCurrentCount
        ) == "function" then

        local currentQuestCount =
            FJ.QuestMilestones
                .GetCurrentCount()

        if currentQuestCount ~= nil then
            completedQuests =
                currentQuestCount
        end
    end

    return {
        character = {
            name =
                profile
                and profile.name
                or FJ.Locale.Get("UNKNOWN"),

            level =
                profile
                and profile.level
                or 0,

            race =
                profile
                and profile.race
                or FJ.Locale.Get("UNKNOWN"),

            class =
                profile
                and profile.class
                or FJ.Locale.Get("UNKNOWN")
        },

        journey = {
            recordingStartedAt =
                recordingStartedAt,

            -- Compatibility for existing callers.
            startedAt =
                recordingStartedAt,

            completedQuests =
                completedQuests,

            totalPlayed =
                JourneyState.played.total
                or (
                    recovered
                    and recovered.played.total
                )
                or 0,

            currentMoney =
                JourneyState.money.current
                or 0,

            deaths =
                FJ.ServerStatistics
                and FJ.ServerStatistics.GetTotalDeaths
                and FJ.ServerStatistics.GetTotalDeaths(
                    JourneyState.stats.deaths
                    or 0
                )
                or JourneyState.stats.deaths
                or 0,

            memories =
                #JourneyState.memories
        },

        professions =
            JourneyState.professions
            or {}
    }
end

function FJ.ViewModel.GetRecoveredHistory()
    local recovered =
        JourneyState.recoveredHistory
        or {}

    local completedQuests =
        recovered.completedQuests
        or {}

    local played =
        recovered.played
        or {}

    local money =
        recovered.money
        or {}

    local professions = {}

    for _, profession in ipairs(
        recovered.professions
        or {}
    ) do
        table.insert(
            professions,
            {
                name =
                    FJ.Utils.GetLocalizedProfessionName(
                        profession
                    ),

                skillLevel =
                    profession.skillLevel
                    or 0,

                maxSkillLevel =
                    profession.maxSkillLevel
                    or 0,

                skillLine =
                    profession.skillLine
            }
        )
    end

    return {
        initialized =
            recovered.initialized
            == true,

        capturedAt =
            recovered.capturedAt,

        level =
            recovered.level
            or 0,

        completedQuests =
            completedQuests.count
            or 0,

        totalPlayed =
            played.total
            or 0,

        currentLevelPlayed =
            played.currentLevel
            or 0,

        money =
            money.current
            or 0,

        professions =
            professions
    }
end

function FJ.ViewModel.GetMemory(
    memory
)
    if type(memory) ~= "table" then
        return nil
    end

    return BuildMemoryView(
        memory
    )
end

function FJ.ViewModel.GetAllMemories()
    local result = {}

    local memories =
        JourneyState.memories
        or {}

    for _, memory in ipairs(
        memories
    ) do
        table.insert(
            result,
            BuildMemoryView(
                memory
            )
        )
    end

    return result
end

function FJ.ViewModel.GetRecentMemories(
    limit
)
    local result = {}

    local memories =
        JourneyState.memories
        or {}

    local maxItems =
        limit
        or 5

    local added = 0

    for index = #memories, 1, -1 do
        table.insert(
            result,
            BuildMemoryView(
                memories[index]
            )
        )

        added =
            added + 1

        if added >= maxItems then
            break
        end
    end

    return result
end