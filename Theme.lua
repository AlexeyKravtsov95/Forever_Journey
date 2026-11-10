local addonName, FJ = ...

FJ.Theme = {}

FJ.Theme.Window = {
    width = 920,
    height = 634,

    parchmentWidth = 850,
    parchmentHeight = 510,

    contentWidth = 790,
    contentHeight = 440,

    leftColumnWidth = 335,
    columnGap = 18,

    timelineRowHeight = 72,
    maxOverviewMemories = 5
}

FJ.Theme.Header = {
    titleX = 150,
    titleY = -17,

    compassWidth = 136,
    compassHeight = 68
}

FJ.Theme.Portrait = {
    containerSize = 116,

    modelSize = 100,
    fallbackSize = 100,

    frameSize = 112,

    x = 20,
    y = -17
}

FJ.Theme.Colors = {
    ink = {
        r = 0.18,
        g = 0.11,
        b = 0.06,
        a = 1
    },

    inkMuted = {
        r = 0.40,
        g = 0.30,
        b = 0.20,
        a = 1
    },

    gold = {
        r = 0.72,
        g = 0.49,
        b = 0.18,
        a = 1
    },

    goldMuted = {
        r = 0.52,
        g = 0.34,
        b = 0.14,
        a = 1
    },

    parchmentText = {
        r = 0.20,
        g = 0.12,
        b = 0.07,
        a = 1
    },

    parchmentFallback = {
        r = 0.79,
        g = 0.70,
        b = 0.53,
        a = 1
    },

    timeline = {
        r = 0.44,
        g = 0.30,
        b = 0.13,
        a = 0.70
    },

    recovered = {
        r = 0.38,
        g = 0.24,
        b = 0.44,
        a = 1
    }
}

local root =
    "Interface\\AddOns\\ForeverJourney\\Textures\\"

FJ.Theme.Textures = {
    journalFrame =
        root
        .. "Backgrounds\\journal_frame.tga",

    parchment =
        root
        .. "Backgrounds\\parchment_overlay.tga",

    compass =
        root
        .. "Decorations\\compass_emblem.tga",

    cornerLeft =
        root
        .. "Decorations\\corner_left.tga",

    cornerRight =
        root
        .. "Decorations\\corner_right.tga",

    ornamentLine =
        root
        .. "Decorations\\ornament_line.tga",

    dividerHorizontal =
        root
        .. "Dividers\\divider_horizontal.tga",

    dividerVertical =
        root
        .. "Dividers\\divider_vertical.tga",

    tabActive =
        root
        .. "Tabs\\tab_active.tga",

    tabInactive =
        root
        .. "Tabs\\tab_inactive.tga",

    markerGeneric =
        root
        .. "Timeline\\marker_generic.tga",

    markerLevel =
        root
        .. "Timeline\\marker_level.tga",

    markerZone =
        root
        .. "Timeline\\marker_zone.tga",

    markerInstance =
        root
        .. "Timeline\\marker_instance.tga",

    markerDeath =
        root
        .. "Timeline\\marker_death.tga",

    markerRecovered =
        root
        .. "Timeline\\marker_recovered.tga",

    markerReputation =
        root
        .. "Timeline\\marker_reputation.tga",

    portraitFrame =
        root
        .. "Portrait\\portrait_frame.tga",

    levelBadge =
        root
        .. "Portrait\\level_badge.tga",

    iconTime =
        root
        .. "Icons\\icon_time.tga",

    iconQuests =
        root
        .. "Icons\\icon_quests.tga",

    iconMoney =
        root
        .. "Icons\\icon_money.tga",

    iconDeaths =
        root
        .. "Icons\\icon_deaths.tga",

    iconMemories =
        root
        .. "Icons\\icon_memories.tga",

    iconStarted =
        root
        .. "Icons\\icon_started.tga"
}

function FJ.Theme.ApplyTextColor(
    fontString,
    color
)
    fontString:SetTextColor(
        color.r,
        color.g,
        color.b,
        color.a
    )
end

function FJ.Theme.ApplyColor(
    texture,
    color
)
    texture:SetColorTexture(
        color.r,
        color.g,
        color.b,
        color.a
    )
end

function FJ.Theme.GetMarkerTexture(
    memory
)
    if memory
        and memory.source
            == "RECOVERED" then

        return FJ.Theme.Textures
            .markerRecovered
    end

    local semanticType =
        FJ.MemoryTypes
        and FJ.MemoryTypes.GetSemanticType
        and FJ.MemoryTypes.GetSemanticType(
            memory
        )
        or (
            memory
            and memory.type
        )

    if FJ.MemoryTypes
        and FJ.MemoryTypes.Get
        and semanticType then

        local handler =
            FJ.MemoryTypes.Get(
                semanticType
            )

        if handler
            and type(
                handler.getMarkerTexture
            ) == "function" then

            local rawMemory =
                FJ.MemoryTypes.GetRawMemory
                and FJ.MemoryTypes.GetRawMemory(
                    memory
                )
                or memory

            local texture =
                handler.getMarkerTexture(
                    rawMemory
                )

            if texture then
                return texture
            end
        end
    end

    local textures = {
        LEVEL =
            FJ.Theme.Textures.markerLevel,

        ZONE =
            FJ.Theme.Textures.markerZone,

        INSTANCE =
            FJ.Theme.Textures.markerInstance,

        DEATH =
            FJ.Theme.Textures.markerDeath,

        REPUTATION_MILESTONE =
            FJ.Theme.Textures.markerReputation
    }

    return textures[
        semanticType
        or ""
    ]
        or FJ.Theme.Textures.markerGeneric
end