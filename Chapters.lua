
local addonName, FJ = ...

-- Chapters 0.8.0: chapter metadata and memory membership.
-- Existing memories remain untouched; their time-based assignment is preserved.
-- New memories can store an explicit chapterId without a schema migration.
FJ.Chapters = {}
local Chapters = FJ.Chapters

local MAX_CHAPTERS = 512
local MAX_TITLE_BYTES = 160
local MAX_DESCRIPTION_BYTES = 1200
local isRussian = GetLocale() == "ruRU"

local T = isRussian and {
    help = "Команды: /fjchapter new НАЗВАНИЕ, list, status, rename НАЗВАНИЕ, describe ТЕКСТ, close",
    noCharacter = "Данные персонажа ещё не загружены. Попробуй после входа в мир.",
    titleRequired = "Укажи название главы.",
    titleTooLong = "Название слишком длинное (максимум 160 байт UTF-8).",
    descriptionTooLong = "Описание слишком длинное (максимум 1200 байт UTF-8).",
    limit = "Достигнут предел глав (512).",
    noActive = "Сейчас нет открытой главы. Используй /fjchapter new НАЗВАНИЕ.",
    created = "Новая глава: %s",
    renamed = "Глава переименована: %s",
    described = "Описание главы обновлено: %s",
    closed = "Глава закрыта: %s",
    active = "Текущая глава: %s",
    none = "Глав ещё нет. Создай первую: /fjchapter new НАЗВАНИЕ.",
    listItem = "%d. %s — %s",
    opened = "открыта",
    finished = "закрыта",
    invalid = "Глава не найдена."
} or {
    help = "Commands: /fjchapter new TITLE, list, status, rename TITLE, describe TEXT, close",
    noCharacter = "Character data is not loaded yet. Try again after entering the world.",
    titleRequired = "Enter a chapter title.",
    titleTooLong = "Title is too long (maximum 160 UTF-8 bytes).",
    descriptionTooLong = "Description is too long (maximum 1200 UTF-8 bytes).",
    limit = "Maximum number of chapters reached (512).",
    noActive = "No active chapter. Use /fjchapter new TITLE.",
    created = "New chapter: %s",
    renamed = "Chapter renamed: %s",
    described = "Chapter description updated: %s",
    closed = "Chapter closed: %s",
    active = "Current chapter: %s",
    none = "No chapters yet. Create one: /fjchapter new TITLE.",
    listItem = "%d. %s — %s",
    opened = "open",
    finished = "closed",
    invalid = "Chapter not found."
}

local function Trim(value)
    if type(value) ~= "string" then
        return nil
    end

    local cleaned = value:match("^%s*(.-)%s*$")
    return cleaned or ""
end

local function ValidateTitle(value)
    local title = Trim(value)

    if not title or title == "" then
        return nil, "TITLE_REQUIRED"
    end

    if #title > MAX_TITLE_BYTES then
        return nil, "TITLE_TOO_LONG"
    end

    return title
end

local function ValidateDescription(value)
    if value == nil then
        return ""
    end

    local description = Trim(value)

    if not description then
        return nil, "INVALID_DESCRIPTION"
    end

    if #description > MAX_DESCRIPTION_BYTES then
        return nil, "DESCRIPTION_TOO_LONG"
    end

    return description
end

local function GetCharacter()
    local storage = FJ.Storage
    local character = storage and storage.character

    if type(character) ~= "table" then
        return nil
    end

    return character
end

local function EnsureChapterData()
    local character = GetCharacter()

    if not character then
        return nil, "CHARACTER_NOT_ATTACHED"
    end

    if type(character.chapters) ~= "table" then
        character.chapters = {}
    end

    local sequence = tonumber(character.chapterSequence) or 0
    sequence = math.max(0, math.floor(sequence))

    for _, chapter in ipairs(character.chapters) do
        if type(chapter) == "table"
            and type(chapter.id) == "string" then

            local found = chapter.id:match("^c:(%d+)$")

            if found then
                sequence = math.max(
                    sequence,
                    tonumber(found) or 0
                )
            end
        end
    end

    character.chapterSequence = sequence
    return character
