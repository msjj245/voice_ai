import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/audio_provider.dart';

class RecordingScreen extends ConsumerWidget {
  const RecordingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              if (audioState.isRecording) ...[
                _buildRecordingIndicator(theme),
                const SizedBox(height: 32),
                StreamBuilder<Duration>(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    final duration = DateTime.now().difference(
                      audioState.recordingStartTime ?? DateTime.now()
                    );
                    return Text(
                      _formatDuration(duration),
                      style: theme.textTheme.displaySmall,
                    );
                  },
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(audioProvider.notifier).stopRecording();
                  },
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Recording'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ] else if (audioState.isProcessing) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Processing audio...'),
              ] else if (audioState.transcription != null) ...[
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // 전사 결과
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.text_fields,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Transcription',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(audioState.transcription!),
                              ],
                            ),
                          ),
                        ),
                        // 분석 결과
                        if (audioState.analysis != null) ...[
                          const SizedBox(height: 16),
                          Card(
                            color: theme.colorScheme.primaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.analytics,
                                        color: theme.colorScheme.onPrimaryContainer,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Analysis',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (audioState.analysis!['emotion'] != null) ...[
                                    _buildAnalysisItem(
                                      'Emotion',
                                      audioState.analysis!['emotion'],
                                      Icons.mood,
                                      theme,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (audioState.analysis!['summary'] != null) ...[
                                    _buildAnalysisItem(
                                      'Summary',
                                      audioState.analysis!['summary'],
                                      Icons.summarize,
                                      theme,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // 액션 버튼
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // 저장 완료 후 홈으로 이동
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Complete'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (audioState.error != null)
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      audioState.error!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecordingIndicator(ThemeData theme) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.error.withOpacity(0.1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.error,
            ),
          )
          .animate(onPlay: (controller) => controller.repeat())
          .scale(
            duration: 1.5.seconds,
            begin: const Offset(1, 1),
            end: const Offset(1.2, 1.2),
          )
          .then()
          .scale(
            duration: 1.5.seconds,
            begin: const Offset(1.2, 1.2),
            end: const Offset(1, 1),
          ),
          Icon(
            Icons.mic,
            size: 40,
            color: theme.colorScheme.onError,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnalysisItem(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onPrimaryContainer,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}