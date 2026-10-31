import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_jotac/providers/remote_control_providers.dart';
import 'package:iptv_jotac/screens/settings_screen.dart';
import 'package:iptv_jotac/widgets/remote_control_dialog.dart';
import 'package:iptv_jotac/services/remote_control_preferences.dart';
import 'package:iptv_jotac/services/remote_control_server.dart';

class _NoopHandler implements RemoteControlHandler {
  @override
  Future<List<RemoteItem>> playlists() async => const [];
  @override
  Future<List<RemoteCategory>> categories(RemoteContentType type, String? playlistId) async => const [];
  @override
  Future<(List<RemoteItem>, int)> items(
    RemoteContentType type, {
    String? playlistId,
    String? category,
    String? query,
    int offset = 0,
    int limit = 100,
  }) async => (const <RemoteItem>[], 0);
  @override
  Future<List<RemoteEpisode>> episodes(String seriesId) async => const [];
  @override
  Future<void> play(RemoteContentType? type, String id) async {}
  @override
  Future<void> pressKey(RemoteKey key) async {}
}

void main() {
  late Directory dir;
  late RemoteControlPreferencesService service;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('remote_prefs');
    service = RemoteControlPreferencesService(supportDirectory: () async => dir);
  });

  tearDown(() => dir.delete(recursive: true));

  String? codeOf(RemoteControlNotifier n) => n.state.url?.queryParameters['k'];

  test('defaults: off at startup, fixed address on', () async {
    final notifier = RemoteControlNotifier(_NoopHandler(), service);
    await notifier.initialize();
    expect(notifier.state.active, isFalse);
    expect(notifier.state.preferences.keepAddress, isTrue);
    notifier.dispose();
  });

  test('"ligar sempre" starts it on launch, reusing the same address', () async {
    final first = RemoteControlNotifier(_NoopHandler(), service);
    await first.initialize();
    await first.setAutoStart(true);
    await first.enable();
    final code = codeOf(first);
    expect(code, isNotNull);
    await first.disable();
    first.dispose();

    // Next app launch: turns on by itself with the same code.
    final second = RemoteControlNotifier(_NoopHandler(), service);
    await second.initialize();
    expect(second.state.active, isTrue);
    expect(codeOf(second), code);

    // A new code invalidates the old link and is kept from now on.
    await second.regenerateAccessCode();
    final newCode = codeOf(second);
    expect(second.state.active, isTrue);
    expect(newCode, isNot(code));
    expect((await service.load()).accessCode, newCode);
    await second.disable();
    second.dispose();
  });

  testWidgets('dialog and settings render the options', (tester) async {
    final container = ProviderContainer(
      overrides: [remoteControlPreferencesServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );
    expect(find.text('Ligar sempre ao abrir o app'), findsOneWidget);
    expect(find.text('Manter o mesmo endereco'), findsOneWidget);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(context: context, builder: (_) => const RemoteControlDialog()),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Ligar sempre ao abrir o app'), findsOneWidget);
    expect(find.text('Ativar'), findsOneWidget);
  });

  test('without a fixed address every activation gets a new code', () async {
    final notifier = RemoteControlNotifier(_NoopHandler(), service);
    await notifier.initialize();
    await notifier.setKeepAddress(false);
    await notifier.enable();
    final a = codeOf(notifier);
    await notifier.disable();
    await notifier.enable();
    final b = codeOf(notifier);
    expect(a, isNot(b));
    expect((await service.load()).accessCode, isNull);
    await notifier.disable();
    notifier.dispose();
  });
}
