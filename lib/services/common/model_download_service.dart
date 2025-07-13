import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../constants/model_configs.dart';

class ModelDownloadService {
  static final ModelDownloadService _instance = ModelDownloadService._();
  static ModelDownloadService get instance => _instance;
  
  final Dio _dio = Dio();
  final Map<String, CancelToken> _downloadTokens = {};
  
  ModelDownloadService._() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(minutes: 30);
    _dio.options.headers['User-Agent'] = 'VoiceAI/1.0';
  }
  
  /// 모델 다운로드 (재시도, 검증, 취소 기능 포함)
  Future<void> downloadModel({
    required String url,
    required String modelPath,
    Function(double)? onProgress,
    String? expectedChecksum,
    int maxRetries = 3,
  }) async {
    final tempPath = '$modelPath.tmp';
    final downloadKey = modelPath;
    
    // 이미 다운로드 중인지 확인
    if (_downloadTokens.containsKey(downloadKey)) {
      throw Exception('이미 다운로드 중입니다: $modelPath');
    }
    
    final cancelToken = CancelToken();
    _downloadTokens[downloadKey] = cancelToken;
    
    try {
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          print('모델 다운로드 시도 $attempt/$maxRetries: $url');
          
          await _dio.download(
            url,
            tempPath,
            cancelToken: cancelToken,
            onReceiveProgress: (received, total) {
              if (total != -1 && onProgress != null) {
                onProgress(received / total);
              }
            },
            options: Options(
              headers: {
                'Accept': '*/*',
                'Cache-Control': 'no-cache',
              },
            ),
          );
          
          // 다운로드 완료, 파일 검증
          if (expectedChecksum != null) {
            final isValid = await _verifyChecksum(tempPath, expectedChecksum);
            if (!isValid) {
              throw Exception('파일 무결성 검증 실패');
            }
          }
          
          // 검증 완료, 최종 위치로 이동
          await File(tempPath).rename(modelPath);
          print('모델 다운로드 완료: $modelPath');
          return;
          
        } catch (e) {
          print('다운로드 시도 $attempt 실패: $e');
          
          // 마지막 시도가 아니면 재시도
          if (attempt < maxRetries) {
            await Future.delayed(Duration(seconds: attempt * 2));
            continue;
          }
          
          // 모든 시도 실패
          throw Exception('$maxRetries번 시도 후 다운로드 실패: $e');
        }
      }
    } finally {
      // 정리 작업
      _downloadTokens.remove(downloadKey);
      
      // 임시 파일 삭제
      final tempFile = File(tempPath);
      if (tempFile.existsSync()) {
        await tempFile.delete();
      }
    }
  }
  
  /// 다운로드 취소
  void cancelDownload(String modelPath) {
    final cancelToken = _downloadTokens[modelPath];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('사용자 취소');
      print('다운로드 취소됨: $modelPath');
    }
  }
  
  /// 파일 체크섬 검증
  Future<bool> _verifyChecksum(String filePath, String expectedChecksum) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      final actualChecksum = digest.toString();
      
      return actualChecksum.toLowerCase() == expectedChecksum.toLowerCase();
    } catch (e) {
      print('체크섬 검증 오류: $e');
      return false;
    }
  }
  
  Future<String> getModelPath(String category, String modelName) async {
    final dir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${dir.path}/models/$category');
    if (!modelsDir.existsSync()) {
      modelsDir.createSync(recursive: true);
    }
    return '${modelsDir.path}/$modelName';
  }
  
  Future<bool> isModelDownloaded(String category, String modelName) async {
    final modelPath = await getModelPath(category, modelName);
    return File(modelPath).existsSync();
  }
  
  Future<int?> getModelSize(String category, String modelName) async {
    final modelPath = await getModelPath(category, modelName);
    final file = File(modelPath);
    if (file.existsSync()) {
      return file.lengthSync();
    }
    return null;
  }
  
  /// 모델 설정에서 URL과 정보 가져오기
  Future<void> downloadModelByName(
    String category,
    String modelName, {
    Function(double)? onProgress,
  }) async {
    final Map<String, dynamic>? config;
    
    if (category == 'whisper') {
      config = ModelConfigs.whisperModels[modelName];
    } else if (category == 'llm') {
      config = ModelConfigs.llmModels[modelName];
    } else {
      throw Exception('지원되지 않는 모델 카테고리: $category');
    }
    
    if (config == null) {
      throw Exception('모델 설정을 찾을 수 없음: $modelName');
    }
    
    final url = config['url'] as String;
    final fileName = category == 'whisper' 
        ? 'ggml-$modelName.bin'
        : '$modelName.gguf';
    
    final modelPath = await getModelPath(category, fileName);
    
    await downloadModel(
      url: url,
      modelPath: modelPath,
      onProgress: onProgress,
    );
  }
  
  /// 모델 삭제
  Future<bool> deleteModel(String category, String modelName) async {
    try {
      final modelPath = await getModelPath(category, modelName);
      final file = File(modelPath);
      
      if (file.existsSync()) {
        await file.delete();
        print('모델 삭제됨: $modelPath');
        return true;
      }
      return false;
    } catch (e) {
      print('모델 삭제 오류: $e');
      return false;
    }
  }
  
  /// 모든 모델 삭제
  Future<void> clearAllModels() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${dir.path}/models');
      
      if (modelsDir.existsSync()) {
        await modelsDir.delete(recursive: true);
        print('모든 모델 삭제 완료');
      }
    } catch (e) {
      print('모델 삭제 오류: $e');
    }
  }
  
  /// 다운로드된 모델 목록 조회
  Future<List<String>> getDownloadedModels(String category) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${dir.path}/models/$category');
      
      if (!modelsDir.existsSync()) {
        return [];
      }
      
      final files = modelsDir.listSync()
          .where((entity) => entity is File)
          .map((file) => file.path.split('/').last)
          .toList();
      
      return files;
    } catch (e) {
      print('모델 목록 조회 오류: $e');
      return [];
    }
  }
  
  /// 디스크 사용량 조회
  Future<int> getTotalModelsSize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${dir.path}/models');
      
      if (!modelsDir.existsSync()) {
        return 0;
      }
      
      int totalSize = 0;
      await for (final entity in modelsDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += entity.lengthSync();
        }
      }
      
      return totalSize;
    } catch (e) {
      print('모델 크기 계산 오류: $e');
      return 0;
    }
  }
  
  /// 사용 가능한 저장 공간 확인
  Future<bool> hasEnoughSpace(int requiredBytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      
      // 플랫폼별 저장 공간 확인
      if (Platform.isAndroid || Platform.isIOS) {
        // 모바일: 최소 500MB 여유 공간 필요
        const minFreeSpace = 1024 * 1024 * 500; // 500MB
        return requiredBytes < minFreeSpace;
      } else {
        // 데스크톱: 최소 100MB 여유 공간 필요
        const minFreeSpace = 1024 * 1024 * 100; // 100MB
        return requiredBytes < minFreeSpace;
      }
    } catch (e) {
      print('저장 공간 확인 오류: $e');
      // 확인할 수 없으면 최소한의 안전 검사
      return requiredBytes < (1024 * 1024 * 100); // 100MB 제한
    }
  }
  
  /// 다운로드 진행 상태 확인
  bool isDownloading(String modelPath) {
    return _downloadTokens.containsKey(modelPath);
  }
  
  /// 모든 다운로드 취소
  void cancelAllDownloads() {
    for (final cancelToken in _downloadTokens.values) {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel('모든 다운로드 취소');
      }
    }
    _downloadTokens.clear();
    print('모든 다운로드가 취소되었습니다');
  }
}