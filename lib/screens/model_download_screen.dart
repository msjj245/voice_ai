import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/platform_services.dart';
import '../constants/model_configs.dart';
import 'home_screen.dart';

class ModelDownloadScreen extends ConsumerStatefulWidget {
  const ModelDownloadScreen({super.key});

  @override
  ConsumerState<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends ConsumerState<ModelDownloadScreen> {
  final whisperService = WhisperService();
  final llmService = LLMService();
  
  Map<String, double> downloadProgress = {};
  Map<String, bool> isDownloading = {};
  
  @override
  void initState() {
    super.initState();
    _checkDownloadedModels();
  }
  
  Future<void> _checkDownloadedModels() async {
    // Check Whisper models
    final whisperModels = whisperService.getAvailableModels();
    for (final model in whisperModels) {
      if (await whisperService.isModelDownloaded(model)) {
        setState(() {
          downloadProgress[model] = 1.0;
        });
      }
    }
    
    // Check LLM models
    for (final model in ModelConfigs.llmModels.keys) {
      if (await llmService.isModelDownloaded(model)) {
        setState(() {
          downloadProgress[model] = 1.0;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Models'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Speech Recognition Models', Icons.mic, theme),
          ...ModelConfigs.whisperModels.keys.map((model) {
            final config = ModelConfigs.whisperModels[model];
            return _buildModelCard(
              model: model,
              name: 'Whisper ${model.toUpperCase()}',
              size: (config?['size'] as int?) ?? 0,
              type: 'whisper',
              theme: theme,
              subtitle: '${config?['accuracy']} accuracy, ${config?['speed']} speed',
            );
          }).toList(),
          
          const SizedBox(height: 24),
          
          _buildSectionHeader('Language Models', Icons.psychology, theme),
          ...ModelConfigs.llmModels.entries.map((entry) {
            final config = entry.value;
            return _buildModelCard(
              model: entry.key,
              name: config['name'] as String,
              size: config['size'] as int,
              type: 'llm',
              theme: theme,
              subtitle: '${config['parameters']} parameters, ${config['quantization']}',
            );
          }).toList(),
          
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: _buildFloatingButton(theme),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
  
  Widget _buildModelCard({
    required String model,
    required String name,
    required int size,
    required String type,
    required ThemeData theme,
    String? subtitle,
  }) {
    final progress = downloadProgress[model] ?? 0.0;
    final isComplete = progress >= 1.0;
    final downloading = isDownloading[model] ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${size} MB',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isComplete)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 32,
                  )
                else if (downloading)
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      value: progress > 0 ? progress : null,
                      strokeWidth: 3,
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.download),
                    iconSize: 32,
                    onPressed: () => _downloadModel(model, type),
                  ),
              ],
            ),
            if (downloading && progress > 0) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.surfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toInt()}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildFloatingButton(ThemeData theme) {
    final hasDownloadedModels = downloadProgress.values.any((p) => p >= 1.0);
    
    if (!hasDownloadedModels) return const SizedBox.shrink();
    
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      },
      label: const Text('Continue'),
      icon: const Icon(Icons.arrow_forward),
    );
  }
  
  Future<void> _downloadModel(String model, String type) async {
    setState(() {
      isDownloading[model] = true;
      downloadProgress[model] = 0.0;
    });
    
    try {
      if (type == 'whisper') {
        await whisperService.downloadModel(
          model,
          onProgress: (progress) {
            setState(() {
              downloadProgress[model] = progress;
            });
          },
        );
      } else {
        await llmService.downloadModel(
          model,
          onProgress: (progress) {
            setState(() {
              downloadProgress[model] = progress;
            });
          },
        );
      }
      
      setState(() {
        isDownloading[model] = false;
        downloadProgress[model] = 1.0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$model downloaded successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isDownloading[model] = false;
        downloadProgress[model] = 0.0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download $model: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}