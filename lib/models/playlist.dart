/// Type of content source a user can register in the app.
enum PlaylistType { m3u, xtream }

/// A user-registered content source: either a plain M3U/M3U8 playlist URL
/// or a set of Xtream Codes panel credentials.
class Playlist {
  final String id;
  final String name;
  final PlaylistType type;

  // M3U fields.
  final String? m3uUrl;

  // Xtream Codes fields.
  final String? xtreamHost;
  final String? xtreamUsername;
  final String? xtreamPassword;

  final DateTime createdAt;
  final DateTime? lastSyncedAt;

  const Playlist({
    required this.id,
    required this.name,
    required this.type,
    this.m3uUrl,
    this.xtreamHost,
    this.xtreamUsername,
    this.xtreamPassword,
    required this.createdAt,
    this.lastSyncedAt,
  });

  /// Whether the registered source talks plain HTTP (no TLS). Used to warn
  /// the user that credentials/content travel unencrypted.
  bool get isInsecure {
    final url = type == PlaylistType.m3u ? m3uUrl : xtreamHost;
    if (url == null) return false;
    final uri = Uri.tryParse(url);
    return uri != null && uri.scheme.toLowerCase() == 'http';
  }

  Playlist copyWith({
    String? name,
    String? m3uUrl,
    String? xtreamHost,
    String? xtreamUsername,
    String? xtreamPassword,
    DateTime? lastSyncedAt,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      type: type,
      m3uUrl: m3uUrl ?? this.m3uUrl,
      xtreamHost: xtreamHost ?? this.xtreamHost,
      xtreamUsername: xtreamUsername ?? this.xtreamUsername,
      xtreamPassword: xtreamPassword ?? this.xtreamPassword,
      createdAt: createdAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
