local addonName, FJ = ...

FJ.Utils = {}

local function L(key)
    return FJ.Locale.Get(key)
end

local PROFESSION_NAMES = {
    enUS = {
        [129] = "First Aid",
        [164] = "Blacksmithing",
        [165] = "Leatherworking",
        [171] = "Alchemy",
        [182] = "Herbalism",
        [185] = "Cooking",
        [186] = "Mining",
        [197] = "Tailoring",
        [202] = "Engineering",
        [333] = "Enchanting",
        [356] = "Fishing",
        [393] = "Skinning",
        [755] = "Jewelcrafting",
        [773] = "Inscription",
        [794] = "Archaeology"
    },

    ruRU = {
        [129] = "Первая помощь",
        [164] = "Кузнечное дело",
        [165] = "Кожевничество",
        [171] = "Алхимия",
        [182] = "Травничество",
        [185] = "Кулинария",
        [186] = "Горное дело",
        [197] = "Портняжное дело",
        [202] = "Инженерное дело",
        [333] = "Наложение чар",
        [356] = "Рыбная ловля",
        [393] = "Снятие шкур",
        [755] = "Ювелирное дело",
        [773] = "Начертание",
        [794] = "Археология"
    }
}

local function IsUnknownUnitName(name)
    if type(name) ~= "string"
        or name == "" then

        return true
    end

    local normalized =
        string.lower(
            name
        )

    if normalized == "unknown"
        or normalized == "unknown unit"
        or normalized == "неизвестно"
        or normalized == "неизвестный"
        or normalized == "неизвестная цель" then

        return true
    end

    local globalsToCheck = {
        _G.UNKNOWN,
        _G.UNKNOWNOBJECT,
        _G.UNKNOWN_UNIT
    }

    for _, globalValue in ipairs(
        globalsToCheck
    ) do
        if type(globalValue) == "string"
            and globalValue ~= ""
            and string.lower(
                globalValue
            ) == normalized then

            return true
        end
    end

    return false
end

function FJ.Utils.FormatPlayedTime(seconds)
    if not seconds
        or seconds < 0 then

        seconds = 0
    end

    local days =
        math.floor(
            seconds / 86400
        )

    seconds =
        seconds % 86400

    local hours =
        math.floor(
            seconds / 3600
        )

    seconds =
        seconds % 3600

    local minutes =
        math.floor(
            seconds / 60
        )

    local parts = {}

    if days > 0 then
        table.insert(
            parts,
            tostring(days)
                .. L("TIME_DAY_SHORT")
        )
    end

    if hours > 0
        or days > 0 then

        table.insert(
            parts,
            tostring(hours)
                .. L("TIME_HOUR_SHORT")
        )
    end

    table.insert(
        parts,
        tostring(minutes)
            .. L("TIME_MINUTE_SHORT")
    )

    return table.concat(
        parts,
        " "
    )
end

function FJ.Utils.FormatMoney(copper)
    if not copper
        or copper < 0 then

        copper = 0
    end

    local gold =
        math.floor(
            copper / 10000
        )

    copper =
        copper % 10000

    local silver =
        math.floor(
            copper / 100
        )

    local remainingCopper =
        copper % 100

    local parts = {}

    if gold > 0 then
        table.insert(
            parts,
            tostring(gold)
                .. L("MONEY_GOLD_SHORT")
        )
    end

    if silver > 0
        or gold > 0 then

        table.insert(
            parts,
            tostring(silver)
                .. L("MONEY_SILVER_SHORT")
        )
    end

    table.insert(
        parts,
        tostring(remainingCopper)
            .. L("MONEY_COPPER_SHORT")
    )

    return table.concat(
        parts,
        " "
    )
end

function FJ.Utils.FormatDate(timestamp)
    if not timestamp then
        return L("UNKNOWN")
    end

    return date(
        "%d.%m.%Y %H:%M",
        timestamp
    )
end

