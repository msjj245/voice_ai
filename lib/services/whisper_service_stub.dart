import 'interfaces/whisper_service_interface.dart';

// Stub implementation - should not be used
class WhisperService implements IWhisperService {
  @override
  Future<Map<String, dynamic>> transcribeAudio(String audioPath) {
    throw UnsupportedError('Platform not supported');
  }
  
  @override
  Future<Map<String, dynamic>?> transcribeWithSpeakers(String audioPath) {
    throw UnsupportedError('Platform not supported');
  }
  
  @override
  Future<void> downloadModel(String modelName, {Function(double)? onProgress}) {
    throw UnsupportedError('Platform not supported');
  }
  
  @override
  List<String> getAvailableModels() {
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
  void setCurrentModel(String modelName) {
    throw UnsupportedError('Platform not supported');
  }
  
  @override
  String getCurrentModel() {
    throw UnsupportedError('Platform not supported');
  }
}