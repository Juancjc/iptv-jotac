import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/watch_history_entry.dart';
import '../navigation.dart';
import '../services/remote_control_server.dart';
import 'database_provider.dart';
import 'playlist_providers.dart';

/// Something the phone asked the TV to do that needs the home screen's help.
sealed class RemoteCommand {
  const RemoteCommand();
}

/// Go back to the home dashboard, closing whatever is open.
class RemoteGoHome extends RemoteCommand {
  const RemoteGoHome();
}

/// Open the player for this content.
class RemotePlay extends RemoteCommand {
  final String title;
  final String streamUrl;
  final String contentId;
  final WatchableType contentType;
  final String? posterUrl;

  const RemotePlay({
    required this.title,
    required this.streamUrl,
    required this.contentId,
    required this.contentType,
    this.posterUrl,
  });
}

/// Commands from the phone, handled by the home shell.
final remoteCommandsProvider = Provider<StreamController<RemoteCommand>>((ref) {
  final controller = StreamController<RemoteCommand>.broadcast();
  ref.onDispose(controller.close);
  return controller;
});

class RemoteControlState {
  final bool starting;

  /// Address (with access code) to open on the phone; set while active.
  final Uri? url;
  final String? error;

  const RemoteControlState({this.starting = false, this.url, this.error});

  bool get active => url != null;
}

final remoteControlProvider = StateNotifierProvider<RemoteControlNotifier, RemoteControlState>((ref) {
  final notifier = RemoteControlNotifier(_AppRemoteHandler(ref));
  ref.onDispose(notifier.disable);
  return notifier;
});

/// Turns the phone remote control (local web server) on and off.
class RemoteControlNotifier extends StateNotifier<RemoteControlState> {
  final RemoteControlHandler _handler;
  RemoteControlServer? _server;

  RemoteControlNotifier(this._handler) : super(const RemoteControlState());

  Future<void> enable() async {
    if (state.active || state.starting) return;
    state = const RemoteControlState(starting: true);
    final server = RemoteControlServer(_handler);
    try {
      final url = await server.start();
      _server = server;
      if (mounted) state = RemoteControlState(url: url);
    } catch (error) {
      await server.stop();
      if (mounted) state = RemoteControlState(error: 'Nao foi possivel ativar o controle via rede: $error');
    }
  }

  Future<void> disable() async {
    final server = _server;
    _server = null;
    if (mounted) state = const RemoteControlState();
    await server?.stop();
  }
}

/// Answers the phone page using the local database and drives the app.
class _AppRemoteHandler implements RemoteControlHandler {
  final Ref _ref;

  _AppRemoteHandler(this._ref);

  @override
  Future<List<RemoteItem>> playlists() async {
    final playlists = await _ref.read(playlistsProvider.future);
    return [for (final p in playlists) RemoteItem(p.id, p.name)];
  }

  Future<List<({String id, String name, String? image, String category})>> _all(
    RemoteContentType type,
    String? playlistId,
  ) async {
    final repo = _ref.read(playlistRepositoryProvider);
    String cat(String? c) => c == null || c.trim().isEmpty ? 'Sem categoria' : c.trim();
    switch (type) {
      case RemoteContentType.live:
        final channels = await repo.watchChannels(playlistId: playlistId).first;
        return [for (final c in channels) (id: c.id, name: c.name, image: c.logoUrl, category: cat(c.category))];
      case RemoteContentType.movie:
        final movies = await repo.watchMovies(playlistId: playlistId).first;
        return [for (final m in movies) (id: m.id, name: m.title, image: m.posterUrl, category: cat(m.category))];
      case RemoteContentType.series:
        final series = await repo.watchSeries(playlistId: playlistId).first;
        return [for (final s in series) (id: s.id, name: s.title, image: s.posterUrl, category: cat(s.category))];
    }
  }

  @override
  Future<List<RemoteCategory>> categories(RemoteContentType type, String? playlistId) async {
    final counts = <String, int>{};
    for (final item in await _all(type, playlistId)) {
      counts.update(item.category, (n) => n + 1, ifAbsent: () => 1);
    }
    final names = counts.keys.toList()..sort();
    return [for (final n in names) RemoteCategory(n, counts[n]!)];
  }

  @override
  Future<(List<RemoteItem>, int)> items(
    RemoteContentType type, {
    String? playlistId,
    String? category,
    String? query,
    int offset = 0,
    int limit = 100,
  }) async {
    final q = query?.toLowerCase();
    final matches = [
      for (final item in await _all(type, playlistId))
        if ((category == null || category.isEmpty || item.category == category) &&
            (q == null || item.name.toLowerCase().contains(q)))
          item,
    ];
    final page = matches.skip(offset).take(limit);
    return ([for (final i in page) RemoteItem(i.id, i.name, i.image)], matches.length);
  }