function FJ.Utils.GetLocalizedLocationName(
    location
)
    if type(location) ~= "table" then
        return L("UNKNOWN")
    end

    local instanceID =
        tonumber(
            location.instanceID
        )

    if instanceID
        and type(GetRealZoneText)
            == "function" then

        local success,
            instanceName = pcall(
                GetRealZoneText,
                instanceID
            )

        if success
            and type(instanceName)
                == "string"
            and instanceName ~= "" then

            return instanceName
        end
    end

    local mapID =
        tonumber(
            location.mapID
        )

    if mapID
        and C_Map
        and type(C_Map.GetMapInfo)
            == "function" then

        local success,
            mapInfo = pcall(
                C_Map.GetMapInfo,
                mapID
            )

        if success
            and mapInfo
            and type(mapInfo.name)
                == "string"
            and mapInfo.name ~= "" then

            return mapInfo.name
        end
    end

    if type(location.name) == "string"
        and location.name ~= "" then

        return location.name
    end

    return L("UNKNOWN")
end

function FJ.Utils.GetLocalizedProfessionName(
    profession
)
    if type(profession) ~= "table" then
        return L("UNKNOWN")
    end

    local skillLine =
        tonumber(
            profession.skillLine
            or profession.skillLineID
        )

    if skillLine then
        local locale =
            GetLocale()

        local localeNames =
            PROFESSION_NAMES[locale]
            or PROFESSION_NAMES.enUS

        if localeNames[skillLine] then
            return localeNames[skillLine]
        end
    end

    if type(GetProfessions) == "function"
        and type(GetProfessionInfo)
            == "function" then

        local profession1,
            profession2,
            archaeology,
            fishing,
            cooking,
            firstAid =
                GetProfessions()

        local professionIndexes = {
            [1] = profession1,
            [2] = profession2,
            [3] = archaeology,
            [4] = fishing,
            [5] = cooking,
            [6] = firstAid
        }

        for index = 1, 6 do
            local professionIndex =
                professionIndexes[index]

            if professionIndex then
                local name,
                    icon,
                    skillLevel,
                    maxSkillLevel,
                    numAbilities,
                    spellOffset,
                    currentSkillLine =
                        GetProfessionInfo(
                            professionIndex
                        )

                if name
                    and name ~= ""
                    and (
                        not skillLine
                        or tonumber(
                            currentSkillLine
                        ) == skillLine
                    ) then

                    return name
                end
            end
        end
    end

    if type(profession.name) == "string"
        and profession.name ~= "" then

        return profession.name
    end

    return L("UNKNOWN")
end

function FJ.Utils.IsUnknownUnitName(name)
    return IsUnknownUnitName(
        name
    )
end

function FJ.Utils.GetRecordedUnitName(
    primaryName,
    fallbackName
)
    if type(primaryName) == "string"
        and primaryName ~= ""
        and not IsUnknownUnitName(
            primaryName
        ) then

        return primaryName
    end

    if type(fallbackName) == "string"
        and fallbackName ~= ""
        and not IsUnknownUnitName(
            fallbackName
        ) then

        return fallbackName
    end

    return nil
end

function FJ.Utils.GetLocalizedSpellName(
    spellID,
    fallbackName
)
    spellID =
        tonumber(
            spellID
        )

    if spellID
        and C_Spell
        and type(
            C_Spell.GetSpellName
        ) == "function" then

        local success,
            spellName = pcall(
                C_Spell.GetSpellName,
                spellID
            )

        if success
            and type(spellName) == "string"
            and spellName ~= "" then

            return spellName
        end
    end

    if spellID
        and type(GetSpellInfo)
            == "function" then

        local success,
            spellName = pcall(
                GetSpellInfo,
                spellID
            )

        if success
            and type(spellName) == "string"
            and spellName ~= "" then

            return spellName
        end
    end

    if type(fallbackName) == "string"
        and fallbackName ~= "" then

        return fallbackName
    end

    return nil
end
