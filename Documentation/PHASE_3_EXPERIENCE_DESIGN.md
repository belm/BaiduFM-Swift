# Phase 3: Top-Tier Experience Design

## Product promise

Baidu FM should feel calm, immediate, and trustworthy every time it opens. The interface must make the current song, playback state, and available actions obvious without requiring the user to interpret legacy icons or wait for a modal alert.

## Experience principles

1. **Music first** — artwork and song identity form the visual hierarchy; secondary controls stay quiet.
2. **Every action answers** — play, like, download, seek, retry, and delete provide visual, haptic, and accessibility feedback.
3. **Continuity without surprise** — restore the last song and position in a paused state; never autoplay on cold launch.
4. **One truthful state** — download and favorite controls derive from the durable managers and database, not optimistic local flags.
5. **Comfort for everyone** — support Dynamic Type, VoiceOver, sufficient contrast, large touch targets, Reduce Motion, and both English and Simplified Chinese.

## Player information architecture

The player uses one adaptive vertical composition:

1. channel navigation and ambient artwork background;
2. large rounded artwork card;
3. song, artist, and album identity;
4. scrubbable timeline with elapsed and total time;
5. previous, play/pause, and next controls;
6. like and download actions with explicit selected/progress states;
7. a quiet lyric surface that preserves focus on playback.

The layout must fit compact iPhones without clipping and should expand artwork on larger devices. It uses safe-area constraints instead of fixed storyboard coordinates.

## Interaction states

### Playback

- `idle`: first or restored song is prepared but paused.
- `loading`: the play control shows activity and remains understandable to VoiceOver.
- `playing`: the play control becomes pause; artwork receives a subtle scale treatment when Reduce Motion is off.
- `paused`: position is retained and persisted.
- `error`: a concise recovery alert is shown without destroying the current song context.

### Download

- available: arrow icon and “Download” accessibility value;
- queued/downloading: progress ring-equivalent icon state and percentage accessibility value;
- paused/failed: resumable state exposed on the Downloads screen;
- completed: filled checkmark icon and local playback preference.

### Favorite

- unselected: outline heart;
- selected: filled heart using the accent color;
- state is derived from the database-backed favorites list.

## Motion and feedback

- Use short spring transitions for direct manipulation only.
- Use light haptics for transport controls and selection feedback for like/download.
- Announce completed downloads and state changes through VoiceOver.
- Disable decorative transforms when Reduce Motion is enabled.
- Avoid per-cell scale-from-zero animations; use a restrained fade/translation once.

## Continuity

- Persist the current song and position at coarse checkpoints and on pause.
- Restore the paused session before refreshing the catalog so local playback remains available offline.
- Restore the snapshot only when its URL remains secure or a verified local file exists.
- Restore paused, never playing, after a cold launch.
- Record a song in Recents when playback actually starts and order Recents by last-played time.

## Acceptance criteria

- No cold-launch autoplay.
- Timeline seeking works by touch and VoiceOver adjustable actions.
- Like and download buttons always match their durable state.
- All primary controls have at least 44-point targets, labels, values, and hints.
- Player fits supported compact and regular size classes without fixed vertical coordinates.
- Dynamic Type, dark appearance, Reduce Motion, English, and Simplified Chinese remain usable.
- Last song and position restore in a paused state.
- Recently Played is populated and ordered correctly.
- Swift package tests, release metadata checks, and the iOS Simulator build gate pass.
