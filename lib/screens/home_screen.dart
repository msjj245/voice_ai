import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/recording_button.dart';
import '../providers/audio_provider.dart';
import '../models/audio_state.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const RecordingView(),
    const HistoryScreen(),
  ];
  
  void switchToHistory() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.mic_outlined),
            selectedIcon: Icon(Icons.mic),
            label: 'Record',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class RecordingView extends ConsumerWidget {
  const RecordingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final audioState = ref.watch(audioProvider);
    
    // 에러 메시지 표시
    ref.listen<AudioState>(audioProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: theme.colorScheme.error,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: theme.colorScheme.onError,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    });
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.record_voice_over,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ).animate().fadeIn().scale(),
                      const SizedBox(height: 16),
                      Text(
                        'Start Recording',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the button below to start recording or upload an audio file',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
              const Spacer(),
              const RecordingButton(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(audioProvider.notifier).uploadAudioFile();
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Audio'),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}