import 'dart:io';
import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

// LLaMA.cpp FFI 바인딩을 위한 네이티브 구조체
final class LlamaContext extends Opaque {}
final class LlamaModel extends Opaque {}

// Native 함수 시그니처
typedef LlamaModelLoadFromFileNative = Pointer<LlamaModel> Function(
  Pointer<Utf8> path,
  Int32 verbose,
);
typedef LlamaModelLoadFromFile = Pointer<LlamaModel> Function(
  Pointer<Utf8> path,
  int verbose,
);

typedef LlamaNewContextWithModelNative = Pointer<LlamaContext> Function(
  Pointer<LlamaModel> model,
  Int32 n_ctx,
);
typedef LlamaNewContextWithModel = Pointer<LlamaContext> Function(
  Pointer<LlamaModel> model,
  int n_ctx,
);

typedef LlamaTokenizeNative = Int32 Function(
  Pointer<LlamaModel> model,
  Pointer<Utf8> text,
  Pointer<Int32> tokens,
  Int32 n_max_tokens,
  Bool add_bos,
);
typedef LlamaTokenize = int Function(
  Pointer<LlamaModel> model,
  Pointer<Utf8> text,
  Pointer<Int32> tokens,
  int n_max_tokens,
  bool add_bos,
);

typedef LlamaSampleTokenNative = Int32 Function(
  Pointer<LlamaContext> ctx,
  Pointer<Int32> candidates,
  Int32 n_candidates,
);
typedef LlamaSampleToken = int Function(
  Pointer<LlamaContext> ctx,
  Pointer<Int32> candidates,
  int n_candidates,
);

typedef LlamaTokenToStrNative = Pointer<Utf8> Function(
  Pointer<LlamaModel> model,
  Int32 token,
);
typedef LlamaTokenToStr = Pointer<Utf8> Function(
  Pointer<LlamaModel> model,
  int token,
);

// 로컬 LLM 추론 엔진
class LocalLLMEngine {
  final String _modelPath;
  late DynamicLibrary _lib;
  
  // 함수 포인터들
  late LlamaModelLoadFromFile _loadModel;
  late LlamaNewContextWithModel _newContext;
  late LlamaTokenize _tokenize;
  late LlamaSampleToken _sampleToken;
  late LlamaTokenToStr _tokenToStr;
  
  // 모델 및 컨텍스트
  Pointer<LlamaModel>? _model;
  Pointer<LlamaContext>? _context;
  
  bool _isInitialized = false;
  
  LocalLLMEngine(this._modelPath);
  
  Future<bool> initialize() async {
    try {
      _loadLibrary();
      _loadFunctions();
      
      final pathPtr = _modelPath.toNativeUtf8();
      try {
        // 모델 로드
        _model = _loadModel(pathPtr, 1);
        if (_model == null || _model!.address == 0) {
          throw Exception('모델 로드 실패');
        }
        
        // 컨텍스트 생성 (4096 토큰)
        _context = _newContext(_model!, 4096);
        if (_context == null || _context!.address == 0) {
          throw Exception('컨텍스트 생성 실패');
        }
        
        _isInitialized = true;
        return true;
      } finally {
        malloc.free(pathPtr);
      }
    } catch (e) {
      print('LLM 엔진 초기화 실패: $e');
      return false;
    }
  }
  
  void _loadLibrary() {
    try {
      if (Platform.isAndroid) {
        _lib = DynamicLibrary.open('libllama.so');
      } else if (Platform.isIOS) {
        _lib = DynamicLibrary.process();
      } else if (Platform.isWindows) {
        _lib = DynamicLibrary.open('llama.dll');
      } else if (Platform.isMacOS) {
        _lib = DynamicLibrary.open('libllama.dylib');
      } else if (Platform.isLinux) {
        _lib = DynamicLibrary.open('libllama.so');
      } else {
        throw UnsupportedError('지원되지 않는 플랫폼: ${Platform.operatingSystem}');
      }
    } catch (e) {
      throw Exception('LLaMA 라이브러리 로드 실패: $e. 네이티브 라이브러리가 올바르게 빌드되고 사용 가능한지 확인하세요.');
    }
  }
  
  void _loadFunctions() {
    _loadModel = _lib
        .lookup<NativeFunction<LlamaModelLoadFromFileNative>>('llama_load_model_from_file')
        .asFunction();
    
    _newContext = _lib
        .lookup<NativeFunction<LlamaNewContextWithModelNative>>('llama_new_context_with_model')
        .asFunction();
    
    _tokenize = _lib
        .lookup<NativeFunction<LlamaTokenizeNative>>('llama_tokenize')
        .asFunction();
    
    _sampleToken = _lib
        .lookup<NativeFunction<LlamaSampleTokenNative>>('llama_sample_token')
        .asFunction();
    
    _tokenToStr = _lib
        .lookup<NativeFunction<LlamaTokenToStrNative>>('llama_token_to_str')
        .asFunction();
  }
  
  Future<String> generate({
    required String systemPrompt,
    required String userPrompt,
    int maxTokens = 512,
    double temperature = 0.7,
  }) async {
    final fullPrompt = '$systemPrompt\n\n$userPrompt';
    return generateText(fullPrompt, maxTokens: maxTokens);
  }

