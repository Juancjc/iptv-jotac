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

class _VideoAdjustments {
  final double brightness;
  final double contrast;
  final double saturation;
  final double gamma;
  final double hue;

  const _VideoAdjustments({
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.gamma = 0,
    this.hue = 0,
  });

  _VideoAdjustments copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? gamma,
    double? hue,
  }) {
    return _VideoAdjustments(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      gamma: gamma ?? this.gamma,
      hue: hue ?? this.hue,
    );
  }
}

class _VideoScenePreset {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final _VideoAdjustments adjustments;

  const _VideoScenePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.adjustments = const _VideoAdjustments(),
  });
}

const _videoScenePresets = <_VideoScenePreset>[
  _VideoScenePreset(
    id: 'original',
    name: 'Original',
    description: 'Imagem sem correcoes.',
    icon: Icons.settings_backup_restore,
  ),
  _VideoScenePreset(
    id: 'bright',
    name: 'Claro',
    description: 'Recupera detalhes em cenas escuras.',
    icon: Icons.light_mode_outlined,
    adjustments: _VideoAdjustments(
      brightness: 14,
      contrast: 6,
      saturation: 4,
      gamma: 10,
    ),
  ),
  _VideoScenePreset(
    id: 'cinema',
    name: 'Cinema',
    description: 'Contraste mais profundo e cores contidas.',
    icon: Icons.movie_filter_outlined,
    adjustments: _VideoAdjustments(
      brightness: -3,
      contrast: 18,
      saturation: -5,
      gamma: -4,
    ),
  ),
  _VideoScenePreset(
    id: 'vivid',
    name: 'Vivo',
    description: 'Mais intensidade e cor para esportes e animacoes.',
    icon: Icons.color_lens_outlined,
    adjustments: _VideoAdjustments(
      brightness: 4,
      contrast: 14,
      saturation: 28,
      gamma: 2,
    ),
  ),
  _VideoScenePreset(
    id: 'night',
    name: 'Noturno',
    description: 'Imagem suave para ambientes com pouca luz.',
    icon: Icons.nightlight_outlined,
    adjustments: _VideoAdjustments(
      brightness: -12,
      contrast: -6,
      saturation: -10,
      gamma: -8,
    ),
  ),
  _VideoScenePreset(
    id: 'monochrome',
    name: 'Preto e branco',
    description: 'Remove as cores e reforca o contraste.',
    icon: Icons.filter_b_and_w_outlined,
    adjustments: _VideoAdjustments(contrast: 18, saturation: -100),
  ),
  _VideoScenePreset(
    id: 'custom',
    name: 'Personalizada',
    description: 'Seus ajustes salvos de imagem.',
    icon: Icons.tune,
  ),
];

class PlayerScreen extends ConsumerStatefulWidget {
  final String title;
  final String streamUrl;
  final String contentId;
  final WatchableType contentType;
  final String? posterUrl;
  final int startPositionSeconds;
  final ValueChanged<Future<void>>? onDisposed;

  const PlayerScreen({
    super.key,
    required this.title,
    required this.streamUrl,
    required this.contentId,
    required this.contentType,
    this.posterUrl,
    this.startPositionSeconds = 0,
    this.onDisposed,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with WidgetsBindingObserver {
  late final Player _player;
  late final VideoController _controller;
  late final WatchHistoryRepository _historyRepo;
  late final PlayerPreferencesService _preferencesService;
  late final Future<void> _playerInitialization;
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
  String _sceneId = 'original';
  _VideoAdjustments _imageAdjustments = const _VideoAdjustments();
  _VideoAdjustments _customImageAdjustments = const _VideoAdjustments();
  bool _stableFps = true;
  BoxFit _videoFit = BoxFit.contain;
  double _volume = 100;
  bool _startingPlayback = false;
  String? _initializationError;

  int get _cacheSeconds =>
      widget.contentType == WatchableType.channel ? 15 : 45;

  int get _cachePauseSeconds =>
      widget.contentType == WatchableType.channel ? 3 : 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) unawaited(_enterAndroidFullscreen());
    _historyRepo = ref.read(watchHistoryRepositoryProvider);
    _preferencesService = ref.read(playerPreferencesServiceProvider);
    _player = Player(
      configuration: const PlayerConfiguration(
        // Keeps enough compressed media in memory to absorb IPTV jitter and
        // bitrate peaks without relying on temporary disk I/O.
        bufferSize: 128 * 1024 * 1024,
      ),
    );
    _controller = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
        // Prefer the hardware decoders mpv considers reliable on the device.
        hwdec: 'auto-safe',
      ),
    );

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
    _playerInitialization = _initializePlayer();

