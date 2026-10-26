import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_jotac/services/qr_pairing_server.dart';

void main() {
  late QrPairingServer server;
  late Uri baseUrl;

  setUp(() async {
    server = QrPairingServer(
      initial: const PairingSubmission.xtream(
        name: 'Lista "A"',
        host: 'http://old.example.com:8080',
        username: 'user',
        password: 'segredo',
      ),
    );
    final url = await server.start(preferredPort: 0);
    baseUrl = Uri(scheme: 'http', host: '127.0.0.1', port: url.port);
  });

  tearDown(() => server.stop());

  Future<String> send(String method, {String? body}) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, baseUrl);
      if (body != null) {
        request.headers.contentType = ContentType('application', 'x-www-form-urlencoded');
        request.write(body);
      }
      final response = await request.close();
      return response.transform(utf8.decoder).join();
    } finally {
      client.close();
    }
  }

  test('edit form is prefilled but never exposes the password', () async {
    final html = await send('GET');

    expect(html, contains('Editar lista na TV'));
    expect(html, contains('value="Lista &quot;A&quot;"'));
    expect(html, contains('value="http://old.example.com:8080"'));
    expect(html, contains('value="user"'));
    expect(html, isNot(contains('segredo')));
  });

  test('blank password on edit keeps the current one', () async {
    final submission = server.submissions.first;
    await send('POST', body: 'type=m3u&name=Nova&host=https%3A%2F%2Fnew.example.com&user=user2&pass=');

    final received = await submission;
    expect(received.isXtream, isTrue);
    expect(received.name, 'Nova');
    expect(received.xtreamHost, 'https://new.example.com');
    expect(received.xtreamUsername, 'user2');
    expect(received.xtreamPassword, 'segredo');
  });
}
