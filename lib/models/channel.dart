/// A single live TV channel belonging to a registered playlist.
class Channel {
  final String id;
  final String playlistId;
  final String name;
  final String? logoUrl;
  final String? category;
  final String streamUrl;
  final bool isFavorite;

  const Channel({
    required this.id,
    required this.playlistId,
    required this.name,
    this.logoUrl,
    this.category,
    required this.streamUrl,
    this.isFavorite = false,
  });

  Channel copyWith({bool? isFavorite}) {
    return Channel(
      id: id,
      playlistId: playlistId,
      name: name,
      logoUrl: logoUrl,
      category: category,
      streamUrl: streamUrl,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
