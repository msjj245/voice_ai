# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Communication Rules

**IMPORTANT: Always respond in Korean (한국어) when working on this project.**
이 프로젝트에서 작업할 때는 항상 한국어로 응답해야 합니다.

## Common Development Commands

### Setup and Dependencies
```bash
# Initial setup
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# iOS setup (macOS only)
cd ios && pod install && cd ..

# Quick setup and run
./run_app.sh
```

### Development
```bash
# Run in development mode
flutter run

# Run with hot reload on specific platform
flutter run -d android
flutter run -d ios

# Generate code (Hive adapters, JSON serialization)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for continuous code generation
flutter pub run build_runner watch
```

### Testing and Quality
```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Generate app icons
dart run tools/generate_icons.dart
```

### Native Libraries and AI Models
```bash
# Build native libraries (Whisper.cpp, LLaMA.cpp)
./native/build_native.sh all

# Cross-platform build (Android + iOS)
./native/build_native.sh all --cross-platform

# Download Whisper models
./native/whisper_cpp/download_whisper.sh recommended

# Check downloaded models
./native/whisper_cpp/download_whisper.sh check
```

### Building
```bash
# Android development build
flutter build apk --debug

# Android release build
./build_android.sh

# iOS release build
flutter build ios --release

# Manual release builds
flutter build apk --release --split-per-abi
flutter build appbundle --release
```

## Architecture Overview

### Voice Processing Pipeline
Audio recording → Audio processing → Whisper transcription → LLM analysis → Local storage

### Core Services Architecture
- **AudioService**: File management and recording metadata
- **WhisperService**: Local speech-to-text with speaker diarization (실제 whisper.cpp FFI 연동)
- **LLMService**: Local AI analysis with llama.cpp integration (emotion, summarization, task extraction)
- **ModelManager**: Automatic AI model download and initialization
- **ModelDownloadService**: Advanced model download with retry, verification, progress tracking
- **StorageService**: Hive-based local database

### State Management
Uses **Flutter Riverpod** with:
- Service providers for dependency injection
- StateNotifier providers for complex state (AudioProvider, HistoryProvider)
- Stream providers for reactive data updates

### Native Integration
- **WhisperFFI**: Complete whisper.cpp integration with C FFI bindings
- **LocalLLMEngine**: llama.cpp integration for local LLM inference
- **AudioProcessor**: Advanced audio processing (WAV conversion, PCM extraction, resampling)
- **Cross-platform**: Platform-specific library loading for Android/iOS/Desktop
- **Build Scripts**: Automated native library compilation for all platforms

### Offline-First Design
- All AI processing happens locally (no cloud dependencies)
- Models downloaded once with integrity verification and progress tracking
- Graceful fallbacks when models unavailable (simulation mode)
- Web platform uses mock services, native platforms use real AI models

## Key File Locations

### Core Application
- `lib/main.dart`: App initialization and model setup
- `lib/services/`: Core business logic and AI services
- `lib/providers/`: Riverpod state management
- `lib/models/`: Data structures with Hive adapters

### AI Integration
- `lib/services/whisper_service_impl.dart`: Speech-to-text implementation
- `lib/services/llm_service_impl.dart`: Local LLM inference
- `lib/services/ffi_bridge.dart`: Native library integration
- `lib/constants/model_configs.dart`: AI model definitions and URLs

### Platform-Specific
- `android/`: Android configuration and native libraries
- `ios/`: iOS configuration and CocoaPods
- `native/`: C/C++ and Rust source files

## Development Patterns

### Adding New AI Services
1. Create interface in `services/interfaces/`
2. Implement in `services/` with simulation layer
3. Add model config to `constants/model_configs.dart`
4. Register with ModelManager
5. Integrate via Riverpod provider

### Model Management
- Models defined in `ModelConfigs` with size, URL, capabilities
- Automatic download with user consent for large files
- Version management and integrity verification
- Progressive loading with cancellation support

### Data Storage
- **Transcriptions**: Hive database with structured models
- **Audio files**: Local filesystem with metadata
- **AI models**: Cached in assets/models/ directory
- **Settings**: SharedPreferences for app state

### Native Code Integration
- FFI structs defined in `ffi_bridge.dart`
- Platform-specific library loading
- Memory management with proper allocation/deallocation
- Error handling for native operations

## Testing Strategy
- Unit tests for service logic (use mock services to avoid requiring models)
- Widget tests for UI components
- Integration tests for audio pipeline
- Simulation layers allow development without full AI models