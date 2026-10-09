import 'package:dio/dio.dart';

class XtreamCategory {
  final String id;
  final String name;

  const XtreamCategory({required this.id, required this.name});

  factory XtreamCategory.fromJson(Map<String, dynamic> json) {
    return XtreamCategory(
      id: json['category_id'].toString(),
      name: json['category_name']?.toString() ?? 'Sem categoria',
    );
  }
}

class XtreamLiveStream {
  final String streamId;
  final String name;
  final String? streamIcon;
  final String? categoryId;

  const XtreamLiveStream({
    required this.streamId,
    required this.name,
    this.streamIcon,
    this.categoryId,
  });

  factory XtreamLiveStream.fromJson(Map<String, dynamic> json) {
    return XtreamLiveStream(
      streamId: json['stream_id'].toString(),
      name: json['name']?.toString() ?? 'Sem nome',
      streamIcon: json['stream_icon']?.toString(),
      categoryId: json['category_id']?.toString(),
    );
  }
}

class XtreamVodStream {
  final String streamId;
  final String name;
  final String? streamIcon;
  final String? categoryId;
  final String? containerExtension;

  const XtreamVodStream({
    required this.streamId,
    required this.name,
    this.streamIcon,
    this.categoryId,
    this.containerExtension,
  });

  factory XtreamVodStream.fromJson(Map<String, dynamic> json) {
    return XtreamVodStream(
      streamId: json['stream_id'].toString(),
      name: json['name']?.toString() ?? 'Sem nome',
      streamIcon: json['stream_icon']?.toString(),
      categoryId: json['category_id']?.toString(),
      containerExtension: json['container_extension']?.toString(),
    );
  }
}

class XtreamSeries {
  final String seriesId;
  final String name;
  final String? cover;
  final String? categoryId;

  const XtreamSeries({
    required this.seriesId,
    required this.name,
    this.cover,
    this.categoryId,
  });

  factory XtreamSeries.fromJson(Map<String, dynamic> json) {
    return XtreamSeries(
      seriesId: json['series_id'].toString(),
      name: json['name']?.toString() ?? 'Sem nome',
      cover: json['cover']?.toString(),
      categoryId: json['category_id']?.toString(),
    );
  }
}

class XtreamEpisode {
  final String id;
  final String title;
  final int season;
  final int episodeNumber;
  final String? containerExtension;

  const XtreamEpisode({
    required this.id,
    required this.title,
    required this.season,
    required this.episodeNumber,
    this.containerExtension,
  });

  factory XtreamEpisode.fromJson(Map<String, dynamic> json, int season) {
    return XtreamEpisode(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? 'Episodio',
      season: season,
      episodeNumber: int.tryParse(json['episode_num']?.toString() ?? '') ?? 0,
      containerExtension: json['container_extension']?.toString(),
    );
  }
}

/// Thrown when the Xtream Codes panel rejects the given credentials or
/// returns an unexpected payload.
class XtreamAuthException implements Exception {
  final String message;
  const XtreamAuthException(this.message);

  @override
  String toString() => message;
}

/// Minimal client for the Xtream Codes panel API (`player_api.php`) and the
/// direct stream endpoints (`/live`, `/movie`, `/series`).
///
/// This talks to whatever panel the user configures themselves; the app
/// does not ship with, or phone home to, any particular server.
class XtreamApiClient {
  final String host;
  final String username;
  final String password;
  final Dio _dio;

