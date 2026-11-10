local addonName, FJ = ...

local JourneyState = FJ.State

FJ.ServerStatistics = {}

local ServerStatistics =
    FJ.ServerStatistics

local STATISTIC_IDS = {
    TOTAL_DEATHS = 60,
    COMPLETED_QUESTS = 98,
    TOTAL_KILLS = 1197,
    HONORABLE_KILLS = 588,
    FLIGHTS_TAKEN = 349,
    HEARTHSTONE_USES = 353,
    CRITTERS_KILLED = 108,
    FALLING_DEATHS = 114,
    PVP_DEATHS = 1501
}

ServerStatistics.IDs =
    STATISTIC_IDS

local deathBaseline = nil
local sessionDeaths = 0
local baselineInitialized = false

local INITIALIZE_DELAYS = {
    0.10,
    0.50,
    1.50,
    3.00
}

local function NormalizeNumber(
    value
)
    if type(value) == "number" then
        return value
    end

    if type(value) ~= "string" then
        return nil
    end

    local normalized =
        string.gsub(
            value,
            "%s+",
            ""
        )

    normalized =
        string.gsub(
            normalized,
            ",",
            ""
        )

    if normalized == ""
        or normalized == "--"
        or normalized == "-" then

        return nil
    end

    return tonumber(
        normalized
    )
end

local function ReadStatistic(
    statisticID
)
    if type(GetStatistic)
        ~= "function" then

        return nil,
            nil
    end

    local success,
        rawValue =
            pcall(
                GetStatistic,
                statisticID
            )

    if not success then
        return nil,
            nil
    end

    return NormalizeNumber(
        rawValue
    ),
        rawValue
end

local function GetLocalDeaths()
    if type(JourneyState.stats)
        ~= "table" then

        return 0
    end

    return tonumber(
        JourneyState.stats.deaths
    ) or 0
end

local function SetLocalDeaths(
    value
)
    if type(JourneyState.stats)
        ~= "table" then

        return
    end

    local normalized =
        tonumber(value)

    if normalized == nil then
        return
    end

    normalized =
        math.max(
            math.floor(normalized),
            0
        )

    local current =
        GetLocalDeaths()

    if normalized > current then
        JourneyState.stats.deaths =
            normalized
    end
end

local function InitializeDeathBaseline()
    if baselineInitialized then
        return true
    end

    if not FJ.Storage
        or type(FJ.Storage.character)
            ~= "table" then

        return false
    end

    local serverDeaths =
        ReadStatistic(
            STATISTIC_IDS.TOTAL_DEATHS
        )

    if serverDeaths == nil then
        return false
    end

    local localDeaths =
        GetLocalDeaths()

    deathBaseline =
        math.max(
            serverDeaths,
            localDeaths
        )

    SetLocalDeaths(
        deathBaseline
    )

    baselineInitialized =
        true

    return true
end

local function ScheduleInitialization()
    if baselineInitialized then
        return
    end

    if C_Timer
        and type(C_Timer.After)
            == "function" then

        for _, delay in ipairs(
            INITIALIZE_DELAYS
        ) do
            C_Timer.After(
                delay,
                function()
                    InitializeDeathBaseline()
                end
            )
        end

        return
    end

    InitializeDeathBaseline()
end

function ServerStatistics.IsAvailable()
    return type(GetStatistic)
        == "function"
end

function ServerStatistics.GetValue(
    statisticID
)
    return ReadStatistic(
        statisticID
    )
end

function ServerStatistics.GetTotalDeaths(
    fallback
)
    if not baselineInitialized then
        InitializeDeathBaseline()
    end

    local serverDeaths =
        ReadStatistic(
            STATISTIC_IDS.TOTAL_DEATHS
        )

    local localFallback =
        tonumber(fallback)
        or GetLocalDeaths()
        or 0

    local expectedDeaths = nil

    if deathBaseline ~= nil then
        expectedDeaths =
            deathBaseline
            + sessionDeaths
    end

    local result =
        localFallback

    if serverDeaths ~= nil then
        result =
            math.max(
                result,
                serverDeaths
            )
    end

    if expectedDeaths ~= nil then
        result =
            math.max(
                result,
                expectedDeaths
            )
    end

    SetLocalDeaths(
        result
    )

    return result
end

function ServerStatistics.GetCompletedQuests()
    return ReadStatistic(
        STATISTIC_IDS.COMPLETED_QUESTS
    )
end

function ServerStatistics.GetTotalKills()
    return ReadStatistic(
        STATISTIC_IDS.TOTAL_KILLS
    )
end

function ServerStatistics.GetHonorableKills()
    return ReadStatistic(
        STATISTIC_IDS.HONORABLE_KILLS
    )
end

function ServerStatistics.GetFlightsTaken()
    return ReadStatistic(
        STATISTIC_IDS.FLIGHTS_TAKEN
    )
end

function ServerStatistics.GetHearthstoneUses()
    return ReadStatistic(
        STATISTIC_IDS.HEARTHSTONE_USES
    )
end

function ServerStatistics.GetCrittersKilled()
    return ReadStatistic(
        STATISTIC_IDS.CRITTERS_KILLED
    )
end

function ServerStatistics.GetFallingDeaths()
    return ReadStatistic(
        STATISTIC_IDS.FALLING_DEATHS
    )
end

function ServerStatistics.GetPvPDeaths()
    return ReadStatistic(
        STATISTIC_IDS.PVP_DEATHS
    )
end

function ServerStatistics.GetSnapshot()
    return {
        totalDeaths =
            ServerStatistics.GetTotalDeaths(),

        completedQuests =
            ServerStatistics.GetCompletedQuests(),

        totalKills =
            ServerStatistics.GetTotalKills(),

        honorableKills =
            ServerStatistics.GetHonorableKills(),

        flightsTaken =
            ServerStatistics.GetFlightsTaken(),

        hearthstoneUses =
            ServerStatistics.GetHearthstoneUses(),

        crittersKilled =
            ServerStatistics.GetCrittersKilled(),

        fallingDeaths =
            ServerStatistics.GetFallingDeaths(),

        pvpDeaths =
            ServerStatistics.GetPvPDeaths()
    }
end

local eventFrame =
    CreateFrame(
        "Frame"
    )

eventFrame:RegisterEvent(
    "PLAYER_ENTERING_WORLD"
)

eventFrame:RegisterEvent(
    "PLAYER_DEAD"
)

eventFrame:SetScript(
    "OnEvent",
    function(
        self,
        event
    )
        if event
            == "PLAYER_ENTERING_WORLD" then

            ScheduleInitialization()

            return
        end

        if event
            == "PLAYER_DEAD" then

            if not baselineInitialized then
                InitializeDeathBaseline()
            end

            sessionDeaths =
                sessionDeaths
                + 1
        end
    end
)