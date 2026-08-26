# Port Alder Life Sim

A dramatic, mature, non-graphic life-simulation and visual-novel game planned for Godot 4 and GDScript.

The protagonist begins at age 18 in the fictional coastal city of Port Alder. The game combines an open life sandbox with authored character stories, education, careers, housing, relationships, marriage, parenting, health, and long-term aging.

## Project status

Godot foundation implementation. Phase 0 of the First Week Foundations vertical
slice is complete. Phase 1 includes full content indexing, resolved new-game state,
the seven-block calendar clock, atomic simulation operations, the VN dialogue and
quest engines, complete data-driven character creation, Elena's playable
three-branch opening scene, and the first connected Hale home sandbox. The home
uses Ren'Py-style room menus, static scene stages, private doors, needs-aware food and hygiene actions,
sleep, laundry, household storage, and a working wardrobe. The reusable smartphone
now provides the nine vertical-slice apps plus Education, Jobs, Money, and Shopping, authored character messages and replies,
NPC-aware calendar scheduling, live relationships, weather/outfit checks, the city
map, quest progress, character statistics, and complete persistent settings. Elena,
Daniel, and Lily now follow their character-authored work, school, and home-room
schedules, appear as scheduled character encounters on the VN stage, and expose
available story or ambient conversations through contextual choices.
Room backgrounds and character portraits now resolve through a cached data-driven
artwork service. Location art is assigned by manifest or predictable file path,
while each character owns portrait poses in its `.character` package. Home, city,
and dialogue scenes share safe fallback artwork when a production asset is missing.
The City Map now plans and confirms graph-based walking, bus, taxi, and permitted
car travel across nine opening destinations. Trips charge fares, advance the live
clock, respect closures and safety requirements, update quests, and arrive in a
reusable data-driven destination scene with menu-selectable areas.
Westshore Administration, Harbor Employment Centre, and Forge Fitness now expose
room-specific activity panels. The Westshore advisor creates an actual semester
schedule and tuition state; Harbor provides employment orientation, listing review,
and interview practice; and Rachel's assessment unlocks scheduled strength and
cardio training. Authored quest events now advance objectives and complete branches
without scene-specific quest code.
The Jobs phone app now provides filters, live qualification reports, calendar-aware
availability, applications, scheduled video interviews, scored interview choices,
offers, compatible schedule selection, contract acceptance, and six weeks of work
calendar events. Both the full-time and college/part-time employment quests are
playable through contract acceptance. Active employees can clock into grouped daily
shifts with four work approaches, earn regular wages, overtime, and tips, receive
weekly net pay after authored withholding, and build a performance record. Missed
shifts carry consequences, while ninety-day reviews provide data-driven raises and
open each job's authored promotion path when its requirements are met.
The Money app now processes weekly family allowance, monthly rent, credit-card
minimums, student-loan interest, financial aid, and tuition balances. Every payment
is ledger-backed, missed rent affects the household relationship, and Monday closes
an immutable weekly budget summary. The Shopping app exposes all seven authored
stores with opening hours, sales tax, student and employee discounts, split payment
priority, inventory delivery, declined-payment rollback, and saved receipts.
The Education app turns Westshore's authored semester calendar into a complete
academic loop. Classes and laboratories use their scheduled campus rooms, missed
attendance resolves automatically, studying builds persistent preparation, and
every course receives three assignments, a project, a midterm, and a final. Weighted
grades, warnings, probation, registration holds, credits, academic reputation, and
immutable semester history all progress from the same state-backed records.
The save layer now provides eight manual slots, three rotating autosaves, quicksave
and quickload, newest-valid Continue, phone and main-menu load controls, detailed
slot summaries, playtime tracking, SHA-256 integrity checks, atomic temporary-file
writes, backup recovery, corrupt-file preservation, content compatibility checks,
and a forward migration pipeline. Important day, story, quest, relationship,
education, employment, family, and travel changes trigger coalesced autosaves.
The Relationships app now supports schedule-aware date invitations, calendar plans,
route planning to the exact meeting room, three date approaches, date expenses,
missed and cancelled plans, five relationship chapters, and casual, exclusive, or
open dating agreements. Other partners can witness public dates and respond from
their own jealousy, boundaries, agreement, and authored reaction style; outcomes
range from approval or an honest check-in to damaged trust or a breakup.
Quest progression is now sandbox-first. Quests are discovered through exploration,
conversations, messages, institutions, activities, and earlier choices; they are
open-ended by default and never assigned as weekly priorities. Players choose which
active quests to pin. Stat, skill, relationship, location, life-path, and prior-choice
gates drive most progression, while rare visible deadlines are reserved for
institutional windows, scheduled commitments, emergencies, or fleeting opportunities.
Discovered side stories become optional phone offers rather than starting silently;
the player can accept, postpone, reconsider, or decline them without exposing hidden
future quests.
The phone and main menu now share complete persistent settings for four text sizes,
high contrast, reduced motion, screen-edge effects, camera shake, hold/toggle VN
skipping, independent audio channels, display mode, resolution, VSync, and keyboard
or controller remapping. VN lines can also be replayed, and accessibility choices
apply across character creation, dialogue, home, city, and phone interfaces.
The automated connected-run probe now drives the actual character-creation controls,
Elena's college opening branch, a home hygiene action, live Quest and Calendar apps,
bus travel, Westshore enrollment, Emma's scheduled waterfront story, and an isolated
save/load resume at Alder Bay Park. Calendar-authored character scenes require the
correct current appointment, and phone-created hangouts advance their owning quests.

