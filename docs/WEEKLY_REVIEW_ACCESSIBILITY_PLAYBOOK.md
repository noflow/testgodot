# Weekly Review and Accessibility Playbook

## Sunday reflection

The phone automatically opens the weekly review when the clock reaches Sunday
Evening. Opening it creates one pending record for the current game week. A pending
record remains available through Late Evening and Night; completing it prevents a
second review during the same week.

The review is descriptive, not evaluative. It shows:

- Current education, employment, and life-path direction
- Ledger-backed income, spending, balances, tuition, debt, and rent
- Elapsed time, completed or missed commitments, lateness, sleep, and naps
- Average energy, hygiene, mood, stress, workouts, exposure, and health conditions
- Closest known contacts, relationship-meter changes, dates, and story chapters
- Completed, active, deferred, and failed quests plus branch changes

There is no score, grade, winning path, failure screen, or hidden optimization
reward. The summary is frozen into completed-review history so a later state change
cannot rewrite what that week looked like.

## Next-week priorities

The player may choose zero to three priorities from Education, Career, Finances,
Health, Relationships, Rest and Recreation, and Personal Growth. Priorities are
intentions rather than quests. Each selected priority creates a calendar reminder
for the next week, but missing it has no direct penalty. The review also links to
the normal calendar scheduler so the player can reserve a real commitment before
finishing.

Review definitions live in `content/systems/weekly_review.json`. Runtime summary and
selection logic lives in `src/review/weekly_review_engine.gd`; state mutation still
passes through the atomic simulation operation interface.

## Persistent settings

The same controls are available from the main menu and phone:

- Text size: 100%, 125%, 150%, or 175%
- Reduce motion and high-contrast presentation
- Independent screen-edge-effect and camera-shake preferences
- Dialogue skipping as hold or toggle, plus replay-current-line
- Master, music, ambience, UI, and voice volumes
- Windowed or fullscreen display, three window sizes, and VSync
- Remapping for movement, interaction, menus, phone shortcuts, dialogue, saves, and
  controller inputs, with a reset-to-default action

Settings save automatically to `user://settings.cfg` and apply at startup. They are
device preferences, not part of a playthrough save. High contrast adds white text,
black panels, and a visible yellow focus outline; reduced motion disables camera
smoothing and makes VN lines appear immediately. Text scaling and contrast apply
to main-menu, creation, VN, home, city, and phone UI trees.

## Authoring and verification rules

- New gameplay interfaces must call `SettingsService.apply_accessibility` on their
  root and react to `settings_changed` when they remain alive behind a settings UI.
- New player inputs must be added to `REMAPPABLE_ACTIONS` when safe to rebind.
- Visual effects must respect the screen-effect and camera-shake preferences once
  that effect type is introduced.
- Review values must come from saved state, calendar records, ledger entries, or
  simulation events—never from UI-only counters.
- Review language must remain factual and nonjudgmental.

The foundation suite checks the authored package, trigger timing, section totals,
priority cap, reminders, duplicate protection, older-save initialization, and
atomic completion event. Runtime probes check both settings surfaces, large text,
high contrast, automatic Sunday opening, priority selection and calendar return,
plus 175% VN lines, choices, utility controls, reduced motion, and skip behavior.
