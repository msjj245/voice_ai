# Voice AI App - 배포 가이드

## 🚀 Android 배포

### 1. 사전 준비

#### 필수 도구
- Flutter SDK (3.0+)
- Android Studio
- Android NDK
- Java JDK 11+

#### Whisper.cpp 파일 준비
1. https://github.com/ggerganov/whisper.cpp 에서 소스 다운로드
2. `native/whisper_cpp/` 디렉토리에 복사
   - whisper.cpp, whisper.h
   - ggml 관련 파일들

### 2. 빌드 과정

```bash
# 1. 빌드 스크립트 실행
./build_android.sh

# 또는 수동으로:
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build apk --release --split-per-abi
```

### 3. 테스트

#### 로컬 디바이스 테스트
```bash
# 연결된 디바이스 확인
adb devices

# APK 설치
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

#### 에뮬레이터 테스트
```bash
# x86_64 버전 설치
adb install build/app/outputs/flutter-apk/app-x86_64-release.apk
```

### 4. Google Play 출시

#### App Bundle 생성
```bash
flutter build appbundle --release
```

#### 서명 (실제 출시 시)
1. keystore 생성:
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. `android/key.properties` 파일 생성:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=../upload-keystore.jks
```

3. `android/app/build.gradle` 수정하여 서명 설정 추가

#### Play Console 업로드
1. https://play.google.com/console 접속
2. 새 앱 생성
3. `app-release.aab` 업로드
4. 스토어 등록 정보 작성
5. 콘텐츠 등급 설정
6. 가격 및 배포 설정

### 5. 출시 전 체크리스트

- [ ] 모든 권한이 올바르게 설정되었는지 확인
  - 마이크 권한
  - 저장소 권한
- [ ] ProGuard 규칙 확인 (난독화)
- [ ] 모든 디버그 로그 제거
- [ ] API 키나 민감한 정보 제거
- [ ] 앱 아이콘 및 스플래시 화면 확인
- [ ] 다양한 화면 크기에서 UI 테스트
- [ ] 오프라인 모드 테스트
- [ ] 모델 다운로드 기능 테스트

### 6. 성능 최적화

#### APK 크기 줄이기
- 사용하지 않는 리소스 제거
- 이미지 최적화
- 코드 난독화 활성화

#### 앱 시작 시간 개선
- 지연 로딩 구현
- 스플래시 화면 최적화

## 📱 사용자 가이드

### 첫 실행
1. 앱 실행 시 온보딩 화면 표시
2. 필수 AI 모델 다운로드 안내
3. 권한 요청 (마이크, 저장소)

### 모델 선택 가이드
- **Tiny (39MB)**: 빠른 처리, 기본 정확도
- **Base (74MB)**: 균형잡힌 성능 (권장)
- **Small (244MB)**: 높은 정확도, 느린 처리

### 문제 해결
- 모델 다운로드 실패: Wi-Fi 연결 확인
- 음성 인식 실패: 마이크 권한 확인
- 앱 충돌: 저장 공간 확인

## 🔒 보안 고려사항

1. 모든 처리는 로컬에서 수행
2. 네트워크는 모델 다운로드에만 사용
3. 사용자 데이터는 기기에만 저장
4. 암호화된 저장소 사용 권장

## 📊 분석 및 모니터링

### Firebase 통합 (선택사항)
1. Firebase 프로젝트 생성
2. google-services.json 추가
3. 크래시 리포팅 활성화
4. 사용 분석 추가

## 🆕 업데이트 관리

### 버전 관리
- `pubspec.yaml`에서 버전 업데이트
- 변경 로그 작성
- 호환성 테스트

### 단계적 출시
1. 내부 테스트 (팀원)
2. 비공개 베타 (100명)
3. 공개 베타 (1000명)
4. 정식 출시

## 📝 스토어 등록 정보

### 필수 항목
- 앱 이름: Voice AI Assistant
- 간단한 설명 (80자)
- 자세한 설명 (4000자)
- 스크린샷 (최소 2개)
- 기능 그래픽 (1024x500)
- 앱 아이콘 (512x512)

### 권장 카테고리
- 생산성
- 도구

### 콘텐츠 등급
- 전체 이용가

---

## 지원 및 피드백
- 이메일: support@voiceai.app
- 문제 신고: GitHub Issues