# Port Alder Life Sim — Vertical Slice Specification

Status: approved implementation target once reviewed  
Build name: First Week Foundations  
Engine: Godot 4.x stable with GDScript  
Presentation: 2D top-down exploration with VN-style conversations

Implementation status: Phase 0 project foundation complete. Phase 1 content loading,
new-game state creation, seven-block clock, core simulation, VN dialogue, quest
branching, required character creation, and Elena's playable opening are
implemented. The connected Hale home, room collisions, essential needs actions,
household supplies, and wardrobe equipment are also playable. The phone is next.

## Purpose

The vertical slice must prove that authored character content and the life
simulation work together in a single reliable loop. It is not a content demo or a
mock-up. The player must be able to create a protagonist, make the opening life
choice, manage basic needs, navigate the home and city, use the phone, complete a
quest, develop an NPC relationship, advance time, and save and resume the result.

The slice covers Tuesday through Sunday of the opening week. Content beyond the
required path may remain data-complete but visually minimal.

## Definition of done

The slice is complete when a fresh installation can:

1. Start a new game and create a valid protagonist.
2. Play Elena's opening scene and select college, employment, or both.
3. Enter the sandbox with the correct quests, rent, and allowance rules.
4. Walk through the Hale home and use its essential rooms.
5. Satisfy Hygiene, Hunger, Hydration, Energy, and wardrobe requirements.
6. Use every required phone app without opening developer tools.
7. Leave home and travel to at least three city destinations.
8. Complete one institutional objective and one NPC activity.
9. Observe time, money, needs, quests, calendar, and relationship state change.
10. Save, close the game, reload, and resume without losing or duplicating state.

All priority-zero and priority-one acceptance tests must pass. Data validation must
report no errors.

## Player-facing flow

### Boot and main menu

The game opens to a main menu with New Game, Continue, Load Game, Settings, Content,
Credits, and Quit. Continue is disabled when no valid save exists. Load Game shows
manual, autosave, and quicksave slots with date, location, playtime, life path, and
warning state.

### Character creation

The slice supports:

- First and last name
- Birthday resulting in age 18 on the opening date
- Face, eye color, skin tone, hairstyle, height, and body type
- Three positive traits and three challenging traits
- Three core values
- One starting archetype
- Two hobbies
- Limited, Standard, or Comfortable financial background

The protagonist is male. Health, fertility, reproductive data, and romantic
interest are not selected and are generated or discovered during play.

The confirmation screen explains starting finances, clothing, family-car access,
and trait bonuses before creating the save.

### Opening scene

The first playable scene starts in the player bedroom on Tuesday morning. Elena
enters and the authored `opening_future_talk` conversation runs. Dialogue choices
must apply tone tags and relationship effects immediately.

The life choice produces:

- College: `enroll_at_westshore`, no rent while enrolled, weekly allowance active.
- Employment: `find_employment`, $250 rent due September 1, no school allowance.
- Both: `enroll_at_westshore` and `find_part_time_employment`, no rent while
  enrolled, weekly allowance active.

When the conversation ends, the phone quest tracker unlocks and free movement
begins without a chapter-selection screen.

### Home exploration

The Hale home is a connected top-down scene. The slice requires the player bedroom,
upstairs hall, family bathroom, Lily's door, parents' door, living room, kitchen,
dining room, laundry room, garage, front yard, and backyard.

Essential interactions:

- Sleep or nap in the bedroom
- Open wardrobe and equip clothing
- Shower, bathe, brush teeth, and groom in the bathroom
- Eat, drink, and cook a basic meal in the kitchen
- Talk with available household members
- Complete a chore and laundry
- Access the family car only when permission and requirements allow
- Exit through the front yard

Implementation note: the current playable home contains all twelve required spaces,
free movement, collision boundaries, blocked private bedrooms, bedroom, bathroom,
kitchen, dining, laundry, garage, yard interactions, and a state-backed wardrobe.
Household NPC placement, family conversations, car travel, and the city exit build
on this scene in the following milestones.

Private doors require knocking or permission. The player cannot enter an occupied
bathroom or restricted bedroom by walking through a collision boundary.

### Phone

The phone pauses direct movement but not the current game timestamp until an action
that consumes time is confirmed. It must work with keyboard, mouse, and controller.

Required apps:

- Character Profile: needs, attributes, traits, skills, reputation, and clothing
- Contacts: known NPCs and their discovered public information
- Messages: authored text threads and quick replies
- Calendar: seven daily blocks, travel time, dates, classes, interviews, and shifts
- Quests: active, completed, deferred, deadlines, objectives, and map links
- Relationships: visible meters and discovered supporting variables
- City Map: unlocked locations, routes, time, cost, and closures
- Weather: current conditions, forecast, and wardrobe warning
- Settings: audio, display, accessibility, controls, save, load, and quit

