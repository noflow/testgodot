# Relationship, Social Activity, and Dating Playbook

Status: first playable milestone

## Player loop

The Relationships phone app lists every known contact. A contact detail view shows
the four primary meters, eight supporting variables, current stage, agreement,
completed dates, conflict history, and the latest unlocked chapter.

For an eligible adult romantic interest, the player can choose an activity and one
of the next valid times. Invitations respect the NPC's fixed work, school, and
personal schedule; location hours; the player's required class, work, exam, and
interview commitments; and any date already scheduled with that NPC. Sending an
invitation consumes five minutes and stores both sides of the exchange in the
character's phone thread.

The same contact view offers non-romantic social plans to every known adult
contact, including friends and family. Waterfront hangouts, café catch-ups,
movies, Galleria browsing, and Undertow outings use the NPC's real schedule and
the player's calendar. A hangout never silently becomes a date. At the scheduled
room and time, the player chooses whether to listen, keep things playful, or open
up personally. Activities at undiscovered destinations remain hidden until the
player unlocks that part of the city.

An accepted invitation becomes a calendar event. The player must arrive at the
activity's exact room during its scheduled block. The phone can open the route
planner for that destination. Beginning the date charges its cost, completes the
calendar event, advances time, changes needs, and applies the chosen approach:

- Attentive emphasizes Trust, Respect, Love, and Comfort.
- Playful emphasizes Friendship, Comfort, and Attraction.
- Flirty requires greater Comfort and emphasizes Attraction and Lust.

Cancelling early has a small Trust cost. Cancelling with little notice has a larger
consequence. Passing the scheduled block without attending resolves the plan as a
no-show and reduces Trust, Satisfaction, and Reliability while increasing
Resentment.

## Progression

Each major character retains five authored `relationship_chapters`. Dates and
completed hangouts both count as shared activity. A chapter unlocks only after
its configured combination of shared activities, bond, and Trust. Levels four
and five also require an active agreement when the relationship is following a
romantic route; family and friendship routes never require a dating agreement.
This due-diligence gate prevents meter grinding alone from skipping stories.

Unlocking a chapter places a visible story-arc milestone in the Relationships app
instead of forcing a scene immediately. The player chooses when to begin it. If
the chapter id matches an authored character quest, beginning the milestone starts
that quest; otherwise it remains a durable hook for a later Screenwriter export.

A completed date changes the stage to `dating`. After at least two completed dates
and sufficient Trust, either side may discuss an agreement. The first milestone
implements casual dating, exclusivity, and open relationships. Agreement changes
require mutual acknowledgment and are retained in both current state and agreement
history.

## Other partners and witnessed dates

When another relationship is active, the player chooses whether to disclose a new
date. The phone warns about exclusivity violations, disclosure requirements, and
undefined expectations without preventing the player from making the choice.

Public date activities have a deterministic witness chance so a save produces the
same result when replayed. A witness response combines the current agreement,
whether the date was disclosed, the NPC's Jealousy, and their openness preference.
Possible outcomes include approval, amusement, accepted jealousy, confrontation,
loss of Trust, or ending the relationship. The result and authored reaction line
remain in conflict history.

## Data ownership

Reusable rules live in `content/systems/relationships.json`:

- relationship-level thresholds and chapter diligence;
- agreement definitions;
- approaches and meter effects;
- date activities, rooms, times, duration, costs, and witness chance; and
- invitation and conflict tuning;
- social activities, approaches, and friendship-invitation tuning; and
- shared-activity requirements for five player-paced story milestones.

Character-specific behavior stays in the character's single `.character` file.
The optional `dating_preferences` object owns invitation threshold, favorite date
activities, acceptable agreement types, an NPC-initiated agreement preference,
conflict style, openness response, and authored reaction lines. Characters without
this section receive safe defaults derived from their existing boundaries and
Jealousy personality value.

Characters may also define an optional `social_preferences` object with an
`invitation_threshold` and `preferred_activities`. Missing preferences use safe
global defaults, so existing and modded character files remain compatible.

Runtime histories and agreements belong to the save state. Source character files
are never rewritten during play, which keeps new character packages importable and
mod-friendly.

Social invitation history, completed/cancelled/missed hangouts, pending
milestones, and milestone history are also save-owned. Old saves receive these
collections during relationship synchronization.

## Safety and scope

Only romance-eligible adults compatible with the male protagonist's gender can be
invited. Family relationships never expose romantic actions. This milestone covers
dating, agreements, and non-graphic emotional consequences; later partnership,
engagement, marriage, co-parenting, intimacy, sexual-health, and breakup-repair
systems will extend the same state rather than bypass it.
