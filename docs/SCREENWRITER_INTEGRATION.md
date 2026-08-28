# Screenwriter Integration Contract

Port Alder treats each `.character` file as the canonical package for one major NPC.
Screenwriter is an authoring client for those packages; Godot remains responsible for
runtime state, saves, quests, relationships, schedules, and phone delivery.

## Export choice

Use **Port Alder sheets** when moving authored work into the game. Do not import
Screenwriter's flattened `scenewright.v3` Godot JSON or its standalone dialogue
director into this project. Those files describe an alternative runtime and would
split persistent state between two systems.

Keep exported files in a staging directory until both checks pass:

```sh
python3 tools/validate_screenwriter_export.py /path/to/exported-sheets
python3 tools/validate_characters.py
```

For a no-edit import/export test, require an exact semantic round trip:

```sh
python3 tools/validate_screenwriter_export.py /path/to/exported-sheets --exact
```

The integration-contract check allows conversations and quests to be edited, but it
rejects lost `discovery`, `requirements`, `availability`, `repeatable`, or `timing`
metadata on existing quests. This protects sandbox discovery and counted quest chains
from being erased by an authoring round trip.

## Conversation contract

Godot directly supports Screenwriter's named-node conversation graph:

- `choices` are shown to the player after their conditions pass.
- `branches` are automatic gates; the first matching branch is followed without
  showing a blank dialogue node. Put an unconditional fallback last.
- Conversation `activation.day` and `activation.days` use lowercase weekdays.
- Conversation-level `condition` gates the entire scene.
- `completion_effects` run once before the conversation is closed.
- Unknown condition keys fail closed, keeping unfinished or modded gates locked.

Supported imported conditions are flags, exact state values, money minimums,
relationship meter minimum/maximum/equality, custom character-stat minimum/maximum,
relationship chapters, memories, and completed/met state events.

Screenwriter effects supported by dialogue include relationship meters, flags and
values, quests and objectives, phone-app unlocks, location discoveries, memories,
relationship chapters, custom character stats, player attributes or needs, calendar
events, and explicit character-activity completion.

## Runtime ownership

Authored defaults belong in `.character` files. Mutable values belong in saves:

- relationship memories and custom character stats live with relationship state;
- explicit activity success lives in `conversation_state.activity_progress`;
- activity counter keys are mirrored into player flags for authored conditions;
- the simulation engine still clamps player attributes and needs to their game ranges.

Phone-message delivery and the full activity/milestone picker are later bridge phases.
Until those phases land, character sheets may safely contain the authored data, but
the game will not yet expose every Screenwriter phone or activity workflow.
