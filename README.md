# Port Alder Life Sim

A dramatic, mature, non-graphic life-simulation and visual-novel game planned for Godot 4 and GDScript.

The protagonist begins at age 18 in the fictional coastal city of Port Alder. The game combines an open life sandbox with authored character stories, education, careers, housing, relationships, marriage, parenting, health, and long-term aging.

## Project status

Godot foundation implementation. Phase 0 of the First Week Foundations vertical
slice is complete. Phase 1 includes full content indexing, resolved new-game state,
the seven-block calendar clock, atomic simulation operations, the VN dialogue and
quest engines, complete data-driven character creation, Elena's playable
three-branch opening scene, and the first connected Hale home sandbox. The home
includes room collisions, private doors, needs-aware food and hygiene actions,
sleep, laundry, household storage, and a working wardrobe. The reusable smartphone
now provides the nine vertical-slice apps plus Education, Jobs, Money, and Shopping, authored character messages and replies,
NPC-aware calendar scheduling, live relationships, weather/outfit checks, the city
map, quest progress, character statistics, and initial settings controls. Elena,
Daniel, and Lily now follow their character-authored work, school, and home-room
schedules, appear as reusable top-down actors, and expose available story or ambient
conversations through direct exploration.
The City Map now plans and confirms graph-based walking, bus, taxi, and permitted
car travel across nine opening destinations. Trips charge fares, advance the live
clock, respect closures and safety requirements, update quests, and arrive in a
reusable data-driven destination scene with explorable rooms.
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

## Planned technology

- Godot 4.7.2 stable
- GDScript
- 2D top-down exploration
- VN-style dialogue presentation
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
The first playable build is defined in [docs/VERTICAL_SLICE_SPECIFICATION.md](docs/VERTICAL_SLICE_SPECIFICATION.md).

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
