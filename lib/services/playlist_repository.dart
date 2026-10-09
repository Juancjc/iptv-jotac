import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../models/channel.dart';
import '../models/movie.dart';
import '../models/playlist.dart';
import '../models/series.dart' as domain;
import 'database/app_database.dart';
import 'm3u_parser.dart';
import 'xtream_api_client.dart';

const _uuid = Uuid();

/// Video file extensions that indicate on-demand (downloadable) content, as
/// opposed to a live stream.
const _vodExtensions = {'mp4', 'mkv', 'avi', 'm4v', 'mov', 'wmv'};

/// Matches common "S01E02" / "1x02" style season/episode markers in a title.
final _seasonEpisodeRegExp = RegExp(
  r'(?:S(\d{1,2})\s*E(\d{1,3}))|(?:(\d{1,2})x(\d{1,3}))',
  caseSensitive: false,
);

/// Owns all persistence and remote-sync logic for playlists and their
/// content (channels, movies, series/episodes). Screens and providers talk
/// to this class rather than touching the database or network clients
/// directly.
class PlaylistRepository {
  final AppDatabase _db;
  final Dio _dio;

  PlaylistRepository(this._db, {Dio? dio}) : _dio = dio ?? Dio();

  // ---------------------------------------------------------------------
  // Playlists
  // ---------------------------------------------------------------------

  Stream<List<Playlist>> watchPlaylists() {
    return _db.select(_db.playlists).watch().map(
          (rows) => rows.map(_playlistFromRow).toList(),
        );
  }

  Future<Playlist> addM3uPlaylist({required String name, required String url}) async {
    final row = PlaylistsCompanion.insert(
      id: _uuid.v4(),
      name: name,
      type: 'm3u',
      m3uUrl: Value(url),
      createdAt: DateTime.now(),
    );
    await _db.into(_db.playlists).insert(row);
    final inserted = await (_db.select(_db.playlists)..where((t) => t.id.equals(row.id.value))).getSingle();
    return _playlistFromRow(inserted);
  }

  Future<Playlist> addXtreamPlaylist({
    required String name,
    required String host,
    required String username,
    required String password,
  }) async {
    final row = PlaylistsCompanion.insert(
      id: _uuid.v4(),
      name: name,
      type: 'xtream',
      xtreamHost: Value(host),
      xtreamUsername: Value(username),
      xtreamPassword: Value(password),
      createdAt: DateTime.now(),
    );
    await _db.into(_db.playlists).insert(row);
    final inserted = await (_db.select(_db.playlists)..where((t) => t.id.equals(row.id.value))).getSingle();
    return _playlistFromRow(inserted);
  }

