import 'package:flutter/foundation.dart';

@immutable
class AudioState {
  final bool isRecording;
  final bool isProcessing;
  final String? currentRecordingPath;
  final String? lastRecordingPath;
  final String? transcription;
  final String? error;
  final DateTime? recordingStartTime;
  final Duration? recordingDuration;
  final Map<String, dynamic>? analysis;
  final List<Map<String, dynamic>>? speakers;
  
  const AudioState({
    this.isRecording = false,
    this.isProcessing = false,
    this.currentRecordingPath,
    this.lastRecordingPath,
    this.transcription,
    this.error,
    this.recordingStartTime,
    this.recordingDuration,
    this.analysis,
    this.speakers,
  });
  
  AudioState copyWith({
    bool? isRecording,
    bool? isProcessing,
    String? currentRecordingPath,
    String? lastRecordingPath,
    String? transcription,
    String? error,
    DateTime? recordingStartTime,
    Duration? recordingDuration,
    Map<String, dynamic>? analysis,
    List<Map<String, dynamic>>? speakers,
  }) {
    return AudioState(
      isRecording: isRecording ?? this.isRecording,
      isProcessing: isProcessing ?? this.isProcessing,
      currentRecordingPath: currentRecordingPath ?? this.currentRecordingPath,
      lastRecordingPath: lastRecordingPath ?? this.lastRecordingPath,
      transcription: transcription ?? this.transcription,
      error: error ?? this.error,
      recordingStartTime: recordingStartTime ?? this.recordingStartTime,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      analysis: analysis ?? this.analysis,
      speakers: speakers ?? this.speakers,
    );
  }
}