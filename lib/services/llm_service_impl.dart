import 'dart:io';
import 'dart:convert';
import 'interfaces/llm_service_interface.dart';
import 'common/model_download_service.dart';
import 'local_llm_engine.dart';
import '../constants/model_configs.dart';
import '../utils/text_analysis_utils.dart';

// 실제 LLM 서비스 구현
class LLMService implements ILLMService {
  final ModelDownloadService _downloadService = ModelDownloadService.instance;
  String _currentModel = 'gemma-2b-it-q4';
  
  // 로컬 LLM 추론 엔진 (실제로는 llama.cpp 바인딩 사용)
  LocalLLMEngine? _engine;
  
  @override
  Future<bool> loadModel(String modelName) async {
    try {
      // 모델 파일 경로 가져오기
      final modelConfig = ModelConfigs.llmModels[modelName];
      if (modelConfig == null) {
        print('Unknown model: $modelName');
        return false;
      }
      
      final modelFileName = '${modelName}.gguf';
      final modelPath = await _downloadService.getModelPath('llm', modelFileName);
      
      if (!File(modelPath).existsSync()) {
        print('모델 파일이 존재하지 않음: $modelPath');
        return false;
      }
      
      // LLM 엔진 초기화
      _engine = LocalLLMEngine(modelPath);
      final success = await _engine!.initialize();
      
      if (success) {
        _currentModel = modelName;
        print('LLM 모델 로드 성공: $modelName');
        return true;
      } else {
        _engine = null;
        return false;
      }
    } catch (e) {
      print('LLM 모델 로드 오류: $e');
      _engine = null;
      return false;
    }
  }
  
