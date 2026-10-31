import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/channel.dart';
import '../models/playlist.dart';

/// One entry of a channel's program guide.
class EpgProgram {
  final String title;
  final DateTime start;
  final DateTime end;

  const EpgProgram({required this.title, required this.start, required this.end});

  bool isLiveAt(DateTime time) => !time.isBefore(start) && time.isBefore(end);
}

/// Matches Xtream-style stream URLs: `http://host:port[/live]/user/pass/123.ts`.
/// Both Xtream panels and their `get.php` M3U exports use this shape, so the
/// panel's lightweight per-channel guide API can be used for either.
final _xtreamStreamRegExp = RegExp(r'^(https?://[^/]+)/(?:live/)?([^/]+)/([^/]+)/(\d+)(?:\.[A-Za-z0-9]+)?$');

/// Loads program guides (EPG) for live channels.
///
/// Prefers the Xtream `get_short_epg` endpoint (a few KB per channel); falls
/// back to the playlist's XMLTV file, which is downloaded once per session and
/// kept in memory, trimmed to the next day of programs.
class EpgService {
  /// How long a downloaded XMLTV guide is reused before fetching it again.
  static const _xmltvMaxAge = Duration(hours: 6);

  final Dio _dio;
  final _xmltvCache = <String, _CachedGuide>{};

  EpgService({Dio? dio}) : _dio = dio ?? Dio();

  /// Programs for [channel] that haven't ended yet, oldest first. Returns an
  /// empty list when no guide is available.
  Future<List<EpgProgram>> programsFor(Channel channel, Playlist? playlist) async {
    final xtream = _xtreamTarget(channel.streamUrl);
    if (xtream != null) {
      try {
        final programs = await _shortEpg(xtream);
        if (programs.isNotEmpty) return programs;
      } catch (_) {
        // Panel without the guide API; try XMLTV below.
      }
    }

    final xmltvUrl =
        playlist?.epgUrl ??
        (xtream == null
            ? null
            : '${xtream.base}/xmltv.php?username=${Uri.encodeQueryComponent(xtream.username)}'
                  '&password=${Uri.encodeQueryComponent(xtream.password)}');
    if (xmltvUrl == null) return const [];

    final guide = await _xmltv(xmltvUrl);
    final channelId = _findXmltvChannel(guide, channel);
    if (channelId == null) return const [];
    final now = DateTime.now();
    return [
      for (final p in guide.programs[channelId] ?? const <_RawProgram>[])
        if (p.$2 > now.millisecondsSinceEpoch)
          EpgProgram(
            title: p.$3,
            start: DateTime.fromMillisecondsSinceEpoch(p.$1),
            end: DateTime.fromMillisecondsSinceEpoch(p.$2),
          ),
    ];
  }

  _XtreamTarget? _xtreamTarget(String streamUrl) {
    final match = _xtreamStreamRegExp.firstMatch(streamUrl.trim());
    if (match == null) return null;
    return _XtreamTarget(match.group(1)!, match.group(2)!, match.group(3)!, match.group(4)!);
  }

  Future<List<EpgProgram>> _shortEpg(_XtreamTarget target) async {
    final uri = Uri.parse('${target.base}/player_api.php').replace(
      queryParameters: {
        'username': target.username,
        'password': target.password,
        'action': 'get_short_epg',
        'stream_id': target.streamId,
        'limit': '10',
      },
    );
    final response = await _dio.getUri<dynamic>(
      uri,
      options: Options(receiveTimeout: const Duration(seconds: 15)),
    );
    var data = response.data;
    // Some panels send JSON as text/html, which dio leaves undecoded.
    if (data is String) data = jsonDecode(data);
    final listings = data is Map ? data['epg_listings'] : null;
    if (listings is! List) return const [];

    final now = DateTime.now();
    final programs = <EpgProgram>[];
    for (final item in listings) {
      if (item is! Map) continue;
      final start = _epochSeconds(item['start_timestamp']);
      final end = _epochSeconds(item['stop_timestamp'] ?? item['end_timestamp']);
      if (start == null || end == null || !end.isAfter(now)) continue;
      final title = _decodeBase64(item['title']?.toString() ?? '').trim();
      if (title.isEmpty) continue;
      programs.add(EpgProgram(title: title, start: start, end: end));
    }
    programs.sort((a, b) => a.start.compareTo(b.start));
    return programs;
  }

  Future<_Guide> _xmltv(String url) {
    final cached = _xmltvCache[url];
    if (cached != null && DateTime.now().difference(cached.loadedAt) < _xmltvMaxAge) {
      return cached.guide;
    }
    final future = _downloadXmltv(url);
    _xmltvCache[url] = _CachedGuide(future, DateTime.now());
    // A failed download shouldn't be cached for hours.
    future.catchError((Object _) {
      _xmltvCache.remove(url);
      return const _Guide({}, {});
    });
    return future;
  }

  Future<_Guide> _downloadXmltv(String url) async {
    final response = await _dio.get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
    final bytes = response.data is Uint8List ? response.data as Uint8List : Uint8List.fromList(response.data ?? const []);
    final now = DateTime.now().millisecondsSinceEpoch;
    // Big guides take seconds to parse; keep that off the UI thread.
    return Isolate.run(() => _parseXmltv(bytes, now));
  }

