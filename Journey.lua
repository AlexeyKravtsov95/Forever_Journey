local addonName, FJ = ...

local JourneyState = FJ.State

FJ.Journey = {}

function FJ.Journey.RefreshProfile()
    JourneyState.profile = {
        name = UnitName("player"),
        level = UnitLevel("player"),
        race = UnitRace("player"),
        class = UnitClass("player")
    }

    return JourneyState.profile
end

function FJ.Journey.TrackCurrentZone(
    createMemory
)
    local location =
        FJ.Memories.GetCurrentLocation()

    if location.kind ~= "ZONE"
        or not location.mapID then

        return
    end

    if JourneyState
        .visitedZones[location.mapID] then

        return
    end

    JourneyState.visitedZones[
        location.mapID
    ] = {
        name = location.name,
        firstSeenAt = time()
    }

    if createMemory then
        FJ.Memories.Add(
            "ZONE",
            {
                mapID =
                    location.mapID,

                zoneName =
                    location.name
            },
            location
        )
    end
end

function FJ.Journey.HandleLevelUp(
    newLevel
)
    if not JourneyState.profile then
        FJ.Journey.RefreshProfile()
    end

    JourneyState.profile.level =
        newLevel

    FJ.Memories.Add(
        "LEVEL",
        {
            level = newLevel
        }
    )
end

function FJ.Journey.HandleMoneyChanged()
    local newMoney =
        GetMoney()

    local previousMoney =
        JourneyState.money.current

    if previousMoney == nil then
        JourneyState.money.current =
            newMoney

        return
    end

    local difference =
        newMoney
        - previousMoney

    JourneyState.money.current =
        newMoney

    if difference > 0 then
        JourneyState.money.earned =
            JourneyState.money.earned
            + difference

    elseif difference < 0 then
        local spent =
            math.abs(
                difference
            )

        JourneyState.money.spent =
            JourneyState.money.spent
            + spent
    end
end

local DEATH_RECAP_RETRY_DELAYS = {
    0.15,
    0.35,
    0.75,
    1.25
}

local function SafeNumber(value)
    local success,
        numberValue = pcall(
            tonumber,
            value
        )

    if success then
        return numberValue
    end

    return nil
end

local function GetLatestDeathRecapEvents()
    if not C_DeathRecap
        or type(
            C_DeathRecap.GetRecapEvents
        ) ~= "function" then

        return nil
    end

    if type(
        C_DeathRecap.HasRecapEvents
    ) == "function" then

        local success,
            hasEvents = pcall(
                C_DeathRecap.HasRecapEvents
            )

        if success
            and not hasEvents then

            return nil
        end
    end

    local success,
        events = pcall(
            C_DeathRecap.GetRecapEvents
        )

    if not success
        or type(events) ~= "table" then

        return nil
    end

    return events
end

local function FindLethalDeathEvent(
    events
)
    if type(events) ~= "table" then
        return nil
    end

    local lethalEvent = nil
    local lethalTimestamp = nil

    local fallbackEvent = nil
    local fallbackTimestamp = nil

    for _, eventInfo in pairs(
        events
    ) do
        if type(eventInfo) == "table" then
            local amount =
                SafeNumber(
                    eventInfo.amount
                )

            if amount
                and amount > 0 then

                local timestamp =
                    SafeNumber(
                        eventInfo.timestamp
                    )
                    or 0

                if not fallbackEvent
                    or timestamp
                        >= fallbackTimestamp then

                    fallbackEvent =
                        eventInfo

                    fallbackTimestamp =
                        timestamp
                end

                local overkill =
                    SafeNumber(
                        eventInfo.overkill
                    )

                local currentHP =
                    SafeNumber(
                        eventInfo.currentHP
                    )

                local isLethal =
                    (
                        overkill ~= nil
                        and overkill >= 0
                    )
                    or (
                        currentHP ~= nil
                        and currentHP <= 0
                    )

                if isLethal
                    and (
                        not lethalEvent
                        or timestamp
                            >= lethalTimestamp
                    ) then

                    lethalEvent =
                        eventInfo

                    lethalTimestamp =
                        timestamp
                end
            end
        end
    end

    return lethalEvent
        or fallbackEvent
