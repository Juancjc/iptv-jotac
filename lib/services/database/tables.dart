import 'package:drift/drift.dart';

// Row classes are suffixed with `Row` (via @DataClassName) so they don't
// collide with the plain domain models in lib/models/, which repositories
// map these rows into.

@DataClassName('PlaylistRow')
class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'm3u' or 'xtream'
  TextColumn get m3uUrl => text().nullable()();
  TextColumn get xtreamHost => text().nullable()();
  TextColumn get xtreamUsername => text().nullable()();
  TextColumn get xtreamPassword => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ChannelRow')
class Channels extends Table {
  TextColumn get id => text()();
  TextColumn get playlistId => text()();
  TextColumn get name => text()();
  TextColumn get logoUrl => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get streamUrl => text()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MovieRow')
class Movies extends Table {
  TextColumn get id => text()();
  TextColumn get playlistId => text()();
  TextColumn get title => text()();
  TextColumn get posterUrl => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get streamUrl => text()();
  TextColumn get extension => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SeriesRow')
class SeriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get playlistId => text()();
  TextColumn get title => text()();
  TextColumn get posterUrl => text().nullable()();
  TextColumn get category => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EpisodeRow')
class Episodes extends Table {
  TextColumn get id => text()();
  TextColumn get seriesId => text()();
  IntColumn get seasonNumber => integer()();
  IntColumn get episodeNumber => integer()();
  TextColumn get title => text()();
  TextColumn get streamUrl => text()();
  TextColumn get extension => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DownloadRow')
class Downloads extends Table {
  TextColumn get id => text()();
  TextColumn get sourceUrl => text()();
  TextColumn get title => text()();
  TextColumn get contentType => text()(); // 'movie' or 'episode'
  TextColumn get localPath => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('queued'))();
  RealColumn get progress => real().withDefault(const Constant(0))();
  IntColumn get totalBytes => integer().nullable()();
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();
  DateTimeColumn get addedAt => dateTime()();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WatchHistoryRow')
class WatchHistoryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get contentId => text()();
  TextColumn get contentType => text()(); // 'channel', 'movie' or 'episode'
  TextColumn get title => text()();
  TextColumn get streamUrl => text()();
  TextColumn get posterUrl => text().nullable()();
  IntColumn get positionSeconds => integer().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().nullable()();
  DateTimeColumn get lastWatchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
