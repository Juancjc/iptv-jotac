import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../models/watch_history_entry.dart';
import 'database/app_database.dart';

const _uuid = Uuid();

/// Persists "continue watching" entries.
class WatchHistoryRepository {
  final AppDatabase _db;

  WatchHistoryRepository(this._db);

  Stream<List<WatchHistoryEntry>> watchHistory() {
    final query = _db.select(_db.watchHistoryEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.lastWatchedAt)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  Future<void> upsertProgress({
    required String contentId,
    required WatchableType contentType,
    required String title,
    required String streamUrl,
    String? posterUrl,
    required int positionSeconds,
    int? durationSeconds,
  }) async {
    final existing = await (_db.select(_db.watchHistoryEntries)..where((t) => t.contentId.equals(contentId))).getSingleOrNull();
    final id = existing?.id ?? _uuid.v4();
    await _db.into(_db.watchHistoryEntries).insertOnConflictUpdate(WatchHistoryEntriesCompanion(
          id: Value(id),
          contentId: Value(contentId),
          contentType: Value(contentType.name),
          title: Value(title),
          streamUrl: Value(streamUrl),
          posterUrl: Value(posterUrl),
          positionSeconds: Value(positionSeconds),
          durationSeconds: Value(durationSeconds),
          lastWatchedAt: Value(DateTime.now()),
        ));
  }

  Future<void> remove(String id) async {
    await (_db.delete(_db.watchHistoryEntries)..where((t) => t.id.equals(id))).go();
  }

  WatchHistoryEntry _fromRow(WatchHistoryRow row) {
    return WatchHistoryEntry(
      id: row.id,
      contentId: row.contentId,
      contentType: WatchableType.values.firstWhere(
        (e) => e.name == row.contentType,
        orElse: () => WatchableType.movie,
      ),
      title: row.title,
      streamUrl: row.streamUrl,
      posterUrl: row.posterUrl,
      positionSeconds: row.positionSeconds,
      durationSeconds: row.durationSeconds,
      lastWatchedAt: row.lastWatchedAt,
    );
  }
}
