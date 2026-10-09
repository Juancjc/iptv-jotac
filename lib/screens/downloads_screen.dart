import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/download_item.dart';
import '../providers/download_providers.dart';
import '../widgets/empty_state.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsProvider);

    if (downloads.isEmpty) {
      return const EmptyState(
        icon: Icons.download_outlined,
        title: 'Nenhum download em andamento',
        message: 'Toque no icone de download em um filme ou episodio para baixa-lo.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        final item = downloads[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.title, style: Theme.of(context).textTheme.titleSmall, overflow: TextOverflow.ellipsis),
                    ),
                    _StatusChip(status: item.status),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: item.status == DownloadStatus.queued ? null : item.progress),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_subtitleFor(item), style: Theme.of(context).textTheme.bodySmall),
                    Row(
                      children: [
                        if (item.status == DownloadStatus.downloading || item.status == DownloadStatus.queued)
                          TextButton(
                            onPressed: () => ref.read(downloadsProvider.notifier).cancel(item.id),
                            child: const Text('Cancelar'),
                          ),
                        if (item.status == DownloadStatus.failed || item.status == DownloadStatus.canceled)
                          TextButton(
                            onPressed: () => ref.read(downloadsProvider.notifier).retry(item.id),
                            child: const Text('Repetir'),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Remover',
                          onPressed: () => ref.read(downloadsProvider.notifier).remove(item.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _subtitleFor(DownloadItem item) {
    switch (item.status) {
      case DownloadStatus.queued:
        return 'Na fila';
      case DownloadStatus.downloading:
        final total = item.totalBytes;
        if (total != null) {
          final receivedMb = (item.downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
          final totalMb = (total / (1024 * 1024)).toStringAsFixed(1);
          return '$receivedMb MB / $totalMb MB';
        }
        return 'Baixando...';
      case DownloadStatus.paused:
        return 'Pausado';
      case DownloadStatus.completed:
        return item.localPath ?? 'Concluido';
      case DownloadStatus.failed:
        return item.errorMessage ?? 'Falhou';
      case DownloadStatus.canceled:
        return 'Cancelado';
    }
  }
}

class _StatusChip extends StatelessWidget {
  final DownloadStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      DownloadStatus.queued => ('Na fila', Colors.grey),
      DownloadStatus.downloading => ('Baixando', Colors.blue),
      DownloadStatus.paused => ('Pausado', Colors.orange),
      DownloadStatus.completed => ('Concluido', Colors.green),
      DownloadStatus.failed => ('Falhou', Colors.red),
      DownloadStatus.canceled => ('Cancelado', Colors.grey),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
