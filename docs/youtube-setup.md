# Connect YouTube to ÖmirAI

The implementation is ready to use a YouTube Data API v3 key. Without a key,
channel search shows a connection message; pasted video links and timers work.
There are no fake search results or bundled API credentials.

## One-time Google setup

1. Open [Google Cloud Console](https://console.cloud.google.com/) and create or select a project.
2. In **APIs & Services → Library**, find **YouTube Data API v3** and enable it.
3. In **APIs & Services → Credentials**, create an **API key**.
4. Restrict the key to **YouTube Data API v3**. For deployment, also restrict it to
   your backend's outgoing public IP addresses. ÖmirAI sends requests from the server,
   so Android application restrictions do not apply to this key.

See [Google's setup guide](https://developers.google.com/youtube/v3/getting-started)
and [API key practices](https://docs.cloud.google.com/docs/authentication/api-keys-best-practices).
No YouTube sign-in or subscription permissions are needed: favorites belong to ÖmirAI.

## Local setup

From a Bash terminal in the project root, enter the key without putting it in
shell history or printing it:

```bash
read -rsp 'YouTube API key: ' YOUTUBE_API_KEY
export YOUTUBE_API_KEY
./scripts/run-local-emulator.sh
```

If the local backend is already running, stop that backend first and restart the
launcher in this terminal so it inherits the new environment variable. Setting
`infra/.env.example` alone does not load a key. Do not add a key to source files,
Flutter `--dart-define`, or the APK.

The backend health endpoint `/api/v1/youtube/status` returns
`{"configured":true}` when a nonempty key is loaded. It does not validate the key
against Google. Test live access with the app's channel picker. Wrong API
restrictions, a disabled API, or exhausted quota show a retry message.

## Use it

**Activities → add/edit a movement activity → With video → Choose YouTube channels.**
The picker requests three relevant channels for the activity type. Search supports
more results and pagination. Select up to five favorite channels or use **Pick a
random channel**. Save the channel selection, then save the activity.

Favorites are stored per activity type in account-owned day settings. The activity
stores its selected channel pool, and each planned day retains its own snapshot.
Existing planned days keep their settings when a routine is edited.

Starting a session chooses a channel from the activity's favorites, retrieves its
uploads in pages of 50, and checks exact durations in seconds using `videos.list`.
A video exactly equal to the requested duration qualifies; shorter videos never do.
Private, unavailable, unprocessed, and live/upcoming videos are excluded.

Selection is random among qualifying videos in the first eligible upload page,
not uniformly random across the entire channel. Up to ten pages are checked per
attempt. If older pages remain, **Look through older videos** continues the search.
Only the end of the uploads list produces a no-match message. A timer fallback is
always available. Android playback occurs inside ÖmirAI using the open-source
[android-youtube-player](https://github.com/PierfrancescoSoffritti/android-youtube-player)
13.0.0 WebView player. Pasted-link previews and selected session videos use the same
player, with standard YouTube controls (including seeking and available captions
and playback settings), fullscreen, retry, and an external YouTube fallback.
Playback pauses when the player is no longer visible and releases on exit. Back
exits fullscreen first, then returns to the activity. Rotation retains the player;
activity recreation restores its position. Playback itself needs no Data API key.
On other platforms playback occurs in YouTube or the browser. The user confirms
actual completion in ÖmirAI. Regional restrictions or later removals can still prevent
playback; the user can choose another video.

The chosen video is saved on the occurrence and survives navigation or restart.
Choosing another video avoids repeating the same video when alternatives exist in
the page, and changes channels when the activity has multiple favorites.

API reference: [channel search](https://developers.google.com/youtube/v3/docs/search/list),
[uploads playlist](https://developers.google.com/youtube/v3/docs/channels/list),
[playlist pagination](https://developers.google.com/youtube/v3/docs/playlistItems/list),
[video metadata](https://developers.google.com/youtube/v3/docs/videos).

## Deployment and verification

Set `YOUTUBE_API_KEY` on the backend service and restart it. The Flutter app uses
its existing `OYLA_API_URL`. The GET routes `/youtube/channels` and `/youtube/videos`
are available to guests; requests have a per-address limit and responses use a
bounded five-minute server cache. Configure upstream rate limits for larger deployments.
Google's project quota still applies and can be inspected in Cloud Console.

Run `cd backend && ./gradlew test` and `cd mobile && flutter test`.
API transport tests use controlled Google responses and do not spend quota.
Live Google verification requires your key and is separate from those tests.
