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

Godot will write to `user://saves`. A save is first written and validated as a
temporary file. The current save becomes a backup only after the temporary file is
valid, and the temporary file then atomically replaces it.

Each file carries a SHA-256 checksum. Loading tries the primary file, its backup,
and then another autosave. Unrecoverable files are reported but never silently
deleted.

## Versions and migrations

The initial save format is version 1. Migrations move forward exactly one version at
a time, are safe to run more than once, preserve unknown fields, log their work, and
never replace the original if migration fails. Downgrading a save is unsupported.

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
