# Day/night background production

Updated: 2026-09-02

## Coverage

All 371 rooms and exterior scenes across 65 locations now have separate day and
night artwork registered in the game: 371/371 pairs, with no missing night scenes.
The complete-city pass added the remaining 302 night backgrounds to the prior 69.
Existing day images were preserved. No save format, room IDs, or navigation changed.

Coverage includes homes and residences, campus and dormitories, outdoor districts,
parks and waterfronts, entertainment venues, shops, workplaces, medical facilities,
and Crown Point properties. This includes locked and discoverable rooms without
changing their access rules.

Exact saved paths, source files, edit prompts, and visual-review records are in
[the asset log](day_night_asset_log.jsonl). Each night image is a sibling of its
day source named `<room_id>_night.png`; only reviewed files are registered.

Initial proof pairs:

| Room | Day file | Night file |
| --- | --- | --- |
| Player bedroom | `hale_home/player_bedroom.png` | `hale_home/player_bedroom_night.png` |
| Upstairs landing | `hale_home/upstairs_landing.png` | `hale_home/upstairs_landing_night.png` |
| Home entrance | `hale_home/entryway.png` | `hale_home/entryway_night.png` |

Paths are relative to `assets/art/backgrounds/`. The target size is 1672×941 PNG.
All 371 day images and 368 night images meet it. Three installed night images
remain 1671×941 after repeated built-in size-correction attempts:

- `port_alder_auto/service_desk_night.png`
- `st_maren_community_clinic/reception_night.png`
- `crown_point_boulevard/corporate_block_night.png`

These load in Godot, but the exact-size validator correctly rejects them. Local
one-pixel normalization was offered and awaits user confirmation; no validator
tolerance was relaxed and no local raster resize was performed.
Night edits were made with the built-in image-generation tool, one asset per call,
using each room's current anime base. Targeted corrections used the resulting
night image; some size corrections also used the same room's day image as a
canvas/layout reference. Sources and final prompts are retained in the asset log.
No API/CLI image mode or programmatic repainting was used.

## Time and preview rules

| Activity block | Variant lookup order, then base image |
| --- | --- |
| Early Morning | early_morning → dawn → day |
| Morning | morning → day |
| Lunch | lunch → day |
| Afternoon | afternoon → day |
| Evening | evening → sunset → day |
| Late Evening | late_evening → night |
| Night | night |

Home and city scenes refresh on block changes without requiring a room change.
Blank dialogue overrides inherit the clock. Explicit scene overrides retain priority.
This first pass uses activity blocks, not seasonal sunrise/sunset calculations.

Main menu → Background Gallery → choose a location and room → Day/Night selector.
The chosen variant stays selected while browsing; unavailable night art is labeled
and uses the room's base/day image. The gallery never alters the game clock.

## Visual checks

Inspected the source and generated images for layout consistency, doors, flooring,
furniture, windows, and nighttime lighting. Interior adjoining views and reflections
were checked alongside exterior windows. The landing's existing railed staircase
is intentional and was preserved. Unintended additions found during this pass were
corrected, including extra lamps and an accidental glow in Olivia's terrace flowers.

Known pre-existing layout concerns remain in Greyport Studios' lobby and studio:
the foreground doorway/stair details can read as doors sunk into the floor. The
night versions preserve the day layouts for continuity; these are not certified
as geometry fixes. The asset log records this caveat. Correcting both versions
was offered separately and is awaiting direction. Similar foreground threshold
details in Undertow's staff room warrant a separate layout pass.

This check does not resolve the user's separately reported, still-unidentified
floor-hole image; its room name or attachment is still needed.
Inspect each source and output before registering future variants, and record
any unresolved source-art concerns rather than treating preserved geometry as fixed.
Night artwork does not change opening hours, NPC schedules, or access restrictions.

## Exact edit prompts

### player_bedroom

Reference: `assets/art/backgrounds/hale_home/player_bedroom.png`

