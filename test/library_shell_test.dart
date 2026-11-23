import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_jotac/app.dart';
import 'package:iptv_jotac/providers/playlist_refresh_provider.dart';
import 'package:iptv_jotac/services/playlist_refresh_preferences.dart';
import 'package:iptv_jotac/models/playlist.dart';
import 'package:iptv_jotac/providers/database_provider.dart';
import 'package:iptv_jotac/providers/playlist_providers.dart';
import 'package:iptv_jotac/providers/watch_history_providers.dart';
import 'package:iptv_jotac/screens/settings_screen.dart';
import 'package:iptv_jotac/services/database/app_database.dart';
import 'package:iptv_jotac/services/playlist_repository.dart';

class _Repository extends PlaylistRepository {
  int syncs = 0;
  _Repository(super.db);
  @override
  Stream<List<Playlist>> watchPlaylists() => Stream.value([
    Playlist(
      id: 'saved',
      name: 'Lista salva',
      type: PlaylistType.m3u,
      m3uUrl: 'https://example.com/list.m3u',
      createdAt: DateTime(2026),
    ),
  ]);
  @override
  Future<void> syncPlaylist(
    Playlist playlist, {
    SyncProgressCallback? onProgress,
  }) async {
    syncs++;
  }
}

class _MemoryRefreshStore extends PlaylistRefreshPreferencesStore {
  PlaylistRefreshPreferences value;
  _MemoryRefreshStore([this.value = const PlaylistRefreshPreferences()]);
  @override
  Future<PlaylistRefreshPreferences> load() async => value;
  @override
  Future<void> save(PlaylistRefreshPreferences preferences) async {
    value = preferences;
  }
}

void main() {
  setUpAll(() async {
    if (Platform.environment['JOTAC_CAPTURE'] == '1') {
      await (FontLoader('Roboto')..addFont(
            File(
              'C:/Windows/Fonts/segoeui.ttf',
            ).readAsBytes().then(ByteData.sublistView),
          ))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  for (final startup in [false, true]) {
    testWidgets('Opening respects startup refresh: $startup', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = _Repository(db);
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playlistRefreshStoreProvider.overrideWithValue(
              _MemoryRefreshStore(
                PlaylistRefreshPreferences(onStartup: startup),
              ),
            ),
            playlistRepositoryProvider.overrideWithValue(repo),
            allChannelsProvider.overrideWith((ref) => Stream.value([])),
            allMoviesProvider.overrideWith((ref) => Stream.value([])),
            allSeriesProvider.overrideWith((ref) => Stream.value([])),
            watchHistoryProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const IptvJotacApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.syncs, startup ? 1 : 0);
      await tester.tap(find.byTooltip('Atualizar listas'));
      await tester.pumpAndSettle();
      expect(repo.syncs, startup ? 2 : 1);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Configurações'));
      await tester.pumpAndSettle();
      expect(find.text('Design e cores'), findsOneWidget);
      await tester.tap(find.text('Playlists'));
      await tester.pumpAndSettle();
      expect(find.text('Configurações • Playlists'), findsOneWidget);
      expect(find.text('Atualizar em horários definidos'), findsOneWidget);
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('Design e cores'), findsOneWidget);

      if (Platform.environment['JOTAC_CAPTURE'] == '1') {
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byType(RepaintBoundary).first,
          );
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/design').create(recursive: true);
          await File(
            'build/design/settings-shell.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('scheduler refreshes saved playlists once per configured time', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = _Repository(db);
    addTearDown(db.close);
    var now = DateTime(2026, 11, 23, 2, 59);
    final container = ProviderContainer(
      overrides: [
        playlistRepositoryProvider.overrideWithValue(repo),
        playlistRefreshClockProvider.overrideWithValue(() => now),
        playlistRefreshStoreProvider.overrideWithValue(
          _MemoryRefreshStore(
            const PlaylistRefreshPreferences(scheduled: true, minutes: [180]),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      playlistRefreshSchedulerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(playlistRefreshPreferencesProvider.future);
    container.read(playlistRefreshSchedulerProvider);
    await tester.pump();
    expect(repo.syncs, 0);
    now = DateTime(2026, 11, 23, 3);
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    expect(repo.syncs, 1);
    await tester.pump(const Duration(seconds: 30));
    expect(repo.syncs, 1);
    await container
        .read(playlistRefreshPreferencesProvider.notifier)
        .save(const PlaylistRefreshPreferences(scheduled: false));
    await tester.pump();
    now = DateTime(2026, 11, 24, 3);
    await tester.pump(const Duration(seconds: 30));
    expect(repo.syncs, 1);
  });

  for (final size in [
    const Size(1440, 900),
    const Size(960, 540),
    const Size(390, 844),
  ]) {
    testWidgets('Settings cards and dialogs fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playlistRefreshStoreProvider.overrideWithValue(
              _MemoryRefreshStore(),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: RepaintBoundary(
              key: boundary,
              child: const Scaffold(body: SettingsScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (size.width == 1440 && Platform.environment['JOTAC_CAPTURE'] == '1') {
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/design').create(recursive: true);
          await File(
            'build/design/settings.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.scrollUntilVisible(
        find.text('Atualizar ao iniciar o app'),
        250,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atualizar ao iniciar o app'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Design e cores'), -250);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Design e cores'));
      await tester.pumpAndSettle();
      expect(find.text('Seguir o sistema'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(
        ProviderScope.containerOf(
          tester.element(find.byType(SettingsScreen)),
        ).read(playlistRefreshPreferencesProvider).valueOrNull!.onStartup,
        isTrue,
      );
      await tester.scrollUntilVisible(find.text('Áudio e legendas'), 250);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Áudio e legendas'));
      await tester.pumpAndSettle();
      expect(find.text('Tamanho do texto'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
