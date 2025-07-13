import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'platform_services.dart';
import '../constants/model_configs.dart';

class ModelManager {
  static const String _modelCheckKey = 'models_checked';
  static const String _defaultWhisperModel = 'base';
  static const String _defaultLLMModel = 'gemma-2b-it-q4';
  
  static ModelManager? _instance;
  static ModelManager get instance {
    _instance ??= ModelManager._();
    return _instance!;
  }
  
  ModelManager._();
  
  final _whisperService = getWhisperService();
  final _llmService = getLLMService();
  
  // 앱 시작 시 모델 체크 및 자동 다운로드
  Future<void> initializeModels({
    required BuildContext context,
    Function(String, double)? onProgress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final hasCheckedModels = prefs.getBool(_modelCheckKey) ?? false;
    
    // 이미 체크했고 모델이 있으면 스킵
    if (hasCheckedModels && await _hasRequiredModels()) {
      await _loadModels();
      return;
    }
    
    // 필수 모델 다운로드 확인
    bool needsDownload = false;
    
    // Whisper 모델 체크
    if (!await _whisperService.isModelDownloaded(_defaultWhisperModel)) {
      needsDownload = true;
    }
    
    // LLM 모델 체크 (선택사항)
    final hasAnyLLM = await _hasAnyLLMModel();
    
    if (needsDownload || !hasAnyLLM) {
      // 다운로드 필요함을 사용자에게 알림
      if (context.mounted) {
        final shouldDownload = await _showDownloadDialog(context);
        if (shouldDownload) {
          await _downloadRequiredModels(onProgress: onProgress);
        }
      }
    }
    
    // 모델 로드
    await _loadModels();
    
    // 체크 완료 표시
    await prefs.setBool(_modelCheckKey, true);
  }
  
  Future<bool> _hasRequiredModels() async {
    // 최소한 하나의 Whisper 모델이 있는지 확인
    final whisperModels = _whisperService.getAvailableModels();
    for (final model in whisperModels) {
      if (await _whisperService.isModelDownloaded(model)) {
        return true;
      }
    }
    return false;
  }
  
  Future<bool> _hasAnyLLMModel() async {
    for (final model in ModelConfigs.llmModels.keys) {
      if (await _llmService.isModelDownloaded(model)) {
        return true;
      }
    }
    return false;
  }
  
  Future<void> _loadModels() async {
    // Whisper 모델 로드
    final whisperModels = _whisperService.getAvailableModels();
    for (final model in whisperModels) {
      if (await _whisperService.isModelDownloaded(model)) {
        _whisperService.setCurrentModel(model);
        break;
      }
    }
    
    // LLM 모델 로드
    for (final model in ModelConfigs.llmModels.keys) {
      if (await _llmService.isModelDownloaded(model)) {
        await _llmService.loadModel(model);
        break;
      }
    }
  }
  
  Future<void> _downloadRequiredModels({
    Function(String, double)? onProgress,
  }) async {
    try {
      // Whisper 모델 다운로드
      if (!await _whisperService.isModelDownloaded(_defaultWhisperModel)) {
        await _whisperService.downloadModel(
          _defaultWhisperModel,
          onProgress: (progress) {
            onProgress?.call('Whisper $_defaultWhisperModel', progress);
          },
        );
      }
      
      // LLM 모델은 선택적으로 다운로드
      // 사용자가 원할 때 설정에서 다운로드 가능
    } catch (e) {
      print('Model download failed: $e');
    }
  }
  
  Future<bool> _showDownloadDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Download Required Models'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voice AI needs to download AI models for speech recognition.',
            ),
            const SizedBox(height: 16),
            Text(
              'Download size: ~${ModelConfigs.whisperModels[_defaultWhisperModel]?['size']}MB',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Models are downloaded once and work offline.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Download'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  // 모델 다운로드 상태를 보여주는 위젯
  static Widget buildDownloadProgress({
    required String modelName,
    required double progress,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Downloading $modelName',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}