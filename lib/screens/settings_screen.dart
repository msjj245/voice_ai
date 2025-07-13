import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';
import '../constants/model_configs.dart';
import 'model_download_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String selectedWhisperModel = 'base';
  String selectedLLMModel = 'gemma-2b';
  bool enableSpeakerDiarization = true;
  bool autoAnalyze = true;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Whisper 설정
          _buildSectionHeader('Speech Recognition', Icons.mic),
          ListTile(
            title: const Text('Whisper Model'),
            subtitle: Text('Selected: $selectedWhisperModel'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showModelSelection(context, true),
          ),
          SwitchListTile(
            title: const Text('Speaker Diarization'),
            subtitle: const Text('Identify different speakers'),
            value: enableSpeakerDiarization,
            onChanged: (value) {
              setState(() {
                enableSpeakerDiarization = value;
              });
            },
          ),
          
          const Divider(),
          
          // LLM 설정
          _buildSectionHeader('AI Analysis', Icons.psychology),
          ListTile(
            title: const Text('LLM Model'),
            subtitle: Text('Selected: $selectedLLMModel'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showModelSelection(context, false),
          ),
          SwitchListTile(
            title: const Text('Auto-analyze'),
            subtitle: const Text('Automatically analyze transcriptions'),
            value: autoAnalyze,
            onChanged: (value) {
              setState(() {
                autoAnalyze = value;
              });
            },
          ),
          
          const Divider(),
          
          // 저장 설정
          _buildSectionHeader('Storage', Icons.storage),
          ListTile(
            title: const Text('Clear History'),
            subtitle: const Text('Delete all transcriptions'),
            trailing: const Icon(Icons.delete_outline),
            onTap: () => _showClearHistoryDialog(context),
          ),
          ListTile(
            title: const Text('Export Data'),
            subtitle: const Text('Export all transcriptions'),
            trailing: const Icon(Icons.download),
            onTap: () {
              _exportData();
            },
          ),
          ListTile(
            title: const Text('Download Models'),
            subtitle: const Text('Manage AI models'),
            trailing: const Icon(Icons.model_training),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModelDownloadScreen(),
                ),
              );
            },
          ),
          
          const Divider(),
          
          // 앱 정보
          _buildSectionHeader('About', Icons.info_outline),
          ListTile(
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              _openPrivacyPolicy();
            },
          ),
          ListTile(
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              _openTermsOfService();
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showModelSelection(BuildContext context, bool isWhisper) {
    final models = isWhisper
        ? ModelConfigs.whisperModels.keys.toList()
        : ModelConfigs.llmModels.keys.toList();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                isWhisper ? 'Select Whisper Model' : 'Select LLM Model',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...models.map((model) {
              final isSelected = isWhisper
                  ? model == selectedWhisperModel
                  : model == selectedLLMModel;
              
              return ListTile(
                title: Text(model),
                subtitle: isWhisper
                    ? Text('${ModelConfigs.whisperModels[model]!['size']} MB')
                    : Text('${ModelConfigs.llmModels[model]!['size']} MB'),
                trailing: isSelected
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() {
                    if (isWhisper) {
                      selectedWhisperModel = model;
                    } else {
                      selectedLLMModel = model;
                    }
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to delete all transcriptions? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Clear history
              final storageService = StorageService();
              await storageService.clearAll();
              
              Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History cleared')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _exportData() async {
    try {
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
              Text('데이터 내보내는 중...'),
            ],
          ),
        ),
      );
      
      final storageService = StorageService();
      final transcriptions = await storageService.getAllTranscriptions();
      
      // Create export data
      final exportData = {
        'app': 'Voice AI App',
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'transcriptions': transcriptions.map((t) => {
          'id': t.id,
          'title': t.title,
          'transcription': t.transcription,
          'createdAt': t.createdAt.toIso8601String(),
          'audioFilePath': t.audioFilePath,
          'duration': t.duration,
          'speakers': t.speakers,
          'analysis': t.analysis,
        }).toList(),
      };
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/voice_ai_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(JsonEncoder.withIndent('  ').convert(exportData));
      
      Navigator.of(context).pop(); // Close loading dialog
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '음성 AI 앱 데이터 내보내기',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('데이터를 성공적으로 내보냈습니다')),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('내보내기 실패: $e')),
      );
    }
  }
  
  Future<void> _openPrivacyPolicy() async {
    _showUrlNotAvailableDialog('개인정보 처리방침');
  }
  
  Future<void> _openTermsOfService() async {
    _showUrlNotAvailableDialog('이용약관');
  }
  
  void _showUrlNotAvailableDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('현재 링크를 열 수 없습니다. 나중에 다시 시도해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}