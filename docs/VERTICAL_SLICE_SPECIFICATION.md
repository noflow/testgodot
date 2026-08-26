# Port Alder Life Sim — Vertical Slice Specification

Status: approved implementation target once reviewed  
Build name: First Week Foundations  
Engine: Godot 4.x stable with GDScript  
Presentation: Ren'Py-style visual novel and menu-driven sandbox navigation in Godot

Implementation status: Phase 0 project foundation complete. Phase 1 content loading,
new-game state creation, seven-block clock, core simulation, VN dialogue, quest
branching, required character creation, and Elena's playable opening are
implemented. The connected Hale home, VN room navigation, essential needs actions,
household supplies, wardrobe equipment, reusable phone shell, all nine required
foundation apps, and the additional playable Education, Jobs, Money, and Shopping
apps are implemented. The app
views use live runtime data. Authored opening texts, quick
replies, calendar scheduling,
NPC commitment rejection, optional double-booking warnings, weather/outfit checks,
quest discovery, gated offers, accept/postpone/decline decisions, progress,
relationships, map discovery, and complete persistent settings work.
The employment slice continues beyond hiring with playable shifts, attendance and
performance, weekly payroll, overtime, tips, withholding, raises, and promotions.
The education slice also continues beyond enrollment with playable classes,
studying, assignments, projects, midterms, finals, grades, academic consequences,
credits, and first-semester completion.
Map route confirmation and destination travel, resilient save/load,
player-controlled sandbox quest tracking, complete persistent settings, and the
accessibility baseline now work.
An automated connected-run probe also completes character creation, Elena's college
branch, home and phone interactions, bus travel, Westshore enrollment, Emma's
calendar-gated waterfront story, and an isolated save/load resume at the saved city
room.

## Purpose

The vertical slice must prove that authored character content and the life
simulation work together in a single reliable loop. It is not a content demo or a
mock-up. The player must be able to create a protagonist, make the opening life
choice, manage basic needs, navigate the home and city, use the phone, complete a
quest, develop an NPC relationship, advance time, and save and resume the result.

The slice begins on Tuesday of the opening calendar and proves play across its first
six days. Sunday is not an endpoint: the sandbox continues without a weekly plan or
forced quest sequence. Content beyond the required proof may remain data-complete
but visually minimal.

## Definition of done

The slice is complete when a fresh installation can:

1. Start a new game and create a valid protagonist.
2. Play Elena's opening scene and select college, employment, or both.
3. Enter the sandbox with the correct quests, rent, and allowance rules.
4. Navigate the Hale home with on-scene directional arrows or the accessible room list and use its essential rooms.
5. Satisfy Hygiene, Hunger, Hydration, Energy, and wardrobe requirements.
6. Use every required phone app without opening developer tools.
7. Leave home and travel to at least three city destinations.
8. Complete one institutional objective and one NPC activity.
9. Observe time, money, needs, quests, calendar, and relationship state change.
10. Save, close the game, reload, and resume without losing or duplicating state.
11. Advance beyond Sunday without a forced review, weekly priorities, or expiration
    of open-ended quests.

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

When the conversation ends, the phone quest tracker unlocks and the open sandbox
begins without a chapter-selection screen or forced route.

### Home exploration

The Hale home is a connected visual-novel location screen. The slice requires the player bedroom,
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

Implementation note: the current playable home exposes all twelve required spaces
through directional arrows and an accessible room list, exposes private bedrooms as knock-first doorway scenes with changing locked or unlocked states until permission is granted,
and gives the shared bathroom schedule-aware available, occupied, and locked states.
An occupied or locked bathroom replaces hygiene actions with knock and twenty-minute
wait choices. The home also provides bedroom, bathroom, kitchen, dining, laundry, garage, yard interactions,
and a state-backed wardrobe. Selecting another room does not consume time; confirmed
activities, conversations, and travel do. Elena, Daniel, and Lily appear on the VN
character stage according to work, school, and home routines stored in their character packages. Contextual choices offer active
story conversations or short ambient dialogue; unavailable family members remain at
their external schedule locations. The front gate now opens route confirmation, and
daily family-car permission can be requested from the garage.

Private doors require knocking or permission. Selecting an occupied bathroom or
restricted bedroom moves the player to its doorway, never through the closed door.

### Phone

The phone overlays the current VN location. Opening menus does not advance time;
only a confirmed action that declares a duration does. It must work with keyboard,
mouse, and controller.

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

Implemented expansion apps:

- Education: class attendance, studying, coursework, exams, grades, and standing
- Jobs: listings, applications, interviews, shifts, payroll, and career progress
- Money: accounts, tuition, rent, debt, ledger, receipts, and weekly budgets
- Shopping: seven store catalogs, live quotes, purchases, discounts, and tax

