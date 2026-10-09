import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/database/app_database.dart';
import '../services/playlist_repository.dart';
import '../services/watch_history_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepository(ref.watch(appDatabaseProvider));
});

final watchHistoryRepositoryProvider = Provider<WatchHistoryRepository>((ref) {
  return WatchHistoryRepository(ref.watch(appDatabaseProvider));
});
