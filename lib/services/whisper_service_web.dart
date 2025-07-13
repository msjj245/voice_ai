import 'interfaces/whisper_service_interface.dart';

// 웹용 Whisper 서비스 모의 구현체
class WhisperService implements IWhisperService {
  String _currentModel = 'base';
  
  static const List<String> _models = ['tiny', 'base', 'small'];
  
  @override
  List<String> getAvailableModels() {
    return _models;
  }
  
  @override
  void setCurrentModel(String modelName) {
    if (_models.contains(modelName)) {
      _currentModel = modelName;
    }
  }
  
  @override
  String getCurrentModel() {
    return _currentModel;
  }
  
  @override
  Future<bool> isModelDownloaded(String modelName) async {
    // 웹에서는 모든 모델이 "다운로드됨"으로 가정
    return _models.contains(modelName);
  }
  
  @override
  Future<void> downloadModel(String modelName, {Function(double)? onProgress}) async {
    // 웹에서는 모의 다운로드
    if (!_models.contains(modelName)) return;
    
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      onProgress?.call(i / 100.0);
    }
  }
  
  @override
  Future<Map<String, dynamic>> transcribeAudio(String audioPath) async {
    // 웹에서는 모의 음성 인식 결과 반환
    await Future.delayed(const Duration(seconds: 2));
    
    final text = "안녕하세요. 이것은 웹에서 동작하는 모의 음성 인식 결과입니다. "
                 "실제 앱에서는 Whisper 모델을 사용하여 정확한 음성 인식을 수행합니다.";
    
    return {
      'text': text,
      'segments': [
        {
          'text': text,
          'start': 0.0,
          'end': 5.0,
        }
      ]
    };
  }
  
  @override
  Future<Map<String, dynamic>?> transcribeWithSpeakers(String audioPath) async {
    await Future.delayed(const Duration(seconds: 2));
    
    return {
      'text': "안녕하세요. 이것은 화자 분리가 포함된 모의 음성 인식 결과입니다.",
      'speakers': [
        {
          'speaker': 'Speaker 1',
          'text': '안녕하세요.',
          'start': 0.0,
          'end': 1.5,
        },
        {
          'speaker': 'Speaker 1', 
          'text': '이것은 화자 분리가 포함된 모의 음성 인식 결과입니다.',
          'start': 1.5,
          'end': 5.0,
        }
      ]
    };
  }
  
  @override
  Future<Map<String, dynamic>> getModelInfo(String modelName) async {
    return {
      'name': modelName,
      'size': '모의 크기',
      'description': '웹용 모의 Whisper 모델',
      'isDownloaded': true,
    };
  }
}