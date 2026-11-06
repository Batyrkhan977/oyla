# ÖmirAI MVP product rules

The authoritative scope is `OmirAI_Technical_Specification_RU.docx`; see `omirai-implementation.md` for the MVP and Version 1 additions. ÖmirAI helps adults build a regular day through cognitive activity, reading, movement, and personal routines. It does not assess health or provide medical advice.

## My Day

Guests can select activities, weekdays, time, duration, and reminders. Each dated occurrence supports Start, Complete, Postpone, and Skip. A postponement changes that occurrence only. Editing a routine changes future days; history remains intact. Removing a routine retires it without deleting history.

## Cognitive activity

Exactly four games are playable: Quick Sums, Word Garden, Picture Pairs, and Find the Target. A daily workout contains three distinct deterministically selected games. All four are immediately available in practice. Quick Sums has five questions and supports an accessible keypad. Picture Pairs has four pairs and one unmatched symbol in a 3×3 grid. Difficulty adapts after three completed rounds, by at most one level, using 85% and 55% accuracy boundaries. Abandonment is not an incorrect answer.

## Reading and movement

The offline library contains 12 original short ÖmirAI materials in English, Kazakh, and Russian. The reader saves position and active reading duration, supports device TTS, and offers two optional questions. Answers are not uploaded or stored. Users cannot upload books. The library records origin, edition, and publication basis.

Exercise, walking, tai chi, yoga, Pilates, stretching and dance use timers and explicit full/partial/not-today confirmation. Walking can be entered manually. Movement is measured in minutes, without GPS, steps, calories, watches, or Health Connect. Watching content or leaving a timer running does not automatically complete a session.

## Personalization and progress

Local rules consider the last 28 days: repeated postponements, preferred start time, shorter duration, ignored reminders, and preferred movement type. At most one recommendation appears. Each explains observed usage and requires Accept or Keep unchanged; rejection suppresses that proposal for 14 days. Personalization can be disabled.

Progress reports active days, completed actions, reading minutes, movement minutes, and cognitive workouts. There is no combined brain or health score.

## Release boundary

Included: offline core flows, optional email account and backup, local reminders, English/Kazakh/Russian, accessibility, account deletion.

Version 1 adds Android read-aloud tracking, Piano Journey, Sing, Togyz Academy, mutually confirmed friends, streaks/freezes, challenges and consent-based family emails. See `omirai-implementation.md` for remaining content and deployment dependencies. Future extra games, voice-command navigation, ML/LLM features and sensor integrations remain excluded. Advertisements and medical profiling are prohibited. Legacy records remain compatible.

## Activity UI and YouTube links

My Day uses activity cards with a full-width Start / Continue action. Mark completed,
Postpone, Skip, and Edit activity are available in the card menu. A persistent
bottom navigation connects My Day, Routines, Library, Practice, and Progress.
Routines are grouped into Mind, Read, Move, Music and Togyz; custom routines live in Mind. Music includes Piano and Sing, and Activities provides the Connect entrypoint.

Add activity and Edit activity are full-screen forms, ordered as activity type and
name, duration, format, video source, schedule, and reminder. Movement and custom
activities support Timer only or With video. Cognitive workouts and library
reading keep their dedicated experiences. Saving an edit preserves already
planned occurrence snapshots and applies the changes to future days, as explained
in the editor.

Video source is a separate screen. This phase accepts individual YouTube video
links (watch, youtu.be, shorts, embed, and live), normalizes them, and removes
tracking and playlist parameters. It validates URL structure locally; video
availability is checked by the user through Preview on YouTube. The session screen
opens the video in YouTube or the browser. The timer remains usable offline and
completion still requires the user's confirmation. Existing routines without a
video source stay timer-only. Sources persist with routines and occurrence
snapshots through the existing JSON storage and sync.

YouTube search, channel / playlist selection, and duration / preference-based
video matching are deferred to subsequent phases.