  XtreamApiClient({
    required this.host,
    required this.username,
    required this.password,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  /// True when the configured host uses plain HTTP instead of HTTPS.
  bool get isInsecure => Uri.parse(_normalizedHost).scheme.toLowerCase() == 'http';

  String get _normalizedHost {
    var h = host.trim();
    if (!h.startsWith('http://') && !h.startsWith('https://')) {
      h = 'http://$h';
    }
    if (h.endsWith('/')) h = h.substring(0, h.length - 1);
    return h;
  }

  Uri _apiUri(String action, [Map<String, String>? extra]) {
    return Uri.parse('$_normalizedHost/player_api.php').replace(queryParameters: {
      'username': username,
      'password': password,
      if (action.isNotEmpty) 'action': action,
      ...?extra,
    });
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _dio.getUri(uri);
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      // Some panels return JSON with a text/html content-type, which dio
      // won't auto-decode.
      throw const XtreamAuthException('Resposta inesperada do servidor.');
    }
    throw const XtreamAuthException('Resposta inesperada do servidor.');
  }

  Future<List<dynamic>> _getJsonList(Uri uri) async {
    final response = await _dio.getUri(uri);
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data.isEmpty) return const [];
    throw const XtreamAuthException('Resposta inesperada do servidor.');
  }

  /// Validates credentials by calling the base `player_api.php` endpoint
  /// (no `action`), which returns account/server info on Xtream panels.
  Future<void> authenticate() async {
    final json = await _getJson(_apiUri(''));
    final userInfo = json['user_info'];
    if (userInfo is Map && userInfo['auth'] == 0) {
      throw const XtreamAuthException('Usuario ou senha invalidos.');
    }
  }

  Future<List<XtreamCategory>> getLiveCategories() async {
    final list = await _getJsonList(_apiUri('get_live_categories'));
    return list.map((e) => XtreamCategory.fromJson(e)).toList();
  }

  Future<List<XtreamLiveStream>> getLiveStreams({String? categoryId}) async {
    final list = await _getJsonList(_apiUri('get_live_streams', {
      if (categoryId != null) 'category_id': categoryId,
    }));
    return list.map((e) => XtreamLiveStream.fromJson(e)).toList();
  }

  Future<List<XtreamCategory>> getVodCategories() async {
    final list = await _getJsonList(_apiUri('get_vod_categories'));
    return list.map((e) => XtreamCategory.fromJson(e)).toList();
  }

  Future<List<XtreamVodStream>> getVodStreams({String? categoryId}) async {
    final list = await _getJsonList(_apiUri('get_vod_streams', {
      if (categoryId != null) 'category_id': categoryId,
    }));
    return list.map((e) => XtreamVodStream.fromJson(e)).toList();
  }

  Future<List<XtreamCategory>> getSeriesCategories() async {
    final list = await _getJsonList(_apiUri('get_series_categories'));
    return list.map((e) => XtreamCategory.fromJson(e)).toList();
  }

  Future<List<XtreamSeries>> getSeries({String? categoryId}) async {
    final list = await _getJsonList(_apiUri('get_series', {
      if (categoryId != null) 'category_id': categoryId,
    }));
    return list.map((e) => XtreamSeries.fromJson(e)).toList();
  }

  Future<List<XtreamEpisode>> getSeriesEpisodes(String seriesId) async {
    final json = await _getJson(_apiUri('get_series_info', {'series_id': seriesId}));
    final episodesBySeason = json['episodes'];
    final result = <XtreamEpisode>[];
    if (episodesBySeason is Map) {
      for (final entry in episodesBySeason.entries) {
        final season = int.tryParse(entry.key.toString()) ?? 0;
        final episodes = entry.value;
        if (episodes is List) {
          for (final ep in episodes) {
            result.add(XtreamEpisode.fromJson(ep, season));
          }
        }
      }
    }
    return result;
  }

  String liveStreamUrl(String streamId, {String extension = 'ts'}) {
    return '$_normalizedHost/live/$username/$password/$streamId.$extension';
  }

  String vodStreamUrl(String streamId, {String extension = 'mp4'}) {
    return '$_normalizedHost/movie/$username/$password/$streamId.$extension';
  }

  String seriesEpisodeUrl(String episodeId, {String extension = 'mp4'}) {
    return '$_normalizedHost/series/$username/$password/$episodeId.$extension';
  }
}
