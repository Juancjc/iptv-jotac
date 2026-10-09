enum DownloadStatus { queued, downloading, paused, completed, failed, canceled }

enum DownloadContentType { movie, episode }

/// Tracks the lifecycle of a single VOD download (movie or episode).
class DownloadItem {
  final String id;
  final String sourceUrl;
  final String title;
  final DownloadContentType contentType;
  final String? localPath;
  final DownloadStatus status;
  final double progress; // 0.0 - 1.0
  final int? totalBytes;
  final int downloadedBytes;
  final DateTime addedAt;
  final String? errorMessage;

  const DownloadItem({
    required this.id,
    required this.sourceUrl,
    required this.title,
    required this.contentType,
    this.localPath,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.totalBytes,
    this.downloadedBytes = 0,
    required this.addedAt,
    this.errorMessage,
  });

  DownloadItem copyWith({
    String? localPath,
    DownloadStatus? status,
    double? progress,
    int? totalBytes,
    int? downloadedBytes,
    String? errorMessage,
  }) {
    return DownloadItem(
      id: id,
      sourceUrl: sourceUrl,
      title: title,
      contentType: contentType,
      localPath: localPath ?? this.localPath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      addedAt: addedAt,
      errorMessage: errorMessage,
    );
  }
}
