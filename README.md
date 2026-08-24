# Port Alder Life Sim

A dramatic, mature, non-graphic life-simulation and visual-novel game planned for Godot 4 and GDScript.

The protagonist begins at age 18 in the fictional coastal city of Port Alder. The game combines an open life sandbox with authored character stories, education, careers, housing, relationships, marriage, parenting, health, and long-term aging.

## Project status

Pre-production and design. No gameplay code has been started.

## Planned technology

- Godot 4, latest stable release
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
- `src/` — future Godot source files
- `tests/` — future tests and simulation fixtures

The canonical design summary is in [docs/GAME_DESIGN_PLAYBOOK.md](docs/GAME_DESIGN_PLAYBOOK.md).
Character quest and conversation authoring is documented in [docs/CONTENT_AUTHORING_GUIDE.md](docs/CONTENT_AUTHORING_GUIDE.md).
Opening-week pacing and world scope are summarized in [docs/OPENING_WEEK_PLAYBOOK.md](docs/OPENING_WEEK_PLAYBOOK.md).
Education, jobs, interviews, and repeatable actions are summarized in [docs/EDUCATION_EMPLOYMENT_PLAYBOOK.md](docs/EDUCATION_EMPLOYMENT_PLAYBOOK.md).
Economy, inventory, clothing, food, and stores are summarized in [docs/ECONOMY_INVENTORY_PLAYBOOK.md](docs/ECONOMY_INVENTORY_PLAYBOOK.md).

Validate all character and global content data with `python3 tools/validate_characters.py`.
