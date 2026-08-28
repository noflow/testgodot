# District Exploration Playbook

Port Alder exploration uses Ren'Py-style room choices rather than walking sprites.
An outdoor room may expose a `Look Around` choice beside its directional arrows.
The choice consumes time, selects one authored outcome from the current context,
and may save a lead, phone notification, or optional quest offer.

## Content format

Exploration choices live in `content/systems/city_interactions.json` with
`type: "exploration"`. Each choice declares its location, rooms, and ordered
outcomes. Outcomes use a numeric priority; the highest-priority eligible outcome
wins.

```json
{
  "id": "explore_example_square",
  "name": "Look Around Example Square",
  "type": "exploration",
  "location": "example_square",
  "rooms": ["main_corner"],
  "outcomes": [
    {
      "id": "first_orientation",
      "priority": 100,
      "once_only": true,
      "summary": "The player-facing VN result.",
      "operations": [],
      "leads": [],
      "notification": {},
      "quest_events": []
    },
    {
      "id": "ordinary_visit",
      "priority": 0,
      "summary": "The fallback result.",
      "operations": []
    }
  ]
}
```

Supported outcome requirements are activity blocks, weather conditions, a required
or forbidden player flag, a minimum skill level, and a selected positive trait.
Every exploration choice should include a priority-zero fallback so it remains
usable when no special context matches.

## Persistence and phone presentation

`world_state.exploration` saves three independent collections:

- `completed_outcomes` prevents one-time results from replaying.
- `discovered_leads` stores unique public clues for City Map notes.
- `history` records the latest 100 exploration results with location and time.

Notifications are written to `player.phone.notifications`. The Notifications app
shows unread discoveries and can mark them read. City Map shows the eight newest
local leads. Repeating an exploration can add history and skill experience without
duplicating one-time leads or notices.

## Quest and privacy rules

Exploration may emit quest events, but ordinary discovery quests use the `offer`
policy. The player must accept them in the Quest app before objectives begin.
Exploration can describe public streets, institutions, shops, and transit routes.
It must never reveal a private residence, bedroom, or restricted room unless a
separate quest, invitation, relationship permission, or housing agreement grants
that access.

## Alder Heights reference slice

The first implementation includes Hale Block, the Neighborhood Corner, and the
Alder Heights Bus Shelter. First visits save public leads; repeat visits respond to
time of day and rain. The repeatable Alder Heights Loop provides a low-intensity
neighborhood activity. `Get to Know Alder Heights` is offered after the first Hale
Block exploration and remains inactive until the player accepts it.
