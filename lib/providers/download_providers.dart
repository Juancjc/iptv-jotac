import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/download_item.dart';
import '../services/download_manager.dart';
import 'settings_providers.dart';

const _uuid = Uuid();

final downloadManagerProvider = Provider<DownloadManager>((ref) => DownloadManager());

final downloadsProvider = StateNotifierProvider<DownloadsNotifier, List<DownloadItem>>((ref) {
  return DownloadsNotifier(ref, ref.watch(downloadManagerProvider));
});

/// Queues and runs VOD downloads with a configurable concurrency limit.
/// Actual byte transfer is delegated to [DownloadManager]; this class owns
/// the queue, progress bookkeeping and cancellation.
class DownloadsNotifier extends StateNotifier<List<DownloadItem>> {
  final Ref _ref;
  final DownloadManager _manager;
  final Map<String, CancelToken> _cancelTokens = {};
  int _activeCount = 0;

  DownloadsNotifier(this._ref, this._manager) : super(const []);

  void enqueue({
    required String sourceUrl,
    required String title,
    required DownloadContentType contentType,
  }) {
    final item = DownloadItem(
      id: _uuid.v4(),
      sourceUrl: sourceUrl,
      title: title,
      contentType: contentType,
      addedAt: DateTime.now(),
    );
    state = [...state, item];
    _processQueue();
  }

  void cancel(String id) {
    _cancelTokens[id]?.cancel('canceled by user');
  }

  void retry(String id) {
    _updateItem(id, (d) => d.copyWith(status: DownloadStatus.queued, progress: 0, downloadedBytes: 0));
    _processQueue();
  }

  void remove(String id) {
    _cancelTokens[id]?.cancel('removed by user');
    state = state.where((d) => d.id != id).toList();
  }

  void _processQueue() {
    final maxConcurrent = _ref.read(maxConcurrentDownloadsProvider);
    while (_activeCount < maxConcurrent) {
      DownloadItem? next;
      for (final item in state) {
        if (item.status == DownloadStatus.queued) {
          next = item;
          break;
        }
      }
      if (next == null) return;
      _startDownload(next);
    }
  }

  Future<void> _startDownload(DownloadItem item) async {
    _activeCount++;
    _updateItem(item.id, (d) => d.copyWith(status: DownloadStatus.downloading));
    final cancelToken = CancelToken();
    _cancelTokens[item.id] = cancelToken;

    try {
      final extensionMatch = RegExp(r'\.([a-zA-Z0-9]+)(?:\?.*)?$').firstMatch(item.sourceUrl);
      final fileName = _manager.buildFileName(item.title, extensionMatch?.group(1));
      final path = await _manager.download(
        url: item.sourceUrl,
        fileName: fileName,
        cancelToken: cancelToken,
        onProgress: (received, total) {
          _updateItem(
            item.id,
            (d) => d.copyWith(
              downloadedBytes: received,
              totalBytes: (total != null && total > 0) ? total : null,
              progress: (total != null && total > 0) ? received / total : d.progress,
            ),
          );
        },
      );
      _updateItem(item.id, (d) => d.copyWith(status: DownloadStatus.completed, localPath: path, progress: 1));
    } catch (error) {
      final wasCanceled = error is DioException && error.type == DioExceptionType.cancel;
      _updateItem(
        item.id,
        (d) => d.copyWith(
          status: wasCanceled ? DownloadStatus.canceled : DownloadStatus.failed,
          errorMessage: wasCanceled ? null : error.toString(),
        ),
      );
    } finally {
      _cancelTokens.remove(item.id);
      _activeCount--;
      _processQueue();
    }
  }

  void _updateItem(String id, DownloadItem Function(DownloadItem current) update) {
    state = [
      for (final item in state)
        if (item.id == id) update(item) else item,
    ];
  }
}
