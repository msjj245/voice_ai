class ModelConfigs {
  // Whisper 모델 설정
  static const whisperModels = {
    'tiny': {
      'url': 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin',
      'size': 39, // MB
      'accuracy': 'Basic',
      'speed': 'Very Fast',
    },
    'base': {
      'url': 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin',
      'size': 74,
      'accuracy': 'Good',
      'speed': 'Fast',
    },
    'small': {
      'url': 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin',
      'size': 244,
      'accuracy': 'Very Good',
      'speed': 'Moderate',
    },
  };
  
  // LLM 모델 설정
  static const llmModels = {
    'gemma-2b-it-q4': {
      'url': 'https://huggingface.co/google/gemma-2b-it-GGUF/resolve/main/gemma-2b-it-q4_k_m.gguf',
      'name': 'Gemma 2B Instruct',
      'size': 1400, // MB
      'context_length': 8192,
      'parameters': '2B',
      'quantization': 'Q4_K_M',
    },
    'phi-3-mini-q4': {
      'url': 'https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf',
      'name': 'Phi-3 Mini',
      'size': 2300,
      'context_length': 4096,
      'parameters': '3.8B',
      'quantization': 'Q4',
    },
  };
  
  // 감정 분석 키워드
  static const emotionKeywords = {
    'positive': ['좋', '감사', '훌륭', '완벽', '성공', '기쁘', '행복', '만족'],
    'negative': ['문제', '걱정', '어려', '실패', '부족', '슬프', '화나', '실망'],
    'neutral': ['보통', '일반', '평범', '그저'],
  };
}