end

local function ResolveDeathSpellName(
    eventInfo
)
    if type(eventInfo) ~= "table" then
        return nil
    end

    if type(eventInfo.spellName)
        == "string"
        and eventInfo.spellName ~= "" then

        return eventInfo.spellName
    end

    local spellID =
        eventInfo.spellId
        or eventInfo.spellID

    if not spellID then
        return nil
    end

    if C_Spell
        and type(C_Spell.GetSpellName)
            == "function" then

        local success,
            spellName = pcall(
                C_Spell.GetSpellName,
                spellID
            )

        if success
            and type(spellName)
                == "string"
            and spellName ~= "" then

            return spellName
        end
    end

    if type(GetSpellInfo)
        == "function" then

        local success,
            spellName = pcall(
                GetSpellInfo,
                spellID
            )

        if success
            and type(spellName)
                == "string"
            and spellName ~= "" then

            return spellName
        end
    end

    return nil
end

local function GetKnownRealmNames()
    local realms = {}

    local function AddRealm(value)
        if type(value) ~= "string"
            or value == "" then

            return
        end

        for _, existing in ipairs(realms) do
            if string.lower(existing)
                == string.lower(value) then

                return
            end
        end

        table.insert(
            realms,
            value
        )
    end

    if type(GetRealmName)
        == "function" then

        local success,
            realm = pcall(
                GetRealmName
            )

        if success then
            AddRealm(realm)
        end
    end

    if type(GetNormalizedRealmName)
        == "function" then

        local success,
            realm = pcall(
                GetNormalizedRealmName
            )

        if success then
            AddRealm(realm)
        end
    end

    if type(SelectedRealmName)
        == "function" then

        local success,
            realm = pcall(
                SelectedRealmName
            )

        if success then
            AddRealm(realm)
        end
    end

    return realms
end

local function StripKnownRealmSuffix(
    name
)
    if type(name) ~= "string"
        or name == "" then

        return name
    end

    local lowerName =
        string.lower(name)

    for _, realm in ipairs(
        GetKnownRealmNames()
    ) do
        local lowerRealm =
            string.lower(realm)

        local suffixes = {
            "-" .. lowerRealm,
            " " .. lowerRealm
        }

        for _, suffix in ipairs(
            suffixes
        ) do
            if #lowerName > #suffix
                and string.sub(
                    lowerName,
                    -#suffix
                ) == suffix then

                return string.sub(
                    name,
                    1,
                    #name - #suffix
                )
            end
        end
    end

    return name
end

local function ResolveCreatureID(
    sourceGUID
)
    if not sourceGUID
        or not C_CreatureInfo
        or type(
            C_CreatureInfo.GetCreatureID
        ) ~= "function" then

        return nil
    end

    local success,
        creatureID = pcall(
            C_CreatureInfo.GetCreatureID,
            sourceGUID
        )

    if not success then
        return nil
    end

    return SafeNumber(
        creatureID
    )
end

local function ResolveDeathSourceName(
    eventInfo
)
    if type(eventInfo) ~= "table" then
        return nil, nil, nil, false
    end

    local sourceGUID =
        eventInfo.sourceGUID

    local rawSourceName =
        type(eventInfo.sourceName)
            == "string"
        and eventInfo.sourceName ~= ""
        and eventInfo.sourceName
        or nil

    --
    -- Prefer resolving the name from the GUID while
    -- the death is being recorded. Death Recap's
    -- sourceName may contain cached or mixed-locale
    -- text, so it is kept only as a fallback and for
    -- diagnostics.
    --

    if sourceGUID
        and type(UnitNameFromGUID)
            == "function" then

        local success,
            unitName,
            unitServer = pcall(
                UnitNameFromGUID,
                sourceGUID
            )

        if success
            and not FJ.Utils.IsUnknownUnitName(
                unitName
            ) then

            return StripKnownRealmSuffix(
                unitName
            ), rawSourceName, unitServer, true
        end
    end

    if sourceGUID
        and string.sub(
            sourceGUID,
            1,
            7
        ) == "Player-"
        and type(GetPlayerInfoByGUID)
            == "function" then

        local success,
            localizedClass,
            englishClass,
            localizedRace,
            englishRace,
            sex,
            playerName,
            realmName = pcall(
                GetPlayerInfoByGUID,
                sourceGUID
            )

        if success
            and not FJ.Utils.IsUnknownUnitName(
                playerName
            ) then

            return StripKnownRealmSuffix(
                playerName
            ), rawSourceName, realmName, true
        end
    end

    local recordedRawName =
        FJ.Utils.GetRecordedUnitName(
            rawSourceName,
            nil
        )

    if recordedRawName then
        return StripKnownRealmSuffix(
            recordedRawName
        ), rawSourceName, nil, false
    end

    return nil,
        rawSourceName,
        nil,
        false
