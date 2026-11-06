# Sing catalog

Added 27 September 2026. Titles retain their original language; Latin aliases support search. “Vanka” is “Ванька холостой”, as confirmed by the user. “Guilderaiym” is catalogued as “Гүлдерайым”.

These are links to hosted performances, not bundled audio, lyrics, or transcribed melodies. The existing original offline practice song remains available. Internet access is needed for the recordings. All 20 current primary recordings and two alternates were checked with YouTube oEmbed and started successfully in the emulator’s embedded player on 27 September 2026. Availability may change by region or over time.

| Song | Performer / channel | Recording |
| --- | --- | --- |
| Япурай (Yapurai) | Бекболат Тілеухан | [YouTube](https://www.youtube.com/watch?v=YOy09eVGZTM) |
| Дударай (Dudarai) | Роза Рымбаева | [YouTube](https://www.youtube.com/watch?v=Y4_UpbgH6vQ) |
| Балқадиша (Balqadisha) | Тлеужан | [YouTube](https://www.youtube.com/watch?v=isOln_AnnNA) |
| Бір бала (Bir Bala) | Балаларға арналған әндер | [YouTube](https://www.youtube.com/watch?v=yrM01U6vhjM) |
| Қамажай (Qamajai) | Дауыс International | [YouTube](https://www.youtube.com/watch?v=00zSwKH8hpk) |
| Елім-ай (Elim-ai) | Өмірқұл Айниязов | [YouTube](https://www.youtube.com/watch?v=IUbiiko_3iU) |
| Бипыл (Bipyl) | Жамал Омарова | [YouTube](https://www.youtube.com/watch?v=rZNlUtx4oCA) |
| Гүлдерайым (Guilderaiym) | Айнұр Иманқызы | [YouTube](https://www.youtube.com/watch?v=e4k8HELTzx4) |
| Дайдидау (Daididau) | Дінмұхаммед Қайрат | [YouTube](https://www.youtube.com/watch?v=bvx7g70SIrg) |
| Самалтау (Samaltau) | Димаш Құдайберген | [YouTube](https://www.youtube.com/watch?v=1NkoFc-bQ_s) |
| Калинка (Kalinka) | Вадим Ананьев | [YouTube](https://www.youtube.com/watch?v=bobTxw_VJOM) |
| Коробейники (Korobeiniki) | Леонид Сметанников | [YouTube](https://www.youtube.com/watch?v=KeurN5I-c6I) |
| Из-за острова на стрежень (Iz-za ostrova na strezhen) | Надежда Кадышева | [YouTube](https://www.youtube.com/watch?v=neB-Ns-CnUM) |
| Вот мчится тройка почтовая (Vot mchitsya troika pochtovaya) | Иван Скобцов | [YouTube](https://www.youtube.com/watch?v=Pqqinwbw6Bg) |
| Эй, ухнем (Ey ukhnem) | Леонид Харитонов | [YouTube](https://www.youtube.com/watch?v=eE-Q6RH_Zzk) |
| Дубинушка (Dubinushka) | Фёдор Шаляпин | [YouTube](https://www.youtube.com/watch?v=xeLxsBpzYDg) |
| За морем синичка (Za morem sinichka) | Валерия Геллерт | [YouTube](https://www.youtube.com/watch?v=ysDQMic86Fw) |
| Светит месяц (Svetit mesiats) | Жанна Бичевская, Бисер Киров, Дин Рид | [YouTube](https://www.youtube.com/watch?v=WQ-tBW5Abxg) |
| Ванька холостой (Vanka) | Русская песня | [YouTube](https://www.youtube.com/watch?v=-nrd02DGQmM) |
| Во поле берёза стояла (Vo pole bereza stoyala) | ВЕК | [YouTube](https://www.youtube.com/watch?v=Ck00bzX1trA) |

Yapurai was identified from the [indexed performance listing](https://yandex.kz/video/preview/12448753485203602640). Dudarai now uses the Roza Rymbaeva recording above. Other recording titles were identified from indexed YouTube listings. No redistribution license is asserted for these recordings.

## Interface translation verification

Reviewed English, Kazakh and Russian interface strings, preserving song and game names. Fixed Sing and Connect navigation, loading/save/startup errors, reading metadata labels and values, handwriting prompts and accessibility labels, Togyz board accessibility labels, connection/challenge statuses, generated activity names in suggestions and saved-video lists, and the Android notification channel label. Language selectors retain native language names; personal names and user-authored content are preserved.

Validation: all 103 Flutter tests pass; `flutter analyze --no-pub` reports no issues; Android `:app:compileDebugKotlin --offline` succeeds. Added explicit dictionary-key and placeholder coverage plus catalog search, filtering and playback-routing tests in all three languages with enlarged text. Playback verification was subsequently completed as described below; availability outside the tested emulator/network is not guaranteed.

## Playback repair and verification — 27 September 2026

The original Dudarai link (`DYqBRjA-s98`) returned HTTP 404 from YouTube oEmbed. The original Samaltau link (`92rINhHwfCg`) returned HTTP 403. Both produced player error 150 with no playback on the emulator. The other 18 recordings played successfully, so they were retained.

Replacement sources:

- Dudarai: [Roza Rymbaeva](https://www.youtube.com/watch?v=Y4_UpbgH6vQ), with [Alisa Supronova](https://www.youtube.com/watch?v=tJ6a7oMULjM) as an alternate.
- Samaltau: [Dimash Qudaibergen, 2019](https://www.youtube.com/watch?v=1NkoFc-bQ_s), with [another official performance](https://www.youtube.com/watch?v=OLrFs0WRxgY) as an alternate.

All 22 retained/replacement sources returned public oEmbed metadata and reached player state `PLAYING` with advancing time and no player error during a six-second sample in the emulator’s existing embedded YouTube player. This verifies playback starts, not each recording’s full duration. The two retired links failed in the same test. The library already uses the app identity required by YouTube; no spoofed origin or referrer was added.

The song page now offers alternate performances and a direct YouTube button. The native player distinguishes missing/private videos, embedding restrictions, player identity failures, and other playback errors. It offers a known alternate when available and a song-title search when a source becomes unavailable. Retry retains the selected alternate and position; successful playback clears the error.

Run `python3 scripts/check-song-recordings.py` for a live metadata check of all primary and alternate links. This needs network access and no API key. Follow with actual device playback checks because metadata availability alone does not guarantee playback.

Post-install verification: the Dudarai primary recording played in the rebuilt app. A simulated embedding error exposed the alternate-recording button; selecting it played Alisa Supronova, cleared the error, and Retry retained that alternate and its position. Eleven playback/catalog regression tests passed, Flutter analysis was clean, and the debug APK built and installed successfully. See [playback evidence](sing-playback-verification.json).
