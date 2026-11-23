import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PlaylistRefreshPreferences {
  final bool onStartup;
  final bool scheduled;
  final List<int> minutes;
  const PlaylistRefreshPreferences({
    this.onStartup = false,
    this.scheduled = false,
    this.minutes = const [180],
  });
  PlaylistRefreshPreferences copyWith({
    bool? onStartup,
    bool? scheduled,
    List<int>? minutes,
  }) => PlaylistRefreshPreferences(
    onStartup: onStartup ?? this.onStartup,
    scheduled: scheduled ?? this.scheduled,
    minutes: minutes ?? this.minutes,
  );
  Map<String, Object> toJson() => {
    'onStartup': onStartup,
    'scheduled': scheduled,
    'minutes': minutes,
  };
  factory PlaylistRefreshPreferences.fromJson(Map<String, dynamic> json) {
    final raw = json['minutes'];
    final minutes = raw is List
        ? raw.whereType<int>().where((m) => m >= 0 && m < 1440).toSet().toList()
        : <int>[180];
    minutes.sort();
    return PlaylistRefreshPreferences(
      onStartup: json['onStartup'] == true,
      scheduled: json['scheduled'] == true,
      minutes: minutes,
    );
  }
}

class PlaylistRefreshPreferencesStore {
  final Future<Directory> Function() directory;
  PlaylistRefreshPreferencesStore({Future<Directory> Function()? directory})
    : directory = directory ?? getApplicationSupportDirectory;
  Future<File> _file() async {
    final dir = await directory();
    await dir.create(recursive: true);
    return File(p.join(dir.path, 'playlist_refresh.json'));
  }

  Future<PlaylistRefreshPreferences> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const PlaylistRefreshPreferences();
      return PlaylistRefreshPreferences.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    } on FormatException {
      return const PlaylistRefreshPreferences();
    } on TypeError {
      return const PlaylistRefreshPreferences();
    }
  }

  Future<void> save(PlaylistRefreshPreferences preferences) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(preferences.toJson()), flush: true);
  }
}

/// Checks only times crossed while this app session is running. Opening after
/// a missed time does not trigger a download. Multiple missed slots coalesce.
class PlaylistRefreshSchedule {
  DateTime _previous;
  PlaylistRefreshSchedule(this._previous);
  bool due(DateTime now, PlaylistRefreshPreferences preferences) {
    final previous = _previous;
    _previous = now;
    if (!preferences.scheduled || !now.isAfter(previous)) return false;
    for (final minute in preferences.minutes) {
      var occurrence = DateTime(
        now.year,
        now.month,
        now.day,
        minute ~/ 60,
        minute % 60,
      );
      if (occurrence.isAfter(now)) {
        occurrence = DateTime(
          now.year,
          now.month,
          now.day - 1,
          minute ~/ 60,
          minute % 60,
        );
      }
      if (occurrence.isAfter(previous)) return true;
    }
    return false;
  }
}
