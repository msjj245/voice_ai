import '../constants/model_configs.dart';

class TextAnalysisUtils {
  static String analyzeEmotion(String text) {
    final lowerText = text.toLowerCase();
    int positiveCount = 0;
    int negativeCount = 0;
    
    // 긍정 키워드 체크
    for (final word in ModelConfigs.emotionKeywords['positive']!) {
      if (lowerText.contains(word)) positiveCount++;
    }
    
    // 부정 키워드 체크
    for (final word in ModelConfigs.emotionKeywords['negative']!) {
      if (lowerText.contains(word)) negativeCount++;
    }
    
    // 중립 키워드 체크
    for (final word in ModelConfigs.emotionKeywords['neutral']!) {
      if (lowerText.contains(word)) return '중립적';
    }
    
    if (positiveCount > negativeCount) return '긍정적';
    if (negativeCount > positiveCount) return '부정적';
    if (positiveCount > 0 && negativeCount > 0) return '복합적';
    return '중립적';
  }
  
  static String generateBasicSummary(String text) {
    final sentences = text.split(RegExp(r'[.!?]'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    
    if (sentences.isEmpty) return text;
    if (sentences.length <= 2) return text;
    
    // 첫 문장과 마지막 문장 결합
    return '${sentences.first.trim()}. ${sentences.last.trim()}.';
  }
  
  static List<Map<String, dynamic>> extractTasks(String text) {
    final tasks = <Map<String, dynamic>>[];
    final taskPatterns = [
      RegExp(r'(\w+)(?:이|가)?\s*(.+?)(?:을|를)?\s*(?:해야|하기로|할 예정)'),
      RegExp(r'다음 주(?:까지)?\s*(.+?)(?:완료|준비)'),
      RegExp(r'(\d+월\s*\d+일)(?:까지)?\s*(.+?)'),
    ];
    
    for (final pattern in taskPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        tasks.add({
          'task': match.group(0) ?? '',
          'extracted': true,
        });
      }
    }
    
    return tasks;
  }
}