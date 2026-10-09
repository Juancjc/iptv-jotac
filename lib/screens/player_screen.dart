import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../models/watch_history_entry.dart';
import '../providers/database_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _historyRepo = ref.read(watchHistoryRepositoryProvider);
    _player = Player();
    _controller = VideoController(_player);

    _player.open(Media(widget.streamUrl));
    if (widget.startPositionSeconds > 0) {
      _player.stream.duration.first.then((_) {
        _player.seek(Duration(seconds: widget.startPositionSeconds));
      });
    }
    _player.stream.duration.listen((duration) => _lastKnownDuration = duration);
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (_) => _saveProgress());
  }

  Future<void> _saveProgress() async {
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

  @override
  void dispose() {
    _progressTimer?.cancel();
    unawaited(_saveProgress());
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Video(controller: _controller),
      ),
    );
  }
}
