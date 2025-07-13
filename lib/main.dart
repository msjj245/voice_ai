import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'utils/theme.dart';
import 'services/storage_service.dart';
import 'services/model_manager.dart';
import 'models/transcription_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Hive 초기화
  await Hive.initFlutter();
  
  // 어댑터 등록
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TranscriptionRecordAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(SpeakerSegmentAdapter());
  }
  
  // Storage 서비스 초기화
  final storageService = StorageService();
  await storageService.initialize();
  
  runApp(
    const ProviderScope(
      child: VoiceAIApp(),
    ),
  );
}

class VoiceAIApp extends StatelessWidget {
  const VoiceAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice AI Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AppInitializer(),
    );
  }
  
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  String _statusMessage = 'Initializing...';
  String _currentModel = '';
  double _progress = 0.0;
  bool _showProgress = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Check if first run
      final prefs = await SharedPreferences.getInstance();
      final isFirstRun = prefs.getBool('first_run') ?? true;
      
      if (isFirstRun) {
        // Show onboarding
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const OnboardingScreen(),
            ),
          );
        }
        return;
      }

      // Initialize models automatically
      setState(() {
        _statusMessage = 'Checking AI models...';
      });

      await ModelManager.instance.initializeModels(
        context: context,
        onProgress: (modelName, progress) {
          if (mounted) {
            setState(() {
              _currentModel = modelName;
              _progress = progress;
              _showProgress = true;
              _statusMessage = 'Downloading $modelName...';
            });
          }
        },
      );

      // Navigate to home
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Initialization failed: $e';
        });
        
        // Show error and navigate to home after delay
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.record_voice_over,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Voice AI Assistant',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_showProgress) ...[
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall,
                ),
              ] else
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}