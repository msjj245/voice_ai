import 'package:hive_flutter/hive_flutter.dart';
import '../models/transcription_record.dart';

class StorageService {
  static const String _recordsBoxName = 'transcription_records';
  
  Future<Box<TranscriptionRecord>> get _recordsBox async {
    if (!Hive.isBoxOpen(_recordsBoxName)) {
      return await Hive.openBox<TranscriptionRecord>(_recordsBoxName);
    }
    return Hive.box<TranscriptionRecord>(_recordsBoxName);
  }
  
  Future<void> initialize() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TranscriptionRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SpeakerSegmentAdapter());
    }
  }
  
  Future<List<TranscriptionRecord>> getAllRecords() async {
    final box = await _recordsBox;
    return box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  
  // settings_screen.dart에서 사용되는 메서드
  Future<List<TranscriptionRecord>> getAllTranscriptions() async {
    return await getAllRecords();
  }
  
  Future<TranscriptionRecord?> getRecord(String id) async {
    final box = await _recordsBox;
    try {
      return box.values.firstWhere((record) => record.id == id);
    } catch (e) {
      return null; // 찾지 못한 경우 null 반환
    }
  }
  
  Future<void> saveRecord(TranscriptionRecord record) async {
    final box = await _recordsBox;
    await box.put(record.id, record);
  }
  
  Future<void> updateRecord(TranscriptionRecord record) async {
    final box = await _recordsBox;
    await box.put(record.id, record);
  }
  
  Future<void> deleteRecord(String id) async {
    final box = await _recordsBox;
    await box.delete(id);
  }
  
  Future<void> clearAll() async {
    final box = await _recordsBox;
    await box.clear();
  }
}