import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../models/watch_history_entry.dart';
import '../providers/database_provider.dart';
import '../providers/settings_providers.dart';
import '../services/player_preferences_service.dart';
import '../services/watch_history_repository.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String title;
  final String streamUrl;
  final String contentId;
  final WatchableType contentType;
  final String? posterUrl;
  final int startPositionSeconds;

  const PlayerScreen({
    super.key,
    required this.title,
    required this.streamUrl,
    required this.contentId,
    required this.contentType,
    this.posterUrl,
    this.startPositionSeconds = 0,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  late final WatchHistoryRepository _historyRepo;
  late final PlayerPreferencesService _preferencesService;
  Timer? _progressTimer;
  Duration _lastKnownDuration = Duration.zero;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Tracks>? _tracksSubscription;
  StreamSubscription<double>? _volumeSubscription;
  bool _resumeApplied = false;

  bool _readyToWatch = false;
  Tracks? _tracks;
  AudioTrack _selectedAudio = AudioTrack.auto();
  SubtitleTrack _selectedSubtitle = SubtitleTrack.no();
  double _brightness = 0;
  bool _stableFps = true;
  double _volume = 100;

  @override
  void initState() {
    super.initState();
    _historyRepo = ref.read(watchHistoryRepositoryProvider);
    _preferencesService = ref.read(playerPreferencesServiceProvider);
    _player = Player(
      configuration: const PlayerConfiguration(
        // More headroom helps IPTV streams survive short network variations.
        bufferSize: 64 * 1024 * 1024,
      ),
    );
    _controller = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ),
    );

    _player.open(Media(widget.streamUrl), play: false);
    unawaited(_restorePlayerPreferences());
    _durationSubscription = _player.stream.duration.listen((duration) {
      _lastKnownDuration = duration;
      if (!_resumeApplied &&
          widget.startPositionSeconds > 0 &&
          duration > Duration.zero) {
        _resumeApplied = true;
        unawaited(_player.seek(Duration(seconds: widget.startPositionSeconds)));
      }
    });
    _tracksSubscription = _player.stream.tracks.listen((tracks) {
      if (mounted) setState(() => _tracks = tracks);
    });
    _volumeSubscription = _player.stream.volume.listen((volume) {
      if (mounted && volume != _volume) setState(() => _volume = volume);
    });
    _progressTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _saveProgress(),
    );
  }

  Future<void> _restorePlayerPreferences() async {
    final preferences = await _preferencesService.load();
    if (!mounted) return;

    setState(() {
      _brightness = preferences.brightness;
      _stableFps = preferences.stableFps;
      _volume = preferences.volume;
    });
    await _setNativeProperty('volume-max', '200');
    await Future.wait([
      _setNativeProperty(
        'brightness',
        preferences.brightness.round().toString(),
      ),
      _applyStableFps(preferences.stableFps),
    ]);
    await _player.setVolume(preferences.volume);
  }

  Future<void> _setNativeProperty(String name, String value) async {
    final platform = _player.platform;
    if (platform is! NativePlayer) return;

    try {
      await platform.setProperty(name, value);
    } catch (_) {
      // Some properties are backend-specific. Playback must keep working if a
      // particular libmpv build does not expose one of them.
    }
  }

  Future<void> _applyStableFps(bool enabled) async {
    if (!Platform.isWindows) return;

    await Future.wait([
      _setNativeProperty('video-sync', enabled ? 'display-resample' : 'audio'),
      _setNativeProperty('interpolation', enabled ? 'yes' : 'no'),
      _setNativeProperty('tscale', enabled ? 'oversample' : 'linear'),
    ]);
  }

  void _changeBrightness(double value) {
    final brightness = value.clamp(-100.0, 100.0).toDouble();
    setState(() => _brightness = brightness);
    unawaited(_setNativeProperty('brightness', brightness.round().toString()));
    unawaited(_preferencesService.save(brightness: brightness));
  }

  void _changeStableFps(bool enabled) {
    setState(() => _stableFps = enabled);
    unawaited(_applyStableFps(enabled));
    unawaited(_preferencesService.save(stableFps: enabled));
  }

  void _changeVolume(double value) {
    final volume = value.clamp(0.0, 200.0).toDouble();
    setState(() => _volume = volume);
    unawaited(_player.setVolume(volume));
    unawaited(_preferencesService.save(volume: volume));
  }

  void _seekRelative(int seconds) {
    final position = _player.state.position;
    final duration = _player.state.duration;
    var target = position + Duration(seconds: seconds);

    if (target < Duration.zero) target = Duration.zero;
    if (duration > Duration.zero && target > duration) target = duration;
    unawaited(_player.seek(target));
  }

  BuildContext? get _focusedControlsContext {
    final context = FocusManager.instance.primaryFocus?.context;
    return context != null && VideoStateInheritedWidget.maybeOf(context) != null
        ? context
        : null;
  }

  void _toggleFullscreen() {
    final context = _focusedControlsContext;
    if (context != null) unawaited(toggleFullscreen(context));
  }

  void _exitFullscreen() {
    final context = _focusedControlsContext;
    if (context != null) unawaited(exitFullscreen(context));
  }

  Future<void> _saveProgress() async {
    if (!_readyToWatch) return;
    final position = _player.state.position;
    if (position == Duration.zero) return;
    await _historyRepo.upsertProgress(
      contentId: widget.contentId,
      contentType: widget.contentType,
      title: widget.title,
      streamUrl: widget.streamUrl,
      posterUrl: widget.posterUrl,
      positionSeconds: position.inSeconds,
      durationSeconds: _lastKnownDuration.inSeconds > 0
          ? _lastKnownDuration.inSeconds
          : null,
    );
  }

  void _startWatching() {
    _player.setAudioTrack(_selectedAudio);
    _player.setSubtitleTrack(_selectedSubtitle);
    _player.play();
    setState(() => _readyToWatch = true);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _durationSubscription?.cancel();
    _tracksSubscription?.cancel();
    _volumeSubscription?.cancel();
    unawaited(_saveProgress());
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(subtitleFontSizeProvider);
    final textColor = ref.watch(subtitleTextColorProvider);
    final backgroundColor = ref.watch(subtitleBackgroundColorProvider);

    final desktopControls = MaterialDesktopVideoControlsThemeData(
      hideMouseOnControlsRemoval: Platform.isWindows,
      modifyVolumeOnScroll: false,
      controlsHoverDuration: const Duration(seconds: 3),
      bottomButtonBar: [
        _SeekSecondsButton(seconds: -30, onPressed: () => _seekRelative(-30)),
        const MaterialDesktopPlayOrPauseButton(),
        _SeekSecondsButton(seconds: 30, onPressed: () => _seekRelative(30)),
        _BoostVolumeButton(volume: _volume, onChanged: _changeVolume),
        const MaterialDesktopPositionIndicator(),
        const Spacer(),
        _PlayerVideoSettingsButton(
          brightness: _brightness,
          stableFps: _stableFps,
          volume: _volume,
          onBrightnessChanged: _changeBrightness,
          onStableFpsChanged: _changeStableFps,
          onVolumeChanged: _changeVolume,
        ),
        const MaterialDesktopFullscreenButton(),
      ],
      keyboardShortcuts: {
        const SingleActivator(LogicalKeyboardKey.mediaPlay): _player.play,
        const SingleActivator(LogicalKeyboardKey.mediaPause): _player.pause,
        const SingleActivator(LogicalKeyboardKey.mediaPlayPause):
            _player.playOrPause,
        const SingleActivator(LogicalKeyboardKey.mediaTrackNext): _player.next,
        const SingleActivator(LogicalKeyboardKey.mediaTrackPrevious):
            _player.previous,
        const SingleActivator(LogicalKeyboardKey.space): _player.playOrPause,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _seekRelative(-30),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _seekRelative(30),
        const SingleActivator(LogicalKeyboardKey.keyJ): () =>
            _seekRelative(-30),
        const SingleActivator(LogicalKeyboardKey.keyL): () => _seekRelative(30),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () {
          _changeVolume(_volume + 5);
        },
        const SingleActivator(LogicalKeyboardKey.arrowDown): () {
          _changeVolume(_volume - 5);
        },
        const SingleActivator(LogicalKeyboardKey.keyF): _toggleFullscreen,
        const SingleActivator(LogicalKeyboardKey.escape): _exitFullscreen,
      },
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MaterialDesktopVideoControlsTheme(
            normal: desktopControls,
            fullscreen: desktopControls,
            child: Center(
              child: Video(
                controller: _controller,
                subtitleViewConfiguration: SubtitleViewConfiguration(
                  style: TextStyle(
                    height: 1.4,
                    fontSize: fontSize,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    backgroundColor: backgroundColor,
                  ),
                ),
              ),
            ),
          ),
          if (!_readyToWatch)
            _PrePlaybackOverlay(
              title: widget.title,
              posterUrl: widget.posterUrl,
              tracks: _tracks,
              selectedAudio: _selectedAudio,
              selectedSubtitle: _selectedSubtitle,
              startPositionSeconds: widget.startPositionSeconds,
              onAudioChanged: (track) => setState(() => _selectedAudio = track),
              onSubtitleChanged: (track) =>
                  setState(() => _selectedSubtitle = track),
              onWatch: _startWatching,
            ),
        ],
      ),
    );
  }
}

