local addonName, FJ = ...

FJ.Events = {}

local eventFrame =
    CreateFrame("Frame")

FJ.Events.Frame = eventFrame

eventFrame:RegisterEvent(
    "ADDON_LOADED"
)

eventFrame:RegisterEvent(
    "PLAYER_ENTERING_WORLD"
)

eventFrame:RegisterEvent(
    "PLAYER_LEVEL_UP"
)

eventFrame:RegisterEvent(
    "ZONE_CHANGED_NEW_AREA"
)

eventFrame:RegisterEvent(
    "QUEST_DATA_LOAD_RESULT"
)

eventFrame:RegisterEvent(
    "TIME_PLAYED_MSG"
)

eventFrame:RegisterEvent(
    "PLAYER_MONEY"
)

eventFrame:RegisterEvent(
    "PLAYER_DEAD"
)

eventFrame:SetScript(
    "OnEvent",
    function(self, event, ...)

        if event == "ADDON_LOADED" then
            local loadedAddonName = ...

            if loadedAddonName
                == addonName then

                FJ.Initialize()
            end

        elseif event
            == "PLAYER_ENTERING_WORLD" then

            FJ.Journey
                .HandlePlayerEnteringWorld()
            
            FJ.UI.RefreshIfVisible()

        elseif event
            == "PLAYER_LEVEL_UP" then

            local newLevel = ...

            FJ.Journey
                .HandleLevelUp(
                    newLevel
                )
            FJ.UI.RefreshIfVisible()

        elseif event
            == "ZONE_CHANGED_NEW_AREA" then

            FJ.Journey
                .TrackCurrentZone(true)
            FJ.UI.RefreshIfVisible()

        elseif event
            == "QUEST_DATA_LOAD_RESULT" then

            local questID,
                success = ...

            FJ.Recovery
                .HandleQuestDataLoaded(
                    questID,
                    success
                )
            FJ.UI.RefreshIfVisible()

        elseif event
            == "TIME_PLAYED_MSG" then

            local totalTimePlayed,
                timePlayedThisLevel = ...

            FJ.Journey
                .HandleTimePlayed(
                    totalTimePlayed,
                    timePlayedThisLevel
                )
            FJ.UI.RefreshIfVisible()

        elseif event
            == "PLAYER_MONEY" then

            FJ.Journey
                .HandleMoneyChanged()
            FJ.UI.RefreshIfVisible()

        elseif event
            == "PLAYER_DEAD" then

            FJ.Journey
                .HandlePlayerDeath()
        
            FJ.UI.RefreshIfVisible()
        end
    end
)