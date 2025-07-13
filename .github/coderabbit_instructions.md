# CodeRabbit AI 리뷰 지침서

## 프로젝트 개요
이 프로젝트는 **Flutter 기반 AI 음성 분석 애플리케이션**입니다.

### 핵심 기술 스택
- **Frontend**: Flutter (Dart)
- **상태 관리**: Riverpod
- **로컬 DB**: Hive
- **음성 인식**: Whisper.cpp (FFI)
- **텍스트 분석**: LLaMA.cpp (FFI)
- **아키텍처**: Clean Architecture

## 🎯 CodeRabbit 리뷰 우선순위

### 1. 최고 우선순위 (Critical)
- **FFI 메모리 관리**: malloc/free 쌍, 메모리 누수 방지
- **Null Safety**: null 체크, late 변수 초기화
- **비동기 처리**: Future/async-await 패턴 안전성
- **플랫폼 호환성**: 조건부 컴파일 정확성

### 2. 높은 우선순위 (High)
- **상태 관리**: Riverpod Provider 패턴 일관성
- **오류 처리**: try-catch 블록, 예외 전파
- **성능**: 불필요한 rebuild, 메모리 사용량
- **보안**: 민감 데이터 노출, API 키 보호

### 3. 중간 우선순위 (Medium)
- **코드 품질**: Dart 스타일 가이드 준수
- **아키텍처**: 레이어 분리, 의존성 방향
- **테스트**: 커버리지, 테스트 품질
- **문서화**: 주석, README 업데이트

## 📋 프로젝트별 특화 검토 규칙

### FFI (Foreign Function Interface) 검토
```dart
// ✅ 좋은 예시 - 적절한 메모리 관리
final ptr = calloc<Uint8>(size);
try {
  // FFI 작업 수행
  return processData(ptr);
} finally {
  calloc.free(ptr);  // 항상 메모리 해제
}

// ❌ 나쁜 예시 - 메모리 누수 위험
final ptr = calloc<Uint8>(size);
return processData(ptr);  // 메모리 해제 없음
```

### 상태 관리 패턴 검토
```dart
// ✅ 좋은 예시 - Immutable state
state = state.copyWith(isLoading: true);

// ❌ 나쁜 예시 - Mutable state 직접 수정
state.isLoading = true;  // 권장하지 않음
```

### 플랫폼별 조건부 코드 검토
```dart
// ✅ 좋은 예시 - 안전한 플랫폼 분기
import 'service_stub.dart'
    if (dart.library.io) 'service_impl.dart'
    if (dart.library.html) 'service_web.dart';

// ❌ 나쁜 예시 - 런타임 플랫폼 체크
if (kIsWeb) {
  // 웹 전용 코드
} else {
  // 모바일 코드
}
```

## 🔍 코드 리뷰 체크포인트

### 서비스 레이어 검토
- [ ] 인터페이스와 구현체 일치성
- [ ] 의존성 주입 패턴 준수
- [ ] 오류 처리 및 폴백 로직
- [ ] 비동기 작업 취소 가능성

### UI 레이어 검토
- [ ] Widget 재사용성
- [ ] BuildContext 안전한 사용
- [ ] 접근성 (Semantics) 지원
- [ ] 반응형 디자인 고려

### 데이터 레이어 검토
- [ ] Hive 어댑터 버전 관리
- [ ] 데이터 마이그레이션 전략
- [ ] 캐싱 전략 효율성
- [ ] 데이터 검증 로직

## 🚨 자주 발생하는 문제들

### 1. FFI 관련 문제
- 메모리 해제 누락
- 플랫폼별 라이브러리 로딩 실패
- 포인터 타입 불일치
- 스레드 안전성 문제

### 2. 상태 관리 문제
- Provider 순환 참조
- StateNotifier 부적절한 사용
- 상태 업데이트 누락
- 메모리 누수 (listener 해제 안함)

### 3. 비동기 처리 문제
- BuildContext 비동기 간격 사용
- Future 체이닝 오류
- 비동기 작업 취소 미처리
- 경쟁 조건 (Race condition)

## 💡 CodeRabbit에게 요청하는 추가 검토 사항

### 성능 최적화
- 불필요한 widget rebuild 감지
- 메모리 사용량 분석
- 이미지/애셋 최적화 제안
- 앱 시작 시간 개선점

### 보안 검토
- API 키/토큰 하드코딩 검사
- 민감한 로그 출력 검사
- 파일 권한 적절성
- 네트워크 보안 설정

### 접근성
- 스크린 리더 지원
- 키보드 네비게이션
- 색상 대비 확인
- 텍스트 크기 대응

## 📝 리뷰 형식 요청

### 코멘트 구조
1. **문제 설명**: 무엇이 문제인지 명확히
2. **영향도**: 성능/보안/유지보수에 미치는 영향
3. **해결 방법**: 구체적인 개선 코드 제시
4. **대안**: 여러 해결책이 있다면 비교 설명

### 예시 리뷰 코멘트
```
🚨 **Critical**: 메모리 누수 위험

현재 FFI 포인터가 해제되지 않아 메모리 누수가 발생할 수 있습니다.

**수정 제안**:
```dart
final ptr = calloc<Uint8>(size);
try {
  // 작업 수행
} finally {
  calloc.free(ptr);
}
```

**참고**: FFI 메모리 관리 베스트 프랙티스 [링크]
```

## 🎉 기대하는 CodeRabbit의 역할

1. **멘토 역할**: 코드 품질 향상을 위한 건설적 피드백
2. **보안 가드**: 잠재적 보안 위험 사전 차단
3. **성능 컨설턴트**: 최적화 기회 발견 및 제안
4. **지식 공유자**: Flutter/Dart 베스트 프랙티스 전파

---

CodeRabbit AI는 이 지침서를 참고하여 프로젝트의 특성에 맞는 맞춤형 코드 리뷰를 제공해주시기 바랍니다.