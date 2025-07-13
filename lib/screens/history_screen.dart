import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transcription_record.dart';
import '../providers/history_provider.dart';
import '../widgets/common/empty_state_widget.dart';
import 'transcription_detail_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search
            },
          ),
        ],
      ),
      body: history.when(
        data: (records) {
          if (records.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.history,
              title: 'No recordings yet',
              subtitle: 'Start recording or upload an audio file to see your history here',
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return _HistoryCard(record: record);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final TranscriptionRecord record;
  
  const _HistoryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y h:mm a');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TranscriptionDetailScreen(record: record),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.mic,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(record.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (record.duration != null)
                    Text(
                      _formatDuration(record.duration!),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                record.title ?? 'Untitled Recording',
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                record.transcription,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (record.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: record.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                      labelStyle: const TextStyle(fontSize: 12),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}