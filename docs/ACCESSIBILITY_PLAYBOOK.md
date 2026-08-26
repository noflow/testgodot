# Accessibility and Settings Playbook

The same persistent controls are available from the main menu and phone:

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
- Required controls cannot rely on color alone and must remain usable at 175% text.
- Menu, dialogue, phone, and world interactions must remain keyboard- and
  controller-operable without requiring a mouse.

