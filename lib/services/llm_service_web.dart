import 'interfaces/llm_service_interface.dart';

// 웹용 LLM 서비스 모의 구현체
class LLMService implements ILLMService {
  bool _isInitialized = false;
  String? _currentModel;
  
  Future<void> initialize() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _isInitialized = true;
  }
  
  Future<bool> isInitialized() async {
    return _isInitialized;
  }
  
  @override
  Future<bool> loadModel(String modelName) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentModel = modelName;
    return true;
  }
  
  @override
  Future<bool> isModelDownloaded(String modelName) async {
    // 웹에서는 모든 모델이 "다운로드됨"으로 가정
    return true;
  }
  
  @override
  Future<void> downloadModel(String modelName, {Function(double)? onProgress}) async {
    // 웹에서는 모의 다운로드
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 50));
      onProgress?.call(i / 100.0);
    }
  }
  
  @override
  Future<Map<String, dynamic>> analyzeEmotion(String text) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    // 간단한 키워드 기반 감정 분석 모의
    final lowerText = text.toLowerCase();
    String emotion = 'neutral';
    double confidence = 0.7;
    
    if (lowerText.contains('좋') || lowerText.contains('기쁘') || lowerText.contains('행복')) {
      emotion = 'positive';
      confidence = 0.85;
    } else if (lowerText.contains('나쁘') || lowerText.contains('슬프') || lowerText.contains('화나')) {
      emotion = 'negative'; 
      confidence = 0.82;
    }
    
    return {
      'emotion': emotion,
      'confidence': confidence,
      'details': {
        'positive': emotion == 'positive' ? confidence : 0.2,
        'negative': emotion == 'negative' ? confidence : 0.1,
        'neutral': emotion == 'neutral' ? confidence : 0.3,
      }
    };
  }
  
  @override
  Future<String> summarizeText(String text) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    
    final sentences = text.split('.').where((s) => s.trim().isNotEmpty).toList();
    if (sentences.isEmpty) return '요약할 내용이 없습니다.';
    
    final firstSentence = sentences.first.trim();
    return '요약: $firstSentence... (웹 모의 요약)';
  }
  
  @override
  Future<List<String>> extractTasks(String text) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    final tasks = <String>[];
    
    // 간단한 키워드 기반 작업 추출
    if (text.contains('회의') || text.contains('미팅')) {
      tasks.add('회의 참석하기');
    }
    if (text.contains('보고서') || text.contains('문서')) {
      tasks.add('보고서 작성하기');
    }
    if (text.contains('연락') || text.contains('전화')) {
      tasks.add('연락하기');
    }
    
    if (tasks.isEmpty) {
      tasks.add('추출된 작업이 없습니다');
    }
    
    return tasks;
  }
  
  @override
  Future<String> generateMeetingMinutes(String transcription) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    
    return '''
# 회의록 (웹 모의 생성)

## 참석자
- 참석자 정보 추출됨

## 주요 내용
${transcription.length > 100 ? transcription.substring(0, 100) + '...' : transcription}

## 결정사항
- 웹에서 생성된 모의 결정사항

## 액션 아이템
- [ ] 추후 논의 필요 사항 정리
- [ ] 다음 회의 일정 조율

*이 회의록은 웹 환경에서 모의로 생성되었습니다.*
''';
  }
  
  @override
  Future<Map<String, dynamic>> analyzeTranscription(String transcription) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    return {
      'summary': await summarizeText(transcription),
      'emotion': await analyzeEmotion(transcription),
      'tasks': await extractTasks(transcription),
      'meeting_minutes': await generateMeetingMinutes(transcription),
    };
  }
  
  @override
  Future<Map<String, dynamic>> getModelInfo(String modelName) async {
    return {
      'name': modelName,
      'size': '모의 크기',
      'description': '웹용 모의 모델',
      'isDownloaded': true,
    };
  }
  
  @override
  Future<String> runCustomPrompt(String text, String prompt) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return '웹 환경에서 "$prompt" 프롬프트로 처리된 결과: ${text.substring(0, text.length > 50 ? 50 : text.length)}...';
  }
  
  void dispose() {
    _isInitialized = false;
    _currentModel = null;
  }
}