import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_jotac/services/player_preferences_service.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'iptv_jotac_player_preferences_',
    );
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  test('saves and restores brightness and stable FPS mode', () async {
    final writer = PlayerPreferencesService(
      supportDirectory: () async => temporaryDirectory,
    );

    await writer.save(brightness: 34, stableFps: false, volume: 175);

    final reader = PlayerPreferencesService(
      supportDirectory: () async => temporaryDirectory,
    );
    final preferences = await reader.load();

    expect(preferences.brightness, 34);
    expect(preferences.stableFps, isFalse);
    expect(preferences.volume, 175);
  });

  test('clamps invalid brightness values before persisting', () async {
    final service = PlayerPreferencesService(
      supportDirectory: () async => temporaryDirectory,
    );

    await service.save(brightness: 150, volume: 250);

    expect(service.current.brightness, 100);
    expect((await service.load()).brightness, 100);
    expect(service.current.volume, 200);
    expect((await service.load()).volume, 200);
  });
}