end

local function FindByID(character, chapterID)
    if not character
        or type(chapterID) ~= "string" then
        return nil
    end

    for _, chapter in ipairs(character.chapters) do
        if type(chapter) == "table"
            and chapter.id == chapterID then
            return chapter
        end
    end

    return nil
end

function Chapters.GetAll()
    local character = EnsureChapterData()

    if not character then
        return nil
    end

    return character.chapters
end

function Chapters.GetActive()
    local character = EnsureChapterData()

    if not character then
        return nil
    end

    local chapter = FindByID(
        character,
        character.activeChapterID
    )

    if chapter and chapter.closedAt == nil then
        return chapter
    end

    return nil
end

function Chapters.FindByID(chapterID)
    local character = EnsureChapterData()
    return FindByID(character, chapterID)
end

function Chapters.Create(title, description)
    local validTitle, titleError = ValidateTitle(title)

    if not validTitle then
        return nil, titleError
    end

    local validDescription, descriptionError =
        ValidateDescription(description)

    if not validDescription then
        return nil, descriptionError
    end

    local character, characterError = EnsureChapterData()

    if not character then
        return nil, characterError
    end

    if #character.chapters >= MAX_CHAPTERS then
        return nil, "CHAPTER_LIMIT"
    end

    local now = time()

    local previous = FindByID(
        character,
        character.activeChapterID
    )

    if previous and previous.closedAt == nil then
        previous.closedAt = now
    end

    character.chapterSequence =
        character.chapterSequence + 1

    local chapter = {
        id = "c:" .. character.chapterSequence,
        title = validTitle,
        description = validDescription,
        startedAt = now
    }

    table.insert(character.chapters, chapter)
    character.activeChapterID = chapter.id

    return chapter
end

function Chapters.Rename(chapterID, title)
    local validTitle, err = ValidateTitle(title)

    if not validTitle then
        return nil, err
    end

    local chapter = Chapters.FindByID(chapterID)

    if not chapter then
        return nil, "NOT_FOUND"
    end

    chapter.title = validTitle
    return chapter
end

function Chapters.SetDescription(chapterID, description)
    local validDescription, err =
        ValidateDescription(description)

    if not validDescription then
        return nil, err
    end

    local chapter = Chapters.FindByID(chapterID)

    if not chapter then
        return nil, "NOT_FOUND"
    end

    chapter.description = validDescription
    return chapter
end

function Chapters.Close()
    local character = EnsureChapterData()

    if not character then
        return nil, "CHARACTER_NOT_ATTACHED"
    end

    local chapter = Chapters.GetActive()

    if not chapter then
        return nil, "NO_ACTIVE_CHAPTER"
    end

    chapter.closedAt = time()
    character.activeChapterID = nil

    return chapter
end

-- Historical time-based lookup for memories without explicit membership.
function Chapters.FindForTimestamp(timestamp)
    if type(timestamp) ~= "number" then
        return nil
    end

    local chapters = Chapters.GetAll()

    if not chapters then
        return nil
    end

    for index = #chapters, 1, -1 do
        local chapter = chapters[index]

        if type(chapter) == "table"
            and type(chapter.startedAt) == "number"
            and timestamp >= chapter.startedAt
            and (
                chapter.closedAt == nil
                or timestamp < chapter.closedAt
            ) then

            return chapter
        end
    end

    return nil
end

-- Prefer an explicit assignment over the historical time-based rule.
-- memory.chapterId == false means intentionally outside every chapter.
-- A dangling explicit ID stays unassigned, rather than silently moving
-- a memory into another chapter after backup restoration.
function Chapters.ResolveForMemory(memory)
    if type(memory) ~= "table" then
        return nil
    end

    local raw = type(memory.raw) == "table"
        and memory.raw or memory

    if raw.chapterId == false then
        return nil
    end

    if type(raw.chapterId) == "string" then
        return Chapters.FindByID(raw.chapterId)
    end

    return Chapters.FindForTimestamp(raw.timestamp)