  String? _findXmltvChannel(_Guide guide, Channel channel) {
    final tvgId = channel.tvgId?.trim();
    if (tvgId != null && tvgId.isNotEmpty) {
      if (guide.programs.containsKey(tvgId)) return tvgId;
      final byLowerId = guide.idByName['id:${tvgId.toLowerCase()}'];
      if (byLowerId != null) return byLowerId;
    }
    return guide.idByName[_normalizeName(channel.name)];
  }
}

DateTime? _epochSeconds(Object? value) {
  final seconds = int.tryParse(value?.toString() ?? '');
  return seconds == null ? null : DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
}

String _decodeBase64(String value) {
  try {
    return utf8.decode(base64.decode(base64.normalize(value)), allowMalformed: true);
  } catch (_) {
    return value;
  }
}

/// Lowercase name without quality tags or punctuation, so "ESPN 2 [HD]"
/// matches a guide entry called "ESPN 2".
String _normalizeName(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r'\[[^\]]*\]|\([^)]*\)'), ' ')
      .replaceAll(RegExp(r'\b(fhd|uhd|hd|sd|4k|h265|hevc)\b'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9à-ú]+'), '');
}

class _XtreamTarget {
  final String base;
  final String username;
  final String password;
  final String streamId;

  const _XtreamTarget(this.base, this.username, this.password, this.streamId);
}

class _CachedGuide {
  final Future<_Guide> guide;
  final DateTime loadedAt;

  const _CachedGuide(this.guide, this.loadedAt);
}

/// (start ms, end ms, title) — a record so it can cross isolates cheaply.
typedef _RawProgram = (int, int, String);

class _Guide {
  /// Programs per XMLTV channel id, sorted by start time.
  final Map<String, List<_RawProgram>> programs;

  /// Normalized display name (and `id:<lowercase id>`) -> XMLTV channel id.
  final Map<String, String> idByName;

  const _Guide(this.programs, this.idByName);
}

final _channelRegExp = RegExp(r'<channel\s[^>]*id="([^"]*)"[^>]*>(.*?)</channel>', dotAll: true);
final _displayNameRegExp = RegExp(r'<display-name[^>]*>(.*?)</display-name>', dotAll: true);
final _programmeRegExp = RegExp(r'<programme\s([^>]*)>(.*?)</programme>', dotAll: true);
final _titleRegExp = RegExp(r'<title[^>]*>(.*?)</title>', dotAll: true);
final _attrRegExp = RegExp(r'([a-z_-]+)="([^"]*)"');
final _xmltvTimeRegExp = RegExp(r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})?\s*([+-]\d{4})?');

/// Parses an XMLTV document (optionally gzipped), keeping only programs that
/// overlap the window from now until 24h ahead. Top-level so it can run in
/// [Isolate.run].
_Guide _parseXmltv(Uint8List bytes, int nowMs) {
  final raw = bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b ? gzip.decode(bytes) : bytes;
  final xml = utf8.decode(raw, allowMalformed: true);
  final windowEnd = nowMs + const Duration(hours: 24).inMilliseconds;

  final idByName = <String, String>{};
  for (final match in _channelRegExp.allMatches(xml)) {
    final id = _unescapeXml(match.group(1)!);
    idByName['id:${id.toLowerCase()}'] = id;
    for (final name in _displayNameRegExp.allMatches(match.group(2)!)) {
      idByName.putIfAbsent(_normalizeName(_unescapeXml(name.group(1)!)), () => id);
    }
  }

  final programs = <String, List<_RawProgram>>{};
  for (final match in _programmeRegExp.allMatches(xml)) {
    final attrs = <String, String>{
      for (final a in _attrRegExp.allMatches(match.group(1)!)) a.group(1)!: a.group(2)!,
    };
    final start = _parseXmltvTime(attrs['start']);
    final stop = _parseXmltvTime(attrs['stop']);
    final channel = attrs['channel'];
    if (start == null || stop == null || channel == null) continue;
    if (stop <= nowMs || start >= windowEnd) continue;
    final title = _titleRegExp.firstMatch(match.group(2)!)?.group(1);
    if (title == null) continue;
    programs.putIfAbsent(_unescapeXml(channel), () => []).add((start, stop, _unescapeXml(title).trim()));
  }
  for (final list in programs.values) {
    list.sort((a, b) => a.$1.compareTo(b.$1));
  }
  return _Guide(programs, idByName);
}

/// XMLTV times look like `20261031191500 -0300`.
int? _parseXmltvTime(String? value) {
  if (value == null) return null;
  final m = _xmltvTimeRegExp.firstMatch(value.trim());
  if (m == null) return null;
  final utc = DateTime.utc(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
    int.parse(m.group(4)!),
    int.parse(m.group(5)!),
    int.parse(m.group(6) ?? '0'),
  );
  final offset = m.group(7);
  if (offset == null) return utc.millisecondsSinceEpoch;
  final sign = offset.startsWith('-') ? -1 : 1;
  final minutes = int.parse(offset.substring(1, 3)) * 60 + int.parse(offset.substring(3, 5));
  return utc.millisecondsSinceEpoch - sign * minutes * 60000;
}

String _unescapeXml(String value) {
  var s = value;
  if (s.startsWith('<![CDATA[') && s.endsWith(']]>')) {
    return s.substring(9, s.length - 3);
  }
  s = s.replaceAllMapped(RegExp(r'&#(x?)([0-9a-fA-F]+);'), (m) {
    final code = int.tryParse(m.group(2)!, radix: m.group(1)!.isEmpty ? 10 : 16);
    return code == null ? m.group(0)! : String.fromCharCode(code);
  });
  return s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}
