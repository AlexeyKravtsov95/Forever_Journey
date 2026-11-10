local addonName, FJ = ...

local JourneyState = FJ.State

FJ.Recovery = {}

function FJ.Recovery.GetCompletedQuestIDs()
    if not C_QuestLog.GetAllCompletedQuestIDs then
        return nil
    end

    return C_QuestLog.GetAllCompletedQuestIDs()
end

function FJ.Recovery.GetCompletedQuestCount()
    local questIDs =
        FJ.Recovery.GetCompletedQuestIDs()

    if not questIDs then
        return nil
    end

    return #questIDs
end

function FJ.Recovery.RequestQuestSample(limit)
    local completedQuestIDs =
        FJ.Recovery.GetCompletedQuestIDs()

    if not completedQuestIDs
        or #completedQuestIDs == 0 then

        print(
            "Forever Journey: no completed quests found."
        )

        return
    end

    local sampleSize =
        math.min(
            limit or 10,
            #completedQuestIDs
        )

    print(
        "Forever Journey: loading",
        sampleSize,
        "completed quests..."
    )

    for index = 1, sampleSize do
        local questID =
            completedQuestIDs[index]

        JourneyState.pendingQuestSample[questID] =
            true

        C_QuestLog.RequestLoadQuestByID(
            questID
        )
    end
end

function FJ.Recovery.HandleQuestDataLoaded(
    questID,
    success
)
    if not JourneyState
        .pendingQuestSample[questID] then

        return
    end

    JourneyState
        .pendingQuestSample[questID] = nil

    if not success then
        print(
            "Forever Journey: failed to load quest",
            questID
        )

        return
    end

    local title =
        C_QuestLog.GetTitleForQuestID(
            questID
        )

    if title then
        print(
            "Recovered quest:",
            questID,
            "-",
            title
        )
    else
        print(
            "Recovered quest:",
            questID,
            "- title unavailable"
        )
    end
end

function FJ.Recovery.CaptureInitialSnapshot()
    local recoveredHistory =
        FJ.State.recoveredHistory

    if recoveredHistory.initialized then
        return
    end

    recoveredHistory.capturedAt =
        time()

    recoveredHistory.level =
        UnitLevel("player")

    recoveredHistory.money.current =
        GetMoney()

    local completedQuestIDs =
        FJ.Recovery.GetCompletedQuestIDs()

    if completedQuestIDs then
        recoveredHistory
            .completedQuests
            .count =
                #completedQuestIDs

        for _, questID in ipairs(
            completedQuestIDs
        ) do
            table.insert(
                recoveredHistory
                    .completedQuests
                    .questIDs,
                questID
            )
        end
    end

    local professions =
        FJ.Journey.RefreshProfessions()

    for _, profession in ipairs(
        professions
    ) do
        table.insert(
            recoveredHistory.professions,
            {
                name =
                    profession.name,

                skillLevel =
                    profession.skillLevel,

                maxSkillLevel =
                    profession.maxSkillLevel,

                skillLine =
                    profession.skillLine
            }
        )
    end

    recoveredHistory.initialized = true
end

function FJ.Recovery.SetRecoveredPlayedTime(
    totalTimePlayed,
    timePlayedThisLevel
)
    local recoveredHistory =
        FJ.State.recoveredHistory

    if recoveredHistory.played.total == nil then
        recoveredHistory.played.total =
            totalTimePlayed

        recoveredHistory
            .played
            .currentLevel =
                timePlayedThisLevel
    end
end