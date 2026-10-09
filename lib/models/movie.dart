/// A single VOD movie belonging to a registered playlist.
class Movie {
  final String id;
  final String playlistId;
  final String title;
  final String? posterUrl;
  final String? category;
  final String streamUrl;
  final String? extension;
  final bool isFavorite;

  const Movie({
    required this.id,
    required this.playlistId,
    required this.title,
    this.posterUrl,
    this.category,
    required this.streamUrl,
    this.extension,
    this.isFavorite = false,
  });

  Movie copyWith({bool? isFavorite}) {
    return Movie(
      id: id,
      playlistId: playlistId,
      title: title,
      posterUrl: posterUrl,
      category: category,
      streamUrl: streamUrl,
      extension: extension,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