  @override
  Future<List<RemoteEpisode>> episodes(String seriesId) async {
    final repo = _ref.read(playlistRepositoryProvider);
    final series = await repo.seriesById(seriesId);
    if (series == null) return const [];
    final episodes = await repo.ensureEpisodesLoaded(series);
    return [for (final e in episodes) RemoteEpisode(e.id, e.seasonNumber, e.episodeNumber, e.title)];
  }

  @override
  Future<void> play(RemoteContentType? type, String id) async {
    final repo = _ref.read(playlistRepositoryProvider);
    final RemotePlay command;
    switch (type) {
      case RemoteContentType.live:
        final c = await repo.channelById(id);
        if (c == null) throw StateError('Canal nao encontrado. Atualize a pagina.');
        command = RemotePlay(
          title: c.name,
          streamUrl: c.streamUrl,
          contentId: c.id,
          contentType: WatchableType.channel,
          posterUrl: c.logoUrl,
        );
      case RemoteContentType.movie:
        final m = await repo.movieById(id);
        if (m == null) throw StateError('Filme nao encontrado. Atualize a pagina.');
        command = RemotePlay(
          title: m.title,
          streamUrl: m.streamUrl,
          contentId: m.id,
          contentType: WatchableType.movie,
          posterUrl: m.posterUrl,
        );
      case null:
        final e = await repo.episodeById(id);
        if (e == null) throw StateError('Episodio nao encontrado. Atualize a pagina.');
        final s = await repo.seriesById(e.seriesId);
        command = RemotePlay(
          title: '${s?.title ?? e.title} - S${e.seasonNumber}E${e.episodeNumber}',
          streamUrl: e.streamUrl,
          contentId: e.id,
          contentType: WatchableType.episode,
          posterUrl: s?.posterUrl,
        );
      case RemoteContentType.series:
        throw StateError('Escolha um episodio da serie.');
    }
    _ref.read(remoteCommandsProvider).add(command);
  }

  @override
  Future<void> pressKey(RemoteKey key) async {
    switch (key) {
      case RemoteKey.up:
        injectKey(LogicalKeyboardKey.arrowUp, PhysicalKeyboardKey.arrowUp);
      case RemoteKey.down:
        injectKey(LogicalKeyboardKey.arrowDown, PhysicalKeyboardKey.arrowDown);
      case RemoteKey.left:
        injectKey(LogicalKeyboardKey.arrowLeft, PhysicalKeyboardKey.arrowLeft);
      case RemoteKey.right:
        injectKey(LogicalKeyboardKey.arrowRight, PhysicalKeyboardKey.arrowRight);
      case RemoteKey.ok:
        injectKey(LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter);
      case RemoteKey.playPause:
        injectKey(LogicalKeyboardKey.mediaPlayPause, PhysicalKeyboardKey.mediaPlayPause);
      case RemoteKey.back:
        // Like the remote's Back: screens may handle it themselves (closing a
        // category, the player controls...); otherwise leave the screen. At
        // the root this never exits the app.
        if (!injectKey(LogicalKeyboardKey.goBack, PhysicalKeyboardKey.browserBack)) {
          await rootNavigatorKey.currentState?.maybePop();
        }
      case RemoteKey.home:
        _ref.read(remoteCommandsProvider).add(const RemoteGoHome());
    }
  }
}

/// Feeds a key press (down + up) through the same path as a real keyboard or
/// TV remote, so focus movement, buttons and the player react exactly as if
/// the key had been pressed on the remote. Returns whether the press was
/// handled by some widget.
bool injectKey(LogicalKeyboardKey logical, PhysicalKeyboardKey physical) {
  final timeStamp = Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);
  final keyboard = HardwareKeyboard.instance;
  // A real key held at the same time would make the synthetic down invalid.
  if (keyboard.physicalKeysPressed.contains(physical)) return false;
  var handled = false;
  for (final event in <KeyEvent>[
    KeyDownEvent(physicalKey: physical, logicalKey: logical, timeStamp: timeStamp),
    KeyUpEvent(physicalKey: physical, logicalKey: logical, timeStamp: timeStamp),
  ]) {
    final byKeyboard = keyboard.handleKeyEvent(event);
    final byFocus =
        ServicesBinding.instance.keyEventManager.keyMessageHandler?.call(KeyMessage([event], null)) ?? false;
    if (event is KeyDownEvent) handled = byKeyboard || byFocus;
  }
  return handled;
}
