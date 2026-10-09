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

final playlistSyncControllerProvider = Provider<PlaylistSyncController>((ref) {
  return PlaylistSyncController(ref);
});

class PlaylistSyncController {
  final Ref _ref;
  PlaylistSyncController(this._ref);

  Future<void> sync(Playlist playlist) async {
    final notifier = _ref.read(syncingPlaylistIdsProvider.notifier);
    notifier.state = {..._ref.read(syncingPlaylistIdsProvider), playlist.id};
    try {
      await _ref.read(playlistRepositoryProvider).syncPlaylist(playlist);
    } finally {
      final updated = {..._ref.read(syncingPlaylistIdsProvider)}
        ..remove(playlist.id);
      notifier.state = updated;
    }
  }
}
