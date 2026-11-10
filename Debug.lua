local addonName, FJ = ...

local JourneyState = FJ.State

FJ.Debug = {}

local function PrintHelp()
    print("Forever Journey debug commands:")

    print("/fj memories")
    print("/fj memoryschema")
    print("/fj zones")
    print("/fj quests")
    print("/fj questsample")
    print("/fj played")
    print("/fj professions")
    print("/fj money")
    print("/fj deaths")
    print("/fj deathrecap")
    print("/fj instance")
    print("/fj storage")
    print("/fj recovered")
    print("/fj overview")
    print("/fj open")
end

local function PrintOverview()
    local overview =
        FJ.ViewModel.GetOverview()

    print("Forever Journey overview:")

    print(
        overview.character.name,
        overview.character.race,
        overview.character.class,
        "Level",
        overview.character.level
    )

    print(
        "Journal started:",
        FJ.Utils.FormatDate(
            overview.journey.recordingStartedAt
        )
    )

    print(
        "Completed quests:",
        overview.journey.completedQuests
    )

    print(
        "Played:",
        FJ.Utils.FormatPlayedTime(
            overview.journey.totalPlayed
        )
    )

    print(
        "Money:",
        FJ.Utils.FormatMoney(
            overview.journey.currentMoney
        )
    )

    print(
        "Deaths:",
        overview.journey.deaths
    )

    print(
        "Memories:",
        overview.journey.memories
    )
end

local function PrintMemories()
    print(
        "Forever Journey memories:"
    )

    local memories =
        FJ.ViewModel.GetAllMemories()

    for index, memory in ipairs(
        memories
    ) do
        print(
            index,
            memory.type,
            memory.title,
            "-",
            FJ.Utils.GetLocalizedLocationName(memory.location),
            "[" .. memory.source .. "]"
        )
    end
end

local function PrintMemorySchema()
    local total = 0
    local semantic = 0
    local legacyText = 0
    local invalid = 0

    for _, memory in ipairs(
        JourneyState.memories
    ) do
        total =
            total + 1

        if type(memory) ~= "table" then
            invalid =
                invalid + 1
        else
            if memory.schemaVersion
                == FJ.Memories.GetSchemaVersion()
                and type(memory.data)
                    == "table" then

                semantic =
                    semantic + 1
            end

            if memory.title
                or memory.description then

                legacyText =
                    legacyText + 1
            end
        end
    end

    print(
        "Forever Journey memory schema:"
    )

    print(
        "Total:",
        total
    )

    print(
        "Schema v"
            .. FJ.Memories.GetSchemaVersion()
            .. ":",
        semantic
    )

    print(
        "Legacy text preserved:",
        legacyText
    )

    print(
        "Invalid:",
        invalid
    )
end

local function PrintStorage()
    if not FJ.Storage.character then
        print(
            "Forever Journey: storage is not attached."
        )

        return
    end

    print(
        "Forever Journey storage:"
    )

    print(
        "Character:",
        FJ.Storage.characterKey
    )

    print(
        "Schema:",
        ForeverJourneyDB.schemaVersion
    )

    print(
        "Character schema:",
        FJ.Storage.character.schemaVersion
    )

    print(
        "Memories:",
        #JourneyState.memories
    )

    local zoneCount = 0

    for _ in pairs(
        JourneyState.visitedZones
    ) do
        zoneCount =
            zoneCount + 1
    end

    print(
        "Visited zones:",
        zoneCount
    )

    print(
        "Deaths:",
        JourneyState.stats.deaths
    )

    print(
        "Recovered:",
        JourneyState
            .recoveredHistory
            .initialized
            and "yes"
            or "no"
    )
end

local function PrintRecovered()
    local recovered =
        JourneyState.recoveredHistory

    print(
        "Forever Journey recovered history:"
    )

    print(
        "Level:",
        recovered.level
            or "Unknown"
    )

    print(
        "Completed quests:",
        recovered.completedQuests.count
    )

    print(
        "Money:",
        FJ.Utils.FormatMoney(
            recovered.money.current
        )
    )

    if recovered.played.total then
        print(
            "Played:",
            FJ.Utils.FormatPlayedTime(
                recovered.played.total
            )
        )
    else
        print(
            "Played: waiting for data"
        )
    end

    print(
        "Professions:",
        #recovered.professions
    )

    for _, profession in ipairs(
        recovered.professions
    ) do
        print(
            profession.name,
            profession.skillLevel
                .. "/"
                .. profession.maxSkillLevel
        )
    end
