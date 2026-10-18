import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PlayerPreferences {
  final double brightness;
  final bool stableFps;
  final double volume;

  const PlayerPreferences({
    this.brightness = 0,
    this.stableFps = true,
    this.volume = 100,
  });

  PlayerPreferences copyWith({
    double? brightness,
    bool? stableFps,
    double? volume,
  }) {
    return PlayerPreferences(
      brightness: brightness ?? this.brightness,
      stableFps: stableFps ?? this.stableFps,
      volume: volume ?? this.volume,
    );
  }

  Map<String, Object> toJson() => {
    'brightness': brightness,
    'stableFps': stableFps,
    'volume': volume,
  };

  factory PlayerPreferences.fromJson(Map<String, Object?> json) {
    final storedBrightness = json['brightness'];
    final storedVolume = json['volume'];
    return PlayerPreferences(
      brightness: storedBrightness is num
          ? storedBrightness.toDouble().clamp(-100, 100)
          : 0,
      stableFps: json['stableFps'] is bool ? json['stableFps']! as bool : true,
      volume: storedVolume is num ? storedVolume.toDouble().clamp(0, 200) : 100,
    );
  }
}

/// Persists preferences shared by every playback session.
///
/// Writes are serialized so quickly moving the brightness slider cannot let an
/// older disk write overwrite a newer value.
class PlayerPreferencesService {
  static const _fileName = 'player_preferences.json';

  final Future<Directory> Function() _supportDirectory;
  PlayerPreferences _current = const PlayerPreferences();
  Future<void> _writeQueue = Future.value();

  PlayerPreferencesService({Future<Directory> Function()? supportDirectory})
    : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  PlayerPreferences get current => _current;

  Future<PlayerPreferences> load() async {
    try {
      final file = await _preferencesFile();
      if (!await file.exists()) return _current;

      final json = jsonDecode(await file.readAsString());
      if (json is Map<String, dynamic>) {
        _current = PlayerPreferences.fromJson(json);
      }
    } on FileSystemException {
      // Keep safe defaults if the preferences file is unavailable.
    } on FormatException {
      // Keep safe defaults if a previous file is invalid or incomplete.
    }
    return _current;
  }

  Future<void> save({double? brightness, bool? stableFps, double? volume}) {
    _current = _current.copyWith(
      brightness: brightness?.clamp(-100, 100),
      stableFps: stableFps,
      volume: volume?.clamp(0, 200),
    );
    final snapshot = _current;

    _writeQueue = _writeQueue
        .catchError((Object _) {})
        .then((_) => _write(snapshot));
    return _writeQueue;
  }

  Future<File> _preferencesFile() async {
    final directory = await _supportDirectory();
    await directory.create(recursive: true);
    return File(p.join(directory.path, _fileName));
  }

  Future<void> _write(PlayerPreferences preferences) async {
    final file = await _preferencesFile();
    await file.writeAsString(jsonEncode(preferences.toJson()), flush: true);
  }
}
