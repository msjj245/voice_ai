abstract class IWhisperService {
  Future<Map<String, dynamic>> transcribeAudio(String audioPath);
  Future<Map<String, dynamic>?> transcribeWithSpeakers(String audioPath);
  Future<void> downloadModel(String modelName, {Function(double)? onProgress});
  List<String> getAvailableModels();
  Future<bool> isModelDownloaded(String modelName);
  Future<Map<String, dynamic>> getModelInfo(String modelName);
  void setCurrentModel(String modelName);
  String getCurrentModel();
}