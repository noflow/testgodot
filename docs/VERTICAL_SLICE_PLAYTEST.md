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
7. Acceptance of Emma's optional story and her authored text reply.
8. A live phone-scheduler availability preview that disables a class conflict and
   enables a valid evening hangout.
9. Calendar-driven placement of Emma in the exact waterfront room, with her portrait
   rendered over the location's visual-novel background.
10. Rejection of Emma's scene when its required appointment is absent.
11. Completion of the appointment, quest, relationship effects, and character memory.
12. Acceptance of Marcus's independent cinema story, including a second authored text
    thread and a movie appointment created in the phone.
13. Rejection of Marcus's Wednesday film-club conflict and acceptance of his available
    Tuesday late-evening window.
14. Travel to Harborlight Cinema, calendar placement and portrait staging in the lobby,
    and rejection of the VN scene when its appointment is absent.
15. Completion of Marcus's scene, his flag-selected trust branch, and the automatic
    start and text delivery for his next quest, The Missing Scene.
16. An isolated checksum-backed save/load round trip that preserves both characters'
    quest, message, meter, and memory state, then resumes at Harborlight Cinema. Probe
    saves use their own temporary directory and are removed afterward.

## Manual verification

Before packaging a playable build, repeat the same route with mouse and keyboard,
then repeat character creation, dialogue choices, phone navigation, and interactions
with a controller. Confirm visual focus, readable text, correct button states,
transition timing, audio feedback, and that Continue resumes at Harborlight Cinema
with The Missing Scene still active and Marcus's rough-cut message in the thread.

The connected probe is a regression gate, not a replacement for the remaining
priority-zero and priority-one acceptance cases in `tests/acceptance/vertical_slice.json`.
