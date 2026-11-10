local addonName, FJ = ...

FJ.ProfessionMilestones = {}

local JourneyState = FJ.State

local MEMORY_TYPE = "PROFESSION_MILESTONE"
local MILESTONE_STEP = 75

local locale = GetLocale()
local baselineReady = false
local lastSkills = {}

local strings = {
    enUS = {
        TYPE = "PROFESSION",
        LEARNED = "Learned profession: %s",
        MILESTONE = "%s reached skill %d",
        DESCRIPTION_LEARNED = "A new profession became part of the journey.",
        DESCRIPTION_MILESTONE = "A new profession milestone has been reached."
    },

    ruRU = {
        TYPE = "ПРОФЕССИЯ",
        LEARNED = "Изучена профессия: %s",
        MILESTONE = "%s: навык повышен до %d",
        DESCRIPTION_LEARNED = "Новая профессия стала частью путешествия.",
        DESCRIPTION_MILESTONE = "Достигнута новая профессиональная веха."
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

    local ok,
        result = pcall(
            string.format,
            value,
            ...
        )

    if ok then
        return result
    end

    return value
end

local PROFESSION_ICON_BY_SKILL_LINE = {
    [164] =
        "Interface\\Icons\\Trade_BlackSmithing",

    [165] =
        "Interface\\Icons\\INV_Misc_ArmorKit_17",

    [171] =
        "Interface\\Icons\\Trade_Alchemy",

    [182] =
        "Interface\\Icons\\Trade_Herbalism",

    [185] =
        "Interface\\Icons\\INV_Misc_Food_15",

    [186] =
        "Interface\\Icons\\Trade_Mining",

    [197] =
        "Interface\\Icons\\Trade_Tailoring",

    [202] =
        "Interface\\Icons\\Trade_Engineering",

    [333] =
        "Interface\\Icons\\Trade_Engraving",

    [356] =
        "Interface\\Icons\\Trade_Fishing",

    [393] =
        "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",

    [755] =
        "Interface\\Icons\\INV_Misc_Gem_01",

    [773] =
        "Interface\\Icons\\INV_Inscription_Tradeskill01",

    [794] =
        "Interface\\Icons\\Trade_Archaeology"
}

local PROFESSION_ICON_BY_NAME = {
    ["Горное дело"] =
        "Interface\\Icons\\Trade_Mining",

    ["Инженерное дело"] =
        "Interface\\Icons\\Trade_Engineering",

    ["Кулинария"] =
        "Interface\\Icons\\INV_Misc_Food_15",

    ["Алхимия"] =
        "Interface\\Icons\\Trade_Alchemy",

    ["Травничество"] =
        "Interface\\Icons\\Trade_Herbalism",

    ["Кузнечное дело"] =
        "Interface\\Icons\\Trade_BlackSmithing",

    ["Кожевничество"] =
        "Interface\\Icons\\INV_Misc_ArmorKit_17",

    ["Наложение чар"] =
        "Interface\\Icons\\Trade_Engraving",

    ["Портняжное дело"] =
        "Interface\\Icons\\Trade_Tailoring",

    ["Снятие шкур"] =
        "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",

    ["Рыбная ловля"] =
        "Interface\\Icons\\Trade_Fishing",

    ["Археология"] =
        "Interface\\Icons\\Trade_Archaeology",

    ["Ювелирное дело"] =
        "Interface\\Icons\\INV_Misc_Gem_01",

    ["Начертание"] =
        "Interface\\Icons\\INV_Inscription_Tradeskill01",

    ["Mining"] =
        "Interface\\Icons\\Trade_Mining",

    ["Engineering"] =
        "Interface\\Icons\\Trade_Engineering",

    ["Cooking"] =
        "Interface\\Icons\\INV_Misc_Food_15",

    ["Alchemy"] =
        "Interface\\Icons\\Trade_Alchemy",

    ["Herbalism"] =
        "Interface\\Icons\\Trade_Herbalism",

    ["Blacksmithing"] =
        "Interface\\Icons\\Trade_BlackSmithing",

    ["Leatherworking"] =
        "Interface\\Icons\\INV_Misc_ArmorKit_17",

    ["Enchanting"] =
        "Interface\\Icons\\Trade_Engraving",

    ["Tailoring"] =
        "Interface\\Icons\\Trade_Tailoring",

    ["Skinning"] =
        "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",

    ["Fishing"] =
        "Interface\\Icons\\Trade_Fishing",

    ["Archaeology"] =
        "Interface\\Icons\\Trade_Archaeology",

    ["Jewelcrafting"] =
        "Interface\\Icons\\INV_Misc_Gem_01",

    ["Inscription"] =
        "Interface\\Icons\\INV_Inscription_Tradeskill01"
}

local function GetProfessionIcon(
    skillLine,
    name
)
    skillLine =
        tonumber(
            skillLine
        )

    if skillLine
        and PROFESSION_ICON_BY_SKILL_LINE[
            skillLine
        ] then

        return PROFESSION_ICON_BY_SKILL_LINE[
            skillLine
        ]
    end

    if name
        and PROFESSION_ICON_BY_NAME[
            name
        ] then

        return PROFESSION_ICON_BY_NAME[
            name
        ]
    end

    return FJ.Theme.Textures
        .iconStarted
end

local function ReadCurrentProfessions()
    local professions =
        FJ.Journey.RefreshProfessions()
        or {}

    local result = {}

    for _, profession in ipairs(
        professions
    ) do
        local skillLine =
            tonumber(
                profession.skillLine
            )

        if skillLine then
            result[skillLine] = {
                name =
                    profession.name,

                skillLine =
                    skillLine,

                skillLevel =
                    tonumber(
                        profession.skillLevel
                    ) or 0,

                maxSkillLevel =
                    tonumber(
                        profession.maxSkillLevel
                    ) or 0
            }
        end
    end

    return result
end

local function HasRecordedEvent(
    kind,
    skillLine,
    milestone
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
            and memory.data.kind
                == kind
            and tonumber(
                memory.data.skillLine
            ) == tonumber(
                skillLine
            ) then

            if kind == "LEARNED" then
                return true
            end

            if tonumber(
                memory.data.milestone
            ) == tonumber(
                milestone
            ) then

                return true
            end
        end
    end

    return false
end

local function AddLearnedMemory(
    profession
)
    if HasRecordedEvent(
        "LEARNED",
        profession.skillLine
    ) then

        return false
    end

    FJ.Memories.Add(
        MEMORY_TYPE,
        {
            kind =
                "LEARNED",

            professionName =
                profession.name,

            skillLine =
                profession.skillLine,

            skillLevel =
                profession.skillLevel,

            maxSkillLevel =
                profession.maxSkillLevel
        }
    )

    return true
end

local function AddMilestoneMemory(
    profession,
    milestone
)
    if HasRecordedEvent(
        "MILESTONE",
        profession.skillLine,
        milestone
    ) then

        return false
    end

    FJ.Memories.Add(
        MEMORY_TYPE,
        {
            kind =
                "MILESTONE",

            professionName =
                profession.name,

            skillLine =
                profession.skillLine,

            skillLevel =
                profession.skillLevel,

            maxSkillLevel =
                profession.maxSkillLevel,

            milestone =
                milestone
        }
    )

    return true
end

local function SyncBaseline()
    lastSkills =
        ReadCurrentProfessions()

    baselineReady =
        true
end

local function EvaluateProfessionProgress()
    local current =
        ReadCurrentProfessions()

    if not baselineReady then
        lastSkills =
            current

        baselineReady =
            true

        return
    end

    local createdAny =
        false

    for skillLine,
        profession in pairs(
            current
        ) do

        local previous =
            lastSkills[skillLine]

        if not previous then
            if AddLearnedMemory(
                profession
            ) then

                createdAny =
                    true
            end
        else
            local previousSkill =
                tonumber(
                    previous.skillLevel
                ) or 0

            local currentSkill =
                tonumber(
                    profession.skillLevel
                ) or 0

            if currentSkill
                > previousSkill then

                local milestone =
                    MILESTONE_STEP

                while milestone
                    <= currentSkill do

                    if previousSkill
                        < milestone then

                        if AddMilestoneMemory(
                            profession,
                            milestone
                        ) then

                            createdAny =
                                true
                        end
                    end

                    milestone =
                        milestone
                        + MILESTONE_STEP
                end
            end
        end
    end

    lastSkills =
        current

    if createdAny
        and FJ.UI
        and FJ.UI.RefreshIfVisible then

        FJ.UI.RefreshIfVisible()
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

function FJ.ProfessionMilestones
    .GetIcon(
        skillLine,
        name
    )

    return GetProfessionIcon(
        skillLine,
        name
    )
end

--
-- Memory type registration.
--

FJ.MemoryTypes.Register(
    MEMORY_TYPE,
    {
        getTypeLabel = function()
            return T(
                "TYPE"
            )
        end,

        getTitle = function(memory)
            local data =
                type(memory.data)
                    == "table"
                and memory.data
                or {}

            local name =
                FJ.Utils.GetLocalizedProfessionName(
                    {
                        skillLine =
                            data.skillLine,

                        name =
                            data.professionName
                    }
                )
                or FJ.Locale.Get(
                    "UNKNOWN"
                )

            if data.kind
                == "LEARNED" then

                return T(
                    "LEARNED",
                    name
                )
            end

            if data.kind
                == "MILESTONE" then

                return T(
                    "MILESTONE",
                    name,
                    tonumber(
                        data.milestone
                    )
                        or tonumber(
                            data.skillLevel
                        )
                        or 0
                )
            end

            return nil
        end,

        getDescription = function(memory)
            local data =
                type(memory.data)
                    == "table"
                and memory.data
                or {}

            if data.kind
                == "LEARNED" then

                return T(
                    "DESCRIPTION_LEARNED"
                )
            end

            return T(
                "DESCRIPTION_MILESTONE"
            )
        end,

        getMarkerTexture = function(memory)
            local data =
                type(memory.data)
                    == "table"
                and memory.data
                or {}

            return GetProfessionIcon(
                data.skillLine,
                data.professionName
            )
        end
    }
)

--
-- Live profession tracking.
--

local eventFrame =
    CreateFrame(
        "Frame"
    )

eventFrame:RegisterEvent(
    "PLAYER_ENTERING_WORLD"
)

eventFrame:RegisterEvent(
    "SKILL_LINES_CHANGED"
)

eventFrame:SetScript(
    "OnEvent",
    function(
        self,
        event
    )
        if event
            == "PLAYER_ENTERING_WORLD" then

            Schedule(
                0.90,
                SyncBaseline
            )

        elseif event
            == "SKILL_LINES_CHANGED" then

            Schedule(
                0.20,
                EvaluateProfessionProgress
            )
        end
    end
)