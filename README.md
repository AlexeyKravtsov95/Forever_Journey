
# Forever Journey

**Forever Journey** is a personal character journal for **World of Warcraft: Forever**.

Instead of being another statistics dashboard, Forever Journey records the story of your character: places discovered, levels reached, quests completed, professions developed, deaths encountered, personal memories, and other meaningful moments along the way.

## Help Shape Forever Journey

Forever Journey is a personal project, and your feedback can help shape its future.

**What moments from your character's journey would you love to remember?**

If you have tried the addon, please share what you liked or what could be improved in the CurseForge comments.

## Features

### Overview

A compact summary of your current journey:

- Character portrait, race, class, and level
- Total played time
- Completed quests from game statistics when available
- Current money
- Lifetime deaths from game statistics (with a local fallback)
- Total recorded events
- Chronicle start date
- Recent journey events

### Chronicle

A chronological journal of recorded events.

Events are grouped by date and can include:

- Level ups
- New zone discoveries
- Dungeon and instance entries
- Boss victories
- Deaths
- Quest milestones
- Learned professions
- Profession skill milestones
- Manual memories created by the player

Chronicle also supports:

- Favorite stars on memories
- Editing and deleting manual memories
- Multi-select filtering by event type
- Favorites-only filtering
- Combining Favorites with one or more event-type filters
- Text search by memory title, description, and location, including combinations with existing filters
- Personal notes on automatically recorded events, with a note preview and editor

### Chapters of Your Life (0.8.0)

Create your own chapters to turn Chronicle events into a personal story. Each chapter has a title, an optional description, a start time, and an optional closing time.

- Open **Chapters** in Chronicle to create, rename, describe, or close a chapter. Creating a new chapter closes the previously active one.
- Newly recorded events are automatically assigned to the active chapter.
- Open a memory and choose **Change Chapter** to assign it to any existing chapter, including a closed one.
- Choose **By Date** to restore automatic assignment based on the chapter's time interval, or **Outside Chapters** to keep the memory out of every chapter.
- Memories recorded before the chapter feature remain intact; no historical events are fabricated or rewritten.
- Chapter assignments and descriptions persist in SavedVariables. Chronicle remains chronological even if you manually assign an older memory to a newer chapter.

The chapter picker uses the same parchment reader, with up to eight chapters per page. This feature is available in English and Russian.

### Manual Memories

You can add your own memories directly from the Chronicle.

A manual memory contains:

- A title
- An optional note
- The current date and time
- The current location

Manual memories can be edited or deleted later. Automatically recorded event details remain unchanged, but you can attach, edit, or clear a personal note on an automatic memory.

### Personal Notes for Recorded Events

Add your own commentary to an automatically recorded Chronicle moment without changing its original time, place, or event details.

- Select **+ Note** on an event to write a comment.
- After saving, use **My Note** to read or edit it; hover to see its text.
- Clear and save an empty note to remove just the personal commentary.
- Personal notes are saved with the memory and included in full-character backups.

## Favorites

Any Chronicle memory can be marked as a favorite.

Favorite state is persistent and is used by:

- The Favorites-only Chronicle filter
- The Memorable Moments section in History

### History

A retrospective view of your character's journey.

Depending on when Forever Journey was installed, History can contain:

- Recovered character state from before the journal started
- First recorded discoveries
- Level milestones
- Quest milestones
- Profession milestones
- Memorable Moments selected with favorite stars
- Journey summary

## Recovered History

Forever Journey does **not** invent historical dates.

If the addon is installed on an existing character, it can recover information that is still available through the game API, such as:

- Current level
- Completed quest count
- Played time
- Money
- Professions

This information is displayed as a recovered snapshot rather than as fabricated historical events.

From the moment Forever Journey starts recording, new events are stored normally in the Chronicle.

If the addon is installed on a new character, the History begins naturally from the start without creating a recovered archive.

## Quest Milestones

Forever Journey records quest milestones every 50 completed quests:

- 50
- 100
- 150
- 200
- and so on

Milestones that were already passed before the addon started recording are not recreated retroactively.

## Profession Tracking

Forever Journey records:

- Newly learned professions
- Profession skill milestones every 75 skill points

Existing professions at the moment the journal starts are treated as part of the character baseline and do not generate fake historical events.

## Boss Victories

Forever Journey records successful boss encounters from the moment this version starts tracking them.

A boss victory stores the boss, instance, difficulty, and group-size context exposed by the client. Rapid duplicate notifications for the same encounter are suppressed so a single kill does not create duplicate Chronicle entries.

Boss victories are available as a dedicated Chronicle filter and can also be marked as favorites.

## Death Memories

Deaths are recorded as part of your journey.

When the client exposes additional Death Recap information, Forever Journey can enrich a death memory with details such as:

- Killer
- Ability or spell
- Damage information
- Environmental cause

Supported environmental causes can include:

- Falling
- Drowning
- Fatigue
- Fire
- Lava
- Slime

Available detail depends on the information provided by the game client.

