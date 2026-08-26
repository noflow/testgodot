# Runtime and Save Architecture

## Core principle

Authored content and changing state remain separate.

- `.character` and global content packages are read-only definitions.
- Runtime state records what has changed in the current life.
- A save never rewrites an original character, quest, conversation, job, or item.
- Starting defaults are copied or resolved when a new game is created.

This separation lets us add characters and content without damaging existing saves.

## Implementation status

Godot now loads and indexes every global JSON package and `.character` file during
boot. Content can be retrieved by package or typed ID, including characters,
districts, locations, quests, conversations, items, jobs, courses, programs,
activities, and stores.

The new-game state factory deep-copies the authored template, applies identity,
appearance, and trait choices, resolves the selected financial background and
inventory loadout, generates hidden health and fertility profiles from a recorded
seed, imports opening weather, initializes all fifteen relationships, and records
the loaded content manifest. The resulting state contains no unresolved template
tokens and is held by the `GameState` autoload without modifying source content.
Character creation now validates the protagonist's age against the fixed opening
date, applies exactly three positive and three challenging trait modifiers, stores
three core values, one archetype, two hobbies, and all six appearance choices, and
resolves the selected financial background before this state becomes active.

The first simulation processor now applies atomic time, need, attribute, skill,
reputation, relationship, economy, inventory, quest, travel, and map-unlock events.
Rejected events leave the prior snapshot unchanged. Successful events receive a
monotonic sequence and game timestamp and enter the bounded event log. The clock
supports both minute-based short actions and full activity blocks, with real month
lengths, weekdays, four seasons, and daily, weekly, and monthly tick markers.

The Hale home composes those operations into atomic player actions. Showering,
sleeping, eating, drinking, cooking, and laundry advance time and update needs or
skills only when every required step succeeds. Food, water, and detergent come from
named household containers. Failed multi-step actions do not consume supplies,
advance time, or leave partial events. Clothing carries condition and cleanliness,
and the wardrobe equips only owned items into their declared slots.

The phone is also state-backed. New games create one persistent thread per known
contact. Triggered character texts are synchronized from `.character` packages and
deduplicated by authored message ID. Replies, unread state, relationship effects,
quest effects, and their five-minute time cost use atomic simulation events.
Calendar plans validate dates, blocks, known participants, and fixed NPC work or
school commitments. Required work/class/interview/exam overlaps are rejected; optional
overlaps are preserved with explicit conflict records. Weather advances from the
authored opening-week forecast whenever the game date changes.

Travel is state-backed as an atomic begin/complete pair. Planning is read-only;
confirmation records a pending trip only in the working transaction, then validates
the arrival room, advances exact minutes, charges the selected account, discovers
the destination, clears pending state, and stores a compact `last_trip` summary.
If any completion step fails, neither event is committed by `TravelService`.

`EconomyService` catches up each elapsed due date through idempotent recurring
records. It composes ledger transactions, relationship consequences, debt accrual,
weekly summaries, store pricing, payment splits, receipts, and inventory delivery
without mutating authored economy or store packages. A purchase is committed only
after both storage capacity and complete purchasing power validate.

`EducationService` initializes assessments from the enrolled course schedule and
synchronizes every required academic event against the live clock. It records each
class attendance result and assessment result exactly once, closes overdue events,
recalculates component-weighted grades, and updates semester phase and academic
standing. Studying, class participation, coursework, and exams compose registered
time, need, skill, attendance, and grade operations before committing a new state.
The save retains course sections, preparation, attendance history, assessment
results, credits, registration holds, and immutable semester summaries.

SaveService now provides eight confirmed-overwrite manual slots, three
oldest-first rotating autosaves, one quicksave, quickload, and Continue from the
newest valid compatible snapshot. The main menu lists validated saves; the phone
Settings app can create and load them without a separate pause scene. Slot summaries
show the protagonist, game date and block, location, available money, education,
employment, playtime, build, and recovery state. Loading resumes an active VN node
or routes to the saved home/city scene. F5 and F9 provide scene-independent
quicksave and quickload controls, including during VN conversations.

## Runtime state

The root state contains:

- Metadata and content versions
- Calendar, season, semester phase, activity block, and time within the block
- Player identity, appearance, traits, needs, attributes, skills, and reputation
- Health, reproductive health, education, employment, money, inventory, and housing
- Phone apps, contacts, messages, quests, and calendar
- One runtime entry for every persistent NPC
- Relationship meters, agreements, memories, and relationship chapters
- Quest, conversation, world, household, pregnancy, child, and custody state
- Pending simulation events and a bounded recent event log
- The exact base-game and mod content manifest used by the save

The new-game template initializes all fifteen opening NPCs so their schedules and
independent lives can progress before the player meets them. Hidden health and
fertility values are generated at game creation but remain unknown to the player.

## Simulation events

Changes flow through declarative events rather than arbitrary content scripts. An
event has a monotonically increasing sequence, game timestamp, operation, source,
payload, and optional target, cause, random seed, and transaction ID.

The initial registry covers time, needs, attributes, skills, relationships,
memories, quests, conversations, calendars, travel, money, inventory, health,
alcohol, fertility, pregnancy, birth, education, employment, weather, stores, and
daily, weekly, and monthly processing.

Each event follows this order:

1. Validate the request and all references.
2. Reserve and record any random result.
3. Apply all related state changes atomically.
4. Append the event to the recent log.
5. Emit notifications and follow-up events.
6. Create a checkpoint when required.

If any atomic change fails, the entire transaction rolls back. Saving waits for a
transaction to finish or roll back.

## Save strategy

Saves use a state snapshot plus the latest 500 simulation events. Older events are
summarized into histories and counters. This preserves useful debugging and story
context without allowing files to grow forever.

The game provides eight manual slots, three rotating autosaves, and one quicksave.
Autosaves occur at day boundaries and around major scenes, quest completions,
relationship agreements, enrollment, employment, pregnancy, and birth changes.

Conversations and travel can be saved safely because their current node or remaining
trip state is recorded explicitly.

## Safe writing and recovery

Godot writes to `user://saves`. A save is first written and validated as a
temporary file. The current save becomes a backup only after the temporary file is
valid, and the temporary file then atomically replaces it.

Each file carries a SHA-256 checksum. Loading tries the primary file, its backup,
and then another save when Continue searches newest-first. An unreadable primary is
preserved under a quarantine filename before a later replacement. Unrecoverable
files are reported but never silently deleted.

## Versions and migrations

The initial save format is version 1. The implemented version-zero baseline
migration establishes version-one metadata and content state, preserves the
version-zero source as the slot backup, validates the migrated temporary file, and
only then replaces the primary. Migrations move forward exactly one version at a
time, preserve unknown fields, log their work, and never replace the original if
migration fails. Downgrading a save is unsupported.

Runtime validation covers required state sections, clock ranges, need and
relationship ranges, the 0–250 skill scale, pending transactions, the 500-event
limit, checksum integrity, and required loaded package IDs. Automated runtime probes
disable autosave so validation runs cannot touch a player's real slots.

Every save records the checksum, version, requirement status, and load order of each
base-game and mod package. Missing required content blocks loading with a useful
error. Missing optional content may be disabled only when its package declares that
the save can continue safely.

## Privacy

Save files remain local unless the player exports them. Exports warn that saves may
contain private health, fertility, relationship, and family simulation state.

## Source data

- `content/runtime/new_game_state.json`
- `content/systems/simulation_events.json`
- `content/systems/save_system.json`
- `schemas/save_game.schema.json`
