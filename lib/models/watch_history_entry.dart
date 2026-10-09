enum WatchableType { channel, movie, episode }

/// A "continue watching" entry: the last known playback position for a
/// piece of content.
class WatchHistoryEntry {
  final String id;
  final String contentId;
  final WatchableType contentType;
  final String title;
  final String streamUrl;
  final String? posterUrl;
  final int positionSeconds;
  final int? durationSeconds;
  final DateTime lastWatchedAt;

  const WatchHistoryEntry({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.title,
    required this.streamUrl,
    this.posterUrl,
    this.positionSeconds = 0,
    this.durationSeconds,
    required this.lastWatchedAt,
  });

  double get progressFraction {
    final duration = durationSeconds;
    if (duration == null || duration <= 0) return 0;
    return (positionSeconds / duration).clamp(0, 1).toDouble();
  }
}