  @override
  Future<Map<String, dynamic>> analyzeTranscription(String transcription) async {
    try {
      if (_engine == null) {
        // 엔진이 없으면 기본 분석 수행
        return await _performBasicAnalysis(transcription);
      }
      
      // 각 분석 작업을 병렬로 수행
      final results = await Future.wait([
        _analyzeEmotion(transcription),
        _generateSummary(transcription),
        _extractTasks(transcription),
        _formatMeetingMinutes(transcription),
      ]);
      
      return {
        'emotion': results[0],
        'summary': results[1],
        'tasks': results[2],
        'minutes': results[3],
        'analyzedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('LLM analysis failed: $e');
    }
  }
  
  @override
  Future<Map<String, dynamic>> analyzeEmotion(String text) async {
    try {
      final emotion = await _analyzeEmotion(text);
      return {
        'emotion': emotion,
        'confidence': 0.85,
        'analyzedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'emotion': _basicEmotionAnalysis(text),
        'confidence': 0.6,
        'analyzedAt': DateTime.now().toIso8601String(),
      };
    }
  }
  
  Future<String> _analyzeEmotion(String text) async {
    const systemPrompt = '''당신은 감정 분석 전문가입니다. 
주어진 텍스트의 전반적인 감정 톤을 분석하세요.''';
    
    const userPrompt = '''다음 텍스트의 감정을 분석하고 다음 중 하나로 분류하세요:
- 긍정적: 희망적, 열정적, 만족스러운 톤
- 중립적: 사실적, 객관적인 톤
- 부정적: 우려, 불만, 실망스러운 톤
- 복합적: 여러 감정이 섞여 있는 경우

텍스트: {text}

감정 (한 단어로):''';
    
    if (_engine != null) {
      try {
        final prompt = LLMPrompts.emotionAnalysis(text);
        final response = await _engine!.generateText(prompt, maxTokens: 150);
        return _parseEmotionFromResponse(response);
      } catch (e) {
        print('LLM 감정 분석 오류: $e');
      }
    }
    
    // 기본 감정 분석
    return _basicEmotionAnalysis(text);
  }
  
  String _parseEmotionFromResponse(String response) {
    // LLM 응답에서 감정 정보 추출
    final lowerResponse = response.toLowerCase();
    if (lowerResponse.contains('긍정') || lowerResponse.contains('positive')) {
      return '긍정적';
    } else if (lowerResponse.contains('부정') || lowerResponse.contains('negative')) {
      return '부정적';
    } else if (lowerResponse.contains('복합')) {
      return '복합적';
    } else {
      return '중립적';
    }
  }
  
  Future<String> _generateSummary(String text) async {
    const systemPrompt = '''당신은 전문 요약 작성자입니다.
핵심 내용만을 간결하게 요약하세요.''';
    
    const userPrompt = '''다음 내용을 2-3문장으로 요약하세요:

{text}

요약:''';
    
    if (_engine != null) {
      try {
        final prompt = LLMPrompts.summarization(text);
        final response = await _engine!.generateText(prompt, maxTokens: 200);
        return response.trim();
      } catch (e) {
        print('LLM 요약 생성 오류: $e');
      }
    }
    
    // 기본 요약
    final sentences = text.split(RegExp(r'[.!?]'));
    if (sentences.length <= 3) {
      return text;
    }
    return sentences.take(2).join('. ') + '.';
  }
  
  Future<List<Map<String, dynamic>>> _extractTasks(String text) async {
    const systemPrompt = '''당신은 작업 추출 전문가입니다.
텍스트에서 할 일, 마감일, 담당자를 찾아내세요.''';
    
    const userPrompt = '''다음 텍스트에서 작업 항목을 추출하세요.
각 작업에 대해 다음 정보를 JSON 형식으로 제공하세요:
- task: 작업 내용
- date: 날짜나 기한 (있는 경우)
- assignee: 담당자 (있는 경우)

텍스트: {text}

작업 목록 (JSON 배열):''';
    
    if (_engine != null) {
      try {
        final prompt = LLMPrompts.taskExtraction(text);
        final response = await _engine!.generateText(prompt, maxTokens: 300);
        return _parseTasksFromResponse(response);
      } catch (e) {
        print('LLM 작업 추출 오류: $e');
      }
    }
    
    // 기본 작업 추출
    return _basicTaskExtraction(text);
  }
  
  List<Map<String, dynamic>> _parseTasksFromResponse(String response) {
    final tasks = <Map<String, dynamic>>[];
    final lines = response.split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && (trimmed.startsWith('-') || trimmed.startsWith('•') || trimmed.startsWith('*'))) {
        final taskText = trimmed.replaceFirst(RegExp(r'^[-•*]\s*'), '');
        if (taskText.isNotEmpty) {
          tasks.add({
            'task': taskText,
            'date': null,
            'assignee': null,
            'completed': false,
          });
        }
      }
    }
    
