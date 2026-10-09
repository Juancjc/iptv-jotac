import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/watch_history_entry.dart';
import 'database_provider.dart';

final watchHistoryProvider = StreamProvider<List<WatchHistoryEntry>>((ref) {
  return ref.watch(watchHistoryRepositoryProvider).watchHistory();
});
