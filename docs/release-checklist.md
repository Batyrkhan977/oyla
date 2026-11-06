# Release checklist

## Product

- Complete every exercise with TalkBack, VoiceOver, and at 200% text scaling.
- Test the smallest supported phone plus physical Android and iPhone devices; the iOS build must not advertise iPad support.
- Build iOS with the pinned Flutter 3.44.7 SDK and confirm the deployment target remains iOS 13.0 in Debug, Profile, and Release.
- Verify reminder permission grant and denial, narration, one-time-code autofill, and secure token persistence on iOS.
- Moderate usability sessions with at least five adults from the target audience.
- Confirm all prompts, images, names, and sounds are original and licensed for use.

## Privacy and security

- Configure and test the SMTP delivery credentials; never enable development code logging outside local development.
- Set `AUTH_EXPOSE_CODE=false`, rotate database credentials and `AUTH_PEPPER`, and require TLS.
- Publish privacy policy, terms, support contact, export instructions, and deletion instructions.
- Verify logs contain no tokens, codes, answer content, or full email addresses.
- Run dependency and container scans and rehearse database restore.

## Store and operations

- Configure a release signing key outside the repository; the checked-in Android config uses debug signing only.
- Configure an Apple distribution team and production signing before TestFlight or App Store delivery; personal-team signing is for direct device testing only.
- Provide store listing, screenshots, content rating, non-medical disclaimer, and data-safety declaration.
- Confirm health checks, backups, alerting, crash reporting consent, and staging/production separation.
- Roll out through internal testing, closed beta, then a staged production release.

## Final-spec MVP regression checks

- Run `flutter analyze`, `flutter test`, and backend `./gradlew test`.
- Run the PostgreSQL version-4-to-6 migration test with Docker available; an H2 pass is insufficient.
- Run `scripts/run-local-emulator.sh`, then the emulator smoke, offline, accessibility, and reminder scripts. They preserve existing data and restore temporary emulator settings.
- Confirm four base cognitive games and three-game daily workouts, with Togyz in its own Academy. Verify Connect sharing is disabled by default and private routines/scores never appear in friend summaries.
- Confirm recommendation acceptance is required and personalization can be disabled.
- Review the 12 original reading materials and localized text before public distribution.
- Complete a human TalkBack/Switch Access walkthrough and notification reboot/timezone tests on physical Android hardware.
- On macOS, compile and verify the retained iOS runner, TTS voices, and notification actions.

See `mvp-acceptance.md` for the recorded verification results.

## ÖmirAI Version 1

- Complete the folk-song rights and recording review before declaring FR-SING-02 complete.
- Verify all Piano modes, synthesized sound, Togyz lesson/capture/tuzdyk positions and saved-game restoration on Android hardware.
- Check read-aloud availability and disclosure for installed Kazakh, Russian and English recognition services.
- Verify mutual friendship, invitation limits, challenge acceptance, earned/gifted freezes and disabling social display.
- Configure SMTP and the public HTTPS unsubscribe endpoint; verify recipient opt-out and owner revocation with test recipients before enabling production delivery.
- See `omirai-implementation.md` for current automated verification and known release dependencies.
