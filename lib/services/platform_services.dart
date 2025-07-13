// 플랫폼별 서비스 조건부 export
export 'whisper_service_stub.dart'
    if (dart.library.io) 'whisper_service_impl.dart'
    if (dart.library.html) 'whisper_service_web.dart';

export 'llm_service_stub.dart'
    if (dart.library.io) 'llm_service_impl.dart'
    if (dart.library.html) 'llm_service_web.dart';

// 플랫폼별 서비스 팩토리 함수들
import 'whisper_service_stub.dart'
    if (dart.library.io) 'whisper_service_impl.dart'
    if (dart.library.html) 'whisper_service_web.dart' as whisper_impl;
    
import 'llm_service_stub.dart'
    if (dart.library.io) 'llm_service_impl.dart'
    if (dart.library.html) 'llm_service_web.dart' as llm_impl;

// 서비스 인스턴스 제공 함수들
dynamic getWhisperService() => whisper_impl.WhisperService();
dynamic getLLMService() => llm_impl.LLMService();