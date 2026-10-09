/// A single entry parsed out of an M3U/M3U8 playlist, before it is
/// classified and persisted as a [Channel]/[Movie]/[Episode].
class M3UEntry {
  final String name;
  final String? logoUrl;
  final String? groupTitle;
  final String? tvgId;
  final String url;

  const M3UEntry({
    required this.name,
    this.logoUrl,
    this.groupTitle,
    this.tvgId,
    required this.url,
  });
}

/// Parses the text content of an M3U/M3U8 playlist.
///
/// Supports the common `#EXTM3U` / `#EXTINF` format used by IPTV providers:
///
/// ```
/// #EXTM3U
/// #EXTINF:-1 tvg-id="bbc1" tvg-logo="http://.../bbc1.png" group-title="UK",BBC One
/// http://example.com/live/bbc1.m3u8
/// ```
class M3UParser {
  static final RegExp _attributeRegExp = RegExp(r'([a-zA-Z0-9_-]+)="([^"]*)"');
  static final RegExp _titleRegExp = RegExp(r',(.*)$');

  /// Parses raw M3U [content] into a list of entries. Lines that don't
  /// conform to the expected format are skipped rather than throwing, since
  /// real-world provider playlists are frequently slightly malformed.
  List<M3UEntry> parse(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    final entries = <M3UEntry>[];

    String? pendingName;
    String? pendingLogo;
    String? pendingGroup;
    String? pendingTvgId;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF')) {
        final attributes = <String, String>{};
        for (final match in _attributeRegExp.allMatches(line)) {
          attributes[match.group(1)!.toLowerCase()] = match.group(2)!;
        }
        final titleMatch = _titleRegExp.firstMatch(line);
        pendingName = titleMatch?.group(1)?.trim();
        pendingLogo = attributes['tvg-logo'];
        pendingGroup = attributes['group-title'];
        pendingTvgId = attributes['tvg-id'];
        continue;
      }

      if (line.startsWith('#')) {
        // Other directives (#EXTM3U, #EXTGRP, #EXTVLCOPT, ...) are ignored.
        continue;
      }

      // Any non-comment, non-empty line is treated as a stream URL.
      if (pendingName != null) {
        entries.add(M3UEntry(
          name: pendingName,
          logoUrl: pendingLogo,
          groupTitle: pendingGroup,
          tvgId: pendingTvgId,
          url: line,
        ));
      } else {
        // URL with no preceding #EXTINF metadata: fall back to the URL itself.
        entries.add(M3UEntry(name: line, url: line));
      }

      pendingName = null;
      pendingLogo = null;
      pendingGroup = null;
      pendingTvgId = null;
    }

    return entries;
  }
}
