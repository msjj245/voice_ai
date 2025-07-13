import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/audio_state.dart';
import '../services/audio_service.dart';
import '../services/platform_services.dart';
import '../services/storage_service.dart';
import '../constants/model_configs.dart';

final audioServiceProvider = Provider((ref) => AudioService());

final audioProvider = StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return AudioNotifier(audioService);
});

class AudioNotifier extends StateNotifier<AudioState> {
  final AudioService _audioService;
  final AudioRecorder _recorder = AudioRecorder();
  
  AudioNotifier(this._audioService) : super(const AudioState()) {
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    try {
      // Whisper 모델 체크 및 로드
      final whisperService = getWhisperService();
      final models = whisperService.getAvailableModels();
      for (final model in models) {
        if (await whisperService.isModelDownloaded(model)) {
          whisperService.setCurrentModel(model);
          break;
        }
      }
      
      // LLM 모델 체크 및 로드
      final llmService = getLLMService();
      for (final model in ModelConfigs.llmModels.keys) {
        if (await llmService.isModelDownloaded(model)) {
          await llmService.loadModel(model);
          break;
        }
      }
    } catch (e) {
      print('Failed to initialize services: $e');
    }
  }
  
  Future<void> startRecording() async {
    final hasPermission = await _checkPermission();
    if (!hasPermission) {
      state = state.copyWith(
        error: 'Microphone permission denied',
      );
      return;
    }
    
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${tempDir.path}/recording_$timestamp.m4a';
      
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      
      state = state.copyWith(
        isRecording: true,
        currentRecordingPath: path,
        error: null,
        recordingStartTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to start recording: $e',
      );
    }
  }
  
  Future<void> stopRecording() async {
    try {
      final path = await _recorder.stop();
      
      if (path != null) {
        final startTime = state.recordingStartTime ?? DateTime.now();
        state = state.copyWith(
          isRecording: false,
          lastRecordingPath: path,
          recordingDuration: DateTime.now().difference(startTime),
        );
        
        // Process the audio file
        await _processAudioFile(path);
      }
    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        error: 'Failed to stop recording: $e',
      );
    }
  }
  
  Future<void> uploadAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'opus', 'flac'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final path = file.path!;
        
        // 파일 크기 체크 (최대 100MB)
        const maxSize = 100 * 1024 * 1024; // 100MB
        if (file.size > maxSize) {
          state = state.copyWith(
            error: 'File too large. Maximum size is 100MB.',
          );
          return;
        }
        
        state = state.copyWith(
          lastRecordingPath: path,
          error: null,
        );
        await _processAudioFile(path);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to upload file: $e',
      );
    }
  }
  
  Future<void> _processAudioFile(String path) async {
    state = state.copyWith(isProcessing: true);
    
    try {
      // Whisper 처리
      final whisperService = getWhisperService();
      final transcriptionResult = await whisperService.transcribeAudio(path);
      final speakerResult = await whisperService.transcribeWithSpeakers(path);
      
      final transcription = transcriptionResult['text'] ?? '';
      List<Map<String, dynamic>>? speakers;
      if (speakerResult != null && speakerResult['speakers'] != null) {
        speakers = List<Map<String, dynamic>>.from(speakerResult['speakers']);
      }
      
      // LLM 분석
      final llmService = getLLMService();
      final analysis = await llmService.analyzeEmotion(transcription);
      
      state = state.copyWith(
        isProcessing: false,
        transcription: transcription,
        analysis: analysis,
        speakers: speakers,
      );
      
      // 저장
      final record = await _audioService.saveTranscription(
        audioPath: path,
        transcription: transcription,
        analysis: analysis,
        speakers: speakers,
      );
      
      // 히스토리에 추가
      final storageService = StorageService();
      await storageService.saveRecord(record);
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to process audio: $e',
      );
    }
  }
  
  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.status;
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return status.isGranted;
  }
  
  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }
}