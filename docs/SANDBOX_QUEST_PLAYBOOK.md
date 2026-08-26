# Sandbox Quest Playbook

Port Alder is a life sandbox, not a week-by-week campaign. The calendar simulates
time, schedules, school, work, appointments, seasons, and consequences; it does not
assign a weekly checklist. After the opening conversation, the player is free to
explore the city, build a routine, meet people, and discover stories in any order.

## Core rules

- Every quest is open-ended unless its data explicitly declares a supported timing mode.
- Advancing days, weeks, birthdays, or years never fails an open-ended quest.
- Quests appear only after the player discovers them through play.
- The player chooses which discovered active quests to pin in the tracker.
- Untracked quests keep their state and can be resumed later without a penalty.
- Stats, skills, relationships, locations, resources, life direction, and prior
  choices are the normal progression gates.
- A quest may start or reveal a follow-up path, but there is no global chapter
  selector and no weekly assignment screen.

The machine-readable rules live in `content/systems/quest_progression.json`.

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

The phone lists discovered active, completed, deferred, and failed quests. Each
active quest has a Track or Untrack action. The HUD shortcut shows only the quests
the player deliberately pinned and gives no judgment when nothing is tracked.
Calendar entries are appointments and commitments, never system-assigned weekly
goals.

## Authoring checklist

Before adding a quest:

1. Choose discovery, opportunity, path, or urgent as its purpose.
2. Define the in-world discovery source.
3. Prefer meaningful gates and consequences over elapsed-time checks.
4. If it is timed, declare a supported timing mode, visible reason, and warnings.
5. Make failure branch, delay, or alter later content where possible.
6. Test that months of unrelated sandbox play cannot expire an open-ended quest.
7. Test that follow-ups respect prior choices and do not reveal themselves early.