## Journey Statistics

The **Statistics** action on Overview opens a journal subpage with lifetime values reported by the game: total deaths, quests completed, enemies defeated, honorable kills, flights, hearthstone uses, falling deaths and deaths caused by other players. These aggregate values can remain available after reinstalling WoW because they come from the game statistics API; they do not reconstruct the timestamps or locations of historical events.

## Book Creator

Open **Chronicle > Export Book**, select the `FJBOOK1` code, and copy it using **Ctrl+C**. Paste the code into **https://journal.mythweld.com/** to preview your character's journal and create a PDF book.

- The book export includes recorded memories, chapter metadata, and explicit chapter assignments.
- The website groups older journals without authored chapters by month. With authored chapters, it uses the player's chapter names and descriptions.
- **Only chapters with assigned memories appear as authored sections** in the current Book Creator. Empty chapters remain saved in the addon and included in the export but are hidden in the book.
- An exported book is **not** a restorable backup and cannot replace your WoW SavedVariables files.

## Backup and Restore

The **Data** action on Overview opens the backup page.

**Create a backup:**

1. Open **Data > Export**. Generate or refresh the backup, then select all of the export text and press **Ctrl+C**.
2. Paste the complete text into a UTF-8 `.txt` file saved **outside the WoW installation and its `WTF` folder**.
3. Keep the file somewhere safe (ideally also in another location or backup service).

**Restore a backup:**

1. Open **Data > Import**. Copy the previously saved backup text from the `.txt` file and paste it with **Ctrl+V**.
2. Use **Validate Backup** to check the version, checksum and character key, and inspect how many new and duplicate records will be imported.
3. Press **Restore Data**, then **Confirm Restore**. Existing memories are preserved; new memories are merged by stable memory ID.
4. Run **`/reload`** or log out normally so the restored SavedVariables are written to disk.

**Important:** Forever Journey cannot automatically create a file outside the WoW sandbox. Its normal `SavedVariables` file is stored under `WTF/Account/.../SavedVariables/ForeverJourney.lua` and **will be lost if that directory is deleted without a backup**. Export manually after meaningful Chronicle changes and before reinstalling or moving the game. A backup is scoped to the same realm/character identity.

**Chapter backup limitation in 0.8.0-rc.1:** the in-game text backup still exports character data, but its restore operation does **not** restore or merge chapter metadata. `ChaptersBackup.lua` is intentionally not loaded because conflict handling for chapter IDs is not yet safe. Imported memories may retain a `chapterId` that no longer resolves, or that refers to a different chapter if IDs collide. **Do not rely on Data > Restore to recover chapter structure or assignments.** Before reinstalling or moving WoW, keep a separate copy of `WTF/Account/.../SavedVariables/ForeverJourney.lua` with the game closed. Full chapter-aware backup restoration is deferred.

## Minimap Launcher

Forever Journey adds a small journal launcher around the minimap.

- **Left Click** — open or close the journal
- **Drag** — move the launcher around the minimap

The launcher position is saved between sessions.

## Slash Commands

Open or close the journal:

    /fj open

## Saved Data

Forever Journey uses WoW SavedVariables.

Journey data:

- Persists between game sessions
- Is stored separately for each character
- Survives `/reload`
- Survives a full client restart

Manual memories, favorite state, chapter metadata, and explicit memory-to-chapter assignments are stored in the existing schema v3.

## Localization

Currently supported:

- English
- Russian

## Compatibility

Designed for:

- **World of Warcraft: Forever**
- Client: `1.60.1` (Forever)
- Interface: `16001`

## Version

Current release candidate:

    0.8.0-rc.1

## Beta Status

Forever Journey is actively being developed for World of Warcraft: Forever. It focuses on preserving meaningful moments from a character's journey without turning the journal into a combat-statistics dashboard.

Player feedback helps guide future improvements.

## Known Limitations

- Exact chronology from before addon installation cannot be reconstructed when the game API does not expose it.
- Recovered History is therefore a snapshot, not a fabricated timeline.
- Quest milestones already passed before recording began are not recreated retroactively.
- Existing professions are treated as baseline history.
- Profession milestone tracking begins after the profession baseline has been established.
- Detailed Death Recap information depends on client API availability.
- Previously recorded NPC names are preserved as historical data and may remain in the client language in which they were originally captured.
- Boss victories are recorded forward-only from live encounter events; earlier boss kills are not reconstructed.
- Reputation records only standing-rank increases; individual reputation gains are intentionally ignored.
- Manual text backup is required to preserve detailed Chronicle events across deletion of the WoW `WTF` directory. For full chapter preservation in this release candidate, back up the original SavedVariables file as well.
- Chapter-aware restoration from in-game text backups is deferred; chapters and assignments must not be assumed to survive that restore operation.
- Book Creator currently hides authored chapters with no assigned memories.

## Feedback

What moments would you like Forever Journey to remember? Bug reports, compatibility issues, and suggestions are welcome in the CurseForge comments.