end

local function PrintLatestDeathRecap()
    for index = #JourneyState.memories,
        1,
        -1 do

        local memory =
            JourneyState.memories[index]

        if type(memory) == "table"
            and memory.type == "DEATH" then

            local view =
                FJ.ViewModel.GetMemory(
                    memory
                )

            local data =
                type(memory.data) == "table"
                and memory.data
                or {}

            print(
                "Forever Journey latest death recap:"
            )

            print(
                "Title:",
                view
                and view.title
                or "Unknown"
            )

            print(
                "Cause:",
                data.cause
                    or "Unknown"
            )

            print(
                "Killer:",
                data.killerName
                    or "Unknown"
            )

            print(
                "Raw source:",
                data.killerNameRaw
                    or "Unknown"
            )

            print(
                "Source realm:",
                data.killerRealm
                    or "None"
            )

            print(
                "Spell:",
                data.spellName
                    or data.spellID
                    or "Unknown"
            )

            print(
                "Damage:",
                data.amount
                    or "Unknown"
            )

            print(
                "Event:",
                data.eventType
                    or "Unknown"
            )

            print(
                "Environment:",
                data.environmentalType
                    or "None"
            )

            return
        end
    end

    print(
        "Forever Journey: no death memory found."
    )
end

SLASH_FOREVERJOURNEY1 = "/fj"

SlashCmdList["FOREVERJOURNEY"] =
    function(message)
        message =
            string.lower(
                message
                or ""
            )

        if message == "overview" then
            PrintOverview()

        elseif message == "memories" then
            PrintMemories()

        elseif message == "memoryschema" then
            PrintMemorySchema()

        elseif message == "zones" then
            print(
                "Forever Journey visited zones:"
            )

            for mapID, zone in pairs(
                JourneyState.visitedZones
            ) do
                print(
                    mapID,
                    zone.name
                )
            end

        elseif message == "quests" then
            local count =
                FJ.Recovery
                    .GetCompletedQuestCount()

            if count == nil then
                print(
                    "Forever Journey: completed quests are unavailable."
                )

                return
            end

            print(
                "Forever Journey:",
                count,
                "completed quests found."
            )

        elseif message == "questsample" then
            FJ.Recovery
                .RequestQuestSample(10)

        elseif message == "open" then
            FJ.UI.Toggle()

        elseif message == "played" then
            if type(RequestTimePlayed)
                ~= "function" then

                print(
                    "Forever Journey: played time API is unavailable."
                )

                return
            end

            print(
                "Forever Journey: requesting played time..."
            )

            RequestTimePlayed()

        elseif message == "storage" then
            PrintStorage()

        elseif message == "professions" then
            local professions =
                FJ.Journey
                    .RefreshProfessions()

            print(
                "Forever Journey:",
                #professions,
                "professions found."
            )

            for _, profession in ipairs(
                professions
            ) do
                print(
                    profession.name,
                    profession.skillLevel
                        .. "/"
                        .. profession.maxSkillLevel,
                    "modifier:",
                    profession.skillModifier
                )
            end

        elseif message == "money" then
            if JourneyState.money.current
                == nil then

                print(
                    "Forever Journey: money data unavailable."
                )

                return
            end

            print(
                "Forever Journey: current:",
                FJ.Utils.FormatMoney(
                    JourneyState.money.current
                )
            )

            print(
                "Forever Journey: earned this session:",
                FJ.Utils.FormatMoney(
                    JourneyState.money.earned
                )
            )

            print(
                "Forever Journey: spent this session:",
                FJ.Utils.FormatMoney(
                    JourneyState.money.spent
                )
            )

        elseif message == "deaths" then
            print(
                "Forever Journey: recorded deaths:",
                JourneyState.stats.deaths
            )

        elseif message == "deathrecap" then
            PrintLatestDeathRecap()

        elseif message == "recovered" then
            PrintRecovered()

        elseif message == "instance" then
            if JourneyState
                .instance.inInstance then

                print(
                    "Forever Journey: instance:",
                    JourneyState.instance.name,
                    "type:",
                    JourneyState.instance.type,
                    "ID:",
                    JourneyState.instance.instanceID
                )
            else
                print(
                    "Forever Journey: not currently in an instance."
                )
            end

        else
            PrintHelp()
        end
    end