class _SeekSecondsButton extends StatelessWidget {
  final int seconds;
  final VoidCallback onPressed;

  const _SeekSecondsButton({required this.seconds, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final forward = seconds > 0;
    return Tooltip(
      message: forward
          ? 'Avancar $seconds segundos'
          : 'Voltar ${seconds.abs()} segundos',
      child: MaterialDesktopCustomButton(
        onPressed: onPressed,
        icon: Icon(forward ? Icons.forward_30 : Icons.replay_30),
      ),
    );
  }
}

class _PlayerVideoSettingsButton extends StatelessWidget {
  final double brightness;
  final bool stableFps;
  final double volume;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<bool> onStableFpsChanged;
  final ValueChanged<double> onVolumeChanged;

  const _PlayerVideoSettingsButton({
    required this.brightness,
    required this.stableFps,
    required this.volume,
    required this.onBrightnessChanged,
    required this.onStableFpsChanged,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Imagem e FPS',
      child: MaterialDesktopCustomButton(
        icon: const Icon(Icons.tune),
        onPressed: () => _showSettings(context),
      ),
    );
  }

  Future<void> _showSettings(BuildContext context) async {
    var draftBrightness = brightness;
    var draftStableFps = stableFps;
    var draftVolume = volume;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final brightnessLabel = draftBrightness.round();
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.tune),
                SizedBox(width: 10),
                Text('Imagem e reproducao'),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.brightness_6_outlined),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Brilho')),
                      Text(
                        brightnessLabel > 0
                            ? '+$brightnessLabel'
                            : '$brightnessLabel',
                      ),
                    ],
                  ),
                  Slider(
                    value: draftBrightness,
                    min: -100,
                    max: 100,
                    divisions: 200,
                    label: brightnessLabel > 0
                        ? '+$brightnessLabel'
                        : '$brightnessLabel',
                    onChanged: (value) {
                      setDialogState(() => draftBrightness = value);
                      onBrightnessChanged(value);
                    },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setDialogState(() => draftBrightness = 0);
                        onBrightnessChanged(0);
                      },
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Restaurar brilho'),
                    ),
                  ),
                  const Divider(height: 28),
                  Row(
                    children: [
                      Icon(
                        draftVolume > 100
                            ? Icons.volume_up
                            : draftVolume == 0
                            ? Icons.volume_off
                            : Icons.volume_down,
                        color: draftVolume > 100 ? Colors.orangeAccent : null,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Volume')),
                      Text('${draftVolume.round()}%'),
                    ],
                  ),
                  Slider(
                    value: draftVolume.clamp(0, 200),
                    min: 0,
                    max: 200,
                    divisions: 40,
                    label: '${draftVolume.round()}%',
                    onChanged: (value) {
                      setDialogState(() => draftVolume = value);
                      onVolumeChanged(value);
                    },
                  ),
                  const Text(
                    'Acima de 100% aplica ganho e pode causar distorcao em alguns audios.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const Divider(height: 28),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('FPS estavel'),
                    subtitle: const Text(
                      'Suaviza a exibicao quando os FPS do video e do monitor nao coincidem.',
                    ),
                    value: draftStableFps,
                    onChanged: (value) {
                      setDialogState(() => draftStableFps = value);
                      onStableFpsChanged(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Atalhos: setas esquerda/direita ou J/L voltam e avancam 30 segundos.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Concluir'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BoostVolumeButton extends StatefulWidget {
  final double volume;
  final ValueChanged<double> onChanged;

  const _BoostVolumeButton({required this.volume, required this.onChanged});

  @override
  State<_BoostVolumeButton> createState() => _BoostVolumeButtonState();
}

class _BoostVolumeButtonState extends State<_BoostVolumeButton> {
  bool _hovering = false;
  double _lastAudibleVolume = 100;

  @override
  void didUpdateWidget(covariant _BoostVolumeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.volume > 0) _lastAudibleVolume = widget.volume;
  }

  void _adjustFromScroll(PointerScrollEvent event) {
    if (event.scrollDelta.dy < 0) {
      widget.onChanged(widget.volume + 5);
    } else if (event.scrollDelta.dy > 0) {
      widget.onChanged(widget.volume - 5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final volume = widget.volume.clamp(0.0, 200.0).toDouble();
    final boosted = volume > 100;
    final icon = volume == 0
        ? Icons.volume_off
        : volume < 50
        ? Icons.volume_down
        : Icons.volume_up;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) _adjustFromScroll(event);
        },
        child: Row(
          children: [
            Tooltip(
              message: 'Volume: ${volume.round()}% (maximo 200%)',
              child: IconButton(
                onPressed: () {
                  if (volume > 0) _lastAudibleVolume = volume;
                  widget.onChanged(
                    volume == 0
                        ? _lastAudibleVolume.clamp(1.0, 200.0).toDouble()
                        : 0.0,
                  );
                },
                icon: Icon(
                  icon,
                  color: boosted ? Colors.orangeAccent : Colors.white,
                ),
              ),
            ),
            AnimatedContainer(
              width: _hovering ? 138 : 0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Slider(
                        value: volume,
                        min: 0,
                        max: 200,
                        divisions: 40,
                        onChanged: widget.onChanged,
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      child: Text(
                        '${volume.round()}%',
                        style: TextStyle(
                          color: boosted ? Colors.orangeAccent : Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen cover shown before playback starts, letting the viewer pick
/// an audio language and subtitle track with a TV remote (D-pad) before
/// committing to "watch". Skippable with a single autofocused button when
/// there is nothing to choose.
class _PrePlaybackOverlay extends StatelessWidget {
  final String title;
  final String? posterUrl;
  final Tracks? tracks;
  final AudioTrack selectedAudio;
  final SubtitleTrack selectedSubtitle;
  final int startPositionSeconds;
  final ValueChanged<AudioTrack> onAudioChanged;
  final ValueChanged<SubtitleTrack> onSubtitleChanged;
  final VoidCallback onWatch;

  const _PrePlaybackOverlay({
    required this.title,
    required this.posterUrl,
    required this.tracks,
    required this.selectedAudio,
    required this.selectedSubtitle,
    required this.startPositionSeconds,
    required this.onAudioChanged,
    required this.onSubtitleChanged,
    required this.onWatch,
  });

  // Real, selectable tracks only: media_kit always injects synthetic
  // 'auto'/'no' entries even when the stream has a single track.
  List<AudioTrack> get _audioOptions =>
      (tracks?.audio ?? const []).where((t) => t.id != 'no').toList();

  List<SubtitleTrack> get _subtitleOptions =>
      (tracks?.subtitle ?? const []).where((t) => t.id != 'auto').toList();

  String _audioLabel(AudioTrack track, int index) {
    if (track.id == 'auto') return 'Automatico';
    return track.title ?? track.language ?? 'Faixa ${index + 1}';
  }

  String _subtitleLabel(SubtitleTrack track, int index) {
    if (track.id == 'no') return 'Desativada';
    return track.title ?? track.language ?? 'Legenda ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final poster = posterUrl;
    final showAudioPicker = _audioOptions.length > 1;
    final showSubtitlePicker = _subtitleOptions.length > 1;

    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (poster != null && poster.isNotEmpty)
            Image.network(
              poster,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: .35),
                  Colors.black.withValues(alpha: .88),
                ],
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),
                    if (showAudioPicker)
                      _OptionDropdown<AudioTrack>(
                        icon: Icons.record_voice_over_outlined,
                        label: 'Audio',
                        value: selectedAudio,
                        items: _audioOptions,
                        itemLabel: _audioLabel,
                        onChanged: onAudioChanged,
                      ),
                    if (showAudioPicker && showSubtitlePicker)
                      const SizedBox(height: 12),
                    if (showSubtitlePicker)
                      _OptionDropdown<SubtitleTrack>(
                        icon: Icons.subtitles_outlined,
                        label: 'Legenda',
                        value: selectedSubtitle,
                        items: _subtitleOptions,
                        itemLabel: _subtitleLabel,
                        onChanged: onSubtitleChanged,
                      ),
                    if (showAudioPicker || showSubtitlePicker)
                      const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        autofocus: true,
                        onPressed: onWatch,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          startPositionSeconds > 0
                              ? 'Continuar de ${_formatPlaybackTime(startPositionSeconds)}'
                              : 'Assistir',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatPlaybackTime(int totalSeconds) {
  final duration = Duration(seconds: totalSeconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

class _OptionDropdown<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final T value;
  final List<T> items;
  final String Function(T item, int index) itemLabel;
  final ValueChanged<T> onChanged;

  const _OptionDropdown({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final containsValue = items.any((item) => item == value);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: containsValue ? value : null,
          isExpanded: true,
          dropdownColor: const Color(0xFF1C181D),
          icon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.arrow_drop_down, color: Colors.white),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          selectedItemBuilder: (context) => items
              .map(
                (item) => Row(
                  children: [
                    Icon(icon, size: 18, color: Colors.white70),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$label: ${itemLabel(item, items.indexOf(item))}',
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
          items: [
            for (var i = 0; i < items.length; i++)
              DropdownMenuItem<T>(
                value: items[i],
                child: Text(itemLabel(items[i], i)),
              ),
          ],
          onChanged: (item) {
            if (item != null) onChanged(item);
          },
        ),
      ),
    );
  }
}
