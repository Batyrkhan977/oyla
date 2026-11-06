# ÖmirAI implementation and specification comparison

Source: `OmirAI_Technical_Specification_RU.docx`, current edition supplied in this repository. Implementation date: 27 September 2026.

## Decision: extend the existing project

The existing app already uses Flutter/Riverpod, GoRouter, Dio, Drift/SQLite and Java 21/Spring/JPA/PostgreSQL/Flyway, exactly as required in section 3. Its tested daily plan, routines, notifications, four games, reading library, movement timers, authentication and sync are valuable working foundations. A rewrite would duplicate these systems and risk losing installation data without resolving any architectural mismatch.

Package names (`com.oyla.app`, Dart package `oyla`), method channels for existing features, storage filenames and legacy settings keys are intentionally retained for compatible upgrades. User-facing names, Android launcher label/icon, authentication emails, reading attribution and current release documentation use ÖmirAI. Historical specification files remain intact.

The implemented target is Core + MVP + Version 1. Section 25's Future work and section 24's explicit exclusions are not silently promoted into this release.

## Comparison and additions

| Specification | Existing foundation | ÖmirAI implementation |
| --- | --- | --- |
| 3–9: architecture, guests, My Day, routines, events, games, difficulty | Implemented | Reused; corrected Picture Pairs to include the specified unmatched ninth symbol; extended activity kinds to Music, Togyz, stretching, dance, Personal and Other; retained history |
| 7: explainable personalization | Five evidence-based local rules and confirmation before changes | Existing rules apply to new routine categories; music sessions correlate with an active music routine for time/duration evidence |
| 10: controlled reading, TTS, questions and rights | 12 original multilingual materials, position/session storage, TTS | Preserved; Android read-aloud recognition with explicit disclosure, conservative forward matching, highlighted read text and saved position; no app audio files |
| 11: movement | Timers, manual confirmation, minutes, YouTube selection | Added stretching and dance; no GPS, steps or medical metrics |
| 12: Music hub | Absent | Music links to Piano Journey and Ән салайық; accessible custom brand icons |
| 12.1: Piano | Absent | Four modes, synthesized notes, visible/accessible keys, 3 keys expanding to one octave, guided fragments combined into a melody, saved lessons/levels/sessions, no ability score |
| 12.2: Sing | Absent | Listen/sing/repeat controls, synchronized lyric line, tempo and manual line navigation, optional hidden words, session recording; original offline practice song plus a searchable catalog of 20 linked Kazakh/Russian recordings |
| 13: Togyz Academy | Absent | Seven interactive topics, sowing/capture/tuzdyk/endgame rules, three bounded-search AI levels, explained hints, deterministic daily capture positions and automatic game save/resume |
| 14–15: Connect and streaks | Historical friendship/cache schema only | Mutual confirmation, sharing off by default, allowlisted summary, daily invitation limit, optional challenges, earned/gifted freezes, display opt-out; no scores or private routine contents |
| 16: family emails | SMTP used for login only | Owner consent, chosen address and threshold, optional weekly summary, revocation, recipient unsubscribe, once-per-inactivity-episode scheduler; delivery configuration required |
| 17–18: progress, offline and sync | Account-owned local records and conflict handling | Music and Togyz progress/sessions/game state in Drift; schema v3 upgrade; new kinds in existing versioned sync; new module activity contributes to active days |
| 19: accessibility and brand | Large text, contrast setting, existing tests | Deep Teal/Warm Sand theme, sprout mark, amber wordmark accent, eight custom direction symbols, Android launcher icon; wrapping keyboard/board and screen-reader state labels |
| 20: privacy | No ads, medical profiling or required account for local activity | Explicit sharing defaults, restricted summaries, no microphone in Sing, no app audio storage, deletion includes new server data |
| 21–23: entities, tests and acceptance | Existing MVP suites | Added persistent social/consent entities, music/Togyz records, API documentation and targeted tests |

## Remaining release dependencies and limitations

This is a working development implementation, not a declaration that every release acceptance criterion has been manually certified.

