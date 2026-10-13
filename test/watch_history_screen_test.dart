import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_jotac/models/watch_history_entry.dart';
import 'package:iptv_jotac/providers/watch_history_providers.dart';
import 'package:iptv_jotac/screens/watch_history_screen.dart';

void main() {
  testWidgets('shows all VOD history with the saved playback position', (tester) async {
    final entries = [
      WatchHistoryEntry(
        id: 'episode-history',
        contentId: 'episode-4',
        contentType: WatchableType.episode,
        title: 'Serie exemplo - S1E4',
        streamUrl: 'https://example.com/episode-4.mp4',
        positionSeconds: 2535,
        durationSeconds: 6000,
        lastWatchedAt: DateTime(2026, 10, 13),
      ),
      WatchHistoryEntry(
        id: 'channel-history',
        contentId: 'channel',
        contentType: WatchableType.channel,
        title: 'Canal ao vivo',
        streamUrl: 'https://example.com/live.ts',
        positionSeconds: 60,
        lastWatchedAt: DateTime(2026, 10, 12),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [watchHistoryProvider.overrideWith((ref) => Stream.value(entries))],
        child: const MaterialApp(home: Scaffold(body: WatchHistoryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ultimos assistidos'), findsOneWidget);
    expect(find.text('Serie exemplo - S1E4'), findsOneWidget);
    expect(find.text('Parou em 42:15 de 1:40:00'), findsOneWidget);
    expect(find.text('Canal ao vivo'), findsNothing);
  });
}
