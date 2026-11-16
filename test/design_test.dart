import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_jotac/models/movie.dart';
import 'package:iptv_jotac/models/watch_history_entry.dart';
import 'package:iptv_jotac/providers/playlist_providers.dart';
import 'package:iptv_jotac/providers/watch_history_providers.dart';
import 'package:iptv_jotac/screens/home_dashboard_screen.dart';
import 'package:iptv_jotac/widgets/catalog_toolbar.dart';

void main() {
  setUpAll(() async {
    if (Platform.environment['JOTAC_CAPTURE'] == '1') {
      final font = FontLoader('Roboto')
        ..addFont(
          File(
            'C:/Windows/Fonts/segoeui.ttf',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await font.load();
      await icons.load();
    }
  });
  for (final size in [
    const Size(1280, 720),
    const Size(960, 540),
    const Size(390, 844),
  ]) {
    testWidgets('Dashboard fits $size and opens library sections', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      int? selected;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allChannelsProvider.overrideWith((ref) => Stream.value([])),
            allMoviesProvider.overrideWith((ref) => Stream.value([])),
            allSeriesProvider.overrideWith((ref) => Stream.value([])),
            watchHistoryProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: HomeDashboardScreen(
                onSectionSelected: (index) => selected = index,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Conectar lista'));
      expect(selected, 7);
      await tester.ensureVisible(find.byKey(const ValueKey('movies-card')));
      await tester.tap(find.byKey(const ValueKey('movies-card')));
      expect(selected, 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Home shows library and only unfinished history', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allChannelsProvider.overrideWith((ref) => Stream.value([])),
          allMoviesProvider.overrideWith(
            (ref) => Stream.value([
              const Movie(
                id: '1',
                playlistId: 'p',
                title: 'Uma noite de cinema',
                category: 'Aventura',
                streamUrl: 'https://example.com/film',
              ),
            ]),
          ),
          allSeriesProvider.overrideWith((ref) => Stream.value([])),
          watchHistoryProvider.overrideWith(
            (ref) => Stream.value([
              for (final complete in [false, true])
                WatchHistoryEntry(
                  id: '$complete',
                  contentId: '$complete',
                  contentType: WatchableType.movie,
                  title: complete
                      ? 'Filme concluído'
                      : 'Sua próxima aventura',
                  streamUrl: 'https://example.com/film',
                  positionSeconds: complete ? 990 : 300,
                  durationSeconds: 1000,
                  lastWatchedAt: DateTime(2026),
                ),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF100E12),
            colorScheme:
                ColorScheme.fromSeed(
                  seedColor: const Color(0xFFB71C1C),
                  brightness: Brightness.dark,
                ).copyWith(
                  primary: const Color(0xFFE04848),
                  surface: const Color(0xFF121014),
                  surfaceContainer: const Color(0xFF29262C),
                  surfaceContainerHigh: const Color(0xFF332E34),
                ),
          ),
          home: RepaintBoundary(
            key: boundary,
            child: Scaffold(
              body: HomeDashboardScreen(onSectionSelected: (_) {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Continue assistindo'), findsOneWidget);
    expect(find.text('Sua próxima aventura'), findsOneWidget);
    expect(find.text('Filme concluído'), findsNothing);
    expect(find.text('Assistir agora'), findsOneWidget);
    expect(tester.takeException(), isNull);
    if (Platform.environment['JOTAC_CAPTURE'] == '1') {
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/design').create(recursive: true);
        await File(
          'build/design/home-preview.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });

  testWidgets('Catalog search and category remain usable on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? query;
    String? category;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CatalogToolbar(
            showingMovies: true,
            movieCount: 12,
            seriesCount: 4,
            onShowMovies: () {},
            onShowSeries: () {},
            onSearchChanged: (value) => query = value,
            categories: const ['Aventura'],
            selectedCategory: null,
            onCategorySelected: (value) => category = value,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Cinema');
    expect(query, 'Cinema');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aventura').last);
    await tester.pumpAndSettle();
    expect(category, 'Aventura');
    expect(tester.takeException(), isNull);
  });
}
