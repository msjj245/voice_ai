import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../models/transcription_record.dart';
import '../providers/history_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioService {
  Future<String> saveAudioFile(String tempPath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${appDir.path}/recordings');
    
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final newPath = '${audioDir.path}/recording_$timestamp.m4a';
    
    await File(tempPath).copy(newPath);
    return newPath;
  }
  
  Future<List<FileSystemEntity>> getRecordings() async {
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${appDir.path}/recordings');
    
    if (!await audioDir.exists()) {
      return [];
    }
    
    return audioDir.listSync()
      .where((file) => file.path.endsWith('.m4a'))
      .toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  }
  
  Future<void> deleteRecording(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
  
  Future<TranscriptionRecord> saveTranscription({
    required String audioPath,
    required String transcription,
    Map<String, dynamic>? analysis,
    List<Map<String, dynamic>>? speakers,
  }) async {
    // 오디오 파일 저장
    final savedAudioPath = await saveAudioFile(audioPath);
    
    // Speaker segments 변환
    List<SpeakerSegment>? speakerSegments;
    if (speakers != null) {
      speakerSegments = speakers.map((s) => SpeakerSegment(
        speaker: s['speaker'] ?? 'Unknown',
        text: s['text'] ?? '',
        startTime: (s['start'] as num?)?.toDouble() ?? 0.0,
        endTime: (s['end'] as num?)?.toDouble() ?? 0.0,
      )).toList();
    }
    
    // 제목 생성 (요약 또는 첫 문장)
    String title = '녹음';
    if (analysis?['summary'] != null) {
      title = analysis!['summary'];
    } else if (transcription.isNotEmpty) {
      title = transcription.split('.').first;
      if (title.length > 50) {
        title = '${title.substring(0, 47)}...';
      }
    }
    
    // 태그 생성
    List<String> tags = [];
    if (analysis?['emotion'] != null) {
      tags.add(analysis!['emotion']);
    }
    if (analysis?['tasks'] != null && (analysis!['tasks'] as List).isNotEmpty) {
      tags.add('작업있음');
    }
    
    // Record 생성
    final record = TranscriptionRecord(
      transcription: transcription,
      title: title,
      tags: tags,
      audioFilePath: savedAudioPath,
      analysis: analysis,
      speakerSegments: speakerSegments,
      duration: _getAudioDuration(savedAudioPath),
    );
    
    return record;
  }
  
  Duration? _getAudioDuration(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        return null;
      }
      
      // 오디오 파일 헤더 분석을 통한 길이 추출
      // 실제로는 FFI 또는 플러그인을 사용해야 하지만, 
      // 여기서는 파일 크기 기반 추정 사용
      
      final fileSize = file.lengthSync();
      
      // M4A/AAC 파일의 평균 비트레이트 추정 (128kbps)
      const avgBitrate = 128 * 1000 / 8; // bytes per second
      final estimatedDurationSeconds = fileSize / avgBitrate;
      
      // WAV 파일인 경우 더 정확한 계산
      if (path.toLowerCase().endsWith('.wav')) {
        return _parseWavDuration(file);
      }
      
      // M4A, MP3 등의 경우 추정값 사용
      return Duration(seconds: estimatedDurationSeconds.round());
      
    } catch (e) {
      print('오디오 길이 추출 오류: $e');
      // 기본값 반환
      return const Duration(minutes: 2, seconds: 30);
    }
  }
  
  Duration? _parseWavDuration(File file) {
    try {
      final bytes = file.readAsBytesSync();
      if (bytes.length < 44) return null; // WAV 헤더가 최소 44바이트
      
      // WAV 헤더 파싱
      final data = ByteData.sublistView(Uint8List.fromList(bytes));
      
      // RIFF 체크
      if (String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF') return null;
      if (String.fromCharCodes(bytes.sublist(8, 12)) != 'WAVE') return null;
      
      // fmt 청크 찾기
      int offset = 12;
      while (offset < bytes.length - 8) {
        final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
        final chunkSize = data.getUint32(offset + 4, Endian.little);
        
        if (chunkId == 'fmt ') {
          if (chunkSize >= 16) {
            final sampleRate = data.getUint32(offset + 12, Endian.little);
            final byteRate = data.getUint32(offset + 16, Endian.little);
            
            // data 청크 찾기
            int dataOffset = offset + 8 + chunkSize;
            while (dataOffset < bytes.length - 8) {
              final dataChunkId = String.fromCharCodes(bytes.sublist(dataOffset, dataOffset + 4));
              final dataSize = data.getUint32(dataOffset + 4, Endian.little);
              
              if (dataChunkId == 'data') {
                final durationSeconds = dataSize / byteRate;
                return Duration(microseconds: (durationSeconds * 1000000).round());
              }
              
              dataOffset += 8 + dataSize;
            }
          }
          break;
        }
        
        offset += 8 + chunkSize;
      }
      
      return null;
    } catch (e) {
      print('WAV 파일 파싱 오류: $e');
      return null;
    }
  }
}