# Port Alder Connected Vertical-Slice Playtest

The connected-run probe protects the first complete player journey across systems.
It uses the same controls, services, scenes, content, and save format as the game
instead of constructing a pre-completed test state.

## Automated route

`tools/test_all.sh` runs `scenes/tests/vertical_slice_runtime_probe.tscn` after the
foundation and focused live-scene probes. The route verifies:

1. Character creation through the live UI, including an August 21 birthday that
   automatically resolves to 2007, appearance, traits, archetype, hobbies, and the
   Standard financial background.
2. Elena's complete opening conversation and the College life-path decision.
3. Entry into the Hale home sandbox, room state, a shower, and changed Hygiene.
4. Quest and Calendar phone views backed by the current runtime state.
5. A paid bus trip from the Hale home to Westshore Administration.
6. Part-time Computer Systems enrollment with financial aid, two courses, and the
   generated class calendar.
7. Acceptance of Emma's optional story, her authored text reply, scheduling a valid
   evening hangout, travel to the waterfront, and completion of her friendship path.
8. Rejection of Emma's scene when its required appointment is absent.
9. Completion of the appointment, quest, relationship effects, and character memory.
10. An isolated checksum-backed save/load round trip and scene resume at Alder Bay
    Park. Probe saves use their own temporary directory and are removed afterward.

## Manual verification

Before packaging a playable build, repeat the same route with mouse and keyboard,
then repeat character creation, dialogue choices, phone navigation, and interactions
with a controller. Confirm visual focus, readable text, correct button states,
transition timing, audio feedback, and that Continue resumes at the waterfront.

The connected probe is a regression gate, not a replacement for the remaining
priority-zero and priority-one acceptance cases in `tests/acceptance/vertical_slice.json`.