## Planned technology

- Godot 4.7.2 stable
- GDScript
- Ren'Py-style visual-novel presentation built in Godot
- Static location stages, character portraits, and menu-driven room navigation
- PC first: Windows, macOS, and Linux
- Data-driven quests, schedules, and character packages
- One importable `.character` file per major character

## Repository layout

- `docs/` — game-design playbook and technical specifications
- `characters/` — 15 validated opening-cast `.character` packages
- `content/` — global quests and conversations owned by locations or institutions
- `mods/` — local mod-development workspace
- `assets/` — art, audio, and fonts
- `src/` — Godot source files beginning with the vertical-slice implementation
- `tests/` — acceptance tests and future simulation fixtures

The canonical design summary is in [docs/GAME_DESIGN_PLAYBOOK.md](docs/GAME_DESIGN_PLAYBOOK.md).
Character quest and conversation authoring is documented in [docs/CONTENT_AUTHORING_GUIDE.md](docs/CONTENT_AUTHORING_GUIDE.md).
Opening-week pacing and world scope are summarized in [docs/OPENING_WEEK_PLAYBOOK.md](docs/OPENING_WEEK_PLAYBOOK.md).
The canonical city, room, housing, service, and travel-destination registry is [content/world/all_locations.json](content/world/all_locations.json).
Education, jobs, interviews, and repeatable actions are summarized in [docs/EDUCATION_EMPLOYMENT_PLAYBOOK.md](docs/EDUCATION_EMPLOYMENT_PLAYBOOK.md).
Economy, inventory, clothing, food, and stores are summarized in [docs/ECONOMY_INVENTORY_PLAYBOOK.md](docs/ECONOMY_INVENTORY_PLAYBOOK.md).
Runtime state, simulation events, saves, and migrations are described in [docs/RUNTIME_SAVE_ARCHITECTURE.md](docs/RUNTIME_SAVE_ARCHITECTURE.md).
Date authoring, agreements, conflicts, and relationship progression are described in [docs/RELATIONSHIP_DATING_PLAYBOOK.md](docs/RELATIONSHIP_DATING_PLAYBOOK.md).
Sandbox discovery, gates, paths, deadlines, and player-controlled tracking are described in [docs/SANDBOX_QUEST_PLAYBOOK.md](docs/SANDBOX_QUEST_PLAYBOOK.md).
The implemented settings and accessibility baseline are described in [docs/ACCESSIBILITY_PLAYBOOK.md](docs/ACCESSIBILITY_PLAYBOOK.md).
The background, portrait, pose, fallback, and no-code art-import workflow is described in [docs/VN_ART_ASSET_PLAYBOOK.md](docs/VN_ART_ASSET_PLAYBOOK.md).
The first playable build is defined in [docs/VERTICAL_SLICE_SPECIFICATION.md](docs/VERTICAL_SLICE_SPECIFICATION.md).
The connected automated route and its matching manual checks are documented in [docs/VERTICAL_SLICE_PLAYTEST.md](docs/VERTICAL_SLICE_PLAYTEST.md).

Validate all character and global content data with `python3 tools/validate_characters.py`.

## Running the Godot foundation

1. Install [Godot 4.7.2 stable](https://godotengine.org/download/archive/4.7.2-stable/).
2. Import `project.godot` in the Godot Project Manager.
3. Run the project to validate content and open the main menu.

Command-line checks:

```sh
python3 tools/validate_characters.py
tools/test_godot.sh
tools/test_all.sh
```

The repository includes a macOS export preset. Export templates are installed
through Godot and are not committed.
