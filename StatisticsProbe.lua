local addonName, FJ = ...

FJ.StatisticsProbe = {}

local Probe =
    FJ.StatisticsProbe

local TOTAL_DEATHS_STAT_ID =
    60

local MAX_NONZERO_OUTPUT =
    60

local function PrintSeparator()
    print(
        "--------------------------------"
    )
end

local function SafeCall(
    callback,
    ...
)
    if type(callback)
        ~= "function" then

        return false
    end

    return pcall(
        callback,
        ...
    )
end

local function GetCategories()
    if type(
        GetStatisticsCategoryList
    ) ~= "function" then

        return {}
    end

    local success,
        categories =
            pcall(
                GetStatisticsCategoryList
            )

    if not success
        or type(categories)
            ~= "table" then

        return {}
    end

    return categories
end

local function GetCategoryName(
    categoryID
)
    if type(GetCategoryInfo)
        ~= "function" then

        return nil
    end

    local success,
        name =
            pcall(
                GetCategoryInfo,
                categoryID
            )

    if not success then
        return nil
    end

    return name
end

local function GetCategoryCount(
    categoryID
)
    if type(
        GetCategoryNumAchievements
    ) ~= "function" then

        return 0
    end

    local success,
        total =
            pcall(
                GetCategoryNumAchievements,
                categoryID,
                true
            )

    if not success
        or type(total)
            ~= "number" then

        return 0
    end

    return total
end

local function ReadStatisticInfo(
    categoryID,
    index
)
    if type(GetAchievementInfo)
        ~= "function" then

        return nil
    end

    local success,
        id,
        name,
        points,
        completed,
        month,
        day,
        year,
        description,
        flags,
        icon,
        rewardText,
        isGuild,
        wasEarnedByMe,
        earnedBy,
        isStatistic =
            pcall(
                GetAchievementInfo,
                categoryID,
                index
            )

    if not success
        or not id
        or isStatistic ~= true then

        return nil
    end

    return {
        id =
            id,

        name =
            name,

        categoryID =
            categoryID,

        index =
            index,

        isStatistic =
            isStatistic
    }
end

local function ReadStatisticValue(
    statisticID
)
    if type(GetStatistic)
        ~= "function" then

        return nil,
            nil,
            nil,
            "UNAVAILABLE"
    end

    local success,
        value,
        skip,
        returnedID =
            pcall(
                GetStatistic,
                statisticID
            )

    if not success then
        return nil,
            nil,
            nil,
            "FAILED"
    end

    return value,
        skip,
        returnedID,
        nil
end

local function NormalizeNumber(
    value
)
    if type(value)
        == "number" then

        return value
    end

    if type(value)
        ~= "string" then

        return nil
    end

    local normalized =
        value

    normalized =
        string.gsub(
            normalized,
            ",",
            ""
        )

    normalized =
        string.gsub(
            normalized,
            " ",
            ""
        )

    return tonumber(
        normalized
    )
end

local function ScanStatistics()
    local statistics = {}

    local categories =
        GetCategories()

    for _,
        categoryID in ipairs(
            categories
        ) do

        local count =
            GetCategoryCount(
                categoryID
            )

        local categoryName =
            GetCategoryName(
                categoryID
            )

        for index = 1,
            count do

            local statistic =
                ReadStatisticInfo(
                    categoryID,
                    index
                )

            if statistic then
                local value,
                    skip,
                    returnedID,
                    errorCode =
                        ReadStatisticValue(
                            statistic.id
                        )

                statistic.value =
                    value

                statistic.numericValue =
                    NormalizeNumber(
                        value
                    )

                statistic.skip =
                    skip

                statistic.returnedID =
                    returnedID

                statistic.errorCode =
                    errorCode

                statistic.categoryName =
                    categoryName

                table.insert(
                    statistics,
                    statistic
                )
            end
        end
    end

    return statistics,
        categories
end

local function PrintStatistic(
    statistic
)
    if not statistic then
        print(
            "[FJ STATS] Statistic unavailable."
        )

        return
    end

    print(
        tostring(
            statistic.id
            or "nil"
        ),
        "-",
        statistic.name
            or "Unknown",
        "=",
        statistic.value
            or "nil"
    )
end

local function ReadStatisticByID(
    statisticID
)
    if type(GetAchievementInfo)
        ~= "function" then

        return nil
    end

    local success,
        id,
        name,
        points,
        completed,
        month,
        day,
        year,
        description,
        flags,
        icon,
        rewardText,
        isGuild,
        wasEarnedByMe,
        earnedBy,
        isStatistic =
            pcall(
                GetAchievementInfo,
                statisticID
            )

    local value,
        skip,
        returnedID,
        errorCode =
            ReadStatisticValue(
                statisticID
            )

    if not success then
        return {
            id =
                statisticID,

            value =
                value,

            numericValue =
                NormalizeNumber(
                    value
                ),

            skip =
                skip,

            returnedID =
                returnedID,

            errorCode =
                errorCode
        }
    end

    return {
        id =
            id
            or statisticID,

        name =
            name,

        isStatistic =
            isStatistic,

        value =
            value,

        numericValue =
            NormalizeNumber(
                value
            ),

        skip =
            skip,

        returnedID =
            returnedID,

        errorCode =
            errorCode
    }
end

local function PrintStatus()
    local categories =
        GetCategories()

    PrintSeparator()

    print(
        "[FJ STATS] API status"
    )

    print(
        "GetStatisticsCategoryList:",
        type(
            GetStatisticsCategoryList
        ) == "function"
        and "available"
        or "missing"
    )

    print(
        "GetStatistic:",
        type(
            GetStatistic
        ) == "function"
        and "available"
        or "missing"
    )

    print(
        "GetAchievementInfo:",
        type(
            GetAchievementInfo
        ) == "function"
        and "available"
        or "missing"
    )

    print(
        "Statistic categories:",
        #categories
    )

    PrintSeparator()
