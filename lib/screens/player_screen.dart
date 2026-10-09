import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../models/watch_history_entry.dart';
import '../providers/database_provider.dart';
import '../providers/settings_providers.dart';
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
  Timer? _progressTimer;
  Duration _lastKnownDuration = Duration.zero;
  StreamSubscription<Tracks>? _tracksSubscription;

  bool _readyToWatch = false;
  Tracks? _tracks;
  AudioTrack _selectedAudio = AudioTrack.auto();
  SubtitleTrack _selectedSubtitle = SubtitleTrack.no();

  @override
  void initState() {
    super.initState();
    _historyRepo = ref.read(watchHistoryRepositoryProvider);
    _player = Player();
    _controller = VideoController(_player);

    _player.open(Media(widget.streamUrl), play: false);
    if (widget.startPositionSeconds > 0) {
      _player.stream.duration.first.then((_) {
        _player.seek(Duration(seconds: widget.startPositionSeconds));
      });
    }
    _player.stream.duration.listen((duration) => _lastKnownDuration = duration);
    _tracksSubscription = _player.stream.tracks.listen((tracks) {
      if (mounted) setState(() => _tracks = tracks);
    });
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (_) => _saveProgress());
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
      durationSeconds: _lastKnownDuration.inSeconds > 0 ? _lastKnownDuration.inSeconds : null,
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
    _tracksSubscription?.cancel();
    unawaited(_saveProgress());
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(subtitleFontSizeProvider);
    final textColor = ref.watch(subtitleTextColorProvider);
    final backgroundColor = ref.watch(subtitleBackgroundColorProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Center(
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
          if (!_readyToWatch)
            _PrePlaybackOverlay(
              title: widget.title,
              posterUrl: widget.posterUrl,
              tracks: _tracks,
              selectedAudio: _selectedAudio,
              selectedSubtitle: _selectedSubtitle,
              onAudioChanged: (track) => setState(() => _selectedAudio = track),
              onSubtitleChanged: (track) => setState(() => _selectedSubtitle = track),
              onWatch: _startWatching,
            ),
        ],
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
  final ValueChanged<AudioTrack> onAudioChanged;
  final ValueChanged<SubtitleTrack> onSubtitleChanged;
  final VoidCallback onWatch;

  const _PrePlaybackOverlay({
    required this.title,
    required this.posterUrl,
    required this.tracks,
    required this.selectedAudio,
    required this.selectedSubtitle,
    required this.onAudioChanged,
    required this.onSubtitleChanged,
    required this.onWatch,
  });

  // Real, selectable tracks only: media_kit always injects synthetic
  // 'auto'/'no' entries even when the stream has a single track.
  List<AudioTrack> get _audioOptions => (tracks?.audio ?? const []).where((t) => t.id != 'no').toList();

  List<SubtitleTrack> get _subtitleOptions => (tracks?.subtitle ?? const []).where((t) => t.id != 'auto').toList();

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
            Image.network(poster, fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: .35), Colors.black.withValues(alpha: .88)],
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
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
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
                    if (showAudioPicker && showSubtitlePicker) const SizedBox(height: 12),
                    if (showSubtitlePicker)
                      _OptionDropdown<SubtitleTrack>(
                        icon: Icons.subtitles_outlined,
                        label: 'Legenda',
                        value: selectedSubtitle,
                        items: _subtitleOptions,
                        itemLabel: _subtitleLabel,
                        onChanged: onSubtitleChanged,
                      ),
                    if (showAudioPicker || showSubtitlePicker) const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        autofocus: true,
                        onPressed: onWatch,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Assistir'),
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
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
          icon: const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.arrow_drop_down, color: Colors.white)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          selectedItemBuilder: (context) => items
              .map((item) => Row(
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
                  ))
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