    // Live channels have no resume point or track choice worth stopping for,
    // and on TV remotes the "Assistir" button may not get focus: play directly.
    if (widget.contentType == WatchableType.channel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_startWatching());
      });
    }
  }

  Future<void> _enterAndroidFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (Platform.isAndroid && state == AppLifecycleState.resumed) {
      unawaited(_enterAndroidFullscreen());
    }
  }

  Future<void> _initializePlayer() async {
    try {
      final preferences = await _preferencesService.load();
      if (!mounted) return;

      setState(() {
        _sceneId = preferences.sceneId;
        _imageAdjustments = _VideoAdjustments(
          brightness: preferences.brightness,
          contrast: preferences.contrast,
          saturation: preferences.saturation,
          gamma: preferences.gamma,
          hue: preferences.hue,
        );
        _customImageAdjustments = _VideoAdjustments(
          brightness: preferences.customBrightness,
          contrast: preferences.customContrast,
          saturation: preferences.customSaturation,
          gamma: preferences.customGamma,
          hue: preferences.customHue,
        );
        _stableFps = preferences.stableFps;
        _volume = preferences.volume;
      });

      // These options need to be in place before opening the media. In
      // particular, interpolation may need extra hardware-decoder frames that
      // cannot be allocated reliably after decoding has already started.
      await Future.wait([
        _setNativeProperty('volume-max', '200'),
        _setNativeProperty('cache', 'yes'),
        _setNativeProperty('cache-on-disk', 'no'),
        _setNativeProperty('cache-secs', _cacheSeconds.toString()),
        _setNativeProperty('demuxer-readahead-secs', _cacheSeconds.toString()),
        _setNativeProperty('cache-pause', 'yes'),
        _setNativeProperty('cache-pause-initial', 'yes'),
        _setNativeProperty('cache-pause-wait', _cachePauseSeconds.toString()),
        _setNativeProperty('network-timeout', '15'),
        _setNativeProperty('framedrop', 'vo'),
        _setNativeProperty('hwdec-extra-frames', '8'),
        _applyImageAdjustments(
          _VideoAdjustments(
            brightness: preferences.brightness,
            contrast: preferences.contrast,
            saturation: preferences.saturation,
            gamma: preferences.gamma,
            hue: preferences.hue,
          ),
        ),
        _applyStableFps(preferences.stableFps),
      ]);
      await _player.open(Media(widget.streamUrl), play: false);
      await _player.setVolume(preferences.volume);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _initializationError = 'Nao foi possivel preparar o video: $error';
      });
    }
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
      _setNativeProperty('interpolation-threshold', enabled ? '-1' : '0.01'),
      _setNativeProperty('tscale', enabled ? 'oversample' : 'linear'),
    ]);
  }

  Future<void> _applyImageAdjustments(_VideoAdjustments adjustments) {
    return Future.wait([
      _setNativeProperty(
        'brightness',
        adjustments.brightness.round().toString(),
      ),
      _setNativeProperty('contrast', adjustments.contrast.round().toString()),
      _setNativeProperty(
        'saturation',
        adjustments.saturation.round().toString(),
      ),
      _setNativeProperty('gamma', adjustments.gamma.round().toString()),
      _setNativeProperty('hue', adjustments.hue.round().toString()),
    ]);
  }

  void _selectVideoScene(String sceneId) {
    final preset = _videoScenePresets.firstWhere(
      (scene) => scene.id == sceneId,
      orElse: () => _videoScenePresets.first,
    );
    final adjustments = preset.id == 'custom'
        ? _customImageAdjustments
        : preset.adjustments;

    setState(() {
      _sceneId = preset.id;
      _imageAdjustments = adjustments;
    });
    unawaited(_applyImageAdjustments(adjustments));
    unawaited(_saveVideoScene());
  }

  void _changeVideoAdjustments(_VideoAdjustments adjustments) {
    final normalized = _VideoAdjustments(
      brightness: adjustments.brightness.clamp(-100, 100),
      contrast: adjustments.contrast.clamp(-100, 100),
      saturation: adjustments.saturation.clamp(-100, 100),
      gamma: adjustments.gamma.clamp(-100, 100),
      hue: adjustments.hue.clamp(-100, 100),
    );
    setState(() {
      _sceneId = 'custom';
      _imageAdjustments = normalized;
      _customImageAdjustments = normalized;
    });
    unawaited(_applyImageAdjustments(normalized));
    unawaited(_saveVideoScene());
  }

  Future<void> _saveVideoScene() {
    return _preferencesService.save(
      sceneId: _sceneId,
      brightness: _imageAdjustments.brightness,
      contrast: _imageAdjustments.contrast,
      saturation: _imageAdjustments.saturation,
      gamma: _imageAdjustments.gamma,
      hue: _imageAdjustments.hue,
      customBrightness: _customImageAdjustments.brightness,
      customContrast: _customImageAdjustments.contrast,
      customSaturation: _customImageAdjustments.saturation,
      customGamma: _customImageAdjustments.gamma,
      customHue: _customImageAdjustments.hue,
    );
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

  Future<void> _startWatching() async {
    if (_startingPlayback) return;
    setState(() => _startingPlayback = true);

    try {
      await _playerInitialization;
      if (!mounted) return;
      if (_initializationError != null) {
        setState(() => _startingPlayback = false);
        return;
      }

      await _player.setAudioTrack(_selectedAudio);
      await _player.setSubtitleTrack(_selectedSubtitle);
      await _player.play();
      if (mounted) {
        setState(() {
          _startingPlayback = false;
          _readyToWatch = true;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _startingPlayback = false;
        _initializationError = 'Nao foi possivel iniciar o video: $error';
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isAndroid) {
      // Undo immersive mode: bring the status and navigation bars back and
      // let the rest of the app rotate freely again.
      unawaited(
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        ),
      );
      unawaited(SystemChrome.setPreferredOrientations(const []));
    }
    _progressTimer?.cancel();
    _durationSubscription?.cancel();
    _tracksSubscription?.cancel();
    _volumeSubscription?.cancel();
    unawaited(_saveProgress());
    final disposal = _player.dispose();
    widget.onDisposed?.call(disposal);
    unawaited(disposal);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(subtitleFontSizeProvider);
    final textColor = ref.watch(subtitleTextColorProvider);
    final backgroundColor = ref.watch(subtitleBackgroundColorProvider);

    final settingsButton = _PlayerVideoSettingsButton(
      sceneId: _sceneId,
      adjustments: _imageAdjustments,
      customAdjustments: _customImageAdjustments,
      stableFps: _stableFps,
      volume: _volume,
      cacheSeconds: _cacheSeconds,
      onSceneChanged: _selectVideoScene,
      onAdjustmentsChanged: _changeVideoAdjustments,
      onStableFpsChanged: _changeStableFps,
      onVolumeChanged: _changeVolume,
    );

    final desktopControls = MaterialDesktopVideoControlsThemeData(
      hideMouseOnControlsRemoval: Platform.isWindows,
      modifyVolumeOnScroll: false,
      playAndPauseOnTap: true,
      controlsHoverDuration: const Duration(seconds: 3),
      bottomButtonBar: [
        _SeekSecondsButton(seconds: -30, onPressed: () => _seekRelative(-30)),
        const MaterialDesktopPlayOrPauseButton(),
        _SeekSecondsButton(seconds: 30, onPressed: () => _seekRelative(30)),
        _BoostVolumeButton(volume: _volume, onChanged: _changeVolume),
        const MaterialDesktopPositionIndicator(),
        const Spacer(),
        settingsButton,
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
      appBar: Platform.isAndroid
          ? null
          : AppBar(
              title: Text(widget.title),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MaterialDesktopVideoControlsTheme(
            normal: desktopControls,
            fullscreen: desktopControls,
            child: Center(
              child: Video(
                controller: _controller,
                fit: _videoFit,
                // media_kit's mobile controls only appear on a touch tap and
                // ignore the desktop bar above (volume, +-30s, settings), so
                // on Android/Fire TV nothing showed up with a remote. Android
                // gets its own overlay instead, see _AndroidPlayerControls.
                controls: Platform.isAndroid
                    ? NoVideoControls
                    : AdaptiveVideoControls,
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
          if (Platform.isAndroid && _readyToWatch)
            _AndroidPlayerControls(
              player: _player,
              title: widget.title,
              canSeek: widget.contentType != WatchableType.channel,
              volume: _volume,
              fit: _videoFit,
              onVolumeChanged: _changeVolume,
              onSeekRelative: _seekRelative,
              onFitChanged: (fit) => setState(() => _videoFit = fit),
              onOpenSettings: settingsButton._showSettings,
            ),
          // Channels start on their own, so the overlay only comes back to
          // show an error (and a retry button).
          if (!_readyToWatch &&
              (widget.contentType != WatchableType.channel ||
                  _initializationError != null))
            _PrePlaybackOverlay(
              title: widget.title,
              posterUrl: widget.posterUrl,
              tracks: _tracks,
              selectedAudio: _selectedAudio,
              selectedSubtitle: _selectedSubtitle,
              startPositionSeconds: widget.startPositionSeconds,
              isStarting: _startingPlayback,
              errorMessage: _initializationError,
              onAudioChanged: (track) => setState(() => _selectedAudio = track),
              onSubtitleChanged: (track) =>
                  setState(() => _selectedSubtitle = track),
              onWatch: () => unawaited(_startWatching()),
            ),
        ],
      ),
    );
  }
}

/// Player controls for Android phones and Android/Fire TV boxes. Shown on a
/// tap or on any remote key, hidden again after a few seconds; while visible
/// the D-pad moves between the buttons (the focused one is drawn inverted so
/// it stands out from across the room).
class _AndroidPlayerControls extends StatefulWidget {
  final Player player;
  final String title;
  final bool canSeek;
  final double volume;
  final BoxFit fit;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<int> onSeekRelative;
  final ValueChanged<BoxFit> onFitChanged;
  final Future<void> Function(BuildContext context) onOpenSettings;

  const _AndroidPlayerControls({
    required this.player,
    required this.title,
    required this.canSeek,
    required this.volume,
    required this.fit,
    required this.onVolumeChanged,
    required this.onSeekRelative,
    required this.onFitChanged,
    required this.onOpenSettings,
  });

  @override
  State<_AndroidPlayerControls> createState() => _AndroidPlayerControlsState();
}

class _AndroidPlayerControlsState extends State<_AndroidPlayerControls> {
  static const _hideAfter = Duration(seconds: 5);
  static const _fits = [BoxFit.contain, BoxFit.cover, BoxFit.fill];

  final _rootFocus = FocusNode(debugLabel: 'player-controls');
  final _playFocus = FocusNode(debugLabel: 'player-play');
  Timer? _hideTimer;
  bool _visible = true;
  double _lastAudibleVolume = 100;

  @override
  void initState() {
    super.initState();
    _restartHideTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playFocus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant _AndroidPlayerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.volume > 0) _lastAudibleVolume = widget.volume;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _rootFocus.dispose();
    _playFocus.dispose();
    super.dispose();
  }

  void _restartHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_hideAfter, _hide);
  }

  void _show() {
    _restartHideTimer();
    if (_visible) return;
    setState(() => _visible = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playFocus.requestFocus();
    });
  }

  void _hide() {
    _hideTimer?.cancel();
    if (!mounted || !_visible) return;
    // Keep focus inside the player so the next key press reveals it again.
    _rootFocus.requestFocus();
    setState(() => _visible = false);
  }

  /// Runs a button action and keeps the controls on screen for a while more.
  VoidCallback _act(VoidCallback action) => () {
    action();
    _restartHideTimer();
  };

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    // Back must keep leaving the player.
    if (key == LogicalKeyboardKey.goBack || key == LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.mediaPlayPause) {
      unawaited(widget.player.playOrPause());
      _show();
      return KeyEventResult.handled;
    }
    if (!_visible) {
      // The first press only reveals the controls.
      _show();
      return KeyEventResult.handled;
    }
    _restartHideTimer();
    return KeyEventResult.ignored;
  }

  void _toggleMute() {
    widget.onVolumeChanged(
      widget.volume == 0
          ? _lastAudibleVolume.clamp(1.0, 200.0).toDouble()
          : 0.0,
    );
  }

  void _cycleFit() {
    final next = _fits[(_fits.indexOf(widget.fit) + 1) % _fits.length];
    widget.onFitChanged(next);
  }

  String get _fitLabel => switch (widget.fit) {
    BoxFit.cover => 'Preencher',
    BoxFit.fill => 'Esticar',
    _ => 'Original',
  };

  @override
  Widget build(BuildContext context) {
    final volume = widget.volume.clamp(0.0, 200.0).toDouble();

    return Focus(
      focusNode: _rootFocus,
      onKeyEvent: _onKey,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _visible ? _hide() : _show(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            StreamBuilder<bool>(
              stream: widget.player.stream.buffering,
              initialData: widget.player.state.buffering,
              builder: (context, snapshot) => snapshot.data == true
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const SizedBox.shrink(),
            ),
            ExcludeFocus(
              excluding: !_visible,
              child: IgnorePointer(
                ignoring: !_visible,
                child: AnimatedOpacity(
                  opacity: _visible ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: _buildControls(context, volume),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, double volume) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent, Colors.black87],
          stops: [0, .5, 1],
        ),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                _OverlayButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Voltar',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!widget.canSeek) const _LiveBadge(),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.canSeek)
                  _OverlayButton(
                    icon: Icons.replay_30,
                    tooltip: 'Voltar 30 segundos',
                    size: 36,
                    onPressed: _act(() => widget.onSeekRelative(-30)),
                  ),
                const SizedBox(width: 24),
                StreamBuilder<bool>(
                  stream: widget.player.stream.playing,
                  initialData: widget.player.state.playing,
                  builder: (context, snapshot) {
                    final playing = snapshot.data ?? false;
                    return _OverlayButton(
                      focusNode: _playFocus,
                      icon: playing ? Icons.pause : Icons.play_arrow,
                      tooltip: playing ? 'Pausar' : 'Reproduzir',
                      size: 52,
                      onPressed: _act(
                        () => unawaited(widget.player.playOrPause()),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 24),
                if (widget.canSeek)
                  _OverlayButton(
                    icon: Icons.forward_30,
                    tooltip: 'Avancar 30 segundos',
                    size: 36,
                    onPressed: _act(() => widget.onSeekRelative(30)),
                  ),
              ],
            ),
            const Spacer(),
            if (widget.canSeek) _buildProgressBar(),
            Row(
              children: [
                _OverlayButton(
                  icon: volume == 0
                      ? Icons.volume_off
                      : volume < 50
                      ? Icons.volume_down
                      : Icons.volume_up,
                  tooltip: volume == 0 ? 'Ativar som' : 'Silenciar',
                  onPressed: _act(_toggleMute),
                ),
                const SizedBox(width: 8),
                _OverlayButton(
                  icon: Icons.remove,
                  tooltip: 'Diminuir volume',
                  onPressed: _act(() => widget.onVolumeChanged(volume - 10)),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    '${volume.round()}%',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: volume > 100 ? Colors.orangeAccent : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _OverlayButton(
                  icon: Icons.add,
                  tooltip: 'Aumentar volume (maximo 200%)',
                  onPressed: _act(() => widget.onVolumeChanged(volume + 10)),
                ),
                const Spacer(),
                _OverlayButton(
                  icon: widget.fit == BoxFit.contain
                      ? Icons.fullscreen
                      : Icons.fullscreen_exit,
                  tooltip: 'Tela: $_fitLabel',
                  label: _fitLabel,
                  onPressed: _act(_cycleFit),
                ),
                const SizedBox(width: 8),
                _OverlayButton(
                  icon: Icons.tune,
                  tooltip: 'Imagem e reproducao',
                  onPressed: () async {
                    _hideTimer?.cancel();
                    await widget.onOpenSettings(context);
                    if (mounted) _restartHideTimer();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    const timeStyle = TextStyle(color: Colors.white, fontSize: 13);
    return StreamBuilder<Duration>(
      stream: widget.player.stream.position,
      initialData: widget.player.state.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = widget.player.state.duration;
        final max = duration.inMilliseconds.toDouble();
        return Row(
          children: [
            Text(_formatDuration(position), style: timeStyle),
            Expanded(
              // Touch only: with a remote the +-30s buttons seek, and a
              // focusable slider would swallow left/right navigation.
              child: ExcludeFocus(
                child: Slider(
                  value: max > 0
                      ? position.inMilliseconds.toDouble().clamp(0, max)
                      : 0,
                  max: max > 0 ? max : 1,
                  onChanged: max > 0
                      ? (value) {
                          _restartHideTimer();
                          unawaited(
                            widget.player.seek(
                              Duration(milliseconds: value.round()),
                            ),
                          );
                        }
                      : null,
                ),
              ),
            ),
            Text(_formatDuration(duration), style: timeStyle),
          ],
        );
      },
    );
  }

  static String _formatDuration(Duration value) {
    String two(int n) => n.toString().padLeft(2, '0');
    final hours = value.inHours;
    final minutes = two(value.inMinutes.remainder(60));
    final seconds = two(value.inSeconds.remainder(60));
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'AO VIVO',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Round player button that inverts its colors when focused by the D-pad.
class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final FocusNode? focusNode;
  final double size;
  final String? label;

  const _OverlayButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.focusNode,
    this.size = 26,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? Colors.white
            : Colors.black54,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.focused) ? Colors.black : Colors.white,
      ),
      padding: const WidgetStatePropertyAll(EdgeInsets.all(10)),
    );
    final label = this.label;
    return Tooltip(
      message: tooltip,
      child: label == null
          ? IconButton(
              focusNode: focusNode,
              style: style,
              iconSize: size,
              icon: Icon(icon),
              onPressed: onPressed,
            )
          : TextButton.icon(
              focusNode: focusNode,
              style: style.copyWith(
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              icon: Icon(icon, size: size),
              label: Text(label),
              onPressed: onPressed,
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
  final String sceneId;
  final _VideoAdjustments adjustments;
  final _VideoAdjustments customAdjustments;
  final bool stableFps;
  final double volume;
  final int cacheSeconds;
  final ValueChanged<String> onSceneChanged;
  final ValueChanged<_VideoAdjustments> onAdjustmentsChanged;
  final ValueChanged<bool> onStableFpsChanged;
  final ValueChanged<double> onVolumeChanged;

  const _PlayerVideoSettingsButton({
    required this.sceneId,
    required this.adjustments,
    required this.customAdjustments,
    required this.stableFps,
    required this.volume,
    required this.cacheSeconds,
    required this.onSceneChanged,
    required this.onAdjustmentsChanged,
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
    var draftSceneId = sceneId;
    var draftAdjustments = adjustments;
    var draftCustomAdjustments = customAdjustments;
    var draftStableFps = stableFps;
    var draftVolume = volume;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.tune),
                SizedBox(width: 10),
                Text('Imagem e reproducao'),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Cenas de imagem',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final scene in _videoScenePresets)
                          ChoiceChip(
                            avatar: Icon(scene.icon, size: 18),
                            label: Text(scene.name),
                            selected: draftSceneId == scene.id,
                            onSelected: (selected) {
                              if (!selected) return;
                              final selectedAdjustments = scene.id == 'custom'
                                  ? draftCustomAdjustments
                                  : scene.adjustments;
                              setDialogState(() {
                                draftSceneId = scene.id;
                                draftAdjustments = selectedAdjustments;
                              });
                              onSceneChanged(scene.id);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _videoScenePresets
                          .firstWhere((scene) => scene.id == draftSceneId)
                          .description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Divider(height: 28),
                    _ImageAdjustmentSlider(
                      icon: Icons.brightness_6_outlined,
                      label: 'Brilho',
                      value: draftAdjustments.brightness,
                      onChanged: (value) {
                        final updated = draftAdjustments.copyWith(
                          brightness: value,
                        );
                        setDialogState(() {
                          draftSceneId = 'custom';
                          draftAdjustments = updated;
                          draftCustomAdjustments = updated;
                        });
                        onAdjustmentsChanged(updated);
                      },
                    ),
                    _ImageAdjustmentSlider(
                      icon: Icons.contrast,
                      label: 'Contraste',
                      value: draftAdjustments.contrast,
                      onChanged: (value) {
                        final updated = draftAdjustments.copyWith(
                          contrast: value,
                        );
                        setDialogState(() {
                          draftSceneId = 'custom';
                          draftAdjustments = updated;
                          draftCustomAdjustments = updated;
                        });
                        onAdjustmentsChanged(updated);
                      },
                    ),
                    _ImageAdjustmentSlider(
                      icon: Icons.palette_outlined,
                      label: 'Saturacao',
                      value: draftAdjustments.saturation,
                      onChanged: (value) {
                        final updated = draftAdjustments.copyWith(
                          saturation: value,
                        );
                        setDialogState(() {
                          draftSceneId = 'custom';
                          draftAdjustments = updated;
                          draftCustomAdjustments = updated;
                        });
                        onAdjustmentsChanged(updated);
                      },
                    ),
                    _ImageAdjustmentSlider(
                      icon: Icons.tonality_outlined,
                      label: 'Gama',
                      value: draftAdjustments.gamma,
                      onChanged: (value) {
                        final updated = draftAdjustments.copyWith(gamma: value);
                        setDialogState(() {
                          draftSceneId = 'custom';
                          draftAdjustments = updated;
                          draftCustomAdjustments = updated;
                        });
                        onAdjustmentsChanged(updated);
                      },
                    ),
                    _ImageAdjustmentSlider(
                      icon: Icons.gradient_outlined,
                      label: 'Matiz',
                      value: draftAdjustments.hue,
                      onChanged: (value) {
                        final updated = draftAdjustments.copyWith(hue: value);
                        setDialogState(() {
                          draftSceneId = 'custom';
                          draftAdjustments = updated;
                          draftCustomAdjustments = updated;
                        });
                        onAdjustmentsChanged(updated);
                      },
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          const original = _VideoAdjustments();
                          setDialogState(() {
                            draftSceneId = 'original';
                            draftAdjustments = original;
                          });
                          onSceneChanged('original');
                        },
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Restaurar imagem original'),
                      ),
                    ),
                    const Text(
                      'Ao mover qualquer controle, a cena Personalizada e atualizada e salva automaticamente.',
                      style: TextStyle(fontSize: 12),
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
                    Text(
                      'Cache de rede: $cacheSeconds segundos. Se a conexao oscilar, o player espera alguns segundos antes de continuar para evitar varias pausas curtas.',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Atalhos: setas esquerda/direita ou J/L voltam e avancam 30 segundos.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
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

class _ImageAdjustmentSlider extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _ImageAdjustmentSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final roundedValue = value.round();
    final valueLabel = roundedValue > 0 ? '+$roundedValue' : '$roundedValue';
    return Column(
      children: [
        Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
            Text(valueLabel),
          ],
        ),
        Slider(
          value: value.clamp(-100, 100),
          min: -100,
          max: 100,
          divisions: 200,
          label: valueLabel,
          onChanged: onChanged,
        ),
      ],
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
  final bool isStarting;
  final String? errorMessage;
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
    required this.isStarting,
    required this.errorMessage,
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
                        onPressed: isStarting ? null : onWatch,
                        icon: isStarting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.play_arrow),
                        label: Text(
                          isStarting
                              ? 'Preparando o video...'
                              : startPositionSeconds > 0
                              ? 'Continuar de ${_formatPlaybackTime(startPositionSeconds)}'
                              : 'Assistir',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
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
