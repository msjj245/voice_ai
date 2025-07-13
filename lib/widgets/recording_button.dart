import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/audio_provider.dart';
import '../screens/recording_screen.dart';

class RecordingButton extends ConsumerWidget {
  const RecordingButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () async {
        if (!audioState.isRecording) {
          await ref.read(audioProvider.notifier).startRecording();
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RecordingScreen(),
              ),
            );
          }
        }
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: audioState.isRecording 
              ? theme.colorScheme.error 
              : theme.colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: (audioState.isRecording 
                  ? theme.colorScheme.error 
                  : theme.colorScheme.primary).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          audioState.isRecording ? Icons.stop : Icons.mic,
          size: 48,
          color: theme.colorScheme.onPrimary,
        ),
      )
      .animate(target: audioState.isRecording ? 1 : 0)
      .scale(duration: 200.ms, begin: const Offset(1, 1), end: const Offset(0.9, 0.9))
      .then()
      .scale(duration: 200.ms, begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
    );
  }
}