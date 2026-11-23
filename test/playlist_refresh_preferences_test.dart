import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_jotac/services/playlist_refresh_preferences.dart';

void main() {
  test(
    'preferences survive restarting storage; invalid times are filtered',
    () async {
      final dir = await Directory.systemTemp.createTemp('jotac-refresh-test');
      addTearDown(() => dir.delete(recursive: true));
      final store = PlaylistRefreshPreferencesStore(directory: () async => dir);
      expect((await store.load()).onStartup, isFalse);
      expect((await store.load()).scheduled, isFalse);
      await store.save(
        const PlaylistRefreshPreferences(
          onStartup: true,
          scheduled: true,
          minutes: [60, 720],
        ),
      );
      final restored = await PlaylistRefreshPreferencesStore(
        directory: () async => dir,
      ).load();
      expect(restored.onStartup, isTrue);
      expect(restored.scheduled, isTrue);
      expect(restored.minutes, [60, 720]);
      expect(
        PlaylistRefreshPreferences.fromJson({
          'minutes': [-1, 30, 30, 1440, 'no'],
        }).minutes,
        [30],
      );
    },
  );

  test('schedules run once per slot and do not catch up on opening', () {
    const prefs = PlaylistRefreshPreferences(
      scheduled: true,
      minutes: [180, 720],
    );
    final schedule = PlaylistRefreshSchedule(DateTime(2026, 11, 23, 2, 59));
    expect(schedule.due(DateTime(2026, 11, 23, 3), prefs), isTrue);
    expect(schedule.due(DateTime(2026, 11, 23, 3, 0, 15), prefs), isFalse);
    expect(schedule.due(DateTime(2026, 11, 23, 12), prefs), isTrue);
    expect(schedule.due(DateTime(2026, 11, 24, 3), prefs), isTrue);
    final lateStart = PlaylistRefreshSchedule(DateTime(2026, 11, 23, 4));
    expect(lateStart.due(DateTime(2026, 11, 23, 4, 1), prefs), isFalse);
    expect(
      lateStart.due(
        DateTime(2026, 11, 23, 12),
        const PlaylistRefreshPreferences(),
      ),
      isFalse,
    );
  });

  test('resume coalesces missed slots and midnight is handled', () {
    final schedule = PlaylistRefreshSchedule(DateTime(2026, 11, 23, 23, 59));
    const prefs = PlaylistRefreshPreferences(
      scheduled: true,
      minutes: [0, 60, 120],
    );
    expect(schedule.due(DateTime(2026, 11, 24, 0), prefs), isTrue);
    expect(schedule.due(DateTime(2026, 11, 24, 3), prefs), isTrue);
    expect(schedule.due(DateTime(2026, 11, 24, 3, 1), prefs), isFalse);
  });
}
