# Anime-Forward Visual-Novel Background Style Proof

These previews test a more illustrated visual-novel presentation without replacing
the current production backgrounds:

- `assets/art/style_tests/anime_vn/hale_home_player_bedroom.png`
- `assets/art/style_tests/anime_vn/crown_point_hotel_lobby.png`

The stronger anime revision is the preferred production candidate:

- `assets/art/style_tests/anime_vn_strong/hale_home_player_bedroom.png`
- `assets/art/style_tests/anime_vn_strong/crown_point_hotel_lobby.png`

The third revision removes most remaining architectural-render realism and is the
most strongly animated candidate:

- `assets/art/style_tests/anime_cel/hale_home_player_bedroom.png`
- `assets/art/style_tests/anime_cel/crown_point_hotel_lobby.png`

## Shared repaint direction

Use case: `style-transfer`.

Repaint the supplied production background as a high-end 2D anime visual-novel
environment illustration. Use confident dark outlines with varied line weight,
clean flat color regions, graphic two-step cel shading, simplified but believable
materials, hand-painted skies and foliage, crisp architectural shapes, and stylized
light blooms. Use richer color scripting with clear warm/cool separation. The image
must read immediately as anime background art rather than a realistic architectural
render. Keep the tone mature, dramatic, and contemporary rather than childish or
chibi. Remove the photorealistic and glossy 3D-render appearance.

For the strongest treatment, reduce each material to a few clear color values, use
navy-black or dark-brown ink contours, hard-edged two-tone cel shadows, hand-painted
skies, chunky graphic clouds and foliage, and deliberately simplified fabric and
furniture shapes. Avoid PBR texture, soft ambient occlusion, ray-traced reflections,
realistic material grain, and smooth photographic gradients.

Change only the rendering style. Preserve the source camera, 16:9 framing,
perspective, architecture, furniture placement, character staging space, and every
authored doorway or navigation route. Do not add, remove, move, close, or merge any
opening. Keep the room empty and exclude people, silhouettes, reflections of people,
character sprites, navigation arrows, interface elements, readable text, letters,
numbers, logos, active screens, watermarks, and signatures.

## Pilot-specific invariants

### Hale Home player bedroom

Preserve the right-side bedroom doorway as the sole obvious route, plus the window,
bed, desk, closed closet, dresser, rug, shelving, and coastal view. Retain slate blue,
muted teal, walnut, cream, and restrained rust accents.

### Crown Point Hotel & Spa lobby

Preserve the left Staff Corridor, centered rear Restaurant, right Bar, and flat
foreground Hotel Block return. Retain cream marble, espresso walnut, antique brass,
ocean-blue seating and rugs, muted coral, and coastal daylight.

Both previews were created with the built-in image-generation editing workflow and
normalized to the game's 1672×941 background standard.