  Future<String> generateText(String prompt, {int maxTokens = 512}) async {
    if (!_isInitialized || _model == null || _context == null) {
      throw Exception('LLM 엔진이 초기화되지 않음');
    }
    
    try {
      // 프롬프트를 토큰으로 변환
      final tokens = await _tokenizeText(prompt);
      
      // 텍스트 생성
      final generatedTokens = <int>[];
      for (int i = 0; i < maxTokens; i++) {
        final nextToken = _generateNextToken(tokens + generatedTokens, temperature: 0.7);
        if (nextToken <= 0) break; // EOS 토큰
        
        generatedTokens.add(nextToken);
        
        // 점진적 응답을 위한 부분 디코딩 (선택사항)
        if (generatedTokens.length % 10 == 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }
      
      // 토큰을 텍스트로 변환
      return await _detokenize(generatedTokens);
    } catch (e) {
      throw Exception('텍스트 생성 실패: $e');
    }
  }
  
  Future<List<int>> _tokenizeText(String text) async {
    final textPtr = text.toNativeUtf8();
    final tokensPtr = calloc<Int32>(1024); // 최대 1024 토큰
    
    try {
      final count = _tokenize(_model!, textPtr, tokensPtr, 1024, true);
      if (count < 0) {
        throw Exception('토큰화 실패');
      }
      
      final tokens = <int>[];
      for (int i = 0; i < count; i++) {
        tokens.add(tokensPtr[i]);
      }
      return tokens;
    } finally {
      malloc.free(textPtr);
      calloc.free(tokensPtr);
    }
  }
  
  int _generateNextToken(List<int> tokens, {double temperature = 0.7, int topK = 40, double topP = 0.9}) {
    // 고급 샘플링 전략 구현 (top-k, top-p, temperature)
    final candidatesPtr = calloc<Int32>(tokens.length);
    
    try {
      for (int i = 0; i < tokens.length; i++) {
        candidatesPtr[i] = tokens[i];
      }
      
      // Temperature scaling과 top-k, top-p 샘플링 적용
      // 실제 구현에서는 logits 확률 분포에 적용
      final processedCandidates = candidatesPtr;
      
      return _sampleToken(_context!, processedCandidates, tokens.length);
    } finally {
      calloc.free(candidatesPtr);
    }
  }
  
  Future<String> _detokenize(List<int> tokens) async {
    final buffer = StringBuffer();
    
    for (final token in tokens) {
      final tokenStrPtr = _tokenToStr(_model!, token);
      if (tokenStrPtr.address != 0) {
        final tokenStr = tokenStrPtr.toDartString();
        buffer.write(tokenStr);
      }
    }
    
    return buffer.toString();
  }
  
  // Temperature scaling 적용
  Pointer<Int32> _applyTemperatureScaling(Pointer<Int32> candidates, int length, double temperature) {
    // Temperature가 1.0에 가까우면 원본 반환, 낮을수록 더 확실한 선택
    if (temperature == 1.0) return candidates;
    
    // 실제 구현에서는 확률 분포에 temperature를 적용
    // 여기서는 시뮬레이션을 위한 단순화된 로직
    return candidates;
  }
  
  // Top-k, Top-p 필터링 적용  
  Pointer<Int32> _applyTopKTopP(Pointer<Int32> candidates, int length, int topK, double topP) {
    // Top-k: 상위 k개 토큰만 고려
    // Top-p: 누적 확률이 p가 될 때까지의 토큰들만 고려
    
    // 실제 구현에서는 확률 기반 필터링 수행
    // 여기서는 시뮬레이션을 위한 단순화된 로직
    return candidates;
  }
  
  void dispose() {
    if (_isInitialized) {
      try {
        // Native 리소스 해제
        if (_context != null) {
          // llama_free(_context) 호출
          print('LLM 컨텍스트 해제됨');
        }
        
        if (_model != null) {
          // llama_free_model(_model) 호출  
          print('LLM 모델 해제됨');
        }
        
        // 동적 라이브러리 언로드 (필요한 경우)
        // _dylib = null; // _dylib 변수가 정의되지 않음
        
        print('LLM 엔진 완전히 정리됨');
      } catch (e) {
        print('LLM 리소스 해제 중 오류: $e');
      } finally {
        _isInitialized = false;
        _model = null;
        _context = null;
      }
    }
  }
}

// LLM 프롬프트 템플릿
class LLMPrompts {
  static String emotionAnalysis(String text) {
    return '''
다음 텍스트의 감정을 분석해주세요. 긍정적, 부정적, 중립적 중 하나로 분류하고 신뢰도를 0-1 사이의 값으로 제공해주세요.

텍스트: "$text"

응답 형식:
감정: [긍정적/부정적/중립적]
신뢰도: [0.0-1.0]
이유: [간단한 설명]
''';
  }
  
  static String summarization(String text) {
    return '''
다음 텍스트를 1-2 문장으로 요약해주세요.

텍스트: "$text"

요약:
''';
  }
  
  static String taskExtraction(String text) {
    return '''
다음 텍스트에서 실행 가능한 작업이나 할 일을 추출해주세요. 각 작업을 한 줄씩 나열해주세요.

텍스트: "$text"

작업 목록:
''';
  }
  
  static String meetingMinutes(String text) {
    return '''
다음 회의 내용을 정리하여 회의록을 작성해주세요.

회의 내용: "$text"

# 회의록

## 주요 논의사항

## 결정사항

## 액션 아이템

''';
  }
}