
local addonName, FJ = ...

-- Forever Journey 0.8.0: non-destructive chapter restoration for FJBACKUP1.
-- The existing Backup.lua still owns encoding, checksum and memory merging.
-- Load after Backup.lua (preferably after Chapters.lua).

FJ.ChaptersBackup = {}

local Backup = FJ.Backup
local MAX_CHAPTERS = 512
local MAX_SEQUENCE = 1000000000000
local PREFIX = "FJBACKUP1:"

-- Read only chapter metadata from an already validated FJBACKUP1 payload.
-- All other fields (including potentially huge memory lists) are skipped.
-- This is not a second backup format or an alternate import validator.
local function ReadLength(text, position)
    local colon = text:find(":", position, true)
    if not colon then return nil end
    local length = tonumber(text:sub(position, colon - 1))
    if not length or length < 0 then return nil end
    return length, colon + 1
end

local function DecodeSelected(text, position, depth, mode)
    if depth > 32 or position > #text then return nil, nil end

    local tag = text:sub(position, position)
    position = position + 1

    if tag == "N" then
        return nil, position
    elseif tag == "B" then
        local bit = text:sub(position, position)
        if bit ~= "0" and bit ~= "1" then return nil, nil end
        if not mode then return nil, position + 1 end
        return bit == "1", position + 1
    elseif tag == "S" or tag == "D" then
        local length, start = ReadLength(text, position)
        if not start then return nil, nil end
        local finish = start + length
        if finish > #text + 1 then return nil, nil end
        if not mode then return nil, finish end
        local raw = text:sub(start, finish - 1)
        if tag == "D" then return tonumber(raw), finish end
        return raw, finish
    elseif tag ~= "T" then
        return nil, nil
    end

    local count, nextPosition = ReadLength(text, position)
    if not count or count > 100000 then return nil, nil end
    local output = mode and {} or nil

    for _ = 1, count do
        local key
        key, nextPosition = DecodeSelected(text, nextPosition, depth + 1, true)
        if nextPosition == nil or key == nil then return nil, nil end

        local childMode = false
        if mode == true then
            childMode = true
        elseif mode == "root" and key == "character" then
            childMode = "character"
        elseif mode == "character" and (
            key == "chapters"
            or key == "chapterSequence"
            or key == "activeChapterID"
        ) then
            childMode = true
        end

        local value
        value, nextPosition = DecodeSelected(
            text, nextPosition, depth + 1, childMode
        )
        if nextPosition == nil then return nil, nil end
        if childMode then output[key] = value end
    end

    return output, nextPosition
end

