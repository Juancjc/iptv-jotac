import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_jotac/services/database/app_database.dart';
import 'package:iptv_jotac/services/playlist_repository.dart';

void main() {
  late AppDatabase database;
  late PlaylistRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = PlaylistRepository(database);
  });

  tearDown(() => database.close());

  test(
    'removePlaylist deletes its content without affecting another list',
    () async {
      final now = DateTime(2026, 10, 9);
      await database.batch((batch) {
        batch.insertAll(database.playlists, [
          PlaylistsCompanion.insert(
            id: 'playlist-a',
            name: 'Lista A',
            type: 'm3u',
            m3uUrl: const Value('https://example.com/a.m3u'),
            createdAt: now,
          ),
          PlaylistsCompanion.insert(
            id: 'playlist-b',
            name: 'Lista B',
            type: 'm3u',
            m3uUrl: const Value('https://example.com/b.m3u'),
            createdAt: now,
          ),
        ]);
        batch.insertAll(database.channels, [
          ChannelsCompanion.insert(
            id: 'channel-a',
            playlistId: 'playlist-a',
            name: 'Canal A',
            streamUrl: 'https://example.com/a.ts',
          ),
          ChannelsCompanion.insert(
            id: 'channel-b',
            playlistId: 'playlist-b',
            name: 'Canal B',
            streamUrl: 'https://example.com/b.ts',
          ),
        ]);
        batch.insertAll(database.movies, [
          MoviesCompanion.insert(
            id: 'movie-a',
            playlistId: 'playlist-a',
            title: 'Filme A',
            streamUrl: 'https://example.com/a.mp4',
          ),
          MoviesCompanion.insert(
            id: 'movie-b',
            playlistId: 'playlist-b',
            title: 'Filme B',
            streamUrl: 'https://example.com/b.mp4',
          ),
        ]);
        batch.insertAll(database.seriesTable, [
          SeriesTableCompanion.insert(
            id: 'series-a',
            playlistId: 'playlist-a',
            title: 'Serie A',
          ),
          SeriesTableCompanion.insert(
            id: 'series-b',
            playlistId: 'playlist-b',
            title: 'Serie B',
          ),
        ]);
        batch.insertAll(database.episodes, [
          EpisodesCompanion.insert(
            id: 'episode-a',
            seriesId: 'series-a',
            seasonNumber: 1,
            episodeNumber: 1,
            title: 'Episodio A',
            streamUrl: 'https://example.com/a.mp4',
          ),
          EpisodesCompanion.insert(
            id: 'episode-b',
            seriesId: 'series-b',
            seasonNumber: 1,
            episodeNumber: 1,
            title: 'Episodio B',
            streamUrl: 'https://example.com/b.mp4',
          ),
        ]);
      });

      await repository.removePlaylist('playlist-a');

      expect(await database.select(database.playlists).get(), hasLength(1));
      expect(
        (await database.select(database.playlists).get()).single.id,
        'playlist-b',
      );
      expect(
        (await database.select(database.channels).get()).single.id,
        'channel-b',
      );
      expect(
        (await database.select(database.movies).get()).single.id,
        'movie-b',
      );
      expect(
        (await database.select(database.seriesTable).get()).single.id,
        'series-b',
      );
      expect(
        (await database.select(database.episodes).get()).single.id,
        'episode-b',
      );
    },
  );
}
