import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/channel.dart';
import '../models/movie.dart';
import '../models/playlist.dart';
import '../models/series.dart' as domain;
import 'database_provider.dart';

final playlistsProvider = StreamProvider<List<Playlist>>((ref) {
  return ref.watch(playlistRepositoryProvider).watchPlaylists();
});

/// `null` means "all playlists" everywhere this is consumed.
final selectedPlaylistIdProvider = StateProvider<String?>((ref) => null);

final searchQueryProvider = StateProvider<String>((ref) => '');

/// Unfiltered content streams used by the dashboard counters and by screens
/// that implement their own local search/category filters.
final allChannelsProvider = StreamProvider<List<Channel>>((ref) {
  final repo = ref.watch(playlistRepositoryProvider);
  final playlistId = ref.watch(selectedPlaylistIdProvider);
  return repo.watchChannels(playlistId: playlistId);
});

final allMoviesProvider = StreamProvider<List<Movie>>((ref) {
  final repo = ref.watch(playlistRepositoryProvider);
  final playlistId = ref.watch(selectedPlaylistIdProvider);
  return repo.watchMovies(playlistId: playlistId);
});

final allSeriesProvider = StreamProvider<List<domain.Series>>((ref) {
  final repo = ref.watch(playlistRepositoryProvider);
  final playlistId = ref.watch(selectedPlaylistIdProvider);
  return repo.watchSeries(playlistId: playlistId);
});

final channelsProvider = StreamProvider<List<Channel>>((ref) {
  final repo = ref.watch(playlistRepositoryProvider);
  final playlistId = ref.watch(selectedPlaylistIdProvider);
  final query = ref.watch(searchQueryProvider);
  return repo.watchChannels(playlistId: playlistId, searchQuery: query);
});

final moviesProvider = StreamProvider<List<Movie>>((ref) {
  final repo = ref.watch(playlistRepositoryProvider);
  final playlistId = ref.watch(selectedPlaylistIdProvider);
  final query = ref.watch(searchQueryProvider);
  return repo.watchMovies(playlistId: playlistId, searchQuery: query);
});

final seriesProvider = StreamProvider<List<domain.Series>>((ref) {
  final repo = ref.watch(playlistRepositoryProvider);
  final playlistId = ref.watch(selectedPlaylistIdProvider);
  final query = ref.watch(searchQueryProvider);
  return repo.watchSeries(playlistId: playlistId, searchQuery: query);
});

/// Tracks in-flight playlist sync operations so screens can show a spinner
/// per playlist card.
final syncingPlaylistIdsProvider = StateProvider<Set<String>>((ref) => {});

/// What an in-flight sync is doing right now, e.g. "Baixando lista... 12 MB".
class PlaylistSyncStatus {
  final String playlistName;
  final String message;

  /// Fraction between 0 and 1, or `null` when unknown.
  final double? progress;

  const PlaylistSyncStatus(this.playlistName, this.message, [this.progress]);
}

final playlistSyncStatusProvider = StateProvider<Map<String, PlaylistSyncStatus>>((ref) => {});

/// Last sync error per playlist id; cleared when the playlist syncs again.
final playlistSyncErrorsProvider = StateProvider<Map<String, String>>((ref) => {});

final playlistSyncControllerProvider = Provider<PlaylistSyncController>((ref) {
  return PlaylistSyncController(ref);
});

class PlaylistSyncController {
  /// Download progress fires many times per second; UI updates are limited
  /// to this interval so rebuilding doesn't slow the sync down.
  static const _progressInterval = Duration(milliseconds: 300);

  final Ref _ref;
  PlaylistSyncController(this._ref);

  Future<void> sync(Playlist playlist) async {
    final notifier = _ref.read(syncingPlaylistIdsProvider.notifier);
    notifier.state = {..._ref.read(syncingPlaylistIdsProvider), playlist.id};
    _setError(playlist.id, null);
    _setStatus(playlist.id, PlaylistSyncStatus(playlist.name, 'Atualizando...'));
    var lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
    try {
      await _ref.read(playlistRepositoryProvider).syncPlaylist(
        playlist,
        onProgress: (message, progress) {
          final now = DateTime.now();
          if (now.difference(lastUpdate) < _progressInterval) return;
          lastUpdate = now;
          _setStatus(playlist.id, PlaylistSyncStatus(playlist.name, message, progress));
        },
      );
    } catch (error) {
      _setError(playlist.id, error.toString());
      rethrow;
    } finally {
      _setStatus(playlist.id, null);
      final updated = {..._ref.read(syncingPlaylistIdsProvider)}
        ..remove(playlist.id);
      notifier.state = updated;
    }
  }

  void _setStatus(String playlistId, PlaylistSyncStatus? status) {
    final current = {..._ref.read(playlistSyncStatusProvider)};
    if (status == null) {
      current.remove(playlistId);
    } else {
      current[playlistId] = status;
    }
    _ref.read(playlistSyncStatusProvider.notifier).state = current;
  }

  void _setError(String playlistId, String? error) {
    final current = {..._ref.read(playlistSyncErrorsProvider)};
    if (error == null) {
      if (!current.containsKey(playlistId)) return;
      current.remove(playlistId);
    } else {
      current[playlistId] = error;
    }
    _ref.read(playlistSyncErrorsProvider.notifier).state = current;
  }
}