end

local function BuildDeathRecapData(
    eventInfo
)
    if type(eventInfo) ~= "table" then
        return nil
    end

    local eventType =
        eventInfo.event
        or eventInfo.eventType

    local environmentalType =
        eventInfo.environmentalType

    local spellID =
        eventInfo.spellId
        or eventInfo.spellID

    local sourceName,
        rawSourceName,
        sourceRealm,
        resolvedFromGUID =
            ResolveDeathSourceName(
                eventInfo
            )

    local sourceGUID =
        eventInfo.sourceGUID

    local data = {
        cause = "UNKNOWN",

        eventType =
            eventType,

        killerName =
            sourceName,

        --
        -- Memories.lua from 0.2-A1 still treats
        -- killerNameRaw as the first display fallback.
        -- Keep it empty when GUID resolution succeeded
        -- so the localized resolved name wins.
        --
        killerNameRaw =
            not resolvedFromGUID
            and rawSourceName
            or nil,

        -- Always preserve the exact Death Recap value
        -- separately for diagnostics/future migrations.
        killerNameRecapRaw =
            rawSourceName,

        killerRealm =
            sourceRealm,

        killerGUID =
            sourceGUID,

        killerCreatureID =
            ResolveCreatureID(
                sourceGUID
            ),

        spellID =
            spellID,

        spellName =
            ResolveDeathSpellName(
                eventInfo
            ),

        amount =
            SafeNumber(
                eventInfo.amount
            ),

        overkill =
            SafeNumber(
                eventInfo.overkill
            ),

        environmentalType =
            environmentalType
    }

    if eventType
        == "ENVIRONMENTAL_DAMAGE"
        or environmentalType then

        data.cause =
            "ENVIRONMENTAL"

        data.killerName = nil
        data.killerNameRaw = nil
        data.killerNameRecapRaw = nil
        data.killerGUID = nil
        data.killerCreatureID = nil

    elseif sourceName then
        data.cause =
            "COMBAT"
    end

    return data
end

local function ApplyDeathRecapData(
    memory,
    recapData
)
    if type(memory) ~= "table"
        or type(recapData) ~= "table" then

        return false
    end

    memory.data =
        type(memory.data) == "table"
        and memory.data
        or {}

    for key, value in pairs(
        recapData
    ) do
        if value ~= nil then
            memory.data[key] =
                value
        end
    end

    return true
end

local function TryCaptureDeathRecap(
    memory,
    attempt
)
    if type(memory) ~= "table" then
        return
    end

    local events =
        GetLatestDeathRecapEvents()

    local deathEvent =
        FindLethalDeathEvent(
            events
        )

    if deathEvent then
        local recapData =
            BuildDeathRecapData(
                deathEvent
            )

        if ApplyDeathRecapData(
            memory,
            recapData
        ) then

            if FJ.UI
                and FJ.UI.RefreshIfVisible then

                FJ.UI.RefreshIfVisible()
            end

            return
        end
    end

    local retryDelay =
        DEATH_RECAP_RETRY_DELAYS[
            attempt
        ]

    if retryDelay
        and C_Timer
        and type(C_Timer.After)
            == "function" then

        C_Timer.After(
            retryDelay,
            function()
                TryCaptureDeathRecap(
                    memory,
                    attempt + 1
                )
            end
        )
    end
end