Edit this exact approved anime visual-novel background into a matching NIGHT variant. Use case: lighting-weather-edit. Preserve the precise camera, full 16:9 framing, perspective, composition, all architecture, doors and openings, furniture, plants, pictures and small props at identical locations. Keep bold clean ink outlines, flat cel-painted color shapes and restrained two-tone anime shading, no photorealistic rendering. Change ONLY illumination and exterior time of day: dark navy night sky and subdued coastal landscape visible through existing glass, no daylight, no sunlight streaks or sunny clouds. Warm comfortable indoor electric lighting contrasted with subtle cool moonlight, still bright enough to read exits and props in gameplay. No people, words, UI, new objects, new holes, new doors, floor openings or changed room geometry. Preserve existing legitimate staircase structure exactly. Output a single finished wide background, not a comparison or collage. Turn on the existing bedside lamp and desk lamp; keep the blue bedding, blue walls, rug, desk, closet, dresser and open right-hand door unchanged. Both the main window and the window visible through the doorway show night. Replace hard warm solar beams on walls, furniture and floor with gentle warm lamp pools and soft cool ambient shadows.

### upstairs_landing

Reference: `assets/art/backgrounds/hale_home/upstairs_landing.png`

Edit this exact approved anime visual-novel background into a matching NIGHT variant. Use case: lighting-weather-edit. Preserve the precise camera, full 16:9 framing, perspective, composition, all architecture, doors and openings, furniture, plants, pictures and small props at identical locations. Keep bold clean ink outlines, flat cel-painted color shapes and restrained two-tone anime shading, no photorealistic rendering. Change ONLY illumination and exterior time of day: dark navy night sky and subdued coastal landscape visible through existing glass, no daylight, no sunlight streaks or sunny clouds. Warm comfortable indoor electric lighting contrasted with subtle cool moonlight, still bright enough to read exits and props in gameplay. No people, words, UI, new objects, new holes, new doors, floor openings or changed room geometry. Preserve existing legitimate staircase structure exactly. Output a single finished wide background, not a comparison or collage. Turn on the EXISTING hanging pendant. Preserve the railed staircase and descending stairwell exactly as shown: this is an intentional staircase, not an error to fill. Keep the open doorways, wall pictures, railing posts and floorboards exactly. All three visible upstairs windows and the downstairs door glass show night, not blue daylight. Soft warm ceiling light and subtle cool window light; eliminate solar stripes.

### entryway

Reference: `assets/art/backgrounds/hale_home/entryway.png`

Edit this exact approved anime visual-novel background into a matching NIGHT variant. Use case: lighting-weather-edit. Preserve the precise camera, full 16:9 framing, perspective, composition, all architecture, doors and openings, furniture, plants, pictures and small props at identical locations. Keep bold clean ink outlines, flat cel-painted color shapes and restrained two-tone anime shading, no photorealistic rendering. Change ONLY illumination and exterior time of day: dark navy night sky and subdued coastal landscape visible through existing glass, no daylight, no sunlight streaks or sunny clouds. Warm comfortable indoor electric lighting contrasted with subtle cool moonlight, still bright enough to read exits and props in gameplay. No people, words, UI, new objects, new holes, new doors, floor openings or changed room geometry. Preserve existing legitimate staircase structure exactly. Output a single finished wide background, not a comparison or collage. Keep the closed wooden front door, glass sidelights, bench, boots, floor rug, tile floor, open living-room doorway and right staircase exactly unchanged. The door glass, sidelights and living-room window show a dark nighttime neighborhood. Illuminate warmly from off-camera existing house lighting and the existing living-room lamp. No extra lamps or fixtures. Keep the tiled foreground floor continuous and solid.

## Checks

The complete-city verification run uses Godot 4.7.2. The test executable was
downloaded from the official Godot release into a temporary directory; no engine
or project-version upgrade was made. Built-in image-generation mode was used for
all night edits. The full-city runtime run passed all 1176 foundation tests and
all five runtime probes, including loading all 371 rooms and their variants.
Character/content validation also passed: 15 character packages and 26 global
packages. The 368 asset-log entries are unique (the first three proof pairs are
documented above), and installed files match their logged generated sources.
Exact PNG-dimension validation fails only for the three 1671×941 files listed
above. No missing images or registry entries remain. This is complete artwork
coverage, not a clean asset-validation result until those widths are corrected.

- `python3 tools/validate_backgrounds.py`: base coverage plus every registered variant's file and dimensions.
- `python3 tools/validate_characters.py`: content references.
- `tools/test_godot.sh`: imports, logic tests, home/city/dialogue/gallery runtime probes.

The gallery probe covers all registered artwork, all seven block mappings, explicit
Director-style overrides, exact-block priority, missing-file fallback, persistent
preview selection, and bounded caching. The home probe checks in-place night/day
changes; the city probe checks in-place switching in the advisor office; the
dialogue probe checks blank versus explicit overrides at night.
