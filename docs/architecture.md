# Architecture

Flutter retains Riverpod, GoRouter, Drift/SQLite, SharedPreferences, Dio, secure token storage, and device TTS. The Java 21 Spring Boot backend uses JPA, PostgreSQL, Flyway, and bearer authentication.

## Daily activity modules

`day_models.dart` defines routines, dated occurrences, activity events, recommendations, and the pure local rules. `day_state.dart` serializes transactions and joins local state with reminder actions and sync. `day_screens.dart` provides My Day, routine editing, reading, movement, and participation progress. Original content is bundled in `reading_library.dart`.

Drift schema version 2 adds account-owned routine, occurrence, event, reading-position/session, movement-session, recommendation, and settings tables. Each row has a validated JSON payload, revision, pending-upload flag, and optional conflict snapshot. Existing result and social tables are retained. Routine definitions are separate from dated snapshots. Completion transitions and their events are written together, with stable IDs to prevent duplicates.

## Synchronization

`POST /api/v1/sync/day` accepts up to 2,000 revisioned records. The client batches at 1,000 records. The server assigns ownership from authentication and serializes changes per account. Events and movement confirmations are immutable. Repeated identical uploads succeed. Conflicting changes return the server version without replacing local data; My Day offers a version choice. The MVP response is a full account snapshot with an informational server cursor. Routine deletion is represented by a tombstone.

Day data is partitioned by account. Guest records are claimed when the user signs in for backup. Sign-out selects a separate guest partition; account deletion removes the account's day records. Core flows never require sync success.

Flyway V5 adds `day_record` and makes historical friend codes nullable. Previous migrations and records remain intact. The development H2 profile uses Hibernate schema updates; it does not prove PostgreSQL migration parity.

## Reminders and lifecycle

The platform channel schedules dated activity reminders. Android stores a durable action queue that Flutter acknowledges only after committing events. Permission denial does not pretend that delivery succeeded. Reminders support Start, 30-minute postponement, and Skip. Quiet hours suppress delivery. The app refreshes the rolling schedule on resume and periodically while My Day is open.

Reading records text position and active elapsed time periodically, on navigation, and on lifecycle changes. Movement timers recover from the recorded start time and always require confirmation of actual minutes. TTS uses voices installed on the device; absent language voices leave ordinary reading available.

## Privacy and compatibility

Only usage history is used for personalization. No health inference, answer-level reading history, microphone audio, location, or contact data is collected. The two archived exercise IDs remain decodable but have no playable implementation. Historical friendship records remain private; the Version 1 Connect endpoints expose only consented participation summaries. Read-aloud speech is processed by the Android device service after explicit disclosure; the app stores no microphone recordings.

Android is the MVP acceptance platform. The existing iOS runner and platform channels are retained; native iOS compilation requires macOS/Xcode.

## ÖmirAI Version 1 additions

`brand.dart`, `music_screens.dart`, `sing_screen.dart`, `togyz.dart`, `togyz_screen.dart` and `connect_screen.dart` extend the existing routes. `MusicVoiceBridge.kt` implements generated audio and user-started Android recognition without audio files. New content remains in the shared account-owned Drift store and existing day sync; schema version 3 adds four tables without dropping prior data.

Flyway V6 adds Connect settings, challenges and family consent subscriptions. Social responses use an explicit summary projection. Consent and unsubscribe are separate from friendship preferences. Family sending is disabled unless both delivery and an HTTPS public URL are configured. See `omirai-implementation.md` for scope, operational configuration and remaining release dependencies.
