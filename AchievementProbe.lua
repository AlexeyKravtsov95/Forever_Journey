local addonName, FJ = ...

FJ.AchievementProbe = {}

local Probe =
    FJ.AchievementProbe

local eventFrame =
    CreateFrame(
        "Frame"
    )

local eventCount = 0
local lastAchievementID = nil

local function PrintSeparator()
    print(
        "--------------------------------"
    )
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

local function YesNo(
    value
)
    if value == true then
        return "yes"
    end

    if value == false then
        return "no"
    end

    return tostring(
        value
    )
end

local function PrintAchievementInfo(
    achievementID,
    label
)
    if type(GetAchievementInfo)
        ~= "function" then

        print(
            "[FJ ACH DEBUG] GetAchievementInfo unavailable."
        )

        return
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
        earnedBy =
            pcall(
                GetAchievementInfo,
                achievementID
            )

    PrintSeparator()

    print(
        label
        or "[FJ ACH DEBUG] Achievement payload"
    )

    if not success then
        print(
            "[FJ ACH DEBUG] GetAchievementInfo failed."
        )

        PrintSeparator()

        return
    end

    print(
        "ID:",
        id
        or achievementID
        or "nil"
    )

    print(
        "Name:",
        name
        or "nil"
    )

    print(
        "Points:",
        points
        or "nil"
    )

    print(
        "Completed:",
        YesNo(
            completed
        )
    )

    print(
        "Earned by me:",
        YesNo(
            wasEarnedByMe
        )
    )

    if month
        and day
        and year then

        print(
            "Date:",
            tostring(day)
            .. "."
            .. tostring(month)
            .. "."
            .. tostring(year)
        )
    else
        print(
            "Date:",
            "nil"
        )
    end

    print(
        "Description:",
        description
        or "nil"
    )

    print(
        "Reward:",
        rewardText
        or "nil"
    )

    print(
        "Icon:",
        icon
        or "nil"
    )

    print(
        "Flags:",
        flags
        or "nil"
    )

    print(
        "Guild:",
        YesNo(
            isGuild
        )
    )

    print(
        "Earned by:",
        earnedBy
        or "nil"
    )

    PrintSeparator()
end

local registrationSuccess,
    registrationResult =
        pcall(
            eventFrame.RegisterEvent,
            eventFrame,
            "ACHIEVEMENT_EARNED"
        )

Probe.IsRegistered =
    registrationSuccess
    and registrationResult ~= false

eventFrame:SetScript(
    "OnEvent",
    function(
        self,
        event,
        ...
    )
        if event
            ~= "ACHIEVEMENT_EARNED" then

            return
        end

        eventCount =
            eventCount + 1

        local achievementID =
            select(
                1,
                ...
            )

        lastAchievementID =
            achievementID

        PrintSeparator()

        print(
            "[FJ ACH DEBUG] ACHIEVEMENT_EARNED"
        )

        print(
            "Event count:",
            eventCount
        )

        print(
            "Argument count:",
            select(
                "#",
                ...
            )
        )

        for index = 1,
            select(
                "#",
                ...
            ) do

            print(
                "Arg "
                .. tostring(index)
                .. ":",
                tostring(
                    select(
                        index,
                        ...
                    )
                )
            )
        end

        PrintSeparator()

        if achievementID then
            Schedule(
                0.10,
                function()
                    PrintAchievementInfo(
                        achievementID,
                        "[FJ ACH DEBUG] Payload after 0.10 sec"
                    )
                end
            )

            Schedule(
                0.50,
                function()
                    PrintAchievementInfo(
                        achievementID,
                        "[FJ ACH DEBUG] Payload after 0.50 sec"
                    )
                end
            )

            Schedule(
                1.50,
                function()
                    PrintAchievementInfo(
                        achievementID,
                        "[FJ ACH DEBUG] Payload after 1.50 sec"
                    )
                end
            )
        end
    end
)

SLASH_FOREVERJOURNEYACHIEVEMENTPROBE1 =
    "/fjach"

SlashCmdList[
    "FOREVERJOURNEYACHIEVEMENTPROBE"
] =
    function(
        message
    )
        message =
            string.lower(
                message
                or ""
            )

        if message == ""
            or message == "status" then

            PrintSeparator()

            print(
                "[FJ ACH DEBUG] Status"
            )

            print(
                "ACHIEVEMENT_EARNED registered:",
                Probe.IsRegistered
                and "yes"
                or "no"
            )

            print(
                "Events captured:",
                eventCount
            )

            print(
                "Last achievement ID:",
                lastAchievementID
                or "none"
            )

            PrintSeparator()

            return
        end

        local achievementID =
            tonumber(
                message
            )

        if achievementID then
            PrintAchievementInfo(
                achievementID,
                "[FJ ACH DEBUG] Manual achievement lookup"
            )

            return
        end

        print(
            "[FJ ACH DEBUG] Commands:"
        )

        print(
            "/fjach"
        )

        print(
            "/fjach status"
        )

        print(
            "/fjach <achievementID>"
        )
    end