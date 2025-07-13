# Copilot Instructions for Marhooma-Quran

## Project Overview
This is a Flutter Quran app focused on audio recitation with verse-by-verse synchronization. The app provides an immersive, single-screen experience with focus mode functionality that hides UI elements for distraction-free reading.

## Architecture & Key Components

### Core Service Layer (`lib/data/services/`)
- **QuranAudioPlayer**: Singleton managing `just_audio` with platform-specific optimizations. Uses `LockCachingAudioSource` on mobile, falls back to `AudioSource.uri` on desktop/web
- **QuranTextService**: Offline text retrieval using the `quran` package with English translations
- **QuranApiService**: Singleton managing reciter/surah data from bundled JSON assets

### Audio Integration Pattern
Audio URLs follow EveryAyah.com format: `https://everyayah.com/data/{reciter_subfolder}/{surah_padded}{ayah_padded}.mp3`
- Surah/ayah numbers are zero-padded to 3 digits (001, 002, etc.)
- Reciter subfolders are defined in `quranApiRef.json`
- Audio validates first URL before building full playlist to handle network issues gracefully

### UI Architecture (`lib/ui/`)
**Single Screen Design**: `SpecialDisplayScreen` is the main and only screen - no tab navigation
- Combines verse display, audio controls, and settings in one unified interface
- Uses modal overlays (`SettingsModal`) rather than separate screens

**Focus Mode**: 10-second inactivity timer triggers immersive mode
- Hides app UI elements AND Android system bars using separate animation controllers
- Three animation controllers for performance: app bar, bottom nav, skip widget

### Animation System
Four configurable transition styles in `VerseTransitionStyle` enum:
- `fadeOnly`, `fadeScale`, `fadeSlide`, `elegant`
- Uses implicit animations (`AnimatedOpacity`, `AnimatedScale`, `AnimatedSlide`) for performance
- 400ms duration with `Curves.easeInOut` for consistency

## Development Workflow

### Key Commands
```bash
# Main development
flutter run
flutter build apk --release

# Debugging with device mirroring
scrcpy --audio-source=output --stay-awake --window-height=1500 --video-codec=h265
scrcpy --no-audio --stay-awake --max-fps=30 --video-codec=h264  # Performance mode
```

### Critical Dependencies
- `just_audio` + `just_audio_background`: Core audio with Android media controls
- `audio_session`: Android media session integration
- `wakelock_plus`: Prevents sleep during playback
- `quran`: Offline text/translation source
- `google_fonts`: Amiri (Arabic) + Lato (UI) typography

## Project-Specific Patterns

### Theme System (`app_theme.dart`)
- Forced dark mode always: `themeMode: ThemeMode.dark`
- Seed color: `#3AB56B` with Material 3 color scheme generation
- Consistent spacing constants: `spaceXs` (4px) through `spaceXl` (32px)
- Font strategy: Amiri for Arabic text, Lato for UI elements

### State Management
No external state management - uses Flutter's built-in StatefulWidget with:
- Service singletons for data persistence
- Stream subscriptions for audio state
- Efficient animation controllers with separate dispose

### Data Models
Simple PODOs without complex inheritance:
- `Surah`: number, name, ayahCount
- `Reciter`: id, name, bitrate, subfolder
- `Ayah`: text, translation, positioning metadata

### Platform Adaptations
Audio caching only on mobile platforms (`!kIsWeb && (Android || iOS)`)
Desktop/web uses direct streaming to avoid caching limitations

## File Locations
- Assets: `quran_app/assets/data/` (quranApiRef.json, quranSurahs.json)
- Main entry: `lib/main.dart` with `JustAudioBackground.init()`
- Single screen: `lib/ui/screens/special_display_screen.dart`
- Core services: `lib/data/services/`

## Testing & Debugging
Use scrcpy batch files for real device testing with audio. The app requires actual device testing for audio session integration and Android media controls functionality.
