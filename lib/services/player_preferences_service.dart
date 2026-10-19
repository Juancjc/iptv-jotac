import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PlayerPreferences {
  static const validSceneIds = <String>{
    'original',
    'bright',
    'cinema',
    'vivid',
    'night',
    'monochrome',
    'custom',
  };

  final String sceneId;
  final double brightness;
  final double contrast;
  final double saturation;
  final double gamma;
  final double hue;
  final double customBrightness;
  final double customContrast;
  final double customSaturation;
  final double customGamma;
  final double customHue;
  final bool stableFps;
  final double volume;

  const PlayerPreferences({
    this.sceneId = 'original',
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.gamma = 0,
    this.hue = 0,
    this.customBrightness = 0,
    this.customContrast = 0,
    this.customSaturation = 0,
    this.customGamma = 0,
    this.customHue = 0,
    this.stableFps = true,
    this.volume = 100,
  });

  PlayerPreferences copyWith({
    String? sceneId,
    double? brightness,
    double? contrast,
    double? saturation,
    double? gamma,
    double? hue,
    double? customBrightness,
    double? customContrast,
    double? customSaturation,
    double? customGamma,
    double? customHue,
    bool? stableFps,
    double? volume,
  }) {
    return PlayerPreferences(
      sceneId: sceneId ?? this.sceneId,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      gamma: gamma ?? this.gamma,
      hue: hue ?? this.hue,
      customBrightness: customBrightness ?? this.customBrightness,
      customContrast: customContrast ?? this.customContrast,
      customSaturation: customSaturation ?? this.customSaturation,
      customGamma: customGamma ?? this.customGamma,
      customHue: customHue ?? this.customHue,
      stableFps: stableFps ?? this.stableFps,
      volume: volume ?? this.volume,
    );
  }

  Map<String, Object> toJson() => {
    'sceneId': sceneId,
    'brightness': brightness,
    'contrast': contrast,
    'saturation': saturation,
    'gamma': gamma,
    'hue': hue,
    'customBrightness': customBrightness,
    'customContrast': customContrast,
    'customSaturation': customSaturation,
    'customGamma': customGamma,
    'customHue': customHue,
    'stableFps': stableFps,
    'volume': volume,
  };

  factory PlayerPreferences.fromJson(Map<String, Object?> json) {
    double adjustment(String key) {
      final value = json[key];
      return value is num ? value.toDouble().clamp(-100, 100) : 0;
    }

    final brightness = adjustment('brightness');
    final storedSceneId = json['sceneId'];
    final sceneId =
        storedSceneId is String && validSceneIds.contains(storedSceneId)
        ? storedSceneId
        // Older versions only stored brightness. Preserve that adjustment by
        // migrating it to the personalized scene.
        : brightness != 0
        ? 'custom'
        : 'original';
    final storedVolume = json['volume'];
    return PlayerPreferences(
      sceneId: sceneId,
      brightness: brightness,
      contrast: adjustment('contrast'),
      saturation: adjustment('saturation'),
      gamma: adjustment('gamma'),
      hue: adjustment('hue'),
      customBrightness: json.containsKey('customBrightness')
          ? adjustment('customBrightness')
          : sceneId == 'custom'
          ? brightness
          : 0,
      customContrast: json.containsKey('customContrast')
          ? adjustment('customContrast')
          : sceneId == 'custom'
          ? adjustment('contrast')
          : 0,
      customSaturation: json.containsKey('customSaturation')
          ? adjustment('customSaturation')
          : sceneId == 'custom'
          ? adjustment('saturation')
          : 0,
      customGamma: json.containsKey('customGamma')
          ? adjustment('customGamma')
          : sceneId == 'custom'
          ? adjustment('gamma')
          : 0,
      customHue: json.containsKey('customHue')
          ? adjustment('customHue')
          : sceneId == 'custom'
          ? adjustment('hue')
          : 0,
      stableFps: json['stableFps'] is bool ? json['stableFps']! as bool : true,
      volume: storedVolume is num ? storedVolume.toDouble().clamp(0, 200) : 100,
    );
  }
}

/// Persists preferences shared by every playback session.
///
/// Writes are serialized so quickly moving the image sliders cannot let an
/// older disk write overwrite a newer scene.
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

  Future<void> save({
    String? sceneId,
    double? brightness,
    double? contrast,
    double? saturation,
    double? gamma,
    double? hue,
    double? customBrightness,
    double? customContrast,
    double? customSaturation,
    double? customGamma,
    double? customHue,
    bool? stableFps,
    double? volume,
  }) {
    _current = _current.copyWith(
      sceneId:
          sceneId != null && PlayerPreferences.validSceneIds.contains(sceneId)
          ? sceneId
          : null,
      brightness: brightness?.clamp(-100, 100),
      contrast: contrast?.clamp(-100, 100),
      saturation: saturation?.clamp(-100, 100),
      gamma: gamma?.clamp(-100, 100),
      hue: hue?.clamp(-100, 100),
      customBrightness: customBrightness?.clamp(-100, 100),
      customContrast: customContrast?.clamp(-100, 100),
      customSaturation: customSaturation?.clamp(-100, 100),
      customGamma: customGamma?.clamp(-100, 100),
      customHue: customHue?.clamp(-100, 100),
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
