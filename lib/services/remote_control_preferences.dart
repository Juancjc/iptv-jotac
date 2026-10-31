import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// User choices for the phone remote control.
class RemoteControlPreferences {
  /// Turn the remote control on as soon as the app opens.
  final bool autoStart;

  /// Reuse the same access code (and so the same address) across restarts,
  /// so a phone can bookmark the page instead of scanning the QR every time.
  final bool keepAddress;

  /// The saved access code, used while [keepAddress] is on.
  final String? accessCode;

  const RemoteControlPreferences({this.autoStart = false, this.keepAddress = true, this.accessCode});

  RemoteControlPreferences copyWith({bool? autoStart, bool? keepAddress, String? accessCode, bool clearCode = false}) {
    return RemoteControlPreferences(
      autoStart: autoStart ?? this.autoStart,
      keepAddress: keepAddress ?? this.keepAddress,
      accessCode: clearCode ? null : accessCode ?? this.accessCode,
    );
  }

  Map<String, Object?> toJson() => {'autoStart': autoStart, 'keepAddress': keepAddress, 'accessCode': accessCode};

  factory RemoteControlPreferences.fromJson(Map<String, Object?> json) {
    final code = json['accessCode'];
    return RemoteControlPreferences(
      autoStart: json['autoStart'] == true,
      keepAddress: json['keepAddress'] is bool ? json['keepAddress']! as bool : true,
      accessCode: code is String && code.length >= 6 ? code : null,
    );
  }
}

/// Saves [RemoteControlPreferences] in the app support directory.
class RemoteControlPreferencesService {
  static const _fileName = 'remote_control.json';

  final Future<Directory> Function() _supportDirectory;
  Future<void> _writeQueue = Future.value();

  RemoteControlPreferencesService({Future<Directory> Function()? supportDirectory})
    : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  Future<RemoteControlPreferences> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const RemoteControlPreferences();
      final json = jsonDecode(await file.readAsString());
      if (json is Map<String, dynamic>) return RemoteControlPreferences.fromJson(json);
    } catch (_) {
      // Missing/corrupt file or no storage (e.g. tests): use the defaults.
    }
    return const RemoteControlPreferences();
  }

  Future<void> save(RemoteControlPreferences preferences) {
    _writeQueue = _writeQueue.catchError((Object _) {}).then((_) async {
      final file = await _file();
      await file.writeAsString(jsonEncode(preferences.toJson()), flush: true);
    });
    return _writeQueue;
  }

  Future<File> _file() async {
    final directory = await _supportDirectory();
    await directory.create(recursive: true);
    return File(p.join(directory.path, _fileName));
  }
}
