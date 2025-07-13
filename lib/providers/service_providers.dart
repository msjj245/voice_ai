import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/platform_services.dart';
import '../services/storage_service.dart';

// 핵심 서비스 providers
final storageServiceProvider = Provider((ref) => StorageService());

final whisperServiceProvider = Provider((ref) => getWhisperService());

final llmServiceProvider = Provider((ref) => getLLMService());