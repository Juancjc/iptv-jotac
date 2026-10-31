import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/channel.dart';
import '../services/epg_service.dart';
import 'playlist_providers.dart';

final epgServiceProvider = Provider<EpgService>((ref) => EpgService());

/// Upcoming programs for a channel (including the one on air). Keyed by the
/// fields the lookup uses, since a re-synced channel gets a new id.
final channelEpgProvider = FutureProvider.autoDispose
    .family<List<EpgProgram>, ({String playlistId, String name, String streamUrl, String? tvgId})>((ref, key) async {
      final playlists = await ref.read(playlistsProvider.future);
      final playlist = playlists.where((p) => p.id == key.playlistId).firstOrNull;
      final channel = Channel(
        id: '',
        playlistId: key.playlistId,
        name: key.name,
        streamUrl: key.streamUrl,
        tvgId: key.tvgId,
      );
      return ref.watch(epgServiceProvider).programsFor(channel, playlist);
    });

extension ChannelEpgKey on Channel {
  ({String playlistId, String name, String streamUrl, String? tvgId}) get epgKey =>
      (playlistId: playlistId, name: name, streamUrl: streamUrl, tvgId: tvgId);
}
