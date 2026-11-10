local addonName, FJ = ...

FJ.State = {
    profile = nil,

    memories = {},

    visitedZones = {},

    hasEnteredWorld = false,

    pendingQuestSample = {},

    played = {
        total = nil,
        currentLevel = nil
    },

    professions = {},

    money = {
        current = nil,
        earned = 0,
        spent = 0
    },

    stats = {
        deaths = 0
    },

    instance = {
        initialized = false,
        inInstance = false,
        instanceID = nil,
        name = nil,
        type = nil
    },
    recoveredHistory = {
        initialized = false,

        capturedAt = nil,

        level = nil,

        completedQuests = {
            count = 0,
            questIDs = {}
        },

        played = {
            total = nil,
            currentLevel = nil
        },

        professions = {},

        money = {
            current = nil
        }
    }
}