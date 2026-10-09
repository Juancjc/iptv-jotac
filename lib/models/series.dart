/// A TV series belonging to a registered playlist.
class Series {
  final String id;
  final String playlistId;
  final String title;
  final String? posterUrl;
  final String? category;
  final bool isFavorite;

  const Series({
    required this.id,
    required this.playlistId,
    required this.title,
    this.posterUrl,
    this.category,
    this.isFavorite = false,
  });

  Series copyWith({bool? isFavorite}) {
    return Series(
      id: id,
      playlistId: playlistId,
      title: title,
      posterUrl: posterUrl,
      category: category,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// A single episode of a [Series].
class Episode {
  final String id;
  final String seriesId;
  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final String streamUrl;
  final String? extension;

  const Episode({
    required this.id,
    required this.seriesId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    required this.streamUrl,
    this.extension,
  });
}
