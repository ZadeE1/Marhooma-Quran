# Marhooma Quran

> *An immersive Quran recitation app designed for focused spiritual engagement*

[![Flutter](https://img.shields.io/badge/Flutter-3.8+-02569B.svg?style=flat&logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-blue)](https://flutter.dev/multi-platform)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🌟 Purpose

Marhooma Quran transforms the traditional Quran reading experience into an immersive, distraction-free journey. Unlike conventional apps with complex navigation and cluttered interfaces, Marhooma focuses on what matters most: **connecting with the Quran through synchronized audio and text**.

### Core Philosophy
- **Single-Screen Simplicity**: One unified interface that combines verse display, audio controls, and settings
- **Focus Mode**: Automatic immersion that hides all UI elements after 10 seconds of inactivity
- **Verse-by-Verse Synchronization**: Audio perfectly aligned with text for enhanced comprehension
- **Offline-First**: Complete Quranic text available without internet connectivity

## ✨ Key Features

### 🎧 **Immersive Audio Experience**
- **Multiple Reciters**: Choose from renowned Quranic reciters with high-quality audio
- **Seamless Playback**: Gapless transitions between verses for uninterrupted listening
- **Background Support**: Continue listening with full Android media controls integration
- **Smart Caching**: Audio files cached on mobile for offline listening

### 📖 **Focused Reading Interface**
- **Clean Typography**: Arabic text in Amiri font with English translations
- **Animated Transitions**: Four elegant transition styles (fade, scale, slide, elegant)
- **Focus Mode**: Hides app UI and system bars for distraction-free reading
- **Auto-Advance**: Seamlessly continues to next surah when current one completes

### ⚙️ **Thoughtful Design**
- **Dark Mode**: Optimized for comfortable reading in all lighting conditions
- **Material 3**: Modern, accessible design following Material Design principles
- **Platform Adaptive**: Optimized for mobile, desktop, and web platforms
- **Minimal Dependencies**: Leverages offline packages to reduce data usage

## 🚀 Getting Started

### Prerequisites
- Flutter 3.8+ installed
- Android Studio / Xcode for mobile development
- Device/emulator for testing

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/ZadeE1/Marhooma-Quran.git
   cd Marhooma-Quran/quran_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Development with Device Testing

For optimal audio testing, use the included scrcpy scripts:

```bash
# Full audio mirroring (recommended for audio testing)
./openScrcpy.bat

# Performance mode (for UI testing)
./openScrcpyNoAudio.bat
```

## 🏗️ Architecture

### Service Layer
- **QuranAudioPlayer**: Manages `just_audio` with platform-specific optimizations
- **QuranTextService**: Offline text retrieval using the `quran` package
- **QuranApiService**: Manages reciter and surah data from bundled assets

### Audio Integration
Audio follows EveryAyah.com format:
```
https://everyayah.com/data/{reciter_subfolder}/{surah_padded}{ayah_padded}.mp3
```
- Zero-padded numbering (001, 002, etc.)
- URL validation before playlist creation
- Platform-adaptive caching (`LockCachingAudioSource` on mobile, streaming on desktop)

### UI Design
- **Single Screen**: `SpecialDisplayScreen` serves as the only interface
- **Modal Overlays**: Settings accessible through non-intrusive modals
- **Animation System**: Four configurable transition styles with 400ms timing

## 🛠️ Technical Highlights

### Audio Features
- **Background Playback**: Full Android media session integration
- **Gapless Playback**: Seamless verse-to-verse transitions
- **Smart Caching**: Mobile-optimized audio caching with fallback streaming
- **Media Controls**: Lock screen and notification panel controls

### Performance Optimizations
- **Lazy Loading**: Audio sources loaded just-in-time
- **Efficient Animations**: Separate controllers for smooth 60fps performance
- **Offline Text**: Zero network dependency for Quranic text
- **Platform Adaptation**: Optimized behavior for each target platform

## 📱 Platform Support

| Platform | Status | Features |
|----------|--------|----------|
| Android | ✅ Full | Background audio, media controls, audio caching |
| iOS | ✅ Full | Background audio, media controls, audio caching |
| Web | ✅ Core | Audio streaming, responsive design |
| Desktop | ✅ Core | Audio streaming, native performance |

## 🎨 Design Principles

- **Minimalist Interface**: Reduce cognitive load during spiritual practice
- **Focus-First**: Automatic immersion mode for distraction-free reading
- **Accessibility**: High contrast, readable fonts, and intuitive navigation
- **Performance**: Smooth 60fps animations and responsive interactions

## 🔧 Development

### Key Commands
```bash
# Development
flutter run

# Production build
flutter build apk --release

# Device mirroring for testing
scrcpy --audio-source=output --stay-awake --window-height=1500
```

### Dependencies
- `just_audio` + `just_audio_background`: Audio playback and background support
- `quran`: Offline Quranic text and translations
- `google_fonts`: Amiri (Arabic) and Lato (UI) typography
- `wakelock_plus`: Prevents device sleep during playback

## 🤝 Contributing

We welcome contributions that align with the app's core philosophy of simplicity and focus. Please read our [contributing guidelines](CONTRIBUTING.md) before submitting pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **EveryAyah.com**: High-quality Quranic recitations
- **Quran Package**: Offline text and translation data
- **Just Audio**: Robust Flutter audio framework
- **Islamic Community**: Guidance and feedback on spiritual UX

---

*Built with ❤️ for the global Muslim community*
