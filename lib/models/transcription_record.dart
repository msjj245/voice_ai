import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'transcription_record.g.dart';

@HiveType(typeId: 0)
class TranscriptionRecord extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String transcription;
  
  @HiveField(2)
  final DateTime createdAt;
  
  @HiveField(3)
  final Duration? duration;
  
  @HiveField(4)
  String? title;
  
  @HiveField(5)
  final List<String> tags;
  
  @HiveField(6)
  final String? audioFilePath;
  
  @HiveField(7)
  final Map<String, dynamic>? analysis;
  
  @HiveField(8)
  final List<SpeakerSegment>? speakerSegments;
  
  TranscriptionRecord({
    String? id,
    required this.transcription,
    DateTime? createdAt,
    this.duration,
    this.title,
    List<String>? tags,
    this.audioFilePath,
    this.analysis,
    this.speakerSegments,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       tags = tags ?? [];
       
  // speakers getter for backward compatibility
  List<Map<String, dynamic>>? get speakers {
    return speakerSegments?.map((segment) => {
      'speaker': segment.speaker,
      'text': segment.text,
      'start_time': segment.startTime,
      'end_time': segment.endTime,
    }).toList();
  }
}

@HiveType(typeId: 1)
class SpeakerSegment {
  @HiveField(0)
  final String speaker;
  
  @HiveField(1)
  final String text;
  
  @HiveField(2)
  final double startTime;
  
  @HiveField(3)
  final double endTime;
  
  SpeakerSegment({
    required this.speaker,
    required this.text,
    required this.startTime,
    required this.endTime,
  });
}