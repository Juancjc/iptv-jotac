import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_jotac/models/channel.dart';
import 'package:iptv_jotac/models/playlist.dart';
import 'package:iptv_jotac/services/epg_service.dart';
import 'package:iptv_jotac/services/m3u_parser.dart';

/// Answers requests from a URL -> body map.
class _FakeAdapter implements HttpClientAdapter {
  final String? Function(Uri uri) respond;
  final requested = <Uri>[];

  _FakeAdapter(this.respond);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requested.add(options.uri);
    final body = respond(options.uri);
    if (body == null) return ResponseBody.fromString('not found', 404);
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

String _b64(String s) => base64.encode(utf8.encode(s));

String _xmltvTime(DateTime t) {
  final u = t.toUtc();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${u.year}${two(u.month)}${two(u.day)}${two(u.hour)}${two(u.minute)}00 +0000';
}

void main() {
  final now = DateTime.now();
  int epoch(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

  test('reads the M3U header guide URL', () {
    const m3u = '#EXTM3U url-tvg="http://epg.example/guide.xml.gz,http://other" x-tvg-url=""\n'
        '#EXTINF:-1 tvg-id="espn2",ESPN 2\nhttp://x/1.ts\n';
    expect(M3UParser().parseEpgUrl(m3u), 'http://epg.example/guide.xml.gz');
    expect(M3UParser().parseEpgUrl('#EXTM3U\n'), isNull);
  });

  test('uses the Xtream short EPG for panel stream URLs', () async {
    final past = now.subtract(const Duration(hours: 2));
    final current = now.subtract(const Duration(minutes: 10));
    final next = now.add(const Duration(minutes: 50));
    final adapter = _FakeAdapter((uri) {
      if (uri.path != '/player_api.php' || uri.queryParameters['action'] != 'get_short_epg') return null;
      expect(uri.queryParameters['stream_id'], '123');
      expect(uri.queryParameters['username'], 'user');
      return jsonEncode({
        'epg_listings': [
          {'title': _b64('Old'), 'start_timestamp': '${epoch(past)}', 'stop_timestamp': '${epoch(current)}'},
          {'title': _b64('NFL: Cowboys x Eagles'), 'start_timestamp': '${epoch(current)}', 'stop_timestamp': '${epoch(next)}'},
          {'title': _b64('Sportscenter'), 'start_timestamp': '${epoch(next)}', 'stop_timestamp': '${epoch(next.add(const Duration(hours: 1)))}'},
        ],
      });
    });
    final service = EpgService(dio: Dio()..httpClientAdapter = adapter);
    final programs = await service.programsFor(
      const Channel(id: '1', playlistId: 'p', name: 'ESPN 2', streamUrl: 'http://panel.tv:8080/user/pass/123.ts'),
      null,
    );
    expect(programs.map((p) => p.title), ['NFL: Cowboys x Eagles', 'Sportscenter']);
    expect(programs.first.isLiveAt(now), isTrue);
  });

  test('falls back to the XMLTV guide, matching by tvg-id or name', () async {
    final start = now.subtract(const Duration(minutes: 30));
    final end = now.add(const Duration(minutes: 30));
    final xml = '''<?xml version="1.0"?><tv>
<channel id="espn2.br"><display-name>ESPN 2</display-name></channel>
<programme start="${_xmltvTime(start)}" stop="${_xmltvTime(end)}" channel="espn2.br"><title lang="pt">NFL &amp; Amigos</title></programme>
<programme start="${_xmltvTime(end)}" stop="${_xmltvTime(end.add(const Duration(hours: 1)))}" channel="espn2.br"><title>Sportscenter</title></programme>
</tv>''';
    final adapter = _FakeAdapter((uri) => uri.toString() == 'http://epg.example/guide.xml' ? xml : null);
    final service = EpgService(dio: Dio()..httpClientAdapter = adapter);
    final playlist = Playlist(
      id: 'p',
      name: 'Lista',
      type: PlaylistType.m3u,
      createdAt: now,
      epgUrl: 'http://epg.example/guide.xml',
    );

    final byId = await service.programsFor(
      const Channel(id: '1', playlistId: 'p', name: 'Whatever', streamUrl: 'http://cdn/a.m3u8', tvgId: 'espn2.br'),
      playlist,
    );
    expect(byId.map((p) => p.title), ['NFL & Amigos', 'Sportscenter']);

    final byName = await service.programsFor(
      const Channel(id: '2', playlistId: 'p', name: 'ESPN 2 [HD]', streamUrl: 'http://cdn/b.m3u8'),
      playlist,
    );
    expect(byName, hasLength(2));
    // The guide is downloaded once and reused.
    expect(adapter.requested, hasLength(1));
  });
}