Scheduling an NPC activity adds it to the calendar. Work or school conflicts prevent
confirmation. Other conflicts create a visible double-booking warning but remain
allowed.

Implementation note: the phone currently renders every required app from one
reusable scene. Opening messages remain authored inside their owners' `.character`
packages. Replies consume five minutes and apply declared relationship or quest
effects atomically. The scheduler checks fixed NPC work and school commitments,
stores confirmed plans, supports cancellation, and records optional overlap
warnings. The City Map compares live route time, cost, waits, closures, weather, and
safety requirements before confirmation. Save/load, control remapping, text and
contrast options, reduced motion, complete audio controls, display preferences, and
VN skip behavior are available from both the phone and main menu.
The Money app synchronizes recurring obligations exactly once per due date and the
Shopping app commits payment and inventory delivery as one rollback-safe action.

### City travel

The front yard exits to Alder Heights. The player can walk to the street, bus stop,
Forge Fitness, and Alder Bay Park. Westshore, Harbor Employment Centre, and
Harborlight Cinema load as destination scenes from the city map or transit flow.

Walking, bus, taxi, and permitted car trips display time, cost, weather exposure,
and arrival block. The slice must fully implement walking and bus travel. Taxi and
car may use menu-driven travel but must still charge money and advance time.

Closed destinations show their next opening time. Travel that would arrive too late
warns the player before confirmation.

Implementation note: the first nine destinations are connected through a
bidirectional graph planner. Walking links can connect to bus, taxi, or car legs;
bus waits vary by activity block. Confirmed trips use atomic begin/complete events,
charge an available account, advance exact minutes, update travel and quest state,
and enter a reusable destination scene whose rooms come from the city registry.

### Required quest proof

Every life path must be completable far enough to prove its system:

- College: visit Westshore, choose a program and course load, select a tuition plan,
  and create class calendar entries.
- Employment: browse jobs, review requirements, submit an application, and schedule
  or practice an interview.
- Both: create a class schedule and save a compatible part-time availability profile.

The required opening-week proof stops after schedule creation, but the implementation
now continues through the full first semester and a ninety-day employment review.
Later-semester course catalogs and graduation remain future content.

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

### Sandbox quest proof

Quests are discovered from locations, NPCs, messages, activities, institutions, or
earlier branches and are open-ended by default. Optional discoveries become offers;
the player can accept, postpone, reconsider, decline, track, or untrack them.
Advancing beyond Sunday must not open a planning screen or
expire open-ended content. Westshore registration demonstrates the exceptional
case: a visible institutional deadline with a narrative reason and warnings.

## Visual and audio scope

The slice may use original placeholder art but cannot use unlabeled debug rectangles
in the required path.

Minimum visual set:

- Main-menu background
- Player identity/profile placeholder art
- Household and four featured NPC placeholder portraits or standing character art
- Hale home room backdrops and prop illustrations
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
| Navigate choices | Arrow keys, mouse, or Tab | Left stick or D-pad |
| Select / advance | E, Space, Enter, or left click | South face button |
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
5. Load global quests, conversations, sandbox quest rules, and opening-calendar content.
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
- Finished background art for every city room and district interior
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

Implement VN room navigation, contextual choices, scheduled household appearances,
wardrobe, Hygiene, food, and sleep. Completion requires leaving the house in a valid outfit.

### Phase 4 — Phone and calendar

Implement every required phone app, messages, scheduling, conflicts, reminders, and
quest navigation. Completion requires scheduling Emma's walk.

### Phase 5 — City and activities

Implement travel, destination scenes, enrollment or employment proof, Rachel's gym
assessment, and one social activity. Completion requires time, cost, needs, and
relationship effects to survive scene changes.

### Phase 6 — Saves and sandbox continuity

Save slots, rotating autosaves, quicksave, checksum validation, atomic writes,
backup recovery, migration, Continue, and load controls are implemented. Sandbox
quest tracking, complete persistent settings, and the accessibility baseline are
implemented and covered by headless logic and live-scene probes. The connected
new-game-through-the-opening-calendar save/load round trip is implemented and runs
as part of the standard Godot test suite.

### Phase 7 — Stabilization

Run all acceptance tests, fix blockers, profile performance, package desktop builds,
and record remaining issues. The slice is complete only when the completion gate in
`content/vertical_slice/manifest.json` passes.

## Acceptance tests

Machine-readable acceptance cases live in
`tests/acceptance/vertical_slice.json`. Priority 0 represents a release blocker;
Priority 1 is required for the slice; Priority 2 may be deferred only with a written
issue and no effect on the required loop.
