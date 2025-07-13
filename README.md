# Voice AI App

AI 기반 음성 분석 앱 - 로컬 음성 인식과 텍스트 분석 기능을 제공합니다.

## 주요 기능

- 🎙️ 실시간 음성 녹음 및 파일 업로드
- 🗣️ 로컬 Whisper 모델을 사용한 정확한 음성 인식
- 👥 화자 분리 (Speaker Diarization)
- ✏️ 텍스트 편집 기능
- 🤖 AI 기반 분석 (감정 분석, 일정 추출, 회의록 요약)
- 🔒 완전한 오프라인 작동으로 개인정보 보호
- 📱 iOS & Android 지원

## 시작하기

### 필수 요구사항

- Flutter 3.0 이상
- Dart 3.0 이상
- iOS: Xcode 14 이상
- Android: Android Studio 또는 VS Code

### 설치

1. 의존성 설치:
```bash
flutter pub get
```

2. 코드 생성 (Hive 어댑터):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. iOS 설정 (iOS 디렉토리에서):
```bash
cd ios
pod install
```

### 권한 설정

#### iOS (ios/Runner/Info.plist)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>음성 녹음을 위해 마이크 접근이 필요합니다.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>오디오 파일 업로드를 위해 라이브러리 접근이 필요합니다.</string>
```

#### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

## Whisper 모델 통합

### flutter_whisper.cpp 설정

1. Native 디렉토리에 Whisper C++ 파일 추가
2. Rust FFI 브릿지 설정
3. 모델 파일 다운로드 및 assets/models/에 배치

### 지원 모델
- tiny: 39MB (가장 빠름)
- base: 74MB (균형잡힌 성능)
- small: 244MB (높은 정확도)

## 로컬 LLM 통합

llm_toolkit을 사용하여 Gemma 또는 Phi-3 모델 통합:

1. 모델 다운로드
2. assets/models/에 배치
3. 서비스에서 초기화

## 개발

### 프로젝트 구조
```
lib/
├── main.dart              # 앱 진입점
├── models/               # 데이터 모델
├── services/             # 비즈니스 로직
├── screens/              # UI 화면
├── widgets/              # 재사용 가능한 위젯
├── providers/            # Riverpod 상태 관리
└── utils/                # 유틸리티 함수
```

### 빌드 및 실행

개발 모드:
```bash
flutter run
```

릴리즈 빌드:
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 기여하기

이슈 및 PR은 언제나 환영합니다!

## 라이선스

MIT License