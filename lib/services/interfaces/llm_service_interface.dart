abstract class ILLMService {
  Future<Map<String, dynamic>> analyzeTranscription(String transcription);
  Future<Map<String, dynamic>> analyzeEmotion(String text);
  Future<String> summarizeText(String text);
  Future<List<String>> extractTasks(String text);
  Future<String> generateMeetingMinutes(String transcription);
  Future<void> downloadModel(String modelName, {Function(double)? onProgress});
  Future<bool> isModelDownloaded(String modelName);
  Future<Map<String, dynamic>> getModelInfo(String modelName);
  Future<bool> loadModel(String modelName);
  Future<String> runCustomPrompt(String text, String prompt);
}