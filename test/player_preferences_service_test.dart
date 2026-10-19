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

  test('saves and restores a personalized image scene', () async {
    final writer = PlayerPreferencesService(
      supportDirectory: () async => temporaryDirectory,
    );

    await writer.save(
      sceneId: 'custom',
      brightness: 34,
      contrast: 18,
      saturation: 22,
      gamma: -7,
      hue: 5,
      customBrightness: 34,
      customContrast: 18,
      customSaturation: 22,
      customGamma: -7,
      customHue: 5,
      stableFps: false,
      volume: 175,
    );

    final reader = PlayerPreferencesService(
      supportDirectory: () async => temporaryDirectory,
    );
    final preferences = await reader.load();

    expect(preferences.sceneId, 'custom');
    expect(preferences.brightness, 34);
    expect(preferences.contrast, 18);
    expect(preferences.saturation, 22);
    expect(preferences.gamma, -7);
    expect(preferences.hue, 5);
    expect(preferences.customBrightness, 34);
    expect(preferences.customContrast, 18);
    expect(preferences.customSaturation, 22);
    expect(preferences.customGamma, -7);
    expect(preferences.customHue, 5);
    expect(preferences.stableFps, isFalse);
    expect(preferences.volume, 175);
  });

  test('clamps invalid image and volume values before persisting', () async {
    final service = PlayerPreferencesService(
      supportDirectory: () async => temporaryDirectory,
    );

    await service.save(
      sceneId: 'not-a-scene',
      brightness: 150,
      contrast: -150,
      saturation: 120,
      gamma: -130,
      hue: 101,
      volume: 250,
    );

    expect(service.current.sceneId, 'original');
    expect(service.current.brightness, 100);
    expect(service.current.contrast, -100);
    expect(service.current.saturation, 100);
    expect(service.current.gamma, -100);
    expect(service.current.hue, 100);
    expect((await service.load()).brightness, 100);
    expect(service.current.volume, 200);
    expect((await service.load()).volume, 200);
  });

  test('migrates the old brightness preference to a custom scene', () async {
    final preferencesFile = File(
      '${temporaryDirectory.path}${Platform.pathSeparator}player_preferences.json',
    );
    await preferencesFile.writeAsString(
      '{"brightness": 27, "stableFps": true, "volume": 100}',
    );

    final service = PlayerPreferencesService(
      supportDirectory: () async => temporaryDirectory,
    );
    final preferences = await service.load();

    expect(preferences.sceneId, 'custom');
    expect(preferences.brightness, 27);
    expect(preferences.customBrightness, 27);
  });
}
