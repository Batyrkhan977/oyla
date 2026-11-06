# ÖmirAI

ÖmirAI is an accessible, offline-first daily activity companion for adults and older adults. My Day combines routines, four cognitive games, a small reading library, movement timers, and explainable local personalization. It does not assess health or provide medical advice.

The current specification is [the ÖmirAI technical specification](docs/OmirAI_Technical_Specification_RU.docx). This implementation extends the existing app with Music, Piano Journey, Sing, Тоғызқұмалақ Academy, read-aloud tracking, Connect and consent-based family emails. Existing package identifiers and databases are retained for upgrade compatibility.

See [the implementation comparison and release status](docs/omirai-implementation.md) for requirement coverage, validation and outstanding release dependencies. Future features explicitly excluded by the specification are not enabled.

## Repository

- `mobile/` — Flutter application for Android and iOS
- `backend/` — Java 21 Spring Boot API
- `infra/` — local PostgreSQL and production container assets
- `docs/` — architecture, privacy, and accessibility decisions

## Run locally

Prerequisites: Flutter 3.44.7 with Dart 3.12+, JDK 21, and Gradle 8.14+.
The Flutter version is intentionally pinned: newer Flutter releases raise the
iOS deployment floor and may migrate the Xcode project automatically.

```bash
cd backend && ./gradlew bootRun --args='--spring.profiles.active=local'
cd mobile && flutter pub get && flutter run
```

The `local` backend profile uses a persistent H2 database at
`backend/.local-data/` and returns the six-digit development code to the app,
so email authorization can be tested without SMTP or Docker. Production and
non-local profiles continue to use PostgreSQL and Flyway migrations.

When the emulator and backend run in the same native host environment, Android
can connect through `http://10.0.2.2:8080/api/v1`. When the Android emulator and
ADB run on Windows while the backend runs in WSL, use the launcher below. It
starts the local backend when necessary, detects WSL's current address, and
configures the debug build automatically:

```bash
./scripts/run-local-emulator.sh
```

Use this as the only launch command for the Windows-emulator/WSL setup. Do not
also run `./gradlew bootRun` or plain `flutter run`: the launcher manages the
backend and passes the reachable WSL API address to Flutter. Plain `flutter run`
uses `10.0.2.2`, which points at Windows rather than the backend in WSL. The
launcher installs the debug APK directly because the VM-service port forwarded
by Windows `adb.exe` is not reachable from the Flutter process in WSL.

An ADB reverse tunnel is not sufficient in this setup because the Windows
`adb.exe` forwards to Windows localhost rather than WSL localhost.

For PostgreSQL parity testing, install Docker and run
`docker compose -f infra/docker-compose.yml up -d`, then start the backend
without the `local` profile.

The mobile app is fully usable as a guest without the backend. The library includes 12 original materials in English, Kazakh, and Russian. Listening uses installed device TTS voices. For Android emulators, its default API URL is `http://10.0.2.2:8080/api/v1`.

## Run on an iPhone

iOS builds require a Mac with compatible Xcode command-line tools and exactly
Flutter 3.44.7. The generated runner is iPhone-only and supports iOS 13 and
newer. If you use FVM, running `fvm install` inside `mobile/` reads the checked-in
`.fvmrc`; otherwise install Flutter 3.44.7 from Flutter's SDK archive.

1. Connect the unlocked iPhone to the Mac, trust the computer, and enable
   **Settings > Privacy & Security > Developer Mode** on the phone.
2. Run `cd mobile && flutter pub get`, then open
   `mobile/ios/Runner.xcworkspace` in Xcode.
3. Select the Runner target, enable **Automatically manage signing**, and
   choose your Apple ID's Personal Team. If Apple reports that `com.oyla.app`
   is unavailable, assign a unique reverse-domain bundle identifier.
4. Select the connected iPhone as the run destination. A free Apple ID works
   for direct device testing; TestFlight and App Store delivery require paid
   Apple Developer Program membership.

Guest workouts do not need a backend. To test accounts, sync, and daily-plan backup,
start the local backend on the Mac, keep the Mac and iPhone on the same network,
and find the Mac's Wi-Fi address in **System Settings > Wi-Fi > Details**. Then
launch these commands in two terminals from the repository root:

```bash
(cd backend && ./gradlew bootRun --args='--spring.profiles.active=local')
(cd mobile && flutter run -d <iphone-device-id> \
  --dart-define=OYLA_API_URL=http://<mac-lan-ip>:8080/api/v1
)
```

Run `flutter devices` to find the device ID. The first authenticated request
prompts for local-network access; allow it. If the phone cannot connect, verify
that macOS Firewall permits Java to accept connections on port 8080. Local HTTP
is permitted only by the iOS Debug configuration; release and profile builds
retain the normal HTTPS-only transport policy.

## Verify

```bash
cd mobile && flutter analyze && flutter test
cd backend && ./gradlew test
```

On a Mac, also run `cd mobile && flutter build ios --simulator --debug` to
compile the iOS runner and all native plugins without device signing.

See [docs/architecture.md](docs/architecture.md) for implementation details and [docs/product.md](docs/product.md) for MVP behavior.

## MVP verification

Run `scripts/emulator-smoke.py` after the local emulator launcher. It creates a walking routine and reading progress, exercises user flows, and writes screenshots to `/tmp/oyla-emulator-evidence`; it never clears app data. The launcher builds only the emulator architecture to reduce installation space and backs up the existing H2 database before an upgrade.

See [MVP acceptance evidence](docs/mvp-acceptance.md) for verified scenarios and remaining platform checks.

## YouTube channels

Movement activities support channel recommendations, search, saved favorites, and random videos meeting the planned minimum duration. See [YouTube setup and behavior](docs/youtube-setup.md) to connect a backend API key. The key is never bundled in the app.
