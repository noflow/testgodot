# Screenwriter Integration Contract

Port Alder treats each `.character` file as the canonical package for one major NPC.
Screenwriter is an authoring client for those packages; Godot remains responsible for
runtime state, saves, quests, relationships, schedules, and phone delivery.

## Export choice

Use **Port Alder sheets** when moving authored work into the game. Do not import
Screenwriter's flattened `scenewright.v3` Godot JSON or its standalone dialogue
graph/export formats into this project. Use the Scene Director inside the normal
Screenwriter project and export the edited `.character` sheets. The alternate files
describe a separate runtime and would
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

## VN presentation contract

The Scene Director writes optional scene defaults to `conversation.presentation`:

```json
"presentation": {
  "transition": "fade",
  "music": "quiet_piano",
  "ambience": "cafe_room_tone",
  "notes": "Keep the camera intimate."
}
```

Each dialogue node may override `portrait`, `expression`, `background_variant`,
`position`, `transition`, `music`, `ambience`, or `sfx`. Position accepts `left`,
`center`, `right`, and `offstage`; transitions accept `cut`, `fade`, `dissolve`,
`wipe_left`, and `wipe_right`. Unspecified node fields inherit the scene default.
Reduced-motion or disabled screen effects turn animated transitions into immediate
cuts without changing authored data.

Audio cue ids resolve first from the speaking character's `asset_refs.audio`, then
from the global `vn_audio` manifest in `content/presentation/vn_art.json`. A direct
`res://` audio path is also accepted. `none`, `stop`, or `silence` stops a continuous
cue. Missing optional audio is recorded as unresolved and never blocks dialogue.

## Runtime ownership

Authored defaults belong in `.character` files. Mutable values belong in saves:

- relationship memories and custom character stats live with relationship state;
- explicit activity success lives in `conversation_state.activity_progress`;
- activity counter keys are mirrored into player flags for authored conditions;
- the simulation engine still clamps player attributes and needs to their game ranges.

## Phone contract

The Messages app supports Screenwriter's incoming and player-authored outgoing
directions. An incoming message may use `introduces_contact` to create its contact and
thread at delivery time. Outgoing messages appear as **Send** actions only while their
triggers and conditions pass, and one-shot messages cannot be sent twice.

Message triggers include sandbox activation, quests and objectives, calendar timing,
weekdays, activity blocks, flags, relationship meters, sent messages, any reply to a
message, and a specific stable reply ID. Message and reply conditions fail closed.
Sending or replying consumes five in-game minutes and then synchronizes immediate
follow-up messages.

Phone effects can adjust relationship meters; start, advance, complete, defer, or fail
quests; set flags and game values; and open calendar scheduling or rescheduling. Text
events also feed the quest engine as `text_sent`, `text_replied`, and
`text_thread_completed` events.

## Relationship story milestones

Each character's existing five-entry `relationship_chapters` list is the stable
bridge between Screenwriter and relationship progression. The game combines dates
and non-romantic hangouts into shared-activity due diligence, then exposes the next
authored chapter as a player-controlled story arc. When a chapter `id` matches a
quest in that character file, beginning the milestone starts the quest. A chapter
without a matching quest can receive its scene chain later without changing save
identity.

An optional character-level `social_preferences` object can tune generic hangouts:

```json
{
  "social_preferences": {
    "invitation_threshold": 24,
    "preferred_activities": ["cafe_catchup", "waterfront_hangout"]
  }
}
```

Social activity ids are reusable system content. Screenwriter owns character
preference and story content; Godot owns scheduling, costs, time, outcomes, and
save persistence.