end

local function PrintDeaths()
    PrintSeparator()

    print(
        "[FJ STATS] Death statistics"
    )

    local directStatistic =
        ReadStatisticByID(
            TOTAL_DEATHS_STAT_ID
        )

    print(
        "Direct Total deaths check:"
    )

    PrintStatistic(
        directStatistic
    )

    local statistics =
        ScanStatistics()

    local found = 0

    print(
        "Death-related statistics found by scan:"
    )

    for _,
        statistic in ipairs(
            statistics
        ) do

        local name =
            statistic.name
            or ""

        local isDeathStatistic =
            string.find(
                name,
                "Death",
                1,
                true
            )
            or string.find(
                name,
                "death",
                1,
                true
            )
            or string.find(
                name,
                "Смерт",
                1,
                true
            )
            or string.find(
                name,
                "смерт",
                1,
                true
            )

        if isDeathStatistic then
            found =
                found + 1

            PrintStatistic(
                statistic
            )
        end
    end

    print(
        "Death-related entries:",
        found
    )

    PrintSeparator()
end

local function PrintNonZero()
    local statistics =
        ScanStatistics()

    local nonZero = {}

    for _,
        statistic in ipairs(
            statistics
        ) do

        local number =
            statistic.numericValue

        if number
            and number ~= 0 then

            table.insert(
                nonZero,
                statistic
            )
        end
    end

    table.sort(
        nonZero,
        function(
            left,
            right
        )
            return (
                left.numericValue
                or 0
            ) > (
                right.numericValue
                or 0
            )
        end
    )

    PrintSeparator()

    print(
        "[FJ STATS] Non-zero statistics"
    )

    print(
        "Found:",
        #nonZero
    )

    local outputCount =
        math.min(
            #nonZero,
            MAX_NONZERO_OUTPUT
        )

    for index = 1,
        outputCount do

        PrintStatistic(
            nonZero[index]
        )
    end

    if #nonZero
        > MAX_NONZERO_OUTPUT then

        print(
            "... output limited to",
            MAX_NONZERO_OUTPUT,
            "entries"
        )
    end

    PrintSeparator()
end

local function PrintSummary()
    local statistics,
        categories =
            ScanStatistics()

    local nonZeroCount = 0
    local readableCount = 0

    for _,
        statistic in ipairs(
            statistics
        ) do

        if statistic.value
            ~= nil then

            readableCount =
                readableCount + 1
        end

        if statistic.numericValue
            and statistic.numericValue
                ~= 0 then

            nonZeroCount =
                nonZeroCount + 1
        end
    end

    PrintSeparator()

    print(
        "[FJ STATS] Scan summary"
    )

    print(
        "Categories:",
        #categories
    )

    print(
        "Statistics discovered:",
        #statistics
    )

    print(
        "Readable values:",
        readableCount
    )

    print(
        "Non-zero numeric values:",
        nonZeroCount
    )

    PrintSeparator()
end

local function PrintByID(
    statisticID
)
    local statistic =
        ReadStatisticByID(
            statisticID
        )

    PrintSeparator()

    print(
        "[FJ STATS] Statistic lookup"
    )

    print(
        "Requested ID:",
        statisticID
    )

    print(
        "Returned ID:",
        statistic
            and statistic.id
            or "nil"
    )

    print(
        "Name:",
        statistic
            and statistic.name
            or "nil"
    )

    print(
        "Is statistic:",
        statistic
            and tostring(
                statistic.isStatistic
            )
            or "nil"
    )

    print(
        "Value:",
        statistic
            and statistic.value
            or "nil"
    )

    print(
        "Numeric value:",
        statistic
            and statistic.numericValue
            or "nil"
    )

    print(
        "Skip:",
        statistic
            and tostring(
                statistic.skip
            )
            or "nil"
    )

    print(
        "GetStatistic returned ID:",
        statistic
            and statistic.returnedID
            or "nil"
    )

    print(
        "Error:",
        statistic
            and statistic.errorCode
            or "none"
    )

    PrintSeparator()
end

function Probe.Scan()
    return ScanStatistics()
end

SLASH_FOREVERJOURNEYSTATISTICSPROBE1 =
    "/fjstats"

SlashCmdList[
    "FOREVERJOURNEYSTATISTICSPROBE"
] =
    function(
        message
    )
        message =
            message
            or ""

        local command,
            argument =
                string.match(
                    message,
                    "^%s*(%S*)%s*(.-)%s*$"
                )

        command =
            string.lower(
                command
                or ""
            )

        if command == ""
            or command == "status" then

            PrintStatus()

            return
        end

        if command
            == "summary" then

            PrintSummary()

            return
        end

        if command
            == "deaths" then

            PrintDeaths()

            return
        end

        if command
            == "nonzero" then

            PrintNonZero()

            return
        end

        if command
            == "id" then

            local statisticID =
                tonumber(
                    argument
                )

            if not statisticID then
                print(
                    "[FJ STATS] Usage: /fjstats id <number>"
                )

                return
            end

            PrintByID(
                statisticID
            )

            return
        end

        print(
            "[FJ STATS] Commands:"
        )

        print(
            "/fjstats status"
        )

        print(
            "/fjstats summary"
        )

        print(
            "/fjstats deaths"
        )

        print(
            "/fjstats nonzero"
        )

        print(
            "/fjstats id <statisticID>"
        )
    end