- **FR-SING-02 is not complete:** the supplied repository does not include a cleared Kazakh folk-song collection with verified words, compositions and recordings. The player ships an original ÖmirAI practice song, clearly identified as original. The [Sing catalog](sing-catalog.md) also offers 20 hosted recording links; those recordings require internet and do not add bundled lyrics, melodies or audio. It does not mislabel that song as folklore. Add reviewed catalog entries with source-specific rights and `approvedForPublication: true`; do not publish modern arrangements or commercial recordings on the assumption that a song title is traditional.
- Speech recognition and synthesized music use the new **Android** bridge. The existing iOS app remains, but equivalent new native iOS media functionality is not implemented. The specification's required platform is Android. On unsupported platforms the screens report unavailable audio/recognition.
- Android read-aloud uses the installed recognition service, requests offline recognition, and explains that the provider may use the network. Availability and language support depend on the device. Matching is approximate; it is not pronunciation scoring. No app recording is saved. Recognition is per user-started passage, not continuous background listening.
- No production SMTP credentials or public deployment URL were supplied. Consent can be saved, but delivery is disabled until the configuration below is provided. The UI exposes whether server delivery is configured. No real family emails were sent during development.
- Social day boundaries use the stored account timezone with UTC fallback for invalid legacy values; local My Day remains device-calendar based. Device timezone changes are applied on profile synchronization. Family delivery checks run hourly on the server.
- SMTP delivery and database commit are not a transactional outbox. Normal retries are suppressed after a successful commit; a process crash between provider delivery and commit could resend an email. A delivery provider with idempotency/outbox handling is recommended before production scale.
- TalkBack/Switch Access on real devices, sound audibility/latency, actual recognition in Kazakh/Russian/English, reduced-motion behavior, and a full palette contrast audit still require device acceptance. Automated large-text and semantic tests do not replace those checks.
- PostgreSQL migration tests use Testcontainers and are skipped when Docker is unavailable. Local H2 tests cover entity creation; production Flyway parity must also be run with Docker/PostgreSQL.
- Future ML planning, MIDI, online Togyz, CABO, unlicensed composer collections, extra cognitive games and voice-command navigation remain excluded by the supplied specification.

## Run and verify

Use the existing root README commands. For Android/Windows-emulator-in-WSL development, keep using `scripts/run-local-emulator.sh`; it preserves existing user data and configures the reachable API address.

```bash
cd mobile
flutter analyze
flutter test
flutter build apk --debug
```

```bash
cd backend
./gradlew test
```

New tests cover legal/illegal Togyz transitions, conserved 162-stone totals through complete games, AI legality, deterministic daily puzzles, saved-game restoration/account isolation, voice matching, piano fragment progression and saved sessions. Widget tests exercise Music, Piano, Sing and Togyz on a 320×568 display at 200% text size. Backend tests cover mutual consent, ownership, restricted summaries, rate limits, challenge acceptance, family consent/unsubscribe, inactivity email deduplication, module sync and account deletion.

## Family delivery configuration

Set existing `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_AUTH`, `SMTP_STARTTLS` and a verified `MAIL_FROM`. The default sender is deliberately an example address, not an owned sending domain.

Set `OMIRAI_PUBLIC_URL=https://your-public-api-host` and `OMIRAI_FAMILY_DELIVERY_ENABLED=true` only on the deployed backend. The URL must reach `/api/v1/family/unsubscribe/{token}`. The scheduler runs hourly. Its emails say **received app activity**, including an offline-sync caveat, rather than inferring a person's health or actual daily behavior. GET renders a confirmation form; POST unsubscribes, preventing email scanners from silently opting recipients out.

## Rule references

The Togyz implementation follows the [Kazakhstan federation rules](https://9kumalak.com/index.php/zhyldy-zhospar/509-to-yz-mala-a-idasy-men-erezhesi) and the [official English rules hosted by Mind Sports Olympiad](https://mindsportsolympiad.com/wp-content/uploads/2021/07/Rules-toguz-en-official.pdf): one stone remains when sowing a multi-stone pit, even captures on the opponent's side, a single tuzdyk with ninth-pit/same-number restrictions, 82-stone victory and empty-side endgame collection.

## Verification result

Flutter static analysis and all 98 mobile tests passed, including the new module, unmatched Picture Pairs tile, piano progression and large-text tests. Backend: 26 tests, 0 failures, 1 skipped (Docker-dependent PostgreSQL migration). A universal debug APK was generated at `mobile/build/app/outputs/flutter-apk/app-debug.apk` with arm64-v8a, armeabi-v7a and x86_64 libraries. This is a development-signed build, not a store release.
