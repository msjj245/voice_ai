import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transcription_record.dart';
import '../widgets/editable_text_field.dart';
import '../services/storage_service.dart';
import '../providers/service_providers.dart';

class TranscriptionDetailScreen extends ConsumerStatefulWidget {
  final TranscriptionRecord record;
  
  const TranscriptionDetailScreen({
    super.key,
    required this.record,
  });

  @override
  ConsumerState<TranscriptionDetailScreen> createState() => _TranscriptionDetailScreenState();
}

class _TranscriptionDetailScreenState extends ConsumerState<TranscriptionDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _transcriptionController;
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.record.title ?? 'Untitled');
    _transcriptionController = TextEditingController(text: widget.record.transcription);
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _transcriptionController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: _isEditing
            ? TextField(
                controller: _titleController,
                style: theme.textTheme.titleLarge,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter title',
                ),
              )
            : Text(widget.record.title ?? 'Untitled'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
              if (!_isEditing) {
                // Save changes
                _saveChanges();
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareTranscription();
                  break;
                case 'delete':
                  _deleteRecord();
                  break;
                case 'analyze':
                  _analyzeTranscription();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Text('Share'),
              ),
              const PopupMenuItem(
                value: 'analyze',
                child: Text('Analyze'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.record.analysis != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.primaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analysis',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.record.analysis!['emotion'] != null)
                      _buildAnalysisChip(
                        'Emotion: ${widget.record.analysis!['emotion']}',
                        Icons.mood,
                      ),
                    if (widget.record.analysis!['summary'] != null)
                      _buildAnalysisChip(
                        'Summary available',
                        Icons.summarize,
                      ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.record.speakerSegments != null &&
                        widget.record.speakerSegments!.isNotEmpty) ...[
                      Text(
                        'Speaker Diarization',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ...widget.record.speakerSegments!.map((segment) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      segment.speaker,
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_formatTime(segment.startTime)} - ${_formatTime(segment.endTime)}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(segment.text),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ] else ...[
                      Text(
                        'Transcription',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      if (_isEditing)
                        TextField(
                          controller: _transcriptionController,
                          maxLines: null,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Edit transcription...',
                          ),
                        )
                      else
                        SelectableText(
                          widget.record.transcription,
                          style: theme.textTheme.bodyLarge,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnalysisChip(String label, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(double seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toInt().toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
  
  void _saveChanges() async {
    widget.record.title = _titleController.text;
    
    // Transcription이 변경되었으면 업데이트
    if (_transcriptionController.text != widget.record.transcription) {
      // 새로운 record 생성 (Hive 객체는 immutable)
      final updatedRecord = TranscriptionRecord(
        id: widget.record.id,
        transcription: _transcriptionController.text,
        createdAt: widget.record.createdAt,
        duration: widget.record.duration,
        title: _titleController.text,
        tags: widget.record.tags,
        audioFilePath: widget.record.audioFilePath,
        analysis: widget.record.analysis,
        speakerSegments: widget.record.speakerSegments,
      );
      
      // 저장
      final storageService = StorageService();
      await storageService.updateRecord(updatedRecord);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved')),
        );
      }
    }
  }
  
  void _shareTranscription() {
    final text = StringBuffer();
    text.writeln(widget.record.title ?? 'Transcription');
    text.writeln('Date: ${widget.record.createdAt}');
    text.writeln();
    text.writeln(widget.record.transcription);
    
    Share.share(text.toString());
  }
  
  void _deleteRecord() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: const Text('Are you sure you want to delete this recording?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);
              
              // 실제로 삭제
              final storageService = StorageService();
              await storageService.deleteRecord(widget.record.id);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recording deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _analyzeTranscription() async {
    try {
      final llmService = ref.read(llmServiceProvider);
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('AI 분석 중...'),
            ],
          ),
        ),
      );
      
      // Perform AI analysis
      final analysis = await llmService.analyzeTranscription(widget.record.transcription);
      
      Navigator.of(context).pop(); // Close loading dialog
      
      // Show analysis results
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI 분석 결과'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('감정: ${analysis['emotion']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('요약: ${analysis['summary']}'),
                const SizedBox(height: 8),
                if (analysis['tasks'] != null && (analysis['tasks'] as List).isNotEmpty) ...[
                  const Text('추출된 작업:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...((analysis['tasks'] as List).map((task) => Text('• ${task['task']}'))),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('분석 실패: $e')),
      );
    }
  }
}