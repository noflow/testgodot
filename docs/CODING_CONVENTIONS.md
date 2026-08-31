# Coding Conventions

## Engine and language

- Godot 4.7.2 stable
- GDScript with static types on public state, parameters, and return values
- UTF-8 and LF line endings
- Tabs for GDScript indentation, four spaces for JSON and documentation examples

## Naming

- Files, variables, functions, actions, and content IDs: `snake_case`
- Script classes and node types: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`
- Signals: past-tense or event descriptions such as `validation_completed`
- Private implementation members begin with `_`

Content IDs are stable API. Renaming one requires a save migration or an explicit
compatibility alias.

## Architecture rules

- Content packages contain declarative data and no executable code.
- UI requests operations; it never modifies runtime state directly.
- State changes pass through the simulation operation interface.
- Multi-field changes are atomic and roll back together.
- Authored packages are immutable during play.
- Save data contains mutable state and content-version references.
- Autoloads expose narrow APIs and do not depend on concrete UI scenes.
- Scene scripts own presentation and local interaction only.

## GDScript style

- Prefer early returns over deep nesting.
- Keep functions focused and normally below forty lines.
- Use `@onready` for required scene-node references.
- Use signals for cross-scene notifications.
- Avoid stringly typed scene paths outside constants or registries.
- Check file, parse, and scene-change errors.
- Do not ignore a failed state-changing operation.
- Comments explain intent, invariants, and non-obvious tradeoffs—not syntax.

## Testing

- Content validation: `python3 tools/validate_characters.py`
- Background coverage: `python3 tools/validate_backgrounds.py`
- Godot foundation tests: `tools/test_godot.sh`
- Complete local check: `tools/test_all.sh`
- A bug fix should include a regression test where practical.
- Priority-zero and priority-one vertical-slice acceptance tests are release gates.

## Commits

Each commit should represent one coherent milestone, pass content validation and
Godot headless tests, and avoid generated `.godot/` or exported `build/` files.
