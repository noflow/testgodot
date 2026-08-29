# Port Alder VN Artwork Asset Playbook

Status: implemented foundation  
Engine: Godot 4.7.2  
Presentation: static visual-novel backgrounds and character portraits; no walking sprites

## Runtime behavior

`VNAssetService` resolves artwork for the home sandbox, reusable city locations,
and dialogue screen. Artwork is loaded once and cached by resource path. Missing
optional artwork never breaks a save or conversation: the service uses the declared
fallback background or portrait and preserves the character or room label.

The same service resolves Scene Director music, ambience, and sound-effect cues.
Missing optional audio remains silent without stopping the conversation. Music and
ambience use their independent settings buses; one-shot sound cues use the UI bus.

Room selection itself does not advance time. Artwork changes immediately when the
player selects another room. Dialogue can change portrait poses or background
variants per node without loading a different gameplay scene.

## Background files

Store backgrounds under:

```text
assets/art/backgrounds/<location_id>/<room_id>.webp
```

PNG, JPG, and SVG are also supported. The resolver prefers WebP, PNG, JPG, then SVG
when using the naming convention. Recommended production size is 1920×1080 with
important subjects kept away from the bottom 35%, where the dialogue box appears.

`content/presentation/vn_art.json` can explicitly assign a file:

```json
{
  "id": "alder_bay_park.waterfront_path",
  "location": "alder_bay_park",
  "room": "waterfront_path",
  "path": "res://assets/art/backgrounds/alder_bay_park/waterfront_path.webp",
  "variants": {
    "night": "res://assets/art/backgrounds/alder_bay_park/waterfront_path_night.webp"
  },
  "credit": "Artist name or original-project credit"
}
```

The `id` must be `<location_id>.<room_id>`. A manifest assignment takes priority
over convention-based discovery. A requested variant falls back to `path` when the
variant is not declared.

## Character portraits

Portrait ownership stays inside each character's `.character` file:

```json
"asset_refs": {
  "portraits": [
    {
      "id": "default",
      "path": "res://assets/art/characters/emma_rowan/default.webp",
      "anchor": "center"
    },
    {
      "id": "smile",
      "path": "res://assets/art/characters/emma_rowan/smile.webp",
      "anchor": "center"
    }
  ],
  "sprites": [],
  "audio": []
}
```

Recommended portrait canvas is 900×1600 or a similar tall ratio with a transparent
background. Keep the character's full head and shoulders inside the center 80%.
Every major character requires a `default` portrait. Placeholder portraits may add
an `accent` HTML color; the runtime uses it only when rendering shared fallback art.

For future convention-only portrait discovery, use:

```text
assets/art/characters/<character_id>/<portrait_id>.webp
```

## Dialogue staging and presentation cues

A dialogue node may request artwork declaratively:

```json
{
  "speaker": "emma_rowan",
  "portrait": "smile",
  "expression": "warm",
  "background_variant": "night",
  "position": "right",
  "transition": "dissolve",
  "music": "emma_theme",
  "ambience": "waterfront_evening",
  "sfx": "phone_buzz",
  "line": "I was hoping you might say that.",
  "next": "walk_end"
}
```

All presentation fields are optional. `portrait` defaults to an expression-matched
portrait when one exists, then `default`; `background_variant` defaults to the room's
main background. Narration and player-choice nodes retain the first non-player
participant on stage when possible. Scene defaults may live in the conversation's
`presentation` object, with individual nodes overriding only what changes.

## Audio cues

Global audio belongs in `content/presentation/vn_art.json`:

```json
"vn_audio": [
  {
    "id": "waterfront_evening",
    "path": "res://assets/audio/ambience/waterfront_evening.ogg",
    "bus": "Ambience",
    "loop": true,
    "credit": "Artist or source"
  }
]
```

Character-owned themes or signature sounds may instead use `asset_refs.audio` with
the same `id`, `path`, `bus`, `loop`, and optional `credit` fields. Recommended buses
are `Music`, `Ambience`, and `UI`. Cue ids are stable content identifiers; replacing
the referenced file does not require rewriting conversations.

## Adding a new character

1. Create `characters/<character_id>.character`.
2. Add at least one `asset_refs.portraits` entry with id `default`.
3. Place the referenced image under `assets/art/characters/`.
4. Author conversations in the same character file and use optional `portrait`
   values for expressions or poses.
5. Run `python3 tools/validate_characters.py` and `tools/test_all.sh`.

No scene or GDScript edit is required.

## Adding a new location or room

1. Add the location and room to the canonical location registry.
2. Place convention-named background art, or add a `vn_backgrounds` entry to
   `content/presentation/vn_art.json`.
3. Add optional time, weather, or story variants to the entry.
4. Run the content validator and Godot test suite.

No location-specific Godot scene is required; the reusable city VN screen resolves
the room and its artwork from data.

## Validation and fallbacks

The Python validator checks every character portrait object, unique portrait id,
required default portrait, `res://` path, and referenced source file. Godot content
validation checks background ids, variant files, character portrait files, and both
global fallbacks. The Godot test runner imports source artwork before runtime probes,
so a fresh clone exercises the same imported textures as the editor.

Current SVGs are original temporary Port Alder artwork and may be replaced in place
without changing their content ids. Production art must keep a credit or provenance
record and must be licensed for redistribution and modification.
