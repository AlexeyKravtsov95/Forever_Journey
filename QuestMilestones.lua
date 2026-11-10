local addonName, FJ = ...

FJ.QuestMilestones = {}

local JourneyState =
    FJ.State

local MEMORY_TYPE =
    "QUEST_MILESTONE"

local MILESTONE_STEP =
    50

local FIRST_MILESTONE =
    50

local lastKnownQuestCount =
    nil

local locale =
    GetLocale()

local strings = {
    enUS = {
        TYPE =
            "QUEST MILESTONE",

        TITLE =
            "%d quests completed",

        DESCRIPTION =
            "Another important questing milestone has been reached."
    },

    ruRU = {
        TYPE =
            "ВЕХА ЗАДАНИЙ",

        TITLE =
            "Выполнено %d заданий",

        DESCRIPTION =
            "Достигнута новая важная веха в путешествии."
    }
}

local currentStrings =
    strings[locale]
    or strings.enUS

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

local function GetCompletedQuestCount()
    if FJ.ServerStatistics
        and type(
            FJ.ServerStatistics.GetCompletedQuests
        ) == "function" then

        local serverCount =
            FJ.ServerStatistics.GetCompletedQuests()

        if serverCount ~= nil then
            return tonumber(
                serverCount
            )
        end
    end

    if not FJ.Recovery
        or not FJ.Recovery
            .GetCompletedQuestCount then

        return nil
    end

    return FJ.Recovery
        .GetCompletedQuestCount()
end

local function GetRecoveredQuestCount()
    local recovered =
        JourneyState.recoveredHistory

    if not recovered
        or not recovered.completedQuests then

        return 0
    end

    return tonumber(
        recovered
            .completedQuests
            .count
    ) or 0
end

local function GetQuestTitle(
    questID
)
    if not questID then
        return nil
    end

    if not C_QuestLog
        or type(
            C_QuestLog
                .GetTitleForQuestID
        ) ~= "function" then

        return nil
    end

    local success,
        title =
            pcall(
                C_QuestLog
                    .GetTitleForQuestID,
                questID
            )

    if success then
        return title
    end

    return nil
end

local function HasRecordedMilestone(
    milestoneCount
)
    for _, memory in ipairs(
        JourneyState.memories
        or {}
    ) do
        if type(memory)
                == "table"
            and memory.type
                == MEMORY_TYPE
            and type(memory.data)
                == "table"
            and tonumber(
                memory.data.count
            ) == milestoneCount then

            return true
        end
    end

    return false
end

local function CreateMilestone(
    milestoneCount,
    observedCount,
    questID
)
    if HasRecordedMilestone(
        milestoneCount
    ) then

        return false
    end

    local questTitle =
        GetQuestTitle(
            questID
        )

    FJ.Memories.Add(
        MEMORY_TYPE,
        {
            count =
                milestoneCount,

            observedCount =
                observedCount,

            questID =
                questID,

            questTitle =
                questTitle
        }
    )

    return true
end

local function EvaluateQuestProgress(
    questID
)
    local currentCount =
        GetCompletedQuestCount()

    if currentCount == nil then
        return
    end

    local previousCount =
        lastKnownQuestCount

    if previousCount == nil then
        previousCount =
            GetRecoveredQuestCount()
    end

    if currentCount
        < previousCount then

        previousCount =
            currentCount
    end

    local firstCandidate =
        (
            math.floor(
                previousCount
                    / MILESTONE_STEP
            )
            * MILESTONE_STEP
        )
        + MILESTONE_STEP

    local createdAny =
        false

    local milestone =
        firstCandidate

    while milestone
        <= currentCount do

        if milestone
            >= FIRST_MILESTONE then

            if CreateMilestone(
                milestone,
                currentCount,
                questID
            ) then

                createdAny =
                    true
            end
        end

        milestone =
            milestone
            + MILESTONE_STEP
    end

    lastKnownQuestCount =
        currentCount

    if createdAny
        and FJ.UI
        and FJ.UI.RefreshIfVisible then

        FJ.UI.RefreshIfVisible()
    end
end

local function CleanupInvalidMilestones(
    currentCount
)
    if currentCount == nil then
        return false
    end

    local removedAny =
        false

    local memories =
        JourneyState.memories
        or {}

    for index = #memories,
        1,
        -1 do

        local memory =
            memories[index]

        local milestoneCount =
            type(memory) == "table"
            and memory.type == MEMORY_TYPE
            and type(memory.data) == "table"
            and tonumber(
                memory.data.count
            )
            or nil

        if milestoneCount
            and milestoneCount > currentCount then

            table.remove(
                memories,
                index
            )

            removedAny =
                true
        end
    end

    return removedAny
end

local function SyncQuestBaseline()
    local currentCount =
        GetCompletedQuestCount()

    if currentCount ~= nil then
        lastKnownQuestCount =
            currentCount

        local repairedSnapshot =
            false

        local recovered =
            JourneyState.recoveredHistory

        if type(recovered) == "table"
            and type(
                recovered.completedQuests
            ) == "table" then

            local recoveredCount =
                tonumber(
                    recovered
                        .completedQuests
                        .count
                )

            if recoveredCount
                and recoveredCount > currentCount then

                recovered
                    .completedQuests
                    .count =
                        currentCount

                repairedSnapshot =
                    true
            end
        end

        local removedMilestones =
            CleanupInvalidMilestones(
                currentCount
            )

        if (
            repairedSnapshot
            or removedMilestones
        )
            and FJ.UI
            and FJ.UI.RefreshIfVisible then

            FJ.UI.RefreshIfVisible()
        end
    end
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

function FJ.QuestMilestones
    .GetCurrentCount()

    return GetCompletedQuestCount()
end

function FJ.QuestMilestones
    .GetNextMilestone()

    local currentCount =
        GetCompletedQuestCount()
        or lastKnownQuestCount
        or GetRecoveredQuestCount()

    local nextMilestone =
        (
            math.floor(
                currentCount
                    / MILESTONE_STEP
            )
            * MILESTONE_STEP
        )
        + MILESTONE_STEP

    return nextMilestone
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
            function(memory)
                local data =
                    type(memory.data)
                        == "table"
                    and memory.data
                    or {}

                local count =
                    tonumber(
                        data.count
                    )

                if count then
                    return T(
                        "TITLE",
                        count
                    )
                end

                return nil
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
                    .iconQuests
            end
    }
)

local eventFrame =
    CreateFrame(
        "Frame"
    )

eventFrame:RegisterEvent(
    "PLAYER_ENTERING_WORLD"
)

eventFrame:RegisterEvent(
    "QUEST_TURNED_IN"
)

eventFrame:SetScript(
    "OnEvent",
    function(
        self,
        event,
        ...
    )
        if event
            == "PLAYER_ENTERING_WORLD" then

            Schedule(
                0.75,
                SyncQuestBaseline
            )

        elseif event
            == "QUEST_TURNED_IN" then

            local questID =
                ...

            Schedule(
                0.40,
                function()
                    EvaluateQuestProgress(
                        questID
                    )
                end
            )
        end
    end
)