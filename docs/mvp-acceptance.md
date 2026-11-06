> Historical acceptance record for the earlier MVP. Current ÖmirAI scope and verification are in [omirai-implementation.md](omirai-implementation.md).

# Final-spec MVP implementation and verification

Specification: `Final_Technical_Specification_Oyla.pdf`, sections 39–42.

The app implements My Day, recurring routines and dated completions, four cognitive games, a 12-material localized offline library, reading/TTS progress, confirmed movement minutes, activity events, five local recommendation rules, account-owned sync, and participation progress. Friends and the two excluded games are removed from active use. Existing history is retained.

## Recorded verification

- Flutter analyzer: no issues.
- Flutter regression suite: 59 tests passed.
- Backend: 10 tests passed. The PostgreSQL migration test was skipped because Docker is unavailable.
- Android debug APK: built, installed in place, and opened on `emulator-5554`.
- Emulator smoke: routine creation, movement timer and partial confirmation, seven movement minutes in progress, reading navigation and resume, TTS controls, optional questions, and exactly four games passed.
- Emulator offline checks: postpone, skip, a previously unopened reading material without connectivity, persisted activity after process restart, and 200% system text scaling passed.
- Native Android reminder: scheduled delivery and notification Skip action passed; the original app reminder preference was restored.
- TalkBack: service enabled, My Day accessibility tree and keyboard focus inspected. This was a structural check, not a complete human speech or Switch Access audit.
- Retained Flutter/native error logs contained no unhandled exception, fatal crash, or RenderFlex overflow after those flows.

Screenshots: [My Day](verification/my-day.png), [reading](verification/reading.png), [200% text](verification/large-text.png), [TalkBack](verification/talkback.png). Full temporary evidence and XML trees are under `/tmp/oyla-emulator-evidence`.

## PDF acceptance criteria

| # | Criterion | Evidence |
|---|---|---|
| 1 | Start without registration | Guest emulator flows and local state tests |
| 2 | Create a daily plan | Routine editor exercised on emulator |
| 3 | My Day displays the plan | Planned, completed, postponed, and skipped screenshots |
| 4 | Complete, postpone, skip | Emulator UI actions and idempotent transaction tests |
| 5 | Four cognitive exercises | Generator/widget tests, four-game menu, emulator game screens |
| 6 | Daily cognitive workout | Deterministic three-distinct-game regression test |
| 7 | Adaptive difficulty | Accuracy-boundary and adaptation tests |
| 8 | Select and read material | Library and reader emulator flow |
| 9 | Retain reading position | Leave/reopen reader emulator check |
| 10 | TTS | Device TTS controls exercised; voice availability depends on installed voices |
| 11 | Reading questions | Two-question optional dialog exercised |
| 12 | Start physical activity | Movement timer emulator flow |
| 13 | Retain movement duration | Seven-minute confirmation and restart persistence |
| 14 | Manually record walking | Manual duration control and completion persistence tests |
| 15 | Activity Events | Atomic state/event and duplicate-action tests |
| 16 | Personalization rules | All five rules, evidence thresholds, and cooldown tests |
| 17 | Explainable recommendation | Reason/proposal UI plus rule tests |
| 18 | Accept or reject | Acceptance persistence and rejection cooldown tests |
| 19 | No silent schedule changes | Acceptance-only change test; existing occurrence unchanged |
| 20 | Offline core flows | Network-disabled reader and process-restart checks |
| 21 | TalkBack and large text | Service/tree/focus check, emulator 200% screenshot, small-display widget tests |
| 22 | No medical conclusions | Product copy and recommendation-rule review |

## Data preservation and remaining release checks

The original local H2 database was copied to `backend/.local-data/pre-mvp-backup/oyla.mv.db` before the launcher upgraded it. The Android application was updated without uninstalling it or clearing its data. Tests created sample routines, reading positions, and movement history on the emulator. Temporary network, font, TalkBack, and storage-reserve settings were restored.

Run the PostgreSQL migration test with Docker before deployment. Native iOS build/runtime verification requires macOS/Xcode. Complete human TalkBack/Switch Access testing, physical-device notification reboot/timezone checks, and editorial review of localized reading content before public release. The MVP sync endpoint currently returns a full account snapshot; pagination is a later scaling concern.
