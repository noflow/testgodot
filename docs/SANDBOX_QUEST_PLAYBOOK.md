# Sandbox Quest Playbook

Port Alder is a life sandbox, not a week-by-week campaign. The calendar simulates
time, schedules, school, work, appointments, seasons, and consequences; it does not
assign a weekly checklist. After the opening conversation, the player is free to
explore the city, build a routine, meet people, and discover stories in any order.

## Core rules

- Every quest is open-ended unless its data explicitly declares a supported timing mode.
- Advancing days, weeks, birthdays, or years never fails an open-ended quest.
- Quests appear only after the player discovers them through play.
- Side quests become offers and do not enter the active log until accepted.
- The player chooses which discovered active quests to pin in the tracker.
- Untracked quests keep their state and can be resumed later without a penalty.
- Stats, skills, relationships, locations, resources, life direction, and prior
  choices are the normal progression gates.
- A quest may start or reveal a follow-up path, but there is no global chapter
  selector and no weekly assignment screen.

The machine-readable rules live in `content/systems/quest_progression.json`.

## Quest state flow

An undiscovered quest is hidden and has no persisted list entry. An in-world trigger
moves it to `discovered`. If every authored gate is met, an optional quest also
enters `available`; Accept moves it to `active`. Postpone removes the offer but keeps
the quest discovered and records it in `postponed` until the player chooses
Reconsider. Decline moves it to `deferred`. Completion and authored failure move an
active quest to their terminal lists.

`auto_start` is reserved for the opening scene, onboarding tutorials, choices the
player already committed to, and direct consequences of a branch. All other quests
use the default `offer` policy. Discovery and decision histories retain the source,
date, and player decision in the save.

## Discovery

A quest can be discovered by entering a location, speaking to an NPC, receiving a
message, reading a job or college board, completing an activity, obtaining an item,
experiencing a health or relationship event, or following an earlier quest branch.
Undiscovered content must not appear in the phone tracker or reveal private NPC
information.

Discovery should feel natural. A gym storyline begins by visiting the gym or
meeting someone connected to it. A career path may appear after reading a listing,
building a relevant skill, or gaining a professional contact. Relationship arcs
should emerge from time spent with that person, not from choosing their route on a
menu.

## Counted repeatable quests

A quest may represent a habit or recurring obligation that advances only after
several valid runs. Add a `repeatable` object with a target of at least two:

```json
"repeatable": {
  "target_completions": 5,
  "progress_label": "Forge workouts",
  "cooldown_blocks": 1,
  "restart_policy": "auto_start",
  "chain_id": "rachel_training_path",
  "stage": 1
}
```

The runtime stores each quest's counter and completion history independently, so
many chains can be in progress at once. A nonfinal completion increments the
counter, resets that run's objectives, and leaves the quest nonterminal. The next
run starts or becomes an offer only after its cooldown and every ordinary authored
requirement are satisfied again. `restart_policy` may be `offer` or `auto_start`;
automatic restart is appropriate only when the player already committed to the
recurring path.

Ordinary `completion_effects`, branches, and `quest_completed` follow-ups run only
when the target is reached. Effects meant to occur after every valid run belong in
`repeatable.each_completion_effects`. The phone and tracked HUD show the saved
counter as `current/target`, including `0/5`, and a final `5/5` remains visible in
completed history. Rachel's `build_a_training_rhythm` and
`consistency_under_pressure` quests are the first two-stage example.

## Gates and paths

Gates should produce possibilities rather than busywork. Authors may require:

- An attribute or skill threshold
- A friendship, love, trust, or relationship-chapter threshold
- A prior choice, promise, dating agreement, or quest branch
- Discovery, access, an invitation, or residence at a location
- Enrollment, employment, housing, relationship, or family state
- Money, an item, transportation, or suitable housing
- A season, semester phase, NPC schedule, or other world state

When a gate is unmet, the game should explain the requirement when the player could
reasonably know it. Major path lockouts must be clearly communicated, and an
alternate route should exist where it fits the story. Earlier choices may change a
scene, open a new chain, close an incompatible branch, or cause an NPC to remember
what happened.

Gate entries use a `type`, type-specific identifier or path, optional `minimum`,
`maximum`, `equals`, or `values`, and `visibility`. Visible failures show their
authored `description`. Hidden failures reveal only that more world context is
needed, preventing spoilers. Supported runtime evaluators cover attributes, skills,
relationship meters or levels, prior state choices, quest status, locations, life
direction, money, inventory items, and world state.

## Deadlines

Timed quests are exceptional. A deadline is allowed only for an institutional
window, a scheduled commitment, an emergency, or a genuinely short-lived
opportunity. The deadline and its narrative reason must be visible before the
player commits, with reminders before expiration. Silent expiration is forbidden.

Missing a deadline should normally delay, redirect, or branch the story. It must
not end the whole game. Rent, bills, hunger, work attendance, school assessments,
and NPC schedules remain real simulation pressures, but those systems do not turn
every related open quest into a countdown. As an authoring target, no more than 15%
of available quests should be timed.

Westshore fall registration is currently the only opening quest with a quest-level
deadline. Finding employment is open-ended; household rent and living costs still
continue independently if the player chose that direction.

## Tracker behavior

The phone lists available offers, gated or postponed discoveries, active quests,
completed quests, deferred quests, and failed quests. Offers expose Accept,
Postpone, and Decline; postponed quests expose Reconsider. Each active quest has a
Track or Untrack action. The HUD shortcut shows only the quests the player
deliberately pinned and gives no judgment when nothing is tracked.
Calendar entries are appointments and commitments, never system-assigned weekly
goals.

## Authoring checklist

Before adding a quest:

1. Choose discovery, opportunity, path, or urgent as its purpose.
2. Define the in-world discovery source and use `offer` unless automatic start is justified.
3. Prefer meaningful, reusable gates and consequences over elapsed-time checks.
4. If it is timed, declare a supported timing mode, visible reason, and warnings.
5. Make failure branch, delay, or alter later content where possible.
6. Test that months of unrelated sandbox play cannot expire an open-ended quest.
7. Test that follow-ups respect prior choices and do not reveal themselves early.
8. For a counted quest, test every counter increment, objective reset, cooldown,
   requirement recheck, final effects, next-stage unlock, and save/load round trip.
