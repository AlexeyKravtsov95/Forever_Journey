local addonName, FJ = ...

local locale =
    GetLocale()

local translations = {
    enUS = {
        ADDON_TITLE =
            "FOREVER JOURNEY",

        ADDON_SUBTITLE =
            "Your adventure, remembered.",

        JOURNEY_SO_FAR =
            "JOURNEY SO FAR",

        RECENT_JOURNEY =
            "RECENT JOURNEY",

        RECENT_JOURNEY_SUBTITLE =
            "The latest moments recorded along your path.",

        EMPTY_JOURNEY =
            "Your recorded journey will appear here.",

        LEVEL =
            "LEVEL",

        TIME_PLAYED =
            "TIME PLAYED",

        QUESTS =
            "QUESTS",

        MONEY =
            "MONEY",

        DEATHS =
            "DEATHS",

        MEMORIES =
            "MEMORIES",

        JOURNEY_BEGAN =
            "JOURNEY BEGAN",

        RECORDING_STARTED =
            "CHRONICLE BEGAN",

        HISTORY_BEFORE_RECORDING =
            "BEFORE THE JOURNAL",

        HISTORY_BEFORE_RECORDING_SUBTITLE =
            "What could be recovered from your adventure before Forever Journey began recording it.",

        RECOVERED_SNAPSHOT =
            "ARCHIVAL ENTRY",

        RECOVERED_CAPTURED_AT =
            "Recovered from character data - %s",

        RECOVERED_CHARACTER =
            "CHARACTER AT THAT MOMENT",

        RECOVERED_LEVEL =
            "LEVEL",

        RECOVERED_TIME_PLAYED =
            "TIME ALREADY PLAYED",

        RECOVERED_QUESTS =
            "QUESTS ALREADY COMPLETED",

        RECOVERED_MONEY =
            "MONEY AT SNAPSHOT",

        RECOVERED_PROFESSIONS =
            "PROFESSIONS",

        RECOVERED_NO_PROFESSIONS =
            "No professions could be recovered.",

        RECOVERED_DATES_UNKNOWN =
            "Exact dates for these earlier milestones are unknown.",

        RECOVERED_KNOWN_PAST =
            "WHAT WE KNOW OF THE PAST",

        RECOVERED_SUMMARY_LEVEL =
            "LEVEL REACHED",

        RECOVERED_SUMMARY_QUESTS =
            "QUESTS COMPLETED",

        RECOVERED_SUMMARY_PLAYED =
            "TIME ON THE JOURNEY",

        RECOVERED_FOOTNOTE =
            "Exact dates are unknown. Forever Journey records precise events from the moment the journal begins.",

        TIME_DAY_SHORT =
            "d",

        TIME_HOUR_SHORT =
            "h",

        TIME_MINUTE_SHORT =
            "m",

        MONEY_GOLD_SHORT =
            "g",

        MONEY_SILVER_SHORT =
            "s",

        MONEY_COPPER_SHORT =
            "c",

        RECOVERED_EMPTY =
            "Recovered history is not available yet.",

        OVERVIEW =
            "OVERVIEW",

        TIMELINE =
            "TIMELINE",

        CHRONICLE_TITLE =
            "JOURNEY CHRONICLE",

        CHRONICLE_SUBTITLE =
            "Every moment recorded since the chronicle began.",

        CHRONICLE_EMPTY =
            "No recorded events yet.",

        CHRONICLE_UNKNOWN_DATE =
            "UNKNOWN DATE",

        CHRONICLE_ADD_MEMORY =
            "+ ADD MEMORY",

        MEMORY_FAVORITE =
            "Add to favorites",

        MEMORY_UNFAVORITE =
            "Remove from favorites",

        MANUAL_MEMORY_CREATE_TITLE =
            "ADD A MEMORY",

        MANUAL_MEMORY_EDIT_TITLE =
            "EDIT MEMORY",

        MANUAL_MEMORY_TITLE_LABEL =
            "TITLE",

        MANUAL_MEMORY_NOTE_LABEL =
            "NOTE",

        MANUAL_MEMORY_AUTO_CAPTURE =
            "Date, time and location are recorded automatically.",

        MANUAL_MEMORY_SAVE =
            "SAVE",

        MANUAL_MEMORY_CANCEL =
            "CANCEL",

        MANUAL_MEMORY_EDIT =
            "EDIT",

        MANUAL_MEMORY_DELETE =
            "DELETE",

        MANUAL_MEMORY_TITLE_REQUIRED =
            "Give this memory a title.",

        MANUAL_MEMORY_SAVE_FAILED =
            "The memory could not be saved.",

        MANUAL_MEMORY_DELETE_TITLE =
            "DELETE MEMORY",

        MANUAL_MEMORY_DELETE_CONFIRM =
            "Delete \"%s\"? This memory will be permanently removed.",

        MANUAL_MEMORY_DELETE_FAILED =
            "The memory could not be deleted.",

        HISTORY =
            "HISTORY",

        MEMORY_TYPE_LEVEL =
            "LEVEL",

        MEMORY_TYPE_ZONE =
            "DISCOVERY",

        MEMORY_TYPE_INSTANCE =
            "INSTANCE",

        MEMORY_TYPE_DEATH =
            "DEATH",

        MEMORY_TYPE_RECOVERED =
            "RECOVERED ENTRY",

        MEMORY_TITLE_LEVEL =
            "Reached Level %d",

        MEMORY_TITLE_ZONE =
            "Discovered %s",

        MEMORY_TITLE_INSTANCE =
            "Entered %s",

        MEMORY_TITLE_DEATH =
            "Fell in battle",

        MEMORY_TITLE_DEATH_KILLER =
            "Fell in battle — %s",

        MEMORY_TITLE_DEATH_FALLING =
            "Died from a fall",

        MEMORY_TITLE_DEATH_DROWNING =
            "Drowned",

        MEMORY_TITLE_DEATH_FATIGUE =
            "Succumbed to exhaustion",

        MEMORY_TITLE_DEATH_FIRE =
            "Perished in fire",

        MEMORY_TITLE_DEATH_LAVA =
            "Perished in lava",

        MEMORY_TITLE_DEATH_SLIME =
            "Perished in slime",

        MEMORY_TITLE_DEATH_ENVIRONMENT =
            "Lost to the environment",

        MEMORY_DESCRIPTION_LEVEL =
            "Your journey continues.",

        MEMORY_DESCRIPTION_ZONE =
            "A new place became part of your journey.",

        MEMORY_DESCRIPTION_INSTANCE =
            "Another chapter of your journey lies within.",

        MEMORY_DESCRIPTION_DEATH =
            "Every journey has its setbacks.",

        MEMORY_DESCRIPTION_DEATH_SPELL =
            "Final blow: %s.",

        MINIMAP_TOOLTIP_OPEN =
            "Open your journey journal",

        MINIMAP_TOOLTIP_CLICK =
            "Left Click - open or close",

        MINIMAP_TOOLTIP_DRAG =
            "Drag to move the launcher",

        UNKNOWN =
            "Unknown",

        UNKNOWN_TIME =
            "Unknown time"
    },

    ruRU = {
        ADDON_TITLE =
            "FOREVER JOURNEY",

        ADDON_SUBTITLE =
            "Твоё приключение. Твоя история.",

        JOURNEY_SO_FAR =
            "ПУТЬ К ЭТОМУ МОМЕНТУ",

        RECENT_JOURNEY =
            "ПОСЛЕДНИЕ СОБЫТИЯ",

        RECENT_JOURNEY_SUBTITLE =
            "Последние моменты твоего путешествия.",

        EMPTY_JOURNEY =
            "Здесь появятся события твоего путешествия.",

        LEVEL =
            "УРОВЕНЬ",

        TIME_PLAYED =
            "ВРЕМЯ В ИГРЕ",

        QUESTS =
            "ЗАДАНИЯ",

        MONEY =
            "МОНЕТЫ",

        DEATHS =
            "СМЕРТИ",

        MEMORIES =
            "СОБЫТИЯ",

        JOURNEY_BEGAN =
            "НАЧАЛО ПУТИ",

        RECORDING_STARTED =
            "НАЧАЛО ХРОНИКИ",

        HISTORY_BEFORE_RECORDING =
            "ДО НАЧАЛА ЗАПИСИ",

        HISTORY_BEFORE_RECORDING_SUBTITLE =
            "То, что удалось восстановить о приключении до того, как Forever Journey начал вести хронику.",

        RECOVERED_SNAPSHOT =
            "АРХИВНАЯ ЗАПИСЬ",

        RECOVERED_CAPTURED_AT =
            "Восстановлено по данным персонажа - %s",

        RECOVERED_CHARACTER =
            "ПЕРСОНАЖ В ТОТ МОМЕНТ",

        RECOVERED_LEVEL =
            "УРОВЕНЬ",

        RECOVERED_TIME_PLAYED =
            "УЖЕ ПРОВЕДЕНО В ИГРЕ",

        RECOVERED_QUESTS =
            "УЖЕ ВЫПОЛНЕНО ЗАДАНИЙ",

        RECOVERED_MONEY =
            "МОНЕТЫ НА МОМЕНТ СНИМКА",

        RECOVERED_PROFESSIONS =
            "ПРОФЕССИИ",

        RECOVERED_NO_PROFESSIONS =
            "Профессии восстановить не удалось.",

        RECOVERED_DATES_UNKNOWN =
            "Точные даты этих ранних этапов неизвестны.",

        RECOVERED_KNOWN_PAST =
            "ЧТО МЫ ЗНАЕМ О ПРОШЛОМ",

        RECOVERED_SUMMARY_LEVEL =
            "ДОСТИГНУТЫЙ УРОВЕНЬ",

        RECOVERED_SUMMARY_QUESTS =
            "ВЫПОЛНЕНО ЗАДАНИЙ",

        RECOVERED_SUMMARY_PLAYED =
            "ВРЕМЕНИ В ПУТИ",

        RECOVERED_FOOTNOTE =
            "Точные даты неизвестны. С момента начала записи Forever Journey ведёт точную хронику.",

        TIME_DAY_SHORT =
            "д",

        TIME_HOUR_SHORT =
            "ч",

        TIME_MINUTE_SHORT =
            "м",

        MONEY_GOLD_SHORT =
            "з",

        MONEY_SILVER_SHORT =
            "с",

        MONEY_COPPER_SHORT =
            "м",

        RECOVERED_EMPTY =
            "Восстановленная история пока недоступна.",

        OVERVIEW =
            "ОБЗОР",

        TIMELINE =
            "ХРОНИКА",

        CHRONICLE_TITLE =
            "ХРОНИКА ПУТЕШЕСТВИЯ",

        CHRONICLE_SUBTITLE =
            "Все события, записанные с момента начала хроники.",

        CHRONICLE_EMPTY =
            "Записанных событий пока нет.",

        CHRONICLE_UNKNOWN_DATE =
            "ДАТА НЕИЗВЕСТНА",

        CHRONICLE_ADD_MEMORY =
            "+ ДОБАВИТЬ",

        MEMORY_FAVORITE =
            "Добавить в избранное",

        MEMORY_UNFAVORITE =
            "Убрать из избранного",

        MANUAL_MEMORY_CREATE_TITLE =
            "ДОБАВИТЬ ВОСПОМИНАНИЕ",

        MANUAL_MEMORY_EDIT_TITLE =
            "РЕДАКТИРОВАТЬ ВОСПОМИНАНИЕ",

        MANUAL_MEMORY_TITLE_LABEL =
            "ЗАГОЛОВОК",

        MANUAL_MEMORY_NOTE_LABEL =
            "ЗАМЕТКА",

        MANUAL_MEMORY_AUTO_CAPTURE =
            "Дата, время и локация записываются автоматически.",

        MANUAL_MEMORY_SAVE =
            "СОХРАНИТЬ",

        MANUAL_MEMORY_CANCEL =
            "ОТМЕНА",

        MANUAL_MEMORY_EDIT =
            "ИЗМЕНИТЬ",

        MANUAL_MEMORY_DELETE =
            "УДАЛИТЬ",

        MANUAL_MEMORY_TITLE_REQUIRED =
            "Укажи заголовок воспоминания.",

        MANUAL_MEMORY_SAVE_FAILED =
            "Не удалось сохранить воспоминание.",

        MANUAL_MEMORY_DELETE_TITLE =
            "УДАЛИТЬ ВОСПОМИНАНИЕ",

        MANUAL_MEMORY_DELETE_CONFIRM =
            "Удалить \"%s\"? Это воспоминание будет удалено навсегда.",

        MANUAL_MEMORY_DELETE_FAILED =
            "Не удалось удалить воспоминание.",

        HISTORY =
            "ИСТОРИЯ",

        MEMORY_TYPE_LEVEL =
            "УРОВЕНЬ",

        MEMORY_TYPE_ZONE =
            "ОТКРЫТИЕ",

        MEMORY_TYPE_INSTANCE =
            "ПОДЗЕМЕЛЬЕ",

        MEMORY_TYPE_DEATH =
            "СМЕРТЬ",

        MEMORY_TYPE_RECOVERED =
            "ВОССТАНОВЛЕНО",

        MEMORY_TITLE_LEVEL =
            "Уровень повышен до %d",

        MEMORY_TITLE_ZONE =
            "Открыта локация: %s",

        MEMORY_TITLE_INSTANCE =
            "Вход в подземелье: %s",

        MEMORY_TITLE_DEATH =
            "Пал в бою",

        MEMORY_TITLE_DEATH_KILLER =
            "Пал в бою — %s",

        MEMORY_TITLE_DEATH_FALLING =
            "Погиб при падении",

        MEMORY_TITLE_DEATH_DROWNING =
            "Утонул",

        MEMORY_TITLE_DEATH_FATIGUE =
            "Погиб от истощения",

        MEMORY_TITLE_DEATH_FIRE =
            "Погиб в огне",

        MEMORY_TITLE_DEATH_LAVA =
            "Погиб в лаве",

        MEMORY_TITLE_DEATH_SLIME =
            "Погиб в слизи",

        MEMORY_TITLE_DEATH_ENVIRONMENT =
            "Погиб из-за окружения",

        MEMORY_DESCRIPTION_LEVEL =
            "Путешествие продолжается.",

        MEMORY_DESCRIPTION_ZONE =
            "Новое место стало частью твоего пути.",

        MEMORY_DESCRIPTION_INSTANCE =
            "Впереди ещё одна глава путешествия.",

        MEMORY_DESCRIPTION_DEATH =
            "Даже поражения становятся частью истории.",

        MEMORY_DESCRIPTION_DEATH_SPELL =
            "Последний удар: %s.",

        MINIMAP_TOOLTIP_OPEN =
            "Открыть журнал путешествия",

        MINIMAP_TOOLTIP_CLICK =
            "ЛКМ - открыть или закрыть",

        MINIMAP_TOOLTIP_DRAG =
            "Перетащите, чтобы переместить иконку",

        UNKNOWN =
            "Неизвестно",

        UNKNOWN_TIME =
            "Время неизвестно"
    }
}

local fallback =
    translations.enUS

local current =
    translations[locale]
    or fallback

FJ.Locale = {}

function FJ.Locale.Get(key)
    return current[key]
        or fallback[key]
        or key
end

function FJ.Locale.Format(key, ...)
    local template =
        FJ.Locale.Get(key)

    local success,
        result = pcall(
            string.format,
            template,
            ...
        )

    if success then
        return result
    end

    return template
end

function FJ.Locale.GetLocale()
    return locale
end