end

-- Public API for the upcoming in-game chapter picker.
-- chapterID: string => explicitly assign (including closed chapters)
-- chapterID: false  => explicitly exclude from all chapters
-- chapterID: nil    => return to automatic timestamp assignment
-- No memory ID, timestamp, event text or schema version is modified.
function Chapters.SetMemoryChapter(memoryID, chapterID)
    if type(memoryID) ~= "string" or memoryID == "" then
        return false, "INVALID_MEMORY_ID"
    end

    if chapterID ~= nil and chapterID ~= false then
        if type(chapterID) ~= "string" then
            return false, "INVALID_CHAPTER_ID"
        end

        if not Chapters.FindByID(chapterID) then
            return false, "NOT_FOUND"
        end
    end

    local memories = FJ.Memories
    local memory = memories
        and type(memories.FindByID) == "function"
        and memories.FindByID(memoryID)

    if not memory then
        return false, "MEMORY_NOT_FOUND"
    end

    if memory.chapterId == chapterID then
        return true, memory
    end

    memory.chapterId = chapterID

    if FJ.UI
        and type(FJ.UI.RefreshIfVisible) == "function" then
        FJ.UI.RefreshIfVisible()
    end

    return true, memory
end

local function Say(message)
    print("Forever Journey: " .. message)
end

local function SayError(err)
    local messages = {
        CHARACTER_NOT_ATTACHED = T.noCharacter,
        TITLE_REQUIRED = T.titleRequired,
        TITLE_TOO_LONG = T.titleTooLong,
        DESCRIPTION_TOO_LONG = T.descriptionTooLong,
        CHAPTER_LIMIT = T.limit,
        NO_ACTIVE_CHAPTER = T.noActive,
        NOT_FOUND = T.invalid
    }

    Say(messages[err] or tostring(err))
end

SLASH_FJCHAPTER1 = "/fjchapter"

SlashCmdList["FJCHAPTER"] = function(message)
    local command, argument =
        (message or ""):match("^%s*(%S*)%s*(.-)%s*$")

    command = (command or ""):lower()

    if command == "" or command == "help" then
        Say(T.help)
        return
    end

    if command == "new" then
        local chapter, err = Chapters.Create(argument)

        if not chapter then
            SayError(err)
        else
            Say(string.format(T.created, chapter.title))
        end

        return
    end

    if command == "list" then
        local chapters = Chapters.GetAll()

        if not chapters then
            Say(T.noCharacter)
        elseif #chapters == 0 then
            Say(T.none)
        else
            for index, chapter in ipairs(chapters) do
                local status =
                    chapter.closedAt
                    and T.finished
                    or T.opened

                Say(string.format(
                    T.listItem,
                    index,
                    chapter.title,
                    status
                ))
            end
        end

        return
    end

    if command == "status" then
        local chapter = Chapters.GetActive()

        if chapter then
            Say(string.format(T.active, chapter.title))
        else
            Say(T.noActive)
        end

        return
    end

    if command == "close" then
        local chapter, err = Chapters.Close()

        if chapter then
            Say(string.format(T.closed, chapter.title))
        else
            SayError(err)
        end

        return
    end

    if command == "rename" or command == "describe" then
        local active = Chapters.GetActive()

        if not active then
            Say(T.noActive)
            return
        end

        local chapter, err

        if command == "rename" then
            chapter, err = Chapters.Rename(
                active.id,
                argument
            )
        else
            chapter, err = Chapters.SetDescription(
                active.id,
                argument
            )
        end

        if not chapter then
            SayError(err)
        elseif command == "rename" then
            Say(string.format(T.renamed, chapter.title))
        else
            Say(string.format(T.described, chapter.title))
        end

        return
    end

    Say(T.help)
end
