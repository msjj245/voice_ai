import 'interfaces/llm_service_interface.dart';

// Stub implementation - should not be used
class LLMService implements ILLMService {
  @override
  Future<Map<String, dynamic>> analyzeTranscription(String transcription) {
    throw UnsupportedError('Platform not supported');
  }
  
  @override
  Future<Map<String, dynamic>> analyzeEmotion(String text) {
    throw UnsupportedError('Platform not supported');
  }
  
  @override
  Future<String> summarizeText(String text) {
    throw UnsupportedError('Platform not supported');
  }
  
  @override
  Future<List<String>> extractTasks(String text) {
    throw UnsupportedError('Platform not supported');
  }
  
  @override
  Future<String> generateMeetingMinutes(String transcription) {
    throw UnsupportedError('Platform not supported');
  }
  
  @override
  Future<void> downloadModel(String modelName, {Function(double)? onProgress}) {
    throw UnsupportedError('Platform not supported');
  }
  
  @override
  Future<bool> isModelDownloaded(String modelName) {
    throw UnsupportedError('Platform not supported');
  }
  
  @override
  Future<Map<String, dynamic>> getModelInfo(String modelName) {
    throw UnsupportedError('Platform not supported');
  }
  
  @override
  Future<bool> loadModel(String modelName) {
    throw UnsupportedError('Platform not supported');
  }
  
  @override
  Future<String> runCustomPrompt(String text, String prompt) {
    throw UnsupportedError('Platform not supported');
  }
}