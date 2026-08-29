# Port Alder Art Direction

Status: production baseline  
Presentation: grounded, static visual-novel backgrounds and transparent character portraits

## Core look

Port Alder uses polished semi-realistic digital illustration for a dramatic, mature
contemporary story. Environments should feel lived in and specific without becoming
photographic or visually noisy. Character anatomy, age, clothing, and expressions
remain believable. Avoid exaggerated anime proportions, glamour posing, childish
styling, and neon or fantasy palettes unless a specific story location calls for it.

The opening palette combines slate blue, muted teal, warm cedar, cream, charcoal,
and restrained rust accents. Coastal daylight is cool and soft; interior practical
light and natural wood provide warmth.

## Background staging

- Compose backgrounds at 16:9; 1920×1080 is the preferred final size.
- Keep the bottom 35 percent relatively calm and darker for the dialogue interface.
- Preserve open center or side staging space for one or more character portraits.
- Show believable entrances and exits that support the authored navigation graph.
- Do not paint navigation arrows, interface elements, people, text, or logos into a background.
- Time, weather, and season variants must preserve the base room geometry and camera.

## Character staging

- Use a tall transparent canvas; 900×1600 or a similar ratio is preferred.
- Keep the full head, shoulders, hands, and silhouette safely inside the canvas.
- Age characters accurately and use practical, character-specific contemporary clothing.
- Expression variants preserve identity, outfit, proportions, camera, and lighting.
- Portraits must have genuine alpha transparency and no painted backdrop or floor.
- Sexualized presentation is reserved for explicitly authored adult scenes; everyday portraits remain grounded and non-graphic.

## Room-first production policy

Room art is the active production priority. Every mapped room will receive a unique
base daytime background before time, weather, or season variants are produced.
Locations are completed one at a time so connected rooms share believable
architecture, materials, sightlines, and exterior continuity. Character portrait
work is deferred; existing portrait data and completed assets remain intact.

The first completed location is the Hale Home. Its 14 mapped destinations now have
unique base-day PNG backgrounds. Each base image is marked ready in the art
registry, while its backlog task remains in progress until every listed variant is
finished.

### Hale Home batch prompt set

The player-bedroom image was the primary visual reference. The entryway and living
room generations were also used as continuity references for connected ground-floor
rooms and the property exterior.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production visual-novel background for a Godot game. Create the named room in the established Hale family home in the fictional coastal city of Port Alder. Grounded semi-realistic contemporary-drama illustration with painterly materials and restrained clean linework. Eye-level 16:9 composition, believable middle-class architecture, open character staging space, and a calm darker lower region for dialogue. Soft late-August daytime coastal light; slate blue, muted teal, warm cedar, cream, charcoal, and restrained rust accents. Preserve clear believable entrances and exits for room-to-room navigation. No people, character sprites, navigation arrows, interface, text, logos, watermark, or fisheye distortion.

Room-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Upstairs landing | `upstairs_landing.png` | Compact stair landing connecting the second floor to the entryway below. |
| Upstairs hall | `upstairs_hall.png` | Family bedroom corridor with distinct doors and coherent upstairs geometry. |
| Entryway | `entryway.png` | Main front-door foyer, stairs, coat storage, and access toward the living spaces. |
| Family bathroom | `family_bathroom.png` | Shared practical bathroom with tub-shower, vanity, toilet, and lockable hall door. |
| Lily's bedroom | `lily_bedroom.png` | Older sister's mature, personalized bedroom with bed, desk, storage, and hall door. |
| Parents' bedroom | `parents_bedroom.png` | Calm adult primary bedroom with restrained decor, storage, and hall access. |
| Living room | `living_room.png` | Warm family gathering room connected naturally to the foyer and dining area. |
| Kitchen | `kitchen.png` | Lived-in family kitchen with work surfaces, appliances, and clear adjacent-room exits. |
| Dining room | `dining_room.png` | Six-place family dining space bridging the kitchen and living room. |
| Laundry room | `laundry_room.png` | Practical utility room linking the kitchen side of the house to the garage. |
| Garage | `garage.png` | Single-family attached garage with shared car, storage, workbench, and interior door. |
| Front yard | `front_yard.png` | Blue-gray two-story coastal Craftsman exterior, driveway, porch, and neighborhood path. |
| Backyard | `backyard.png` | Private fenced garden, patio, lawn, and rear view of the same home. |

All files are saved under
`res://assets/art/backgrounds/hale_home/`. The existing player bedroom completes
the 14-destination set.

## Opening production references

### Hale Home — Player Bedroom

Saved as `res://assets/art/backgrounds/hale_home/player_bedroom.png`.

Prompt:

> Use case: stylized-concept. Asset type: production visual-novel room background for a Godot game. The 18-year-old male player's bedroom in the Hale family home on a late-August Tuesday morning, just before his mother enters to discuss his future. A comfortable, lived-in upstairs bedroom in a middle-class Port Alder home: young-adult rather than childish, with a bed, bedside table, modest desk, dresser, wardrobe or closet, coastal window, and a visible doorway for a character entrance. Polished grounded semi-realistic 2D visual-novel illustration with painterly surfaces and restrained clean linework. Eye-level 16:9 composition, believable geometry, open character staging, and a calm darker lower 35 percent for dialogue. Soft cool coastal morning light, warm wood, slate blue, muted teal, cream, and rust. No people, sprites, arrows, UI, text, logos, watermark, or fisheye distortion.

### Elena Reyes-Hale — Default / Neutral

Saved as `res://assets/art/characters/elena_reyes_hale/default.png`.

Prompt:

> Use case: stylized-concept. Asset type: production visual-novel transparent character portrait. Elena Reyes-Hale, age 45, the player's mother and a clinic administrator: protective, organized, direct, maternal, warm, and quietly stubborn. A believable middle-aged woman with medium warm olive skin, brown eyes, shoulder-length dark chestnut hair with subtle silver strands, mature features and natural smile lines, and an attentive neutral expression. Practical muted-teal blouse, warm-rust cardigan, tailored charcoal trousers, and simple jewelry. Grounded semi-realistic contemporary-drama illustration with painterly materials and restrained linework. Tall centered standing portrait, head to below the knees, natural hands and silhouette, soft coastal morning light, genuinely transparent background. Age-accurate, non-sexualized, and free of text, logos, props, scenery, borders, or watermark.

## Provenance

The baseline assets and complete Hale Home room batch were generated with the
built-in OpenAI image-generation tool on 2026-08-29 for the Port Alder project.
They are original project assets intended for redistribution and modification with
the game. Source generations remain in the local Codex generated-image store; the
checked-in PNG files are the canonical game copies.
