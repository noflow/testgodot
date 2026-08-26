# Character Content Authoring Guide

Status: version 1 development format

All content unique to a major character stays in that character's `.character`
file. Save games store changing runtime state and never rewrite the source package.

## Package sections

- `profile`, `home`, `personality`, `schedule`, and `skills` define simulation data.
- `home_routine` maps free activity blocks to rooms, actor positions, and activities.
- `ambient_dialogue` supplies short contextual lines for non-story interactions.
- `relationship_defaults` supplies new-game meter values.
- `dating_preferences` supplies invitation difficulty, preferred activities,
  acceptable agreements, NPC-initiated agreement behavior, openness response, and
  character-specific conflict lines.
- `relationship_chapters` identifies the five major relationship arcs.
- `quests` contains complete quest definitions owned by the character.
- `conversations` contains complete dialogue graphs owned by the character.
- `text_messages` contains authored phone-message threads and contextual replies.
- `outcomes` lists durable character endings or state transitions.
- `asset_refs` owns portrait poses, voices, and character-specific audio. Walking
  sprites are not used by the Godot VN presentation.

Quest, conversation, message, outcome, sprite, and audio sections may be empty. This
lets a character ship before every later chapter is written while keeping the
package forward-compatible. The portrait list is the exception: every major
character requires a `default` entry so all VN encounters have a safe visual.

Every major character currently declares a `default` portrait object with a
`res://` path. Add other expressions or poses as uniquely named portrait objects,
then request one from a conversation node with `"portrait": "smile"`. A node may
also request a room-art variant with `"background_variant": "night"`. Complete
paths, sizing, fallbacks, and the no-code import workflow are documented in
`docs/VN_ART_ASSET_PLAYBOOK.md`.

## Global economy authoring

Economy rules remain declarative. Add stores and stock to `systems/stores.json`, and
put account limits, payment priority, tax exemptions, recurring rules, withholding,
and budget categories in `systems/economy.json`. Runtime code resolves item prices
from the item package, so store content references item ids rather than repeating
prices. Education tuition and background-specific aid awards live in
`systems/education.json`.

## Global education authoring

Westshore remains data-driven. Programs reference ordered first-semester course
IDs; courses declare subject skills, difficulty, sections, and an optional lab.
Institution dates and the allowed Morning, Lunch, and Afternoon teaching blocks
live beside the catalog. `academic_rules` owns grade-component weights, attendance
grace, assignment and exam cadence, player effort choices, passing thresholds, and
academic-standing consequences. Runtime assessment and grade records belong only
to the save and must never be authored back into the course catalog.

Each enrolled course currently receives the common assessment pattern from
`assessment_calendar`: three assignments, one semester project, a midterm placed
into a real class event, and a final placed in exam week. Adding a course therefore
requires no phone or engine changes as long as its ID, skills, difficulty, and at
least one section are valid.

## Quest structure

Each quest has an ID unique within its package, a category, title, summary,
discovery policy, activation rules, optional requirements, ordered objectives,
branches, rewards, failure behavior, and
completion effects. Objectives use declarative events such as
`conversation_completed`, `visit_location`, `obtain_item`, and `calendar_reached`.

The default timing mode is `open_ended`. Do not add a deadline simply because a
quest touches money, school, work, or an opening-calendar day. Ordinary costs,
schedules, attendance, and NPC availability continue through their own simulation
systems. An open-ended quest can remain active across weeks, seasons, birthdays,
and years without failure.

Use a timed quest only when its `timing.mode` is `institutional_window`,
`scheduled_commitment`, `emergency`, or `short_lived_opportunity`. The deadline and
narrative reason must be visible before acceptance, reminders are required, and
expiration must branch or delay play rather than end the game. Keep timed quests
below the 15% authoring target.

Preferred gates are attributes, skills, relationship state, prior choices,
locations, life direction, resources, and world state. Quest branches may activate
follow-up paths. Major lockouts must be explained, and failure should normally
change later content rather than end the game. Full discovery and deadline rules
are in `docs/SANDBOX_QUEST_PLAYBOOK.md` and
`content/systems/quest_progression.json`.

Every quest declares `discovery.policy` as `offer` or `auto_start` and a registered
`discovery.source`. `offer` is the normal side-story behavior. Use `auto_start` only
when the player has already committed through the opening, a tutorial action, or a
direct branch choice. Requirements are an array of declarative gates. For example:

```json
{
  "discovery": {"policy": "offer", "source": "world_exploration"},
  "requirements": [
    {"type": "attribute", "id": "health", "minimum": 20, "visibility": "visible", "description": "Health 20 or higher is required."},
    {"type": "prior_choice", "path": "player.flags.met_trainer", "equals": true, "visibility": "hidden"}
  ]
}
```

Visible descriptions must tell the player how to qualify. Hidden requirements must
not include spoiler text. The runtime reevaluates known gates when relevant state
changes and whenever the Quests app opens.

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

The quest engine starts discovered quests, completes objectives, selects branches from runtime
values, applies branch-specific household rules, starts linked quests, and exposes
active quest definitions and progress to the phone UI. Tracking is an independent,
player-controlled presentation choice and does not affect progression. Elena's opening scene is the
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

Romance eligibility and orientation determine whether the male protagonist can
offer a date. NPC fixed commitments and destination opening hours determine valid
times. Keep reusable activity costs, duration, locations, approaches, agreement
rules, and chapter diligence in `content/systems/relationships.json`; keep a
character's emotional voice and preferences in that character's package.

## Validation

Run `python3 tools/validate_characters.py`. The validator checks package identity,
ages, meter and skill ranges, five relationship levels, schedules, unique quest and
conversation IDs, valid dialogue links, valid start nodes, dating preference and
agreement values, date activity timing, and valid character connections.