  Future<void> removePlaylist(String playlistId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.channels)..where((t) => t.playlistId.equals(playlistId))).go();
      await (_db.delete(_db.movies)..where((t) => t.playlistId.equals(playlistId))).go();
      await _deleteSeriesContentForPlaylist(playlistId);
      await (_db.delete(_db.playlists)..where((t) => t.id.equals(playlistId))).go();
    });
  }

  /// Deletes every episode for a playlist with one SQL statement. Large M3U
  /// lists can contain hundreds of thousands of episodes, so deleting once per
  /// series makes the UI appear frozen for several minutes.
  Future<void> _deleteSeriesContentForPlaylist(String playlistId) async {
    await _db.customStatement(
      'DELETE FROM episodes '
      'WHERE series_id IN ('
      'SELECT id FROM series_table WHERE playlist_id = ?'
      ')',
      [playlistId],
    );
    await (_db.delete(_db.seriesTable)..where((t) => t.playlistId.equals(playlistId))).go();
  }

  XtreamApiClient _clientFor(Playlist playlist) {
    return XtreamApiClient(
      host: playlist.xtreamHost!,
      username: playlist.xtreamUsername!,
      password: playlist.xtreamPassword!,
      dio: _dio,
    );
  }

  /// Fetches fresh content for [playlist] from its remote source and
  /// replaces the locally cached channels/movies/series.
  Future<void> syncPlaylist(Playlist playlist) async {
    if (playlist.type == PlaylistType.m3u) {
      await _syncM3uPlaylist(playlist);
    } else {
      await _syncXtreamPlaylist(playlist);
    }
    await (_db.update(_db.playlists)..where((t) => t.id.equals(playlist.id))).write(
      PlaylistsCompanion(lastSyncedAt: Value(DateTime.now())),
    );
  }

  Future<void> _syncM3uPlaylist(Playlist playlist) async {
    final response = await _dio.get<String>(
      playlist.m3uUrl!,
      options: Options(responseType: ResponseType.plain),
    );
    final entries = M3UParser().parse(response.data ?? '');

    final channelRows = <ChannelsCompanion>[];
    final movieRows = <MoviesCompanion>[];
    // seriesTitle -> seriesId, used to group episodes under one series row.
    final seriesIdByTitle = <String, String>{};
    final seriesRows = <SeriesTableCompanion>[];
    final episodeRows = <EpisodesCompanion>[];

    for (final entry in entries) {
      final classification = _classifyM3uEntry(entry);
      switch (classification.kind) {
        case _M3uKind.channel:
          channelRows.add(ChannelsCompanion.insert(
            id: _uuid.v4(),
            playlistId: playlist.id,
            name: entry.name,
            logoUrl: Value(entry.logoUrl),
            category: Value(entry.groupTitle),
            streamUrl: entry.url,
          ));
        case _M3uKind.movie:
          movieRows.add(MoviesCompanion.insert(
            id: _uuid.v4(),
            playlistId: playlist.id,
            title: entry.name,
            posterUrl: Value(entry.logoUrl),
            category: Value(entry.groupTitle),
            streamUrl: entry.url,
            extension: Value(classification.extension),
          ));
        case _M3uKind.episode:
          final seriesTitle = classification.seriesTitle!;
          final seriesId = seriesIdByTitle.putIfAbsent(seriesTitle, () {
            final id = _uuid.v4();
            seriesRows.add(SeriesTableCompanion.insert(
              id: id,
              playlistId: playlist.id,
              title: seriesTitle,
              posterUrl: Value(entry.logoUrl),
              category: Value(entry.groupTitle),
            ));
            return id;
          });
          episodeRows.add(EpisodesCompanion.insert(
            id: _uuid.v4(),
            seriesId: seriesId,
            seasonNumber: classification.season!,
            episodeNumber: classification.episode!,
            title: entry.name,
            streamUrl: entry.url,
            extension: Value(classification.extension),
          ));
      }
    }

    await _db.transaction(() async {
      await (_db.delete(_db.channels)..where((t) => t.playlistId.equals(playlist.id))).go();
      await (_db.delete(_db.movies)..where((t) => t.playlistId.equals(playlist.id))).go();
      await _deleteSeriesContentForPlaylist(playlist.id);

      await _db.batch((batch) {
        batch.insertAll(_db.channels, channelRows);
        batch.insertAll(_db.movies, movieRows);
        batch.insertAll(_db.seriesTable, seriesRows);
        batch.insertAll(_db.episodes, episodeRows);
      });
    });
  }

  Future<void> _syncXtreamPlaylist(Playlist playlist) async {
    final client = _clientFor(playlist);
    await client.authenticate();

    final liveStreams = await client.getLiveStreams();
    final vodStreams = await client.getVodStreams();
    final seriesList = await client.getSeries();

    final channelRows = liveStreams
        .map((s) => ChannelsCompanion.insert(
              id: _uuid.v4(),
              playlistId: playlist.id,
              name: s.name,
              logoUrl: Value(s.streamIcon),
              category: Value(s.categoryId),
              streamUrl: client.liveStreamUrl(s.streamId),
            ))
        .toList();

    final movieRows = vodStreams
        .map((s) => MoviesCompanion.insert(
              id: _uuid.v4(),
              playlistId: playlist.id,
              title: s.name,
              posterUrl: Value(s.streamIcon),
              category: Value(s.categoryId),
              streamUrl: client.vodStreamUrl(s.streamId, extension: s.containerExtension ?? 'mp4'),
              extension: Value(s.containerExtension),
            ))
        .toList();

    // Xtream panels can list the same series under multiple categories,
    // repeating its series_id. Since that id is the table's primary key,
    // dedupe before inserting or the batch insert violates the UNIQUE
    // constraint.
    final uniqueSeries = <String, XtreamSeries>{};
    for (final s in seriesList) {
      uniqueSeries[s.seriesId] = s;
    }

    final seriesRows = uniqueSeries.values
        .map((s) => SeriesTableCompanion.insert(
              id: s.seriesId,
              playlistId: playlist.id,
              title: s.name,
              posterUrl: Value(s.cover),
              category: Value(s.categoryId),
            ))
        .toList();

    await _db.transaction(() async {
      await (_db.delete(_db.channels)..where((t) => t.playlistId.equals(playlist.id))).go();
      await (_db.delete(_db.movies)..where((t) => t.playlistId.equals(playlist.id))).go();
      await _deleteSeriesContentForPlaylist(playlist.id);

      await _db.batch((batch) {
        batch.insertAll(_db.channels, channelRows);
        batch.insertAll(_db.movies, movieRows);
        batch.insertAll(_db.seriesTable, seriesRows);
      });
    });
  }

  /// Fetches (and caches) the episode list for a series whose playlist is
  /// an Xtream source. For M3U-sourced series, episodes are already fully
  /// populated during sync, so this is a no-op.
  Future<List<domain.Episode>> ensureEpisodesLoaded(domain.Series series) async {
    final cached = await (_db.select(_db.episodes)..where((t) => t.seriesId.equals(series.id))).get();
    if (cached.isNotEmpty) {
      return cached.map(_episodeFromRow).toList();
    }

    final playlistRow = await (_db.select(_db.playlists)..where((t) => t.id.equals(series.playlistId))).getSingle();
    final playlist = _playlistFromRow(playlistRow);
    if (playlist.type != PlaylistType.xtream) return const [];

    final client = _clientFor(playlist);
    final remoteEpisodes = await client.getSeriesEpisodes(series.id);
    final rows = remoteEpisodes
        .map((e) => EpisodesCompanion.insert(
              id: e.id,
              seriesId: series.id,
              seasonNumber: e.season,
              episodeNumber: e.episodeNumber,
              title: e.title,
              streamUrl: client.seriesEpisodeUrl(e.id, extension: e.containerExtension ?? 'mp4'),
              extension: Value(e.containerExtension),
            ))
        .toList();
    await _db.batch((batch) => batch.insertAll(_db.episodes, rows));
    return rows
        .map((c) => domain.Episode(
              id: c.id.value,
              seriesId: c.seriesId.value,
              seasonNumber: c.seasonNumber.value,
              episodeNumber: c.episodeNumber.value,
              title: c.title.value,
              streamUrl: c.streamUrl.value,
              extension: c.extension.present ? c.extension.value : null,
            ))
        .toList();
  }

  // ---------------------------------------------------------------------
  // Content queries
  // ---------------------------------------------------------------------

  Stream<List<Channel>> watchChannels({String? playlistId, String? searchQuery}) {
    final query = _db.select(_db.channels);
    if (playlistId != null) {
      query.where((t) => t.playlistId.equals(playlistId));
    }
    return query.watch().map((rows) => rows
        .map(_channelFromRow)
        .where((c) => searchQuery == null || searchQuery.isEmpty || c.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList());
  }

  Stream<List<Movie>> watchMovies({String? playlistId, String? searchQuery}) {
    final query = _db.select(_db.movies);
    if (playlistId != null) {
      query.where((t) => t.playlistId.equals(playlistId));
    }
    return query.watch().map((rows) => rows
        .map(_movieFromRow)
        .where((m) => searchQuery == null || searchQuery.isEmpty || m.title.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList());
  }

  Stream<List<domain.Series>> watchSeries({String? playlistId, String? searchQuery}) {
    final query = _db.select(_db.seriesTable);
    if (playlistId != null) {
      query.where((t) => t.playlistId.equals(playlistId));
    }
    return query.watch().map((rows) => rows
        .map(_seriesFromRow)
        .where((s) => searchQuery == null || searchQuery.isEmpty || s.title.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList());
  }

  Future<void> toggleChannelFavorite(String id, bool isFavorite) async {
    await (_db.update(_db.channels)..where((t) => t.id.equals(id))).write(ChannelsCompanion(isFavorite: Value(isFavorite)));
  }

  Future<void> toggleMovieFavorite(String id, bool isFavorite) async {
    await (_db.update(_db.movies)..where((t) => t.id.equals(id))).write(MoviesCompanion(isFavorite: Value(isFavorite)));
  }

  Future<void> toggleSeriesFavorite(String id, bool isFavorite) async {
    await (_db.update(_db.seriesTable)..where((t) => t.id.equals(id))).write(SeriesTableCompanion(isFavorite: Value(isFavorite)));
  }

  // ---------------------------------------------------------------------
  // Mapping helpers
  // ---------------------------------------------------------------------

  Playlist _playlistFromRow(PlaylistRow row) {
    return Playlist(
      id: row.id,
      name: row.name,
      type: row.type == 'xtream' ? PlaylistType.xtream : PlaylistType.m3u,
      m3uUrl: row.m3uUrl,
      xtreamHost: row.xtreamHost,
      xtreamUsername: row.xtreamUsername,
      xtreamPassword: row.xtreamPassword,
      createdAt: row.createdAt,
      lastSyncedAt: row.lastSyncedAt,
    );
  }

  Channel _channelFromRow(ChannelRow row) {
    return Channel(
      id: row.id,
      playlistId: row.playlistId,
      name: row.name,
      logoUrl: row.logoUrl,
      category: row.category,
      streamUrl: row.streamUrl,
      isFavorite: row.isFavorite,
    );
  }

  Movie _movieFromRow(MovieRow row) {
    return Movie(
      id: row.id,
      playlistId: row.playlistId,
      title: row.title,
      posterUrl: row.posterUrl,
      category: row.category,
      streamUrl: row.streamUrl,
      extension: row.extension,
      isFavorite: row.isFavorite,
    );
  }

  domain.Series _seriesFromRow(SeriesRow row) {
    return domain.Series(
      id: row.id,
      playlistId: row.playlistId,
      title: row.title,
      posterUrl: row.posterUrl,
      category: row.category,
      isFavorite: row.isFavorite,
    );
  }

  domain.Episode _episodeFromRow(EpisodeRow row) {
    return domain.Episode(
      id: row.id,
      seriesId: row.seriesId,
      seasonNumber: row.seasonNumber,
      episodeNumber: row.episodeNumber,
      title: row.title,
      streamUrl: row.streamUrl,
      extension: row.extension,
    );
  }

  _M3uClassification _classifyM3uEntry(M3UEntry entry) {
    final extensionMatch = RegExp(r'\.([a-zA-Z0-9]+)(?:\?.*)?$').firstMatch(entry.url);
    final extension = extensionMatch?.group(1)?.toLowerCase();
    final group = entry.groupTitle?.toLowerCase() ?? '';
    final looksLikeSeries = group.contains('serie') || group.contains('série') || _seasonEpisodeRegExp.hasMatch(entry.name);

    if (looksLikeSeries) {
      final match = _seasonEpisodeRegExp.firstMatch(entry.name);
      if (match != null) {
        final season = int.tryParse(match.group(1) ?? match.group(3) ?? '1') ?? 1;
        final episode = int.tryParse(match.group(2) ?? match.group(4) ?? '1') ?? 1;
        final seriesTitle = entry.name.substring(0, match.start).trim().replaceAll(RegExp(r'[-_]+$'), '').trim();
        return _M3uClassification.episode(
          seriesTitle: seriesTitle.isEmpty ? entry.name : seriesTitle,
          season: season,
          episode: episode,
          extension: extension,
        );
      }
    }

    final isVodExtension = extension != null && _vodExtensions.contains(extension);
    if (isVodExtension || group.contains('filme') || group.contains('movie') || group.contains('vod')) {
      return _M3uClassification.movie(extension: extension);
    }

    return const _M3uClassification.channel();
  }
}

enum _M3uKind { channel, movie, episode }

class _M3uClassification {
  final _M3uKind kind;
  final String? extension;
  final String? seriesTitle;
  final int? season;
  final int? episode;

  const _M3uClassification.channel()
      : kind = _M3uKind.channel,
        extension = null,
        seriesTitle = null,
        season = null,
        episode = null;

  const _M3uClassification.movie({this.extension})
      : kind = _M3uKind.movie,
        seriesTitle = null,
        season = null,
        episode = null;

  const _M3uClassification.episode({
    required this.seriesTitle,
    required this.season,
    required this.episode,
    this.extension,
  }) : kind = _M3uKind.episode;
}
