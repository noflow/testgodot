# Character Content Authoring Guide

Status: version 1 development format

All content unique to a major character stays in that character's `.character`
file. Save games store changing runtime state and never rewrite the source package.

## Package sections

- `profile`, `home`, `personality`, `schedule`, and `skills` define simulation data.
- `home_routine` maps free activity blocks to rooms, actor positions, and activities.
- `ambient_dialogue` supplies short contextual lines for non-story interactions.
- `relationship_defaults` supplies new-game meter values.
- `relationship_chapters` identifies the five major relationship arcs.
- `quests` contains complete quest definitions owned by the character.
- `conversations` contains complete dialogue graphs owned by the character.
- `text_messages` contains authored phone-message threads and contextual replies.
- `outcomes` lists durable character endings or state transitions.
- `asset_refs` points to portraits, sprites, voices, and character-specific audio.

An empty section is valid. This lets a character ship before every later chapter is
written while keeping the package forward-compatible.

## Global economy authoring

Economy rules remain declarative. Add stores and stock to `systems/stores.json`, and
put account limits, payment priority, tax exemptions, recurring rules, withholding,
and budget categories in `systems/economy.json`. Runtime code resolves item prices
from the item package, so store content references item ids rather than repeating
prices. Education tuition and background-specific aid awards live in
`systems/education.json`.

## Quest structure

Each quest has an ID unique within its package, a category, title, summary,
activation rules, ordered objectives, branches, rewards, failure behavior, and
completion effects. Objectives use declarative events such as
`conversation_completed`, `visit_location`, `obtain_item`, and `calendar_reached`.

Quest branches may activate other quests. Failure should normally change later
content rather than end the game.

## Conversation structure

A conversation is a directed graph. It contains:

- `id`, `type`, and `start_node`
- activation conditions and repetition rules
- nodes keyed by unique node IDs
- speaker and line text, or a stage direction
- optional choices, conditions, effects, and next-node links
- completion effects and memories

Player choices carry one or more tone tags. Effects are declarative operations such
as `add_meter`, `set_flag`, `set_value`, `start_quest`, `schedule_event`, or
`complete_objective`. Content packages contain no executable scripts.

Line tokens use braces, for example `{player_first_name}`. A later localization
pass will replace raw text with localization keys without changing graph logic.

## Runtime implementation

The Godot dialogue engine now loads these graphs directly, filters conditional
choices, resolves player-name tokens, applies node and choice effects atomically,
records history and seen nodes, and preserves the active node for save/resume.
Once-only conversations receive a durable completion flag.

The quest engine starts quests, completes objectives, selects branches from runtime
values, applies branch-specific household rules, starts linked quests, and exposes
active quest definitions and progress to the phone UI. Elena's opening scene is the
first complete production path through both engines.

Quest objectives now respond directly to their authored completion events. Current
city-facing events include `location_discovered`, `location_entered`,
`npc_encounter_started`, `conversation_node_reached`, `conversation_completed`,
`value_set`, `calendar_events_created`, `job_board_opened`,
`job_listings_viewed`, `job_applications_submitted`, `job_interview_completed`,
`employment_contract_accepted`, `compatible_employment_contract_accepted`, and
`activity_completed`. When the last objective completes,
the quest engine applies its branch and completion effects automatically.

Employment runtime actions use the registered `employment.shift`,
`economy.payday`, and `employment.promote_or_raise` operations. Add job-specific
advancement to `promotion_path`; each step may require performance, one skill, or
professional reputation. Global clock-in grace, work-approach modifiers, probation,
raise ranges, and review timing live in `employment_rules` rather than phone code.

Room actions owned by an institution or location live in
`content/systems/city_interactions.json`. A city interaction names its location and
rooms, declares whether it starts an authored conversation or an atomic activity,
and may provide requirements, simulation operations, state updates, and quest
events. This keeps the city scene generic and makes additional locations importable
without adding location-specific UI code.

Character quests using `activation.event: quest_completed` are synchronized after
their prerequisite quest finishes. An optional `earliest_block` delays activation
until the authored point in the day. The household schedule resolver checks fixed
commitments before `home_routine`, updates live NPC locations, and only spawns an
actor when a room and position are available. Fixed commitments should include a
registered `location`; at-home commitments may also define `home_placement`.

The phone engine reads each known contact's `text_messages` directly from that
character package. A message has a unique `id`, a declarative `trigger`, its sender,
authored text, and optional `quick_replies`. Supported opening triggers include
`sandbox_activated`, `quest_started`, `objective_completed`, `hours_after_quest`,
and `hours_before_calendar_event`. Quick replies may use tone tags and declarative
relationship, quest, or calendar-scheduler effects. Runtime threads deduplicate
messages by ID, so opening the phone repeatedly never redelivers the same text.

## Relationship safety

Family members and ineligible characters explicitly block player romance. Adult
content remains non-graphic. A conversation cannot bypass a hard limit, an explicit
refusal, or the rule that severely intoxicated characters cannot consent.

## Validation

Run `python3 tools/validate_characters.py`. The validator checks package identity,
ages, meter and skill ranges, five relationship levels, schedules, unique quest and
conversation IDs, valid dialogue links, valid start nodes, and valid character
connections.