Scheduling an NPC activity adds it to the calendar. Work or school conflicts prevent
confirmation. Other conflicts create a visible double-booking warning but remain
allowed.

### City travel

The front yard exits to Alder Heights. The player can walk to the street, bus stop,
Forge Fitness, and Alder Bay Park. Westshore, Harbor Employment Centre, and
Harborlight Cinema load as destination scenes from the city map or transit flow.

Walking, bus, taxi, and permitted car trips display time, cost, weather exposure,
and arrival block. The slice must fully implement walking and bus travel. Taxi and
car may use menu-driven travel but must still charge money and advance time.

Closed destinations show their next opening time. Travel that would arrive too late
warns the player before confirmation.

### Required quest proof

Every life path must be completable far enough to prove its system:

- College: visit Westshore, choose a program and course load, select a tuition plan,
  and create class calendar entries.
- Employment: browse jobs, review requirements, submit an application, and schedule
  or practice an interview.
- Both: create a class schedule and save a compatible part-time availability profile.

The slice does not need to simulate the entire semester or a ninety-day promotion.
Those outcomes remain validated content for later builds.

### Required NPC proof

The player must be able to complete at least one of:

- Lily's `one_year_ahead`
- Emma's `before_everything_changes`
- Marcus's `one_last_summer_movie`
- Rachel's `first_rep`

Emma's walk is the primary scheduling test. Rachel's assessment is the primary
attribute and activity test. Lily and Marcus prove home and entertainment content.

NPC availability must come from runtime schedules. An unavailable NPC cannot accept
a date merely because the conversation data exists.

### Sunday review

Reaching Sunday Evening opens the phone review. It summarizes life path, enrollment,
employment, balances, spending, sleep, health, weather exposure, workouts,
relationships, and quest state. It is reflective and never assigns a victory grade.

## Visual and audio scope

The slice may use original placeholder art but cannot use unlabeled debug rectangles
in the required path.

Minimum visual set:

- Main-menu background
- Player placeholder sprite with four-direction movement
- Household and four featured NPC placeholder sprites
- Hale home tiles and room props
- Exterior hub, Westshore, employment office, gym, park, and cinema backdrops
- VN dialogue frame with speaker name, text, portrait area, choices, and history
- Phone frame and icons for all required apps
- Weather and clothing-status icons

Minimum audio set:

- Main-menu music loop
- Home ambience
- City ambience
- One calm conversation music loop
- UI confirm, cancel, message, quest, transaction, and warning sounds

All placeholders must have documented licenses or be created for the project.

## Controls

Default actions:

| Action | Keyboard and mouse | Controller |
| --- | --- | --- |
| Move | WASD or arrows | Left stick or D-pad |
| Interact | E or left click | South face button |
| Cancel/back | Escape or right click | East face button |
| Phone | Tab | Select/View button |
| Quest tracker | Q | Left shoulder |
| Map | M | Right shoulder |
| Pause | Escape | Start/Menu button |
| Advance dialogue | Space, Enter, or click | South face button |
| Dialogue history | H or mouse wheel | D-pad up |

Every binding can be remapped. UI focus must remain visible on keyboard and
controller.

## Accessibility baseline

- Text-size options at 100%, 125%, 150%, and 175%
- High-contrast dialogue and phone themes
- Reduce motion option
- Hold-to-skip and toggle-to-skip dialogue modes
- Dialogue history and replay of the current line
- Independent music, ambience, UI, and voice-volume channels
- Color is never the only indicator for needs, warnings, or relationship changes
- Screen-edge and camera-shake effects can be disabled
- Autosave and confirmation messages use plain language

## Godot architecture

### Proposed project layout

```text
project.godot
src/
  autoload/
  content/
  core/
  simulation/
  save/
  world/
  dialogue/
  quests/
  phone/
  ui/
  tests/
scenes/
  boot/
  menus/
  creation/
  world/
  locations/
  dialogue/
  phone/
assets/
content/
characters/
schemas/
```

### Autoload services

- `ContentRegistry`: loads, validates, indexes, and resolves content IDs.
- `GameState`: owns the current mutable runtime snapshot.
- `SimulationService`: validates and applies atomic simulation operations.
- `TimeService`: advances blocks and triggers daily, weekly, and monthly processing.
- `QuestService`: evaluates quest activation, objectives, branches, and outcomes.
- `ConversationService`: runs dialogue graphs and choice effects.
- `CalendarService`: schedules events, conflicts, travel, reminders, and arrivals.
- `WorldService`: controls locations, weather, stores, and NPC presence.
- `SaveService`: validates, checkpoints, migrates, writes, and recovers saves.
- `SceneRouter`: transitions between menus, world scenes, VN scenes, and overlays.
- `SettingsService`: stores controls, accessibility, audio, and display settings.

