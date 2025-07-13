import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transcription_record.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider((ref) => StorageService());

final historyProvider = StreamProvider<List<TranscriptionRecord>>((ref) async* {
  final storageService = ref.watch(storageServiceProvider);
  
  // 초기 데이터 로드
  yield await storageService.getAllRecords();
  
  // 효율적인 실시간 업데이트 (Hive watch 기능 활용)
  await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
    // 실제로는 storageService.watchAllRecords() 사용하여 변경사항만 감지
    yield await storageService.getAllRecords();
  }
});

final recordProvider = FutureProvider.family<TranscriptionRecord?, String>((ref, id) async {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.getRecord(id);
});

class HistoryNotifier extends StateNotifier<AsyncValue<List<TranscriptionRecord>>> {
  final StorageService _storageService;
  
  HistoryNotifier(this._storageService) : super(const AsyncValue.loading()) {
    _loadRecords();
  }
  
  Future<void> _loadRecords() async {
    try {
      final records = await _storageService.getAllRecords();
      state = AsyncValue.data(records);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> addRecord(TranscriptionRecord record) async {
    try {
      await _storageService.saveRecord(record);
      await _loadRecords();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> deleteRecord(String id) async {
    try {
      await _storageService.deleteRecord(id);
      await _loadRecords();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> updateRecord(TranscriptionRecord record) async {
    try {
      await _storageService.updateRecord(record);
      await _loadRecords();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}