import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_jotac/providers/remote_control_providers.dart';
import 'package:iptv_jotac/services/remote_control_server.dart';

class _FakeHandler implements RemoteControlHandler {
  final played = <(RemoteContentType?, String)>[];
  final keys = <RemoteKey>[];

  @override
  Future<List<RemoteItem>> playlists() async => const [RemoteItem('p1', 'Minha lista')];

  @override
  Future<List<RemoteCategory>> categories(RemoteContentType type, String? playlistId) async =>
      const [RemoteCategory('Esportes', 2)];

  @override
  Future<(List<RemoteItem>, int)> items(
    RemoteContentType type, {
    String? playlistId,
    String? category,
    String? query,
    int offset = 0,
    int limit = 100,
  }) async {
    final all = const [RemoteItem('c1', 'ESPN 2'), RemoteItem('c2', 'Globo')];
    final matches = all.where((i) => query == null || i.name.toLowerCase().contains(query.toLowerCase())).toList();
    return (matches.skip(offset).take(limit).toList(), matches.length);
  }

  @override
  Future<List<RemoteEpisode>> episodes(String seriesId) async => const [RemoteEpisode('e1', 1, 2, 'Piloto')];

  @override
  Future<void> play(RemoteContentType? type, String id) async => played.add((type, id));

  @override
  Future<void> pressKey(RemoteKey key) async => keys.add(key);
}

void main() {
  group('RemoteControlServer', () {
    late _FakeHandler handler;
    late RemoteControlServer server;
    late Uri base;
    final client = HttpClient();

    setUp(() async {
      handler = _FakeHandler();
      server = RemoteControlServer(handler, accessCode: 'abc123');
      final url = await server.start(preferredPort: 0);
      base = Uri.parse('http://127.0.0.1:${url.port}');
    });

    tearDown(() => server.stop());

    Future<(int, String)> send(String method, String path, {Map<String, String>? query, Object? body}) async {
      final request = await client.openUrl(method, base.replace(path: path, queryParameters: query));
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close();
      return (response.statusCode, await response.transform(utf8.decoder).join());
    }

    test('refuses requests without the access code', () async {
      final (status, _) = await send('GET', '/api/playlists', query: {'k': 'wrong'});
      expect(status, 403);
      final (pageStatus, _) = await send('GET', '/');
      expect(pageStatus, 403);
    });

    test('serves the page and the catalog', () async {
      final (status, html) = await send('GET', '/', query: {'k': 'abc123'});
      expect(status, 200);
      expect(html, contains('Escolher o que assistir'));

      final (_, lists) = await send('GET', '/api/playlists', query: {'k': 'abc123'});
      expect(jsonDecode(lists), [
        {'id': 'p1', 'name': 'Minha lista', 'image': null},
      ]);

      final (_, items) = await send('GET', '/api/items', query: {'k': 'abc123', 'type': 'live', 'q': 'espn'});
      final decoded = jsonDecode(items) as Map;
      expect(decoded['total'], 1);
      expect((decoded['items'] as List).single['name'], 'ESPN 2');

      final (_, episodes) = await send('GET', '/api/episodes', query: {'k': 'abc123', 'series': 's1'});
      expect((jsonDecode(episodes) as List).single['title'], 'Piloto');
    });

    test('forwards play requests and keys', () async {
      await send('POST', '/api/play', query: {'k': 'abc123'}, body: {'type': 'live', 'id': 'c1'});
      await send('POST', '/api/play', query: {'k': 'abc123'}, body: {'type': 'episode', 'id': 'e1'});
      expect(handler.played, [(RemoteContentType.live, 'c1'), (null, 'e1')]);

      await send('POST', '/api/key', query: {'k': 'abc123'}, body: {'key': 'down'});
      final (status, _) = await send('POST', '/api/key', query: {'k': 'abc123'}, body: {'key': 'nope'});
      expect(handler.keys, [RemoteKey.down]);
      expect(status, 400);
    });
  });

  testWidgets('injected keys move focus and press buttons like a remote', (tester) async {
    var pressed = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            TextButton(autofocus: true, onPressed: () => pressed = 'first', child: const Text('first')),
            TextButton(onPressed: () => pressed = 'second', child: const Text('second')),
          ],
        ),
      ),
    );
    await tester.pump();

    injectKey(LogicalKeyboardKey.arrowDown, PhysicalKeyboardKey.arrowDown);
    await tester.pump();
    injectKey(LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(pressed, 'second');
  });
}