function FJ.Journey.HandlePlayerDeath()
    JourneyState.stats.deaths =
        JourneyState.stats.deaths
        + 1

    local memory =
        FJ.Memories.Add(
            "DEATH",
            {
                cause = "UNKNOWN"
            }
        )

    TryCaptureDeathRecap(
        memory,
        1
    )
end

function FJ.Journey.UpdateInstanceState(
    createMemory
)
    local inInstance,
        instanceType = IsInInstance()

    if not inInstance then
        JourneyState.instance.inInstance =
            false

        JourneyState.instance.instanceID =
            nil

        JourneyState.instance.name =
            nil

        JourneyState.instance.type =
            nil

        return
    end

    local name,
        currentInstanceType,
        difficultyID,
        difficultyName,
        maxPlayers,
        dynamicDifficulty,
        isDynamic,
        instanceID = GetInstanceInfo()

    local resolvedInstanceType =
        currentInstanceType
        or instanceType

    local resolvedInstanceName =
        name
        or FJ.Locale.Get("UNKNOWN")

    local wasInSameInstance =
        JourneyState.instance.inInstance
        and JourneyState.instance.instanceID
            == instanceID

    JourneyState.instance.inInstance =
        true

    JourneyState.instance.instanceID =
        instanceID

    JourneyState.instance.name =
        name

    JourneyState.instance.type =
        currentInstanceType

    if createMemory
        and not wasInSameInstance then

        local location = {
            kind = "INSTANCE",
            mapID = nil,
            instanceID = instanceID,
            name = resolvedInstanceName,
            type = resolvedInstanceType
        }

        FJ.Memories.Add(
            "INSTANCE",
            {
                instanceID =
                    instanceID,

                instanceName =
                    resolvedInstanceName,

                instanceType =
                    resolvedInstanceType
            },
            location
        )
    end
end

local function ReadProfession(index)
    if not index then
        return nil
    end

    local name,
        icon,
        skillLevel,
        maxSkillLevel,
        numAbilities,
        spellOffset,
        skillLine,
        skillModifier =
            GetProfessionInfo(index)

    if not name then
        return nil
    end

    return {
        name = name,
        skillLevel = skillLevel,
        maxSkillLevel = maxSkillLevel,
        skillLine = skillLine,
        skillModifier =
            skillModifier
            or 0
    }
end

function FJ.Journey.RefreshProfessions()
    local profession1,
        profession2,
        archaeology,
        fishing,
        cooking =
            GetProfessions()

    JourneyState.professions = {}

    local professionIndices = {
        profession1,
        profession2,
        archaeology,
        fishing,
        cooking
    }

    for index = 1, 5 do
        local professionIndex =
            professionIndices[index]

        local profession =
            ReadProfession(
                professionIndex
            )

        if profession then
            table.insert(
                JourneyState.professions,
                profession
            )
        end
    end

    return JourneyState.professions
end

function FJ.Journey.HandleTimePlayed(
    totalTimePlayed,
    timePlayedThisLevel
)
    JourneyState.played.total =
        totalTimePlayed

    JourneyState.played.currentLevel =
        timePlayedThisLevel

    FJ.Recovery.SetRecoveredPlayedTime(
        totalTimePlayed,
        timePlayedThisLevel
    )
end

function FJ.Journey.HandlePlayerEnteringWorld()
    local firstEntry =
        not JourneyState.hasEnteredWorld

    FJ.Journey.RefreshProfile()

    if firstEntry then
        FJ.Storage.AttachCharacter()
    end

    FJ.Journey.RefreshProfessions()

    if firstEntry then
        FJ.Journey.TrackCurrentZone(
            false
        )

        FJ.Recovery.CaptureInitialSnapshot()

        if type(RequestTimePlayed)
            == "function" then

            RequestTimePlayed()
        end

        JourneyState.hasEnteredWorld =
            true
    end

    if JourneyState.money.current
        == nil then

        JourneyState.money.current =
            GetMoney()
    end

    if not JourneyState
        .instance.initialized then

        FJ.Journey.UpdateInstanceState(
            false
        )

        JourneyState.instance.initialized =
            true
    else
        FJ.Journey.UpdateInstanceState(
            true
        )
    end
end