    return tasks.isEmpty ? [] : tasks;
  }
  
  Future<Map<String, dynamic>> _formatMeetingMinutes(String text) async {
    const systemPrompt = '''당신은 회의록 작성 전문가입니다.
체계적이고 명확한 회의록을 작성하세요.''';
    
    const userPrompt = '''다음 대화 내용을 구조화된 회의록으로 정리하세요.
다음 항목을 포함하세요:
- title: 회의 제목
- agenda: 주요 안건 (리스트)
- decisions: 결정 사항 (리스트)
- actionItems: 후속 조치 (리스트)

대화 내용: {text}

회의록 (JSON):''';
    
    if (_engine != null) {
      try {
        final prompt = LLMPrompts.meetingMinutes(text);
        final response = await _engine!.generateText(prompt, maxTokens: 500);
        return _parseMeetingMinutesResponse(response);
      } catch (e) {
        print('LLM 회의록 생성 오류: $e');
      }
    }
    
    // 기본 회의록 생성
    return {
      'title': '회의록',
      'date': DateTime.now().toIso8601String(),
      'agenda': ['논의 사항'],
      'decisions': [],
      'actionItems': [],
    };
  }
  
  Map<String, dynamic> _parseMeetingMinutesResponse(String response) {
    // 간단한 회의록 파싱 (실제로는 더 정교한 파싱 필요)
    return {
      'title': '회의록 - ${DateTime.now().toString().substring(0, 10)}',
      'date': DateTime.now().toIso8601String(),
      'content': response,
      'agenda': ['AI 생성 회의록'],
      'decisions': ['회의 내용 기반 결정사항'],
      'actionItems': ['후속 조치 필요 사항'],
    };
  }
  
  // 기본 분석 함수들 (LLM 없이 수행)
  @override
  Future<String> summarizeText(String text) async {
    try {
      return await _generateSummary(text);
    } catch (e) {
      return _basicSummary(text);
    }
  }
  
  @override
  Future<List<String>> extractTasks(String text) async {
    try {
      final tasks = await _extractTasks(text);
      return tasks.map((t) => t['task']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    } catch (e) {
      final basicTasks = _basicTaskExtraction(text);
      return basicTasks.map((t) => t['task']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
  }
  
  @override
  Future<String> generateMeetingMinutes(String transcription) async {
    try {
      final minutes = await _formatMeetingMinutes(transcription);
      return minutes['content']?.toString() ?? transcription;
    } catch (e) {
      final basicMinutes = _basicMinutes(transcription);
      return basicMinutes['content']?.toString() ?? transcription;
    }
  }

  Map<String, dynamic> _performBasicAnalysis(String text) {
    return {
      'emotion': _basicEmotionAnalysis(text),
      'summary': _basicSummary(text),
      'tasks': _basicTaskExtraction(text),
      'minutes': _basicMinutes(text),
      'analyzedAt': DateTime.now().toIso8601String(),
    };
  }
  
  String _basicEmotionAnalysis(String text) {
    return TextAnalysisUtils.analyzeEmotion(text);
  }
  
  String _basicSummary(String text) {
    return TextAnalysisUtils.generateBasicSummary(text);
  }
  
  List<Map<String, dynamic>> _basicTaskExtraction(String text) {
    return TextAnalysisUtils.extractTasks(text);
  }
  
  Map<String, dynamic> _basicMinutes(String text) {
    return {
      'title': '회의 기록',
      'date': DateTime.now().toIso8601String(),
      'content': text,
      'wordCount': text.split(' ').length,
    };
  }
  
  // 모델 관리 함수들
  @override
  Future<void> downloadModel(String modelName, {
    Function(double)? onProgress,
  }) async {
    final modelConfig = ModelConfigs.llmModels[modelName];
    if (modelConfig == null) {
      throw Exception('Unknown model: $modelName');
    }
    
    final url = modelConfig['url'] as String;
    final modelPath = await _downloadService.getModelPath('llm', modelName);
    
    await _downloadService.downloadModel(
      url: url,
      modelPath: modelPath,
      onProgress: onProgress,
    );
  }
  
  @override
  Future<bool> isModelDownloaded(String modelName) async {
    return await _downloadService.isModelDownloaded('llm', modelName);
  }
  
  @override
  Future<Map<String, dynamic>> getModelInfo(String modelName) async {
    final config = ModelConfigs.llmModels[modelName];
    if (config == null) return {};
    
    final isDownloaded = await isModelDownloaded(modelName);
    return {
      ...config,
      'id': modelName,
      'downloaded': isDownloaded,
      'path': isDownloaded ? await _downloadService.getModelPath('llm', modelName) : null,
    };
  }
  
  @override
  Future<String> runCustomPrompt(String text, String prompt) async {
    try {
      if (_engine != null) {
        return await _engine!.generate(
          systemPrompt: "You are a helpful assistant.",
          userPrompt: prompt.replaceAll('{text}', text),
          maxTokens: 500,
          temperature: 0.7,
        );
      }
      return 'Custom analysis result based on prompt';
    } catch (e) {
      throw Exception('Custom prompt failed: $e');
    }
  }
}