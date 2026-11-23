import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/playlist_refresh_preferences.dart';
import 'database_provider.dart';
import 'playlist_providers.dart';

final playlistRefreshStoreProvider = Provider(
  (ref) => PlaylistRefreshPreferencesStore(),
);
final playlistRefreshPreferencesProvider =
    AsyncNotifierProvider<PlaylistRefreshNotifier, PlaylistRefreshPreferences>(
      PlaylistRefreshNotifier.new,
    );

class PlaylistRefreshNotifier
    extends AsyncNotifier<PlaylistRefreshPreferences> {
  @override
  Future<PlaylistRefreshPreferences> build() =>
      ref.watch(playlistRefreshStoreProvider).load();
  Future<void> save(PlaylistRefreshPreferences preferences) async {
    if (state.isLoading) return;
    final previous = state;
    state = const AsyncLoading();
    try {
      await ref.read(playlistRefreshStoreProvider).save(preferences);
      state = AsyncData(preferences);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final playlistRefreshClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final playlistRefreshSchedulerProvider = Provider.autoDispose<void>((ref) {
  final preferences = ref.watch(playlistRefreshPreferencesProvider).valueOrNull;
  if (preferences == null || !preferences.scheduled) return;
  final now = ref.read(playlistRefreshClockProvider);
  final schedule = PlaylistRefreshSchedule(now());
  var disposed = false;
  var running = false;
  final timer = Timer.periodic(const Duration(seconds: 15), (_) async {
    final due = schedule.due(now(), preferences);
    if (!due || running || ref.read(syncingPlaylistIdsProvider).isNotEmpty) {
      return;
    }
    running = true;
    try {
      final playlists = await ref
          .read(playlistRepositoryProvider)
          .watchPlaylists()
          .first;
      for (final playlist in playlists) {
        if (disposed) break;
        try {
          await ref.read(playlistSyncControllerProvider).sync(playlist);
        } catch (_) {
          /* The controller exposes errors on the playlists screen. */
        }
      }
    } catch (_) {
      /* Retry at the next scheduled time, never in a tight loop. */
    } finally {
      running = false;
    }
  });
  ref.onDispose(() {
    disposed = true;
    timer.cancel();
  });
});