local function ExtractChapters(exportText)
    if type(exportText) ~= "string"
        or exportText:sub(1, #PREFIX) ~= PREFIX then
        return nil
    end

    -- FJBACKUP1: + 8 checksum characters + ':' + payload.
    local payload = exportText:sub(#PREFIX + 10)
    local root, position = DecodeSelected(payload, 1, 0, "root")
    if not root or position ~= #payload + 1
        or type(root.character) ~= "table" then
        return nil
    end
    return root.character
end

local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do
        result[Copy(key)] = Copy(item)
    end
    return result
end

local function Sequence(value)
    local number = tonumber(value)
    if not number or number ~= number
        or number < 0 or number > MAX_SEQUENCE then
        return 0
    end
    return math.floor(number)
end

local function SequenceFromID(value)
    if type(value) ~= "string" or #value > 20 then
        return 0
    end
    local suffix = value:match("^c:(%d+)$")
    return suffix and Sequence(suffix) or 0
end

local function ValidChapter(chapter)
    if type(chapter) ~= "table"
        or SequenceFromID(chapter.id) < 1
        or type(chapter.title) ~= "string"
        or #chapter.title == 0 or #chapter.title > 160
        or (chapter.description ~= nil
            and (type(chapter.description) ~= "string"
                or #chapter.description > 1200)) then
        return false
    end

    local start = chapter.startedAt
    if type(start) ~= "number" or start ~= start
        or start < 0 or start > MAX_SEQUENCE
        or math.floor(start) ~= start then
        return false
    end

    local finish = chapter.closedAt
    return finish == nil or (
        type(finish) == "number" and finish == finish
        and finish >= start and finish <= MAX_SEQUENCE
        and math.floor(finish) == finish
    )
end

-- Same merge algorithm for preview and actual restore.
-- Build the result independently, and commit only when apply = true.
local function Merge(target, source, apply)
    local result = {
        added = 0,
        duplicates = 0,
        conflicts = 0,
        skipped = 0
    }

    if type(source.chapters) ~= "table" then return result end

    local current = type(target.chapters) == "table"
        and target.chapters or {}
    local previousCount = #current
    local merged, used = {}, {}
    local sequence = math.max(
        Sequence(target.chapterSequence),
        Sequence(source.chapterSequence)
    )

    for _, chapter in ipairs(current) do
        if type(chapter) == "table" then
            merged[#merged + 1] = Copy(chapter)
            if type(chapter.id) == "string" then
                used[chapter.id] = true
                sequence = math.max(sequence, SequenceFromID(chapter.id))
            end
        end
    end

    for _, chapter in ipairs(source.chapters) do
        if type(chapter) == "table" then
            sequence = math.max(sequence, SequenceFromID(chapter.id))
        end
    end

    local importedIDs = {}

    for index, incoming in ipairs(source.chapters) do
        if index > MAX_CHAPTERS or not ValidChapter(incoming) then
            result.skipped = result.skipped + 1
        else
            local matching
            for _, existing in ipairs(merged) do
                if existing.startedAt == incoming.startedAt
                    and (existing.id == incoming.id
                        or existing.importedChapterID == incoming.id) then
                    matching = existing
                    break
                end
            end

            if matching then
                importedIDs[incoming.id] = matching.id
                result.duplicates = result.duplicates + 1
            elseif #merged >= MAX_CHAPTERS then
                result.skipped = result.skipped + 1
            else
                local copy = Copy(incoming)

                if used[copy.id] then
                    result.conflicts = result.conflicts + 1
                    copy.importedChapterID = incoming.id
                    repeat
                        sequence = sequence + 1
                        copy.id = "c:" .. sequence
                    until not used[copy.id]
                end

                used[copy.id] = true
                importedIDs[incoming.id] = copy.id
                merged[#merged + 1] = copy
                result.added = result.added + 1
            end
        end
    end

    -- FindForTimestamp expects chronological order in character.chapters.
    -- Tie-breaking preserves the original order of equal-second chapters.
    local sorted = {}
    for index, chapter in ipairs(merged) do
        sorted[index] = { value = chapter, index = index }
    end
    table.sort(sorted, function(a, b)
        local left = tonumber(a.value.startedAt) or 0
        local right = tonumber(b.value.startedAt) or 0
        if left == right then return a.index < b.index end
        return left < right
    end)
    for index, item in ipairs(sorted) do
        merged[index] = item.value
    end

    local activeID = target.activeChapterID
    local validActive = false
    for _, chapter in ipairs(merged) do
        if chapter.id == activeID and chapter.closedAt == nil then
            validActive = true
            break
        end
    end
    if not validActive then activeID = nil end

    -- Restore backup's active chapter only for a fresh local chapter list.
    if not activeID and previousCount == 0 then
        local importedActive = importedIDs[source.activeChapterID]
        for _, chapter in ipairs(merged) do
            if chapter.id == importedActive and chapter.closedAt == nil then
                activeID = importedActive
                break
            end
        end
    end

    if apply then
        target.chapters = merged
        target.chapterSequence = sequence
        target.activeChapterID = activeID
    end

    return result
end

local originalPlan = Backup.BuildImportPlan
local originalMerge = Backup.ImportMerge

function Backup.BuildImportPlan(text)
    local plan, err = originalPlan(text)
    if not plan then return nil, err end

    local source = ExtractChapters(text)
    if not source then return nil, "CHAPTER_BACKUP_PARSE_FAILED" end

    local details = Merge(FJ.Storage.character or {}, source, false)
    plan.newChapters = details.added
    plan.duplicateChapters = details.duplicates
    plan.conflictedChapters = details.conflicts
    plan.skippedChapters = details.skipped
    return plan, nil
end

function Backup.ImportMerge(text)
    -- Validate before modifying any data.
    local valid, errorCode = Backup.ValidateExport(text)
    if not valid then return false, errorCode, nil end

    local source = ExtractChapters(text)
    if not source then return false, "CHAPTER_BACKUP_PARSE_FAILED", nil end

    local success, err, details = originalMerge(text)
    if not success then return success, err, details end

    local chapters = Merge(FJ.Storage.character, source, true)
    details = details or {}
    details.addedChapters = chapters.added
    details.duplicateChapters = chapters.duplicates
    details.conflictedChapters = chapters.conflicts
    details.skippedChapters = chapters.skipped
    details.totalChapters = #(FJ.Storage.character.chapters or {})

    if chapters.added > 0 and FJ.UI
        and type(FJ.UI.RefreshIfVisible) == "function" then
        FJ.UI.RefreshIfVisible()
    end

    return true, nil, details
end