Services communicate through typed signals or a narrow event interface. Content
files never call GDScript functions directly.

### Required scenes

- `Boot.tscn`: validates content and routes to menu or error screen.
- `MainMenu.tscn`
- `NewGame.tscn`
- `GameRoot.tscn`: persistent world, overlays, transition layer, and HUD.
- `HaleHome.tscn`
- `AlderHeights.tscn`
- `WestshoreAdministration.tscn`
- `HarborEmploymentCentre.tscn`
- `ForgeFitness.tscn`
- `AlderBayPark.tscn`
- `HarborlightCinema.tscn`
- `DialogueScreen.tscn`
- `PhoneOverlay.tscn`
- `SaveLoadScreen.tscn`
- `ContentErrorScreen.tscn`

### Data-loading order

1. Read base package manifest and data format versions.
2. Load schemas and core enumerations.
3. Load items, economy, activities, education, employment, locations, and travel.
4. Load `.character` packages.
5. Load global quests, conversations, and opening-week content.
6. Load enabled mods in declared order.
7. Validate unique IDs and all cross-references.
8. Build immutable lookup indexes.
9. Load or create runtime state.
10. Resolve derived caches and enter the selected scene.

Any missing required reference blocks play and opens a content error screen with the
file, content ID, field, and suggested corrective action.

### State and UI rule

UI reads immutable views of `GameState`. It requests changes through simulation
operations. UI code never modifies money, meters, inventory, quests, or time
directly.

## Performance targets

- 60 frames per second at 1920×1080 on the development Mac and a modest integrated
  GPU target machine
- Required location transition below two seconds after initial load
- Phone app transition below 150 milliseconds
- Content validation below three seconds for the current package set
- Manual or autosave below 500 milliseconds for the vertical-slice state
- Memory target below 1 GB during the required path

These are development targets, not promises for the final full-city build.

## Error handling

- Content error: block affected load and identify the exact field.
- Missing optional asset: use a labeled fallback and log once.
- Save checksum failure: try backup, then autosave, without deleting anything.
- Failed simulation event: roll back the transaction and show a recoverable message.
- Missing NPC availability: treat the NPC as unavailable and log the schedule error.
- Invalid calendar destination: cancel scheduling without consuming time or money.

## Explicitly excluded from the vertical slice

- Full semester simulation and graduation
- Promotions beyond proving the data is loadable
- Purchasing or renting a new residence
- Marriage, pregnancy, birth, children, custody, and child-support gameplay
- STI transmission gameplay beyond loading health data and screening items
- Therapy treatment arcs
- Full alcohol social events
- Licensed professional-companion gameplay
- Remaining relationship chapters beyond opening arcs
- Full city free-roaming and every district interior
- Mod creation UI; only base content loading is required
- Optional local LLM support
- Final artwork, animation, voice acting, localization, achievements, and cloud saves

Exclusion means “not required for first playable,” not removed from the full design.

## Implementation phases

### Phase 0 — Project foundation

Create the Godot project, directory layout, input map, automated test runner, coding
conventions, and boot scene. Completion requires launching an empty validated build
on macOS and one export preset.

### Phase 1 — Content and state

Implement `ContentRegistry`, the JSON `.character` development loader, runtime-state
creation, content errors, and the event-operation interface. Completion requires
loading all current packages with the same result as the repository validator.

### Phase 2 — Dialogue and quests

Implement VN presentation, choices, effects, quest activation, objectives, and
Elena's complete opening scene. Completion requires all three life-path branches.

### Phase 3 — Home and needs

Implement movement, collision, room transitions, interactions, wardrobe, Hygiene,
food, and sleep. Completion requires leaving the house in a valid outfit.

### Phase 4 — Phone and calendar

Implement every required phone app, messages, scheduling, conflicts, reminders, and
quest navigation. Completion requires scheduling Emma's walk.

### Phase 5 — City and activities

Implement travel, destination scenes, enrollment or employment proof, Rachel's gym
assessment, and one social activity. Completion requires time, cost, needs, and
relationship effects to survive scene changes.

### Phase 6 — Saves and weekly loop

Implement save slots, autosaves, checksum, backup recovery, Sunday review, settings,
and accessibility baseline. Completion requires a full new-game-to-Sunday save/load
round trip.

### Phase 7 — Stabilization

Run all acceptance tests, fix blockers, profile performance, package desktop builds,
and record remaining issues. The slice is complete only when the completion gate in
`content/vertical_slice/manifest.json` passes.

## Acceptance tests

Machine-readable acceptance cases live in
`tests/acceptance/vertical_slice.json`. Priority 0 represents a release blocker;
Priority 1 is required for the slice; Priority 2 may be deferred only with a written
issue and no effect on the